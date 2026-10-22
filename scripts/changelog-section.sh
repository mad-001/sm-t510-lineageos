#!/usr/bin/env bash
# Print the CHANGELOG.md section for a tag (used as release notes).
# Usage: scripts/changelog-section.sh v23.2-YYYYMMDD
set -euo pipefail
tag="$1"
awk -v tag="## $tag" '
  index($0, tag) == 1 { found = 1; next }
  found && /^## / { exit }
  found { print }
' "$(dirname "$0")/../CHANGELOG.md"
