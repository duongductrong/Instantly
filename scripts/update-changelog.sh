#!/bin/bash
# update-changelog.sh - Prepends new release section to CHANGELOG.md
# Usage: ./scripts/update-changelog.sh <version> <changelog_path>

set -euo pipefail

VERSION="$1"
CHANGELOG_PATH="$2"
DATE=$(date +%Y-%m-%d)

TMPFILE=$(mktemp)
{
  echo "## [${VERSION}] - ${DATE}"
  echo ""
  cat "$CHANGELOG_PATH"
  echo ""
} > "$TMPFILE"

if [ -f CHANGELOG.md ]; then
  cat CHANGELOG.md >> "$TMPFILE"
fi

mv "$TMPFILE" CHANGELOG.md
