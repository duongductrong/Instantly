#!/bin/bash
# bump-version.sh - Bumps MARKETING_VERSION in project.pbxproj
# Usage: ./scripts/bump-version.sh [patch|minor|major]

set -euo pipefail

PBXPROJ="Instantly.xcodeproj/project.pbxproj"
BUMP_TYPE="${1:-patch}"

# Extract current MARKETING_VERSION
CURRENT_VERSION=$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" | sed 's/.*= //' | sed 's/;.*//' | tr -d ' ')

if [ -z "$CURRENT_VERSION" ]; then
  echo "::error::Could not find MARKETING_VERSION in $PBXPROJ"
  exit 1
fi

# Parse semver (handle 2-part versions like "1.0" -> "1.0.0")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
MAJOR="${MAJOR:-0}"
MINOR="${MINOR:-0}"
PATCH="${PATCH:-0}"

# Bump
case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "::error::Invalid bump type: $BUMP_TYPE (use patch, minor, or major)"
    exit 1
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Replace all occurrences of MARKETING_VERSION in pbxproj
sed -i '' "s/MARKETING_VERSION = ${CURRENT_VERSION}/MARKETING_VERSION = ${NEW_VERSION}/g" "$PBXPROJ"

# Bump build number (increment by 1)
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/.*= //' | sed 's/;.*//' | tr -d ' ')
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD}/CURRENT_PROJECT_VERSION = ${NEW_BUILD}/g" "$PBXPROJ"

echo "version=${NEW_VERSION}"
echo "previous_version=${CURRENT_VERSION}"
echo "build_number=${NEW_BUILD}"
