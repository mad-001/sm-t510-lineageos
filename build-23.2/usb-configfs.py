# SM-T510: Samsung's vendor init.exynos7904.usb.rc configures adb, mtp,adb, ptp,adb and rndis,adb itself
# through /sys/class/android_usb/android0/functions. AOSP's init.usb.configfs.rc also symlinks the same
# functions into configfs; when both race, Samsung's configfs GSI hook (make_adb_connection_for_gsi) drops
# everything but adb, so MTP disappears. Leave those modes to the vendor script.
import re, sys
p = f"{sys.argv[1]}/rootdir/init.usb.configfs.rc"
t = open(p).read()
modes = ("adb", "mtp,adb", "ptp,adb", "rndis,adb")
out, drop = [], False
for line in t.split("\n"):
    if line.startswith("on "):
        drop = any(line == f"on property:sys.usb.ffs.ready=1 && property:sys.usb.config={m} && property:sys.usb.configfs=1"
                   for m in modes)
    if drop and (line.strip().startswith("symlink /config/usb_gadget/") or
                 line.strip().startswith("write /config/usb_gadget/g1/UDC")):
        out.append("    # SM-T510: handled by vendor init.exynos7904.usb.rc: " + line.strip())
        continue
    out.append(line)
open(p, "w").write("\n".join(out))
