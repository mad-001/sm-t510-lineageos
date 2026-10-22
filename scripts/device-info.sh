#!/usr/bin/env bash
# Capture SM-T510 identity and lock state via Windows adb.exe.
# Usage: scripts/device-info.sh <label>   (e.g. pre-unlock, post-unlock)
set -euo pipefail
ADB=/mnt/c/temp/sm-t510/platform-tools/adb.exe
OUT="$(dirname "$0")/../backups/device-info-${1:-now}-$(date +%Y%m%d-%H%M%S).txt"
"$ADB" wait-for-device
{
  for p in ro.product.model ro.product.device ro.build.display.id ro.build.PDA ro.bootloader \
           ro.build.version.release ro.build.version.security_patch ro.csc.sales_code ro.boot.carrierid \
           ro.product.cpu.abilist ro.vendor.product.cpu.abilist ro.treble.enabled ro.build.system_root_image \
           ro.boot.dynamic_partitions ro.boot.flash.locked ro.boot.verifiedbootstate ro.boot.warranty_bit \
           ro.oem_unlock_supported sys.oem_unlock_allowed ro.boot.em.status; do
    printf '%s=%s\n' "$p" "$("$ADB" shell getprop "$p" | tr -d '\r')"
  done
  echo "--- kernel"; "$ADB" shell uname -a | tr -d '\r'
  echo "--- partitions"; "$ADB" shell ls -l /dev/block/by-name/ 2>/dev/null | tr -d '\r' || true
} | tee "$OUT"
# Hard stop if this is ever a Verizon device
grep -qiE 'csc.sales_code=VZW|carrierid=VZW' "$OUT" && { echo "VERIZON CSC DETECTED - STOP"; exit 1; } || true
