# hwui: only use memfd for parceled bitmaps if the kernel supports F_SEAL_FUTURE_WRITE (Linux 5.1+).
# The SM-T510 runs a 4.4 kernel, where the seal fails and every large Bitmap parcel throws
# "Could not copy bitmap to parcel blob." Fall back to the ashmem path there.
import sys
p = f"{sys.argv[1]}/libs/hwui/jni/Bitmap.cpp"
t = open(p).read()
if "memfdFutureWriteSealSupported" in t:
    sys.exit(0)
helper = '''static bool memfdFutureWriteSealSupported() {
    static const bool supported = [] {
        base::unique_fd fd(syscall(__NR_memfd_create, "bitmap_seal_probe",
                                   MFD_CLOEXEC | MFD_ALLOW_SEALING));
        return fd.get() >= 0 && fcntl(fd.get(), F_ADD_SEALS, F_SEAL_FUTURE_WRITE) == 0;
    }();
    return supported;
}

static binder_status_t writeBlob(AParcel* parcel, uint64_t bitmapId, const SkBitmap& bitmap,'''
old_sig = "static binder_status_t writeBlob(AParcel* parcel, uint64_t bitmapId, const SkBitmap& bitmap,"
assert t.count(old_sig) == 1
t = t.replace(old_sig, helper, 1)
old_if = "        if (com::android::graphics::hwui::flags::bitmap_use_memfd()) {"
assert t.count(old_if) == 1
t = t.replace(old_if, "        if (com::android::graphics::hwui::flags::bitmap_use_memfd() &&\n                memfdFutureWriteSealSupported()) {", 1)
open(p, "w").write(t)
