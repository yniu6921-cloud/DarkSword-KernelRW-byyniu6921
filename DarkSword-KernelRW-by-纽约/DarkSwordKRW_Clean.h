//我的telegram @TrekQix
//  DarkSwordKRW.h
//  DarkSword 内核读取
//
//  Created by 纽约 on 2026/08/15.
//

#ifndef DarkSwordKRW_h
#define DarkSwordKRW_h

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int DarkSword_Init(void);
bool DarkSword_IsReady(void);
uint64_t DarkSword_GetKernelBase(void);
uint64_t DarkSword_GetKernelSlide(void);
void DarkSword_Deinit(void);

uint64_t DarkSword_kread64(uint64_t kaddr);
uint32_t DarkSword_kread32(uint64_t kaddr);
uint16_t DarkSword_kread16(uint64_t kaddr);
uint8_t DarkSword_kread8(uint64_t kaddr);
int DarkSword_kreadbuf(uint64_t kaddr, void *buffer, size_t size);

int DarkSword_kwrite64(uint64_t kaddr, uint64_t value);
int DarkSword_kwrite32(uint64_t kaddr, uint32_t value);
int DarkSword_kwrite16(uint64_t kaddr, uint16_t value);
int DarkSword_kwrite8(uint64_t kaddr, uint8_t value);
int DarkSword_kwritebuf(uint64_t kaddr, const void *buffer, size_t size);

uint64_t DarkSword_proc_find(uint32_t pid);
uint64_t DarkSword_proc_task(uint64_t proc);
uint64_t DarkSword_proc_ucred(uint64_t proc);
uint64_t DarkSword_task_vm_map(uint64_t task);
uint64_t DarkSword_vm_map_pmap(uint64_t vm_map);

typedef void (*DarkSword_LogCallback)(const char *message);
void DarkSword_SetLogCallback(DarkSword_LogCallback callback);
const char* DarkSword_GetLastError(void);
void DarkSword_GetStats(uint64_t *total_reads, uint64_t *total_writes, uint64_t *avg_read_time_us);

#ifdef __cplusplus
}
#endif

#endif
