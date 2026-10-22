# MtpDatabase: ignore addStorage() for a volume that is already registered. MtpService adds every
# mounted volume when the server starts and again on each MEDIA_MOUNTED event; on the SM-T510 the
# volumes finish mounting after unlock, so every storage showed up twice on the PC.
import sys
p = f"{sys.argv[1]}/media/java/android/mtp/MtpDatabase.java"
t = open(p).read()
old = "    public void addStorage(StorageVolume storage) {\n        MtpStorage mtpStorage"
if "already registered" not in t:
    assert t.count(old) == 1
    t = t.replace(old, "    public void addStorage(StorageVolume storage) {\n"
                       "        if (mStorageMap.containsKey(storage.getPath())) {\n"
                       "            Log.w(TAG, \"MTP storage already registered: \" + storage.getPath());\n"
                       "            return;\n"
                       "        }\n"
                       "        MtpStorage mtpStorage", 1)
    open(p, "w").write(t)
