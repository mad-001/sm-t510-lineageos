# Unlock the SM-T510 bootloader

Source: XDA guide 3989361 (MossyTC, mingkee, Magendanz). Unlocking WIPES ALL DATA.

## Before
1. Charge to 80%+. Back up anything you want to keep.
2. Connect to Wi-Fi (the OEM unlocking option can be hidden without internet).
3. Settings > About tablet > Software information > tap Build number 7x.
4. Developer options: turn on **OEM unlocking** and **USB debugging**.
5. Plug in, accept the RSA prompt, run `scripts/device-info.sh pre-unlock`.
   Note the bootloader version (ro.bootloader, e.g. T510XXU5CWA1). Never flash
   anything with a lower binary revision (the 5th character from the end, "5") - anti-rollback.

## Unlock (buttons only, nothing is flashed)
1. Power off completely.
2. Hold **Vol Up + Vol Down** and plug in the USB cable (connected to the PC).
3. Warning screen (light blue): **long-press Vol Up** -> "Unlock bootloader?".
4. Press **Vol Up** to confirm. The tablet wipes and reboots.
   (Short-press Vol Up on the warning screen = normal Download mode instead.)

## After
1. Boot shows the "bootloader is unlocked" warning every time (Power skips it).
2. Go through setup, **connect to Wi-Fi**, enable Developer options again.
3. OEM unlocking must show greyed out / "Bootloader is already unlocked".
   If it's missing, the unlock is incomplete and Odin flashes fail on product.img.
4. Enable USB debugging, run `scripts/device-info.sh post-unlock`.
5. Optional check: Download mode screen should show OEM LOCK: OFF and KG/RMM state not Prenormal.
