#!/usr/bin/env bash
# Publish a GitHub release of the current build.
#
# Usage: scripts/release.sh [image]   (default: the system.img in the source tree)
# Version and file name come from the build date. Release notes are the newest
# section of CHANGELOG.md, so add an entry there before releasing.
#
# Pushing the tag triggers .github/workflows/release.yml, which creates the release
# page with those notes; this script then uploads the image (too big to build on
# GitHub's runners) to it.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${SRC:-$HOME/android/lineage-23.2}"
IMG="${1:-$SRC/out/target/product/tdgsi_a64_ab/system.img}"
WORK="${WORK:-$HOME/android/release}"
DATE="$(date -r "$IMG" +%Y%m%d)"
TAG="v23.2-$DATE"
NAME="lineage-23.2-$DATE-UNOFFICIAL-sm-t510-a64_bgN.img"

cd "$HERE"
grep -q "^## $TAG" CHANGELOG.md || { echo "Add a '## $TAG' section to CHANGELOG.md first"; exit 1; }

mkdir -p "$WORK"
if [ ! -f "$WORK/$NAME.xz" ] || [ "$IMG" -nt "$WORK/$NAME.xz" ]; then
  cp "$IMG" "$WORK/$NAME"
  xz -T0 -6 -f "$WORK/$NAME"
  (cd "$WORK" && sha256sum "$NAME.xz" > "$NAME.xz.sha256")
fi

git add -A
git diff --cached --quiet || git commit -m "Release $TAG"
git push origin HEAD
if ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  git tag -a "$TAG" -m "$TAG"
fi
git push origin "$TAG"

# Wait for the workflow to create the release page, then attach the image
for _ in $(seq 1 60); do
  gh release view "$TAG" >/dev/null 2>&1 && break
  sleep 10
done
gh release view "$TAG" >/dev/null 2>&1 || gh release create "$TAG" --title "$TAG" --notes-file <(scripts/changelog-section.sh "$TAG")
gh release upload "$TAG" "$WORK/$NAME.xz" "$WORK/$NAME.xz.sha256" --clobber
gh release view "$TAG" --json url -q .url
