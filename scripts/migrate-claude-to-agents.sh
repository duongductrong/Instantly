#!/usr/bin/env bash
# ============================================================================
# migrate-claude-to-agents.sh
# Transforms .claude directory structure → .agents (Google Antigravity format)
# ============================================================================
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLAUDE_DIR="${PROJECT_ROOT}/.claude"
AGENTS_DIR="${PROJECT_ROOT}/.agents"
DRY_RUN=false
FORCE=false
VERBOSE=false

# Counters
SKILLS_COPIED=0
WORKFLOWS_CONVERTED=0
AGENTS_COPIED=0
COMMANDS_CONVERTED=0
SKIPPED=0

# ── Colors ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helpers ────────────────────────────────────────────────────────────────
log()      { echo -e "${BLUE}[INFO]${NC}  $*"; }
success()  { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()     { echo -e "${YELLOW}[SKIP]${NC}  $*"; }
error()    { echo -e "${RED}[ERR]${NC}   $*" >&2; }
verbose()  { $VERBOSE && echo -e "${CYAN}[DBG]${NC}   $*" || true; }
header()   { echo -e "\n${BOLD}═══ $* ═══${NC}"; }

usage() {
  cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [OPTIONS]

Transform .claude directory structure into .agents (Google Antigravity format).

${BOLD}Options:${NC}
  --dry-run    Preview changes without writing anything
  --force      Overwrite existing .agents directory
  --verbose    Show detailed debug output
  --help       Show this help message

${BOLD}What gets migrated:${NC}
  ✅ skills/     → .agents/skills/      (direct copy, already compatible)
  ✅ agents/     → .agents/agents/      (direct copy, YAML frontmatter intact)
  ✅ workflows/  → .agents/workflows/   (adds YAML frontmatter if missing)
  ✅ commands/   → .agents/workflows/   (converted to workflow format)
  ✅ scripts/    → .agents/skills/shared-scripts/  (wrapped as a skill)
  ✅ CLAUDE.md   → AGENTS.md            (path references updated)

${BOLD}What is skipped (Claude-specific, no Antigravity equivalent):${NC}
  ⏭  hooks/         ⏭  output-styles/
  ⏭  settings.json  ⏭  statusline scripts
  ⏭  .mcp.json      ⏭  metadata.json
EOF
}

# ── Parse arguments ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --force)    FORCE=true; shift ;;
    --verbose)  VERBOSE=true; shift ;;
    --help)     usage; exit 0 ;;
    *)          error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# ── Preflight checks ──────────────────────────────────────────────────────
if [[ ! -d "$CLAUDE_DIR" ]]; then
  error "No .claude directory found at: $CLAUDE_DIR"
  exit 1
fi

if [[ -d "$AGENTS_DIR" ]] && ! $FORCE; then
  error ".agents directory already exists. Use --force to overwrite."
  exit 1
fi

if $DRY_RUN; then
  echo -e "\n${YELLOW}${BOLD}═══ DRY RUN MODE — no files will be written ═══${NC}\n"
fi

# ── Safe filesystem ops ───────────────────────────────────────────────────
safe_mkdir() {
  if $DRY_RUN; then
    verbose "mkdir -p $1"
  else
    mkdir -p "$1"
  fi
}

safe_cp() {
  if $DRY_RUN; then
    verbose "cp $1 → $2"
  else
    cp "$1" "$2"
  fi
}

safe_cp_r() {
  if $DRY_RUN; then
    verbose "cp -r $1 → $2"
  else
    cp -r "$1" "$2"
  fi
}

safe_write() {
  local dest="$1"
  local content="$2"
  if $DRY_RUN; then
    verbose "write → $dest (${#content} bytes)"
  else
    echo "$content" > "$dest"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# STEP 1: Create .agents/ directory structure
# ═══════════════════════════════════════════════════════════════════════════
header "Step 1: Creating .agents directory structure"

if [[ -d "$AGENTS_DIR" ]] && $FORCE && ! $DRY_RUN; then
  log "Removing existing .agents directory..."
  rm -rf "$AGENTS_DIR"
fi

safe_mkdir "$AGENTS_DIR/skills"
safe_mkdir "$AGENTS_DIR/workflows"
safe_mkdir "$AGENTS_DIR/agents"
success "Created .agents/{skills,workflows,agents}"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 2: Copy skills (already Antigravity-compatible)
# ═══════════════════════════════════════════════════════════════════════════
header "Step 2: Migrating skills"

if [[ -d "$CLAUDE_DIR/skills" ]]; then
  for skill_dir in "$CLAUDE_DIR/skills"/*/; do
    [[ ! -d "$skill_dir" ]] && continue
    skill_name=$(basename "$skill_dir")

    if [[ -f "$skill_dir/SKILL.md" ]]; then
      safe_cp_r "$skill_dir" "$AGENTS_DIR/skills/$skill_name"
      success "Skill: $skill_name"
      ((SKILLS_COPIED++))
    else
      warn "Skipping $skill_name (no SKILL.md found)"
      ((SKIPPED++))
    fi
  done

  # Copy root-level skill docs (agent_skills_spec.md, README, etc.)
  for file in "$CLAUDE_DIR/skills"/*.md; do
    [[ ! -f "$file" ]] && continue
    fname=$(basename "$file")
    safe_cp "$file" "$AGENTS_DIR/skills/$fname"
    verbose "Copied skill doc: $fname"
  done
else
  warn "No skills/ directory found in .claude"
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 3: Migrate workflows (add YAML frontmatter if missing)
# ═══════════════════════════════════════════════════════════════════════════
header "Step 3: Migrating workflows"

add_workflow_frontmatter() {
  local file="$1"
  local dest="$2"
  local content
  content=$(cat "$file")

  # Check if file already has YAML frontmatter
  if echo "$content" | head -1 | grep -q '^---$'; then
    # Already has frontmatter, copy as-is
    safe_cp "$file" "$dest"
    verbose "  (already has frontmatter)"
    return
  fi

  # Extract title from first # heading for description
  local title
  title=$(echo "$content" | grep -m1 '^# ' | sed 's/^# //' || echo "")
  if [[ -z "$title" ]]; then
    title=$(basename "$file" .md | sed 's/-/ /g; s/\b\(.\)/\u\1/g')
  fi

  # Build new content with frontmatter
  local new_content="---
description: ${title}
---

${content}"

  safe_write "$dest" "$new_content"
}

if [[ -d "$CLAUDE_DIR/workflows" ]]; then
  for wf_file in "$CLAUDE_DIR/workflows"/*.md; do
    [[ ! -f "$wf_file" ]] && continue
    fname=$(basename "$wf_file")
    dest="$AGENTS_DIR/workflows/$fname"

    add_workflow_frontmatter "$wf_file" "$dest"
    success "Workflow: $fname"
    ((WORKFLOWS_CONVERTED++))
  done
else
  warn "No workflows/ directory found in .claude"
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 4: Copy agents (already has YAML frontmatter)
# ═══════════════════════════════════════════════════════════════════════════
header "Step 4: Migrating agents"

if [[ -d "$CLAUDE_DIR/agents" ]]; then
  for agent_file in "$CLAUDE_DIR/agents"/*.md; do
    [[ ! -f "$agent_file" ]] && continue
    fname=$(basename "$agent_file")
    safe_cp "$agent_file" "$AGENTS_DIR/agents/$fname"
    success "Agent: $fname"
    ((AGENTS_COPIED++))
  done
else
  warn "No agents/ directory found in .claude"
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 5: Convert commands → workflows
# ═══════════════════════════════════════════════════════════════════════════
header "Step 5: Converting commands → workflows"

convert_command_to_workflow() {
  local file="$1"
  local dest="$2"
  local content
  content=$(cat "$file")
  local fname
  fname=$(basename "$file" .md)

  # Commands already have YAML frontmatter with 'description'
  # We need to check and transform if needed
  if echo "$content" | head -1 | grep -q '^---$'; then
    # Has frontmatter — check if 'description' exists
    if echo "$content" | head -10 | grep -q '^description:'; then
      # Already has description in frontmatter, copy as-is
      safe_cp "$file" "$dest"
      return
    fi
  fi

  # Fallback: add description frontmatter
  local title
  title=$(echo "$content" | grep -m1 '^# ' | sed 's/^# //' || echo "$fname")

  local new_content="---
description: ${title}
---

${content}"

  safe_write "$dest" "$new_content"
}

if [[ -d "$CLAUDE_DIR/commands" ]]; then
  # Process top-level .md files
  for cmd_file in "$CLAUDE_DIR/commands"/*.md; do
    [[ ! -f "$cmd_file" ]] && continue
    fname=$(basename "$cmd_file")

    # Avoid collision with existing workflows
    dest="$AGENTS_DIR/workflows/$fname"
    if [[ -f "$dest" ]]; then
      dest="$AGENTS_DIR/workflows/cmd-${fname}"
      verbose "  Renamed to cmd-${fname} to avoid collision"
    fi

    convert_command_to_workflow "$cmd_file" "$dest"
    success "Command → Workflow: $fname"
    ((COMMANDS_CONVERTED++))
  done

  # Process command subdirectories (e.g., commands/code/, commands/git/)
  for cmd_subdir in "$CLAUDE_DIR/commands"/*/; do
    [[ ! -d "$cmd_subdir" ]] && continue
    subdir_name=$(basename "$cmd_subdir")

    # Create matching subdirectory in workflows
    safe_mkdir "$AGENTS_DIR/workflows/$subdir_name"

    for cmd_file in "$cmd_subdir"*.md; do
      [[ ! -f "$cmd_file" ]] && continue
      fname=$(basename "$cmd_file")
      dest="$AGENTS_DIR/workflows/$subdir_name/$fname"

      convert_command_to_workflow "$cmd_file" "$dest"
      success "Command → Workflow: $subdir_name/$fname"
      ((COMMANDS_CONVERTED++))
    done
  done
else
  warn "No commands/ directory found in .claude"
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6: Wrap .claude/scripts as a shared-scripts skill
# ═══════════════════════════════════════════════════════════════════════════
header "Step 6: Creating shared-scripts skill"

if [[ -d "$CLAUDE_DIR/scripts" ]]; then
  safe_mkdir "$AGENTS_DIR/skills/shared-scripts/scripts"

  # Copy all scripts
  for script in "$CLAUDE_DIR/scripts"/*; do
    [[ ! -f "$script" ]] && continue
    fname=$(basename "$script")
    safe_cp "$script" "$AGENTS_DIR/skills/shared-scripts/scripts/$fname"
    verbose "Copied script: $fname"
  done

  # Generate SKILL.md
  local_skill_md="---
name: shared-scripts
description: >-
  Shared utility scripts for project management, code generation, and
  development workflows. Contains Python and JavaScript helper scripts
  for tasks like skill/command scanning, environment resolution, worktree
  management, and catalog generation.
---

# Shared Scripts

Utility scripts migrated from the Claude Code configuration.

## Available Scripts

$(for f in "$CLAUDE_DIR/scripts"/*; do
  [[ -f "$f" ]] && echo "- \`$(basename "$f")\` — $(head -1 "$f" | sed 's/^#\+\s*//' | sed 's/^\/\/.*//' | head -c 80)"
done)

## Usage

Run scripts from the project root:

\`\`\`bash
# For Python scripts
python3 .agents/skills/shared-scripts/scripts/<script-name>.py

# For JavaScript scripts
node .agents/skills/shared-scripts/scripts/<script-name>.cjs
\`\`\`"

  safe_write "$AGENTS_DIR/skills/shared-scripts/SKILL.md" "$local_skill_md"
  success "Created shared-scripts skill with $(ls "$CLAUDE_DIR/scripts"/* 2>/dev/null | wc -l | tr -d ' ') scripts"
else
  warn "No scripts/ directory found in .claude"
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 7: Generate AGENTS.md from CLAUDE.md
# ═══════════════════════════════════════════════════════════════════════════
header "Step 7: Generating AGENTS.md"

AGENTS_MD_PATH="${PROJECT_ROOT}/AGENTS.md"

if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then
  local_agents_content=$(cat "${PROJECT_ROOT}/CLAUDE.md")

  # Transform path references
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.claude/workflows/|.agents/workflows/|g')
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.claude/skills/|.agents/skills/|g')
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.claude/agents/|.agents/agents/|g')
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.claude/commands/|.agents/workflows/|g')
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.claude/scripts/|.agents/skills/shared-scripts/scripts/|g')
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.\/\.claude|./.agents|g')
  local_agents_content=$(echo "$local_agents_content" | sed 's|\.claude|.agents|g')

  # Replace header
  local_agents_content=$(echo "$local_agents_content" | sed '1s/^# CLAUDE\.md/# AGENTS.md/')
  local_agents_content=$(echo "$local_agents_content" | sed 's/Claude Code (claude\.ai\/code)/AI coding agents (Claude Code, Gemini CLI, Google Antigravity)/g')

  safe_write "$AGENTS_MD_PATH" "$local_agents_content"
  success "Generated AGENTS.md from CLAUDE.md"
else
  warn "No CLAUDE.md found at project root"
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 8: Generate .agents/.gitignore
# ═══════════════════════════════════════════════════════════════════════════
header "Step 8: Generating .agents/.gitignore"

gitignore_content="# Environment and secrets
.env
.env.*
!.env.example

# Python virtual environments
.venv/
__pycache__/

# OS files
.DS_Store
Thumbs.db

# IDE
.idea/
*.swp"

safe_write "$AGENTS_DIR/.gitignore" "$gitignore_content"
success "Created .agents/.gitignore"

# ═══════════════════════════════════════════════════════════════════════════
# Migration Report
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║              Migration Report                            ║${NC}"
echo -e "${BOLD}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║${NC}  ${GREEN}Skills copied:${NC}           $(printf '%-30s' "$SKILLS_COPIED")${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${GREEN}Workflows converted:${NC}     $(printf '%-30s' "$WORKFLOWS_CONVERTED")${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${GREEN}Agents copied:${NC}           $(printf '%-30s' "$AGENTS_COPIED")${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${GREEN}Commands → Workflows:${NC}    $(printf '%-30s' "$COMMANDS_CONVERTED")${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${YELLOW}Items skipped:${NC}           $(printf '%-30s' "$SKIPPED")${BOLD}║${NC}"
echo -e "${BOLD}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║${NC}  ${CYAN}Output:${NC} .agents/                                     ${BOLD}║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"

if $DRY_RUN; then
  echo -e "\n${YELLOW}${BOLD}Dry run complete. No files were modified.${NC}"
  echo -e "Run without --dry-run to apply changes.\n"
else
  echo ""
  echo -e "${BOLD}Skipped (Claude-specific, no Antigravity equivalent):${NC}"
  echo "  • hooks/          — lifecycle hooks (Claude Code proprietary)"
  echo "  • output-styles/  — coding-level output presets"
  echo "  • settings.json   — Claude settings config"
  echo "  • statusline.*    — Claude statusline scripts"
  echo "  • .mcp.json       — MCP server config"
  echo ""
  echo -e "${GREEN}${BOLD}✅ Migration complete!${NC}"
  echo -e "The .agents/ directory is ready for Google Antigravity & Gemini CLI.\n"
fi
