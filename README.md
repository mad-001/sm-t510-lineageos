# LineageOS 23.2 (Android 16) for the Galaxy Tab A 10.1 2019 (SM-T510)

Unofficial LineageOS 23.2 (Android 16) for the **Samsung Galaxy Tab A 10.1 (2019) Wi-Fi, SM-T510**,
with Google apps and face unlock included.

It is a Treble GSI system image built for this tablet's 32-bit userspace (a64: arm32 with 64-bit binder).
It runs on Samsung's stock **T510XXU5CWA1** kernel and vendor; only the System partition is replaced.

**[Download the latest release](https://github.com/mad-001/sm-t510-lineageos/releases/latest)** ·
**[Install guide](docs/INSTALL.md)** · **[Changelog](CHANGELOG.md)**

> **Provided as is. No feature requests.** This is built for one person's tablet and shared in case it helps
> someone else. If you want different features, everything needed to build it is in this repository:
> build it yourself.

## What's included
- LineageOS 23.2 (Android 16)
- **Google apps** (MindTheGapps). Do not flash GApps separately.
- **Face unlock** (ParanoidSense + Megvii), with "Skip lock screen" and "Require eyes to be open"
- USB file transfer (MTP) and adb
- Wi-Fi, Bluetooth, audio, both cameras, sensors, microSD card

## Not included / by design
- No root and no Magisk
- Wi-Fi only: no phone calls or SMS on the tablet itself (use Google Messages device pairing for texts)
- The bootloader-unlocked warning at power-on is Samsung's and cannot be removed
- No auto-brightness: the SM-T510 has no ambient light sensor (same as stock)

## Changes made for the SM-T510
The tablet ships Android 11 with a Linux 4.4 kernel, which Android 16 no longer expects. The recipe in
[`build-23.2/`](build-23.2) applies these on top of LineageOS + TrebleDroid + MisterZtr's GSI patches:

| Change | Why |
|---|---|
| 32-bit `lineage_a64_bgN4` product, ext4, exact 3,196,059,648-byte system partition | 32-bit vendor, no EROFS in the 4.4 kernel |
| No-eBPF networking (`sm-t510-bpf.rc`, netd/bpfloader changes) | the 4.4 kernel has no usable eBPF |
| Audio HIDL 4.0 client restored | the vendor only provides `android.hardware.audio@4.0` |
| `MtpSamsungHandle` for `/dev/usb_mtp_gadget` | Samsung's `f_mtp_samsung` driver isn't supported by AOSP's MTP server |
| Vendor script owns the adb/mtp/ptp/rndis USB setup | stops a race that dropped the tablet to adb-only |
| MTP storages registered once | storages appeared twice on the PC |
| Bitmaps fall back to ashmem without `F_SEAL_FUTURE_WRITE` | memfd write seals need Linux 5.1 (Settings crashed) |
| Face unlock framework (SenseProvider) + 32-bit Megvii libraries | face unlock on a 32-bit userspace |
| "Require eyes to be open" | uses the Megvii engine's eye-closed check |
| Wi-Fi only, no fingerprint/telephony features, no OPPO fingerprint compat HAL | matches the hardware |

## Building
Needs Linux, ~300 GB of disk, 32 GB+ RAM (or swap), [repo](https://source.android.com/docs/setup/download),
git-lfs, and a JDK 17 for TrebleApp.

```sh
JAVA17_HOME=/path/to/jdk17 scripts/build.sh          # sync + patch + build
# output: ~/android/lineage-23.2/out/target/product/tdgsi_a64_ab/system.img
```

Stages can be run separately: `scripts/build.sh sync|patch|build`. Source tree location: `SRC=/path` (no spaces).

### Releasing
Add a `## v23.2-YYYYMMDD` section to `CHANGELOG.md`, then run `scripts/release.sh`. It compresses the image,
commits, and pushes a tag. GitHub Actions creates the release page from the changelog, and the script uploads
the image and its checksum to it.

## Credits
This build stands on other people's work:

- [LineageOS](https://github.com/LineageOS): the operating system
- [TrebleDroid](https://github.com/TrebleDroid) and [Pierre-Hugues Husson (phhusson)](https://github.com/phhusson):
  Treble GSI device tree and patches, including the 32-bit (a64) target
- [MisterZtr](https://github.com/MisterZtr): [LineageOS_gsi](https://github.com/MisterZtr/LineageOS_gsi) build
  scripts and patches, [treble_manifest](https://github.com/MisterZtr/treble_manifest)
- [AndyCGYan](https://github.com/AndyCGYan), [Ponces](https://github.com/ponces), [Peter Cai](https://github.com/PeterCxy)
  and the other contributors credited in MisterZtr's repository: GSI build work and patches
- [retiredtab](https://github.com/retiredtab) and UDPSendToFailed: SM-T510 GSI work and the BPF-less
  networking hacks for old kernels, and documenting the audio HAL 4.0 and Wi-Fi-only fixes this tablet needs
- [Magendanz](https://github.com/Magendanz): TWRP for the SM-T510 and years of SM-T510 ROMs
- [Paranoid Android (AOSPA)](https://github.com/AOSPA): ParanoidSense face unlock
- [Evolution-X](https://github.com/Evolution-X): the FaceUnlock app and its Android 16 SenseProvider adaptation
- [AOSP-11/vendor_apps_FaceUnlock](https://github.com/AOSP-11/vendor_apps_FaceUnlock): the 32-bit Megvii libraries
- Megvii: face recognition libraries (proprietary, redistributed as in the projects above)
- [MindTheGapps](https://gitlab.com/MindTheGapps): Google apps package
- [ianmacd](https://github.com/ianmacd/multidisabler-samsung): Multidisabler
- mingkee and MossyTC on XDA: SM-T510 bootloader unlock guides
- [topjohnwu](https://github.com/topjohnwu/samloader-rs): samloader (firmware download and flashing)
- Samsung: the stock kernel and vendor this runs on

## License
The scripts, patches and code written for this project are under the [Apache License 2.0](LICENSE).
Third-party components keep their own licenses. The Megvii libraries and Google apps are proprietary.
