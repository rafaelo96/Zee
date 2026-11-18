#ifndef ZEE_CORE_H
#define ZEE_CORE_H

/* Experimental ABI v1. Implementation: ZeeCore/src/ZeeCore.Native.
 * All strings/messages are length-delimited UTF-8, not NUL-terminated.
 * No caller may unload the Native AOT library before process exit.
 */
#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#  if defined(ZEE_CORE_BUILD)
#    define ZEE_API __declspec(dllexport)
#  else
#    define ZEE_API __declspec(dllimport)
#  endif
#  define ZEE_CALL __cdecl
#else
#  define ZEE_API __attribute__((visibility("default")))
#  define ZEE_CALL
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define ZEE_ABI_VERSION 1u

typedef int32_t zee_status_t;

#define ZEE_OK                ((zee_status_t)0)
#define ZEE_EMPTY             ((zee_status_t)1)
#define ZEE_BUFFER_TOO_SMALL  ((zee_status_t)2)
#define ZEE_TIMEOUT           ((zee_status_t)3)
#define ZEE_STOPPED           ((zee_status_t)4)
#define ZEE_BUSY              ((zee_status_t)5)
#define ZEE_INVALID_ARGUMENT  ((zee_status_t)-1)
#define ZEE_VERSION_MISMATCH  ((zee_status_t)-2)
#define ZEE_INVALID_STATE     ((zee_status_t)-3)
#define ZEE_INVALID_HANDLE    ((zee_status_t)-4)
#define ZEE_INVALID_MESSAGE   ((zee_status_t)-5)
#define ZEE_INTERNAL_ERROR    ((zee_status_t)-6)
#define ZEE_LIMIT_EXCEEDED    ((zee_status_t)-7)
/* A durable save to the app's session file failed; nothing was published. */
#define ZEE_STORAGE_FAILED    ((zee_status_t)-8)

/* Returns the ABI major supported by this image. */
ZEE_API uint32_t ZEE_CALL zee_core_abi_version(void);

#ifdef __cplusplus
} /* extern "C" */
#endif
#endif /* ZEE_CORE_H */
