# Changelog

## v23.2-20261022

First release: LineageOS 23.2 (Android 16) for the Galaxy Tab A 10.1 2019 Wi-Fi (SM-T510).

- 32-bit (a64) GSI system image for the stock T510XXU5CWA1 kernel and vendor
- Google apps included (MindTheGapps)
- Face unlock (ParanoidSense with 32-bit Megvii libraries), including "Skip lock screen"
  and "Require eyes to be open"
- USB file transfer (MTP) through Samsung's own MTP driver; available right after boot
- Old 4.4 kernel support: runs without eBPF, audio HAL 4.0, bitmap sharing without
  memfd write seals
- Wi-Fi tablet: no telephony or fingerprint features declared
- SD cards formatted exFAT mount through Samsung's sdfat driver
