# SM-T510: 32-bit userspace, 64-bit binder (a64), GApps, face unlock, no su, ext4
TARGET_GAPPS_ARCH := arm
include build/make/target/product/aosp_arm.mk
$(call inherit-product, device/phh/treble/base.mk)

$(call inherit-product-if-exists, vendor/gapps/arm/arm-vendor.mk)
$(call inherit-product, device/phh/treble/lineage.mk)

PRODUCT_NAME := lineage_a64_bgN4
PRODUCT_DEVICE := tdgsi_a64_ab
PRODUCT_BRAND := google
PRODUCT_SYSTEM_BRAND := google
PRODUCT_MODEL := TrebleDroid

PRODUCT_CHARACTERISTICS := tablet

LINEAGE_BUILDTYPE := GAPPS
LINEAGE_BUILD := GSI

# The 4.4 kernel has no EROFS, so system stays ext4
LINEAGE_EXTRAVERSION := -EXT4
PRODUCT_EXTRA_VNDK_VERSIONS += 28 29

# No eBPF on the 4.4 kernel: unblock services waiting for bpf.progs_loaded
PRODUCT_COPY_FILES += device/phh/treble/sm-t510-bpf.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/sm-t510-bpf.rc

# Face unlock (ParanoidSense) - MisterZtr 23.2 dropped it, so enable it here
TARGET_FACE_UNLOCK_SUPPORTED := true
PRODUCT_PACKAGES += FaceUnlock
PRODUCT_SYSTEM_EXT_PROPERTIES += ro.face.sense_service=true
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.biometrics.face.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.biometrics.face.xml

# Samsung f_mtp_samsung MTP device node permissions
PRODUCT_COPY_FILES += device/phh/treble/sm-t510-mtp.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/sm-t510-mtp.rc
