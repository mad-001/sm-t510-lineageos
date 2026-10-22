# FaceUnlock (ParanoidSense): support "Require eyes to be open" (FEATURE_REQUIRE_ATTENTION).
# The service used to report the feature as unsupported and ignore it; the Megvii engine already has an
# eye-closed check (LiteConfig.eyeStatus) that was never enabled. Store the setting and apply it to the
# engine at the start of every authentication.
import sys
src = f"{sys.argv[1]}/src/co/aospa/sense"

c = f"{src}/util/Constants.kt"
t = open(c).read()
if "SHARED_KEY_REQUIRE_ATTENTION" not in t:
    t = t.replace('    const val SHARED_KEY_SDK_VERSION = "sdk_version"\n',
                  '    const val SHARED_KEY_SDK_VERSION = "sdk_version"\n'
                  '    const val SHARED_KEY_REQUIRE_ATTENTION = "require_attention"\n', 1)
    assert "SHARED_KEY_REQUIRE_ATTENTION" in t
    open(c, "w").write(t)

s = f"{src}/SenseService.kt"
t = open(s).read()
if "applyEyeCheckConfig" in t:
    sys.exit(0)

t = t.replace("import co.aospa.sense.vendor.VendorImpl\n",
              "import co.aospa.sense.vendor.VendorImpl\nimport co.aospa.sense.vendor.impl.MegviiFaceUnlockImpl\n", 1)

old_get = """        override fun getFeature(feature: Int, faceId: Int): Boolean {
            return false
        }

        override fun setFeature(feature: Int, enable: Boolean, cryptoToken: ByteArray?, faceId: Int) {}
"""
new_get = """        override fun getFeature(feature: Int, faceId: Int): Boolean {
            if (feature == BiometricFaceConstants.FEATURE_REQUIRE_ATTENTION) {
                return mPreferenceHelper!!.getBooleanValueByKey(Constants.SHARED_KEY_REQUIRE_ATTENTION)
            }
            return false
        }

        override fun setFeature(feature: Int, enable: Boolean, cryptoToken: ByteArray?, faceId: Int) {
            if (feature == BiometricFaceConstants.FEATURE_REQUIRE_ATTENTION) {
                mPreferenceHelper!!.saveBooleanValue(Constants.SHARED_KEY_REQUIRE_ATTENTION, enable)
            }
        }
"""
assert t.count(old_get) == 1
t = t.replace(old_get, new_get, 1)

old_start = "                    mVendorImpl!!.compareStart()\n"
assert t.count(old_start) == 1
t = t.replace(old_start, old_start + "                    applyEyeCheckConfig()\n", 1)

helper = """    private fun applyEyeCheckConfig() {
        val requireEyesOpen =
            mPreferenceHelper!!.getBooleanValueByKey(Constants.SHARED_KEY_REQUIRE_ATTENTION)
        try {
            val lite = MegviiFaceUnlockImpl.getInstance()
            val config = lite.config
            config.eyeStatus = requireEyesOpen
            val ret = lite.setConfig(config)
            if (Util.IS_DEBUG_LOGGING) Log.d(TAG, "eye check $requireEyesOpen, setConfig=$ret")
        } catch (e: Throwable) {
            Log.e(TAG, "Unable to apply eye check config", e)
        }
    }

    private fun stopCurrentWork() {"""
assert t.count("    private fun stopCurrentWork() {") == 1
t = t.replace("    private fun stopCurrentWork() {", helper, 1)
open(s, "w").write(t)
