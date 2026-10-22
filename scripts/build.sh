#!/usr/bin/env bash
# Build LineageOS 23.2 (Android 16) for the Galaxy Tab A 10.1 2019 Wi-Fi (SM-T510).
# 32-bit userspace / 64-bit binder (a64) GSI system image with GApps and face unlock.
#
# Usage: scripts/build.sh [sync|patch|build|all]   (default: all)
#   SRC   source tree, a path without spaces (default ~/android/lineage-23.2)
#   JOBS  parallel jobs (default: nproc)
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
RECIPE="$HERE/build-23.2"
export SRC="${SRC:-$HOME/android/lineage-23.2}"
JOBS="${JOBS:-$(nproc)}"
TARGET=lineage_a64_bgN4-bp4a-userdebug

sync() {
  mkdir -p "$SRC" && cd "$SRC"
  [ -d .repo ] || repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1 --no-clone-bundle
  mkdir -p .repo/local_manifests
  cp "$RECIPE"/local_manifests/*.xml .repo/local_manifests/
  # Google's servers rate-limit (HTTP 429) at high job counts
  repo sync -c -j8 --force-sync --no-tags --no-clone-bundle --optimized-fetch --prune
}

patch() {
  cd "$SRC"
  git config --global am.threeWay true
  # TrebleDroid + MisterZtr GSI patch set
  bash LineageOS_gsi/patches/apply-patches.sh .
  # SM-T510 changes (idempotent)
  bash "$RECIPE/apply-sm-t510.sh"
  # TrebleApp is built separately with Gradle and needs Java 17
  if [ ! -f treble_app/TrebleApp.apk ]; then
    (cd treble_app && JAVA_HOME="${JAVA17_HOME:?set JAVA17_HOME to a JDK 17}" \
      PATH="$JAVA17_HOME/bin:$PATH" bash build.sh)
  fi
}

build() {
  cd "$SRC"
  export USE_CCACHE=1 CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
  command -v ccache >/dev/null && export CCACHE_EXEC="$(command -v ccache)" && ccache -M 60G >/dev/null
  set +u
  source build/envsetup.sh
  lunch "$TARGET"
  set -u
  make systemimage -j"$JOBS"
  echo "built: $SRC/out/target/product/tdgsi_a64_ab/system.img"
}

case "${1:-all}" in
  sync) sync ;;
  patch) patch ;;
  build) build ;;
  all) sync; patch; build ;;
  *) echo "usage: $0 [sync|patch|build|all]"; exit 1 ;;
esac
