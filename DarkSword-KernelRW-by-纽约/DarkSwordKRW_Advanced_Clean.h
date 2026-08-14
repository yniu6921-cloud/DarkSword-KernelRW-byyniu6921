//我的telegram @TrekQix
//  DarkSwordKRW_Advanced.h
//  DarkSword 内核读取
//
//  Created by 纽约 on 2026/08/15.
//

#ifndef DarkSwordKRW_Advanced_h
#define DarkSwordKRW_Advanced_h

#include "DarkSwordKRW.h"

#ifdef __cplusplus
extern "C" {
#endif

int DarkSword_ElevateToRoot(uint32_t pid);
int DarkSword_RemoveCodeSignature(uint32_t pid);
int DarkSword_AllowInvalidCode(uint32_t pid);
int DarkSword_SetPlatformBinary(uint32_t pid);

uint64_t DarkSword_SearchPattern(const uint8_t *pattern,
                                  size_t pattern_size,
                                  uint64_t start_addr,
                                  uint64_t end_addr,
                                  const uint8_t *mask);
int DarkSword_DumpMemory(uint64_t kaddr, size_t size, const char *file_path);
int DarkSword_LoadMemory(const char *file_path, uint64_t kaddr);

uint64_t DarkSword_FindKernelSymbol(const char *symbol_name);
uint64_t DarkSword_GetKernelFunction(const char *function_name);

int DarkSword_KernelCall(uint64_t func_addr,
                         int argc,
                         const uint64_t *args,
                         uint64_t *ret_value);

int DarkSword_DisableSandbox(uint32_t pid);
int DarkSword_AddSandboxException(uint32_t pid, const char *exception);

int DarkSword_HideFile(const char *path);
int DarkSword_UnhideFile(const char *path);

int DarkSword_HideConnection(uint16_t local_port);

typedef struct {
    uint32_t pid;
    char process_name[256];
    uint32_t local_addr;
    uint16_t local_port;
    uint32_t remote_addr;
    uint16_t remote_port;
    int state;
} NetworkConnection;

int DarkSword_GetAllConnections(NetworkConnection **connections, size_t *count);

int DarkSword_LoadKext(const char *kext_path);
int DarkSword_UnloadKext(const char *bundle_id);

typedef struct {
    uint32_t pid;
    uint32_t ppid;
    uint32_t uid;
    uint32_t gid;
    char name[256];
    uint64_t proc_addr;
    uint64_t task_addr;
} ProcessInfo;

int DarkSword_GetAllProcesses(ProcessInfo **processes, size_t *count);
int DarkSword_GetKernelVersion(int *major, int *minor, int *patch);
int DarkSword_GetDeviceModel(char *model, size_t size);

int DarkSword_AttachDebugger(uint32_t pid);
int DarkSword_InjectDylib(uint32_t pid, const char *dylib_path);

typedef void (*DarkSword_HookCallback)(uint64_t *args, int argc, uint64_t ret_value);
int DarkSword_HookKernelFunction(uint64_t func_addr, DarkSword_HookCallback callback);

int DarkSword_GetMemoryStats(uint64_t *free_mem, uint64_t *wired_mem, uint64_t *active_mem);

#ifdef __cplusplus
}
#endif

#endif
