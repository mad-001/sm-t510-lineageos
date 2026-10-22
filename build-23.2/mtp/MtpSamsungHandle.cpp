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

#define LOG_TAG "MtpSamsungHandle"

#include <android-base/logging.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/endian.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <algorithm>

#include "MtpSamsungHandle.h"
#include "mtp.h"

namespace android {

namespace {

constexpr char kDevPath[] = "/dev/usb_mtp_gadget";

// f_mtp_samsung ioctls (plain numbers, see drivers/usb/gadget/function/f_mtp.h)
constexpr unsigned kMtpWriteIntData = 4;
constexpr unsigned kSetZlpData = 9;
constexpr unsigned kGetHighFullSpeed = 10;

// One kernel bulk request; every write except the last of a transfer must be a
// whole number of packets so the host doesn't see a short packet early.
constexpr size_t kBulkSize = 32768;
// The driver always sends interrupt (event) packets of exactly this size.
constexpr size_t kEventSize = 16;
constexpr uint32_t kMaxContainerLength = 0xFFFFFFFF;

struct __attribute__((packed)) DataHeader {
    uint32_t length;
    uint16_t type;
    uint16_t command;
    uint32_t transaction_id;
};

} // namespace

MtpSamsungHandle::MtpSamsungHandle() : mFd(-1), mPacketSize(512), mBuf(kBulkSize) {}

MtpSamsungHandle::~MtpSamsungHandle() {}

bool MtpSamsungHandle::isAvailable() {
    return access(kDevPath, R_OK | W_OK) == 0;
}

int MtpSamsungHandle::read(void *data, size_t len) {
    // The driver hands back at most one completed bulk request per call.
    return TEMP_FAILURE_RETRY(::read(mFd, data, len));
}

int MtpSamsungHandle::writeAll(const void *data, size_t len) {
    const unsigned char *p = static_cast<const unsigned char*>(data);
    size_t left = len;
    while (left > 0) {
        int ret = TEMP_FAILURE_RETRY(::write(mFd, p, left));
        if (ret < 0) return -1;
        p += ret;
        left -= ret;
    }
    return len;
}

int MtpSamsungHandle::sendZlp() {
    // Unlike AOSP f_mtp, f_mtp_samsung never terminates a full-packet transfer itself.
    return ioctl(mFd, kSetZlpData, 0) < 0 ? -1 : 0;
}

int MtpSamsungHandle::write(const void *data, size_t len) {
    int ret = writeAll(data, len);
    if (ret < 0) return -1;
    if (len > 0 && len % mPacketSize == 0 && sendZlp() < 0) return -1;
    return ret;
}

int MtpSamsungHandle::receiveFile(mtp_file_range mfr, bool /* zero_packet */) {
    // The driver swallows zero length packets itself, so there is nothing extra to read.
    bool unknownLength = mfr.length == kMaxContainerLength;
    uint64_t left = mfr.length;
    off64_t offset = mfr.offset;

    while (unknownLength || left > 0) {
        size_t want = unknownLength ? kBulkSize : std::min<uint64_t>(left, kBulkSize);
        int ret = TEMP_FAILURE_RETRY(::read(mFd, mBuf.data(), want));
        if (ret < 0) return -1;
        if (ret > 0 && TEMP_FAILURE_RETRY(pwrite64(mfr.fd, mBuf.data(), ret, offset)) != ret)
            return -1;
        offset += ret;
        if (!unknownLength) left -= ret;
        // A short request means the host ended the transfer.
        if (static_cast<size_t>(ret) < want) {
            if (unknownLength) break;
            if (left > 0) {
                errno = EIO;
                return -1;
            }
        }
    }
    return 0;
}

int MtpSamsungHandle::sendFile(mtp_file_range mfr) {
    uint64_t left = mfr.length;
    off64_t offset = mfr.offset;
    uint64_t total = left + sizeof(DataHeader);

    DataHeader *header = reinterpret_cast<DataHeader*>(mBuf.data());
    header->length = htole32(static_cast<uint32_t>(std::min<uint64_t>(total, kMaxContainerLength)));
    header->type = htole16(MTP_CONTAINER_TYPE_DATA);
    header->command = htole16(mfr.command);
    header->transaction_id = htole32(mfr.transaction_id);

    // Some hosts can't handle the header in its own packet, so it shares the first one.
    size_t used = sizeof(DataHeader);
    while (true) {
        size_t chunk = std::min<uint64_t>(left, kBulkSize - used);
        if (chunk > 0) {
            int ret = TEMP_FAILURE_RETRY(pread64(mfr.fd, mBuf.data() + used, chunk, offset));
            if (ret != static_cast<int>(chunk)) return -1;
            offset += chunk;
            left -= chunk;
        }
        if (writeAll(mBuf.data(), used + chunk) < 0) return -1;
        used = 0;
        if (left == 0) break;
    }
    if (total % mPacketSize == 0 && sendZlp() < 0) return -1;
    return 0;
}

int MtpSamsungHandle::sendEvent(mtp_event me) {
    // For 32-bit callers the driver's compat path takes a pointer to a raw
    // fixed-size event container rather than a struct mtp_event.
    unsigned char event[kEventSize] = {};
    memcpy(event, me.data, std::min(me.length, kEventSize));
    return ioctl(mFd, kMtpWriteIntData, event) < 0 ? -1 : 0;
}

int MtpSamsungHandle::start(bool /* ptp */) {
    mFd.reset(TEMP_FAILURE_RETRY(open(kDevPath, O_RDWR)));
    if (mFd == -1) {
        PLOG(ERROR) << "can't open " << kDevPath;
        return -1;
    }
    int packetSize = ioctl(mFd, kGetHighFullSpeed, 0);
    if (packetSize > 0) mPacketSize = packetSize;
    return 0;
}

void MtpSamsungHandle::close() {
    mFd.reset();
}

} // namespace android
