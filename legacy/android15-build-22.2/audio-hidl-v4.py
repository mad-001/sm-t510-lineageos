# Re-add the audio HIDL 4.0 client to frameworks/av (SM-T510 vendor only provides android.hardware.audio@4.0).
import re, sys
av = sys.argv[1]
impl = f"{av}/media/libaudiohal/impl/Android.bp"
t = open(impl).read()
if '"libaudiohal@4.0"' not in t:
    m = re.search(r'cc_library_shared \{\n    name: "libaudiohal@6\.0",.*?\n\}\n', t, re.S)
    v4 = m.group(0).replace("@6.0", "@4.0").replace("-DMAJOR_VERSION=6", "-DMAJOR_VERSION=4")
    t = t[:m.start()] + v4 + "\n" + t[m.start():]
    open(impl, "w").write(t)
top = f"{av}/media/libaudiohal/Android.bp"
t = open(top).read()
if '"libaudiohal@4.0"' not in t:
    t = t.replace('        "libaudiohal@6.0",\n', '        "libaudiohal@4.0",\n        "libaudiohal@6.0",\n', 1)
    open(top, "w").write(t)
fac = f"{av}/media/libaudiohal/FactoryHal.cpp"
t = open(fac).read()
if "Type::HIDL, 4, 0" not in t:
    n = int(re.search(r"std::array<AudioHalVersionInfo, (\d+)> sAudioHALVersions", t).group(1))
    t = t.replace(f"std::array<AudioHalVersionInfo, {n}> sAudioHALVersions",
                  f"std::array<AudioHalVersionInfo, {n + 1}> sAudioHALVersions")
    t = t.replace("    AudioHalVersionInfo(AudioHalVersionInfo::Type::HIDL, 6, 0),\n",
                  "    AudioHalVersionInfo(AudioHalVersionInfo::Type::HIDL, 6, 0),\n"
                  "    AudioHalVersionInfo(AudioHalVersionInfo::Type::HIDL, 4, 0),\n")
    open(fac, "w").write(t)
