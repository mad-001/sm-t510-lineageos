# Installing LineageOS 23.2 (Android 16) on the SM-T510

**SM-T510 (Wi-Fi) only.** Not for the SM-T515 (LTE) or any other model.

Installing from stock **wipes everything on the tablet**. Back up first. The microSD card is not touched.

## What you need
- A Galaxy Tab A 10.1 (2019) **SM-T510** on stock firmware **T510XXU5CWA1** (Android 11, the last Samsung update).
  If you are on something older, update to T510XXU5CWA1 first.
- A Windows PC with [Odin 3.13.3](https://xdaforums.com/t/guide-sm-t510-t515-unlock-twrp-odin-howto-root-tab-a-10-1-2019.3989361/)
  and the Samsung USB drivers (or [samloader](https://github.com/topjohnwu/samloader-rs) on any OS).
- **TWRP 3.7.0 for T510XXU5CWA1** by Magendanz: [XDA thread](https://xdaforums.com/t/recovery-unofficial-twrp-3-7-0-for-2019-galaxy-tab-a-10-1-sm-t510.3934805/)
  (`twrp-3.7.0_11-0-T510XXU5CWA1-20230330.tar.md5`).
- **Multidisabler** by ianmacd: [XDA thread](https://xdaforums.com/t/pie-10-11-system-as-root-multidisabler-disables-encryption-vaultkeeper-auto-flash-of-stock-recovery-proca-wsm-cass-etc.3919714/)
  / [GitHub](https://github.com/ianmacd/multidisabler-samsung).
- The ROM: `lineage-23.2-*-UNOFFICIAL-sm-t510-a64_bgN.img.xz` from
  [Releases](https://github.com/mad-001/sm-t510-lineageos/releases/latest). Unzip it to get the `.img`.
- Put the `.img` and the Multidisabler zip on the microSD card.

**Google apps are already included. Do not flash a GApps package.**

## 1. Unlock the bootloader (wipes the tablet)
Full guide: [XDA: SM-T510/T515 Unlock/TWRP/Odin HowTo](https://xdaforums.com/t/guide-sm-t510-t515-unlock-twrp-odin-howto-root-tab-a-10-1-2019.3989361/)
1. Connect to Wi-Fi. Settings > About tablet > Software information > tap **Build number** 7 times.
2. Developer options: turn on **OEM unlocking**.
3. Power off. Hold **Vol Up + Vol Down** and plug in the USB cable.
4. On the light-blue warning screen, **long-press Vol Up**, then press **Vol Up** to confirm. The tablet wipes and reboots.
5. Go through setup, connect to Wi-Fi, and check that OEM unlocking now says the bootloader is already unlocked.

## 2. Install TWRP
1. Power off. Hold **Vol Up + Vol Down** and plug in the cable, then short-press **Vol Up** for Download mode.
2. In Odin, load the TWRP `.tar.md5` in **AP**, untick Auto Reboot, and press Start.
3. Hold **Power + Vol Down** until the screen goes black, then immediately hold **Power + Vol Up** to boot straight into TWRP.
   If stock Android boots first, it puts the stock recovery back; repeat this step.

## 3. Flash the ROM in TWRP
1. **Install** > Multidisabler zip.
2. **Wipe > Format Data** > type `yes`. Then **Reboot > Recovery**.
3. **Wipe > Advanced Wipe**: Dalvik/ART Cache, Cache, System, Data.
4. **Install > Install Image** > the `lineage-23.2-...img` > **System Image**.
5. Optional: **Wipe > Advanced Wipe > System > Repair or Change File System > Resize File System** (gives the
   system partition its full size).
6. **Reboot > System**. The first boot takes a few minutes.

## Updating to a newer build
Boot TWRP (Power + Vol Up), **Install > Install Image** > new `.img` > **System Image**, then reboot.
No wipe is needed when updating from an earlier build of this ROM.

## Tips
- File transfer to a PC: Developer options > **Default USB configuration** > File transfer.
- Faster feel: Developer options > Window/Transition/Animator scale > 0.5x.
- Face unlock: Settings > Security & privacy > Device unlock > Face unlock.

## Back to stock
Download mode, then flash the T510XXU5CWA1 BL, AP and CSC files with Odin.
