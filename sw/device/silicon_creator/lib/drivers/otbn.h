// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_OTBN_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_OTBN_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "sw/device/silicon_creator/lib/error.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The size of OTBN's data memory in bytes.
 */
extern const size_t kOtbnDMemSizeBytes;

/**
 * The size of OTBN's instruction memory in bytes.
 */
extern const size_t kOtbnIMemSizeBytes;

/**
 * Start the execution of the application loaded into OTBN at the start address.
 *
 * @param start_addr The IMEM byte address to start the execution at.
 * @return `kErrorOtbInvalidArgument` if `start_addr` is invalid, `kErrorOk`
 *         otherwise.
 */
rom_error_t otbn_start(uint32_t start_addr);

/**
 * Is OTBN busy executing an application?
 *
 * @return OTBN is busy
 */
bool otbn_is_busy(void);

/**
 * OTBN Errors
 *
 * OTBN uses a bitfield to indicate which errors have been seen. Multiple errors
 * can be seen at the same time. This enum gives the individual bits that may be
 * set for different errors.
 */
typedef enum otbn_err_bits {
  kOtbnErrBitsNoError = 0,
  /** Load or store to invalid address. */
  kOtbnErrBitsBadDataAddr = (1 << 0),
  /** Instruction fetch from invalid address. */
  kOtbnErrBitsBadInsnAddr = (1 << 1),
  /** Call stack underflow or overflow. */
  kOtbnErrBitsCallStack = (1 << 2),
  /** Illegal instruction execution attempted */
  kOtbnErrBitsIllegalInsn = (1 << 3),
  /** LOOP[I] related error */
  kOtbnErrBitsLoop = (1 << 4),
  /** Error seen in Imem read */
  kOtbnErrBitsFatalImem = (1 << 5),
  /** Error seen in Dmem read */
  kOtbnErrBitsFatalDmem = (1 << 6),
  /** Error seen in RF read */
  kOtbnErrBitsFatalReg = (1 << 7)
} otbn_err_bits_t;

/**
 * Get the error bits set by the device if the operation failed.
 *
 * @param[out] err_bits The error bits returned by the hardware.
 */
void otbn_get_err_bits(otbn_err_bits_t *err_bits);

/**
 * Write an OTBN application into its instruction memory (IMEM)
 *
 * Only 32b-aligned 32b word accesses are allowed.
 *
 * @param offset_bytes the byte offset in IMEM the first word is written to
 * @param src the main memory location to start reading from.
 * @param len number of words to copy.
 * @return `kErrorOtbnBadOffset` if `offset_bytes` isn't word aligned,
 * `kErrorOtbnBadOffsetLen` if `len` is invalid , `kErrorOk` otherwise.
 */
rom_error_t otbn_imem_write(uint32_t offset_bytes, const uint32_t *src,
                            size_t len);

/**
 * Write to OTBN's data memory (DMEM)
 *
 * Only 32b-aligned 32b word accesses are allowed.
 *
 * @param offset_bytes the byte offset in DMEM the first word is written to
 * @param src the main memory location to start reading from.
 * @param len number of words to copy.
 * @return `kErrorOtbnBadOffset` if `offset_bytes` isn't word aligned,
 * `kErrorOtbnBadOffsetLen` if `len` is invalid , `kErrorOk` otherwise.
 */
rom_error_t otbn_dmem_write(uint32_t offset_bytes, const uint32_t *src,
                            size_t len);

/**
 * Read from OTBN's data memory (DMEM)
 *
 * Only 32b-aligned 32b word accesses are allowed.
 *
 * @param offset_bytes the byte offset in DMEM the first word is read from
 * @param[out] dest the main memory location to copy the data to (preallocated)
 * @param len number of words to copy.
 * @return `kErrorOtbnBadOffset` if `offset_bytes` isn't word aligned,
 * `kErrorOtbnBadOffsetLen` if `len` is invalid , `kErrorOk` otherwise.
 */
rom_error_t otbn_dmem_read(uint32_t offset_bytes, uint32_t *dest, size_t len);

#ifdef __cplusplus
}
#endif

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_OTBN_H_
