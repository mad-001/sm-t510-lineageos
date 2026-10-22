/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef _MTP_SAMSUNG_HANDLE_H
#define _MTP_SAMSUNG_HANDLE_H

#include <android-base/unique_fd.h>
#include <vector>
#include "IMtpHandle.h"

namespace android {

// Handle for Samsung's legacy f_mtp_samsung gadget driver (/dev/usb_mtp_gadget),
// which has its own ioctl set instead of the AOSP f_mtp MTP_SEND_FILE/MTP_RECEIVE_FILE ones.
class MtpSamsungHandle : public IMtpHandle {
private:
    android::base::unique_fd mFd;
    int mPacketSize;
    std::vector<unsigned char> mBuf;

    int writeAll(const void *data, size_t len);
    int sendZlp();

public:
    static bool isAvailable();

    int read(void *data, size_t len) override;
    int write(const void *data, size_t len) override;

    int receiveFile(mtp_file_range mfr, bool zero_packet) override;
    int sendFile(mtp_file_range mfr) override;
    int sendEvent(mtp_event me) override;

    int start(bool ptp) override;
    void close() override;

    MtpSamsungHandle();
    ~MtpSamsungHandle();
};

} // namespace android

#endif // _MTP_SAMSUNG_HANDLE_H
