#!/usr/bin/env bash
# Apply SM-T510 changes on top of a synced + MisterZtr-patched LineageOS 23.2 GSI tree.
# Safe to re-run.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${SRC:-$HOME/android/lineage-23.2}"
GIT="git -c user.name=mad-001 -c user.email=mad-001@users.noreply.github.com"

# No eBPF on the 4.4 kernel: never reboot on bpfloader failure, don't wait for platform BPF programs
(cd "$SRC/packages/modules/Connectivity"
 sed -i 's/^\(\s*\)reboot_on_failure \(reboot,\(bpfloader\|netbpfload\)-\(failed\|missing\)\)/#\1reboot_on_failure \2/' bpf/loader/*rc
 sed -i 's|^\(\s*\)bpf::waitForProgsLoaded();|\1// SM-T510 (no BPF): bpf::waitForProgsLoaded();|' bpf/netd/BpfHandler.cpp
 git diff --quiet || $GIT commit -qam "SM-T510: run without eBPF on the 4.4 kernel")

# Audio HIDL 4.0 client (vendor only provides android.hardware.audio@4.0)
python3 "$HERE/audio-hidl-v4.py" "$SRC/frameworks/av"
(cd "$SRC/frameworks/av"; git diff --quiet || $GIT commit -qam "SM-T510: re-add audio HIDL HAL V4 client")

# MTP over Samsung's f_mtp_samsung driver
python3 "$HERE/mtp-samsung.py" "$SRC/frameworks/av" "$HERE"
(cd "$SRC/frameworks/av"; git add -A media/mtp; git diff --cached --quiet || $GIT commit -qm "SM-T510: libmtp: support Samsung f_mtp_samsung (/dev/usb_mtp_gadget)")

# Face unlock framework (ParanoidSense SenseProvider), ported from MisterZtr's 22.2 set
(cd "$SRC/frameworks/base"
 if ! git log -50 --format=%s | grep -F "Add Face Unlock with ParanoidSense" >/dev/null; then
   $GIT am -q --3way "$HERE"/patches/frameworks_base/*.patch
 fi)

# Bitmap parcels: memfd F_SEAL_FUTURE_WRITE needs Linux 5.1+, fall back to ashmem on 4.4
python3 "$HERE/bitmap-memfd.py" "$SRC/frameworks/base"
(cd "$SRC/frameworks/base"; git diff --quiet || $GIT commit -qam "SM-T510: hwui: fall back to ashmem when memfd F_SEAL_FUTURE_WRITE is unsupported")

# MTP: don't register the same storage twice
python3 "$HERE/mtp-storage-dedup.py" "$SRC/frameworks/base"
(cd "$SRC/frameworks/base"; git diff --quiet || $GIT commit -qam "MtpDatabase: ignore duplicate addStorage for an already registered volume")

# USB: let Samsung's vendor script own adb/mtp/ptp/rndis gadget setup (avoids ADB-only GSI fallback)
python3 "$HERE/usb-configfs.py" "$SRC/system/core"
(cd "$SRC/system/core"; git diff --quiet || $GIT commit -qam "SM-T510: init.usb.configfs: leave adb/mtp/ptp/rndis gadget setup to vendor")

# Wi-Fi only (com.android.phone crash blocks deep sleep)
T="$SRC/device/phh/treble"
sed -i '/vendor\/lineage\/config\/common_full_phone.mk/d' "$T/lineage.mk"
grep -q common_full_tablet_wifionly "$T/lineage.mk" ||
  sed -i '1i $(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)' "$T/lineage.mk"
sed -i 's|^\$(call inherit-product, \$(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)|$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)|' "$T/base.mk"

# No OPPO fingerprint compat HAL (it waits ~100s at every boot for hardware the T510 lacks)
sed -i '/android.hardware.biometrics.fingerprint@2.1-service.oppo.compat/d' "$T/base.mk"

# Wi-Fi tablet: don't declare telephony or a fingerprint sensor (TrebleDroid adds them for Huawei)
sed -i '/android.hardware.telephony.gsm.xml\|android.hardware.telephony.ims.xml\|android.hardware.fingerprint.xml/d' "$T/base.mk"

# a64 product + exact T510 system partition size
cp "$HERE"/products/* "$T/"
grep -q lineage_a64_bgN4 "$T/AndroidProducts.mk" ||
  sed -i 's|PRODUCT_MAKEFILES += \\|PRODUCT_MAKEFILES += \\\n    $(LOCAL_DIR)/lineage_a64_bgN4.mk \\|' "$T/AndroidProducts.mk"
sed -i 's/^BOARD_SYSTEMIMAGE_PARTITION_SIZE := .*/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3196059648/' "$T/tdgsi_a64_ab/BoardConfig.mk"

# Face unlock app: "Require eyes to be open" via the Megvii eye-closed check
python3 "$HERE/faceunlock-eyes.py" "$SRC/packages/apps/FaceUnlock"

# Face unlock app: 32-bit Megvii libs
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
