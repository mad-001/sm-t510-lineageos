# Add the Samsung f_mtp_samsung handle to frameworks/av libmtp (SM-T510 MTP over /dev/usb_mtp_gadget).
import os, shutil, sys
av, here = sys.argv[1], sys.argv[2]
mtp = f"{av}/media/mtp"
for f in ("MtpSamsungHandle.h", "MtpSamsungHandle.cpp"):
    shutil.copy(f"{here}/mtp/{f}", f"{mtp}/{f}")
bp = f"{mtp}/Android.bp"
t = open(bp).read()
if '"MtpSamsungHandle.cpp"' not in t:
    t = t.replace('        "MtpServer.cpp",\n', '        "MtpSamsungHandle.cpp",\n        "MtpServer.cpp",\n', 1)
    open(bp, "w").write(t)
srv = f"{mtp}/MtpServer.cpp"
t = open(srv).read()
if "MtpSamsungHandle" not in t:
    t = t.replace('#include "MtpFfsHandle.h"\n', '#include "MtpFfsHandle.h"\n#include "MtpSamsungHandle.h"\n', 1)
    old = "    } else {\n        mHandle = new MtpDevHandle();\n    }"
    assert old in t
    t = t.replace(old, "    } else if (MtpSamsungHandle::isAvailable()) {\n        mHandle = new MtpSamsungHandle();\n    } else {\n        mHandle = new MtpDevHandle();\n    }", 1)
    open(srv, "w").write(t)
