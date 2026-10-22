#!/usr/bin/env bash
# Apply SM-T510 changes on top of a synced + MisterZtr-patched LineageOS 22.2 GSI tree.
# Safe to re-run.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${SRC:-$HOME/android/lineage-22.2}"
GIT="git -c user.name=mad-001 -c user.email=mad-001@users.noreply.github.com"

# BPF-less fixes for the 4.4 kernel (retiredtab, ported)
for p in "$HERE"/patches/packages_modules_Connectivity/*.patch; do
  subj="$(sed -n 's/^Subject: \[PATCH[^]]*\] //p' "$p")"
  (cd "$SRC/packages/modules/Connectivity"
   if git log -50 --format=%s | grep -xF "$subj" >/dev/null; then echo "already: $subj"; else $GIT am -q --3way "$p"; fi)
done

# Audio HIDL 4.0 client (vendor only provides android.hardware.audio@4.0)
python3 "$HERE/audio-hidl-v4.py" "$SRC/frameworks/av"
(cd "$SRC/frameworks/av"; git diff --quiet || $GIT commit -qam "SM-T510: re-add audio HIDL HAL V4 client")

# Wi-Fi only (com.android.phone crash blocks deep sleep)
T="$SRC/device/phh/treble"
sed -i '/vendor\/lineage\/config\/common_full_phone.mk/d' "$T/lineage.mk"
sed -i 's|vendor/lineage/config/common_full_tablet.mk|vendor/lineage/config/common_full_tablet_wifionly.mk|' "$T/lineage.mk"
sed -i 's|^\$(call inherit-product, \$(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)|$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)|' "$T/base.mk"

# a64 product + exact T510 system partition size
cp "$HERE"/products/* "$T/"
grep -q lineage_a64_bgN4 "$T/AndroidProducts.mk" ||
  sed -i 's|PRODUCT_MAKEFILES += \\|PRODUCT_MAKEFILES += \\\n    $(LOCAL_DIR)/lineage_a64_bgN4.mk \\|' "$T/AndroidProducts.mk"
sed -i 's/^BOARD_SYSTEMIMAGE_PARTITION_SIZE := .*/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3196059648/' "$T/tdgsi_a64_ab/BoardConfig.mk"

# Face unlock: 32-bit Megvii libs
F="$SRC/packages/apps/FaceUnlock"
mkdir -p "$F/lib32" && cp "$HERE"/faceunlock-lib32/*.so "$F/lib32/"
python3 - "$F/Android.bp" <<'PY'
import re, sys
p = sys.argv[1]; t = open(p).read()
if 'lib32/' in t: sys.exit(0)
t = re.sub(r'android_arm64: \{ srcs: \[ "lib/([^"]+)" \] \},',
           r'android_arm64: { srcs: [ "lib/\1" ] },\n        android_arm: { srcs: [ "lib32/\1" ] },', t)
t = t.replace('compile_multilib: "64"', 'compile_multilib: "both"')
open(p, 'w').write(t)
PY
echo "SM-T510 changes applied"
