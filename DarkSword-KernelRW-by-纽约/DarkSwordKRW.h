//
//  DarkSwordKRW.h
//  DarkSword 内核读写封装 - 公开接口
//
//  Created by 纽约 on 2026/08/15.
//  
//

#ifndef DarkSwordKRW_h
#define DarkSwordKRW_h

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// ==================== 初始化与状态管理 ====================

/**
 * 初始化 DarkSword 内核读写能力
 * @return 0 成功, -1 失败
 * @note 首次调用需要 3-8 秒，会进行物理内存扫描
 */
int DarkSword_Init(void);

/**
 * 检查是否已初始化
 * @return true 已就绪, false 未初始化
 */
bool DarkSword_IsReady(void);

/**
 * 获取内核基地址
 * @return 内核基地址，失败返回 0
 */
uint64_t DarkSword_GetKernelBase(void);

/**
 * 获取内核滑动值
 * @return 内核 slide，失败返回 0
 */
uint64_t DarkSword_GetKernelSlide(void);

/**
 * 清理资源（可选，一般不需要调用）
 */
void DarkSword_Deinit(void);

// ==================== 内核读取接口 ====================

/**
 * 读取内核 64 位值
 * @param kaddr 内核地址
 * @return 读取的值，失败返回 0
 */
uint64_t DarkSword_kread64(uint64_t kaddr);

/**
 * 读取内核 32 位值
 * @param kaddr 内核地址
 * @return 读取的值，失败返回 0
 */
uint32_t DarkSword_kread32(uint64_t kaddr);

/**
 * 读取内核 16 位值
 * @param kaddr 内核地址
 * @return 读取的值，失败返回 0
 */
uint16_t DarkSword_kread16(uint64_t kaddr);

/**
 * 读取内核 8 位值
 * @param kaddr 内核地址
 * @return 读取的值，失败返回 0
 */
uint8_t DarkSword_kread8(uint64_t kaddr);

/**
 * 读取内核缓冲区
 * @param kaddr 内核地址
 * @param buffer 输出缓冲区
 * @param size 读取大小
 * @return 0 成功, -1 失败
 */
int DarkSword_kreadbuf(uint64_t kaddr, void *buffer, size_t size);

// ==================== 内核写入接口 ====================

/**
 * 写入内核 64 位值
 * @param kaddr 内核地址
 * @param value 要写入的值
 * @return 0 成功, -1 失败
 */
int DarkSword_kwrite64(uint64_t kaddr, uint64_t value);

/**
 * 写入内核 32 位值
 * @param kaddr 内核地址
 * @param value 要写入的值
 * @return 0 成功, -1 失败
 */
int DarkSword_kwrite32(uint64_t kaddr, uint32_t value);

/**
 * 写入内核 16 位值
 * @param kaddr 内核地址
 * @param value 要写入的值
 * @return 0 成功, -1 失败
 */
int DarkSword_kwrite16(uint64_t kaddr, uint16_t value);

/**
 * 写入内核 8 位值
 * @param kaddr 内核地址
 * @param value 要写入的值
 * @return 0 成功, -1 失败
 */
int DarkSword_kwrite8(uint64_t kaddr, uint8_t value);

/**
 * 写入内核缓冲区
 * @param kaddr 内核地址
 * @param buffer 数据缓冲区
 * @param size 写入大小
 * @return 0 成功, -1 失败
 */
int DarkSword_kwritebuf(uint64_t kaddr, const void *buffer, size_t size);

// ==================== 便捷功能 ====================

/**
 * 根据 PID 查找进程结构
 * @param pid 进程 ID
 * @return 进程内核地址，失败返回 0
 */
uint64_t DarkSword_proc_find(uint32_t pid);

/**
 * 获取进程的 task 结构
 * @param proc 进程内核地址
 * @return task 内核地址，失败返回 0
 */
uint64_t DarkSword_proc_task(uint64_t proc);

/**
 * 获取进程的 ucred 结构
 * @param proc 进程内核地址
 * @return ucred 内核地址，失败返回 0
 */
uint64_t DarkSword_proc_ucred(uint64_t proc);

/**
 * 获取进程的 vm_map
 * @param task task 内核地址
 * @return vm_map 内核地址，失败返回 0
 */
uint64_t DarkSword_task_vm_map(uint64_t task);

/**
 * 获取 vm_map 的 pmap
 * @param vm_map vm_map 内核地址
 * @return pmap 内核地址，失败返回 0
 */
uint64_t DarkSword_vm_map_pmap(uint64_t vm_map);

// ==================== 调试与日志 ====================

/**
 * 设置日志回调函数
 * @param callback 日志回调，传入 NULL 禁用日志
 */
typedef void (*DarkSword_LogCallback)(const char *message);
void DarkSword_SetLogCallback(DarkSword_LogCallback callback);

/**
 * 获取最后一次错误信息
 * @return 错误描述字符串
 */
const char* DarkSword_GetLastError(void);

/**
 * 获取性能统计信息
 * @param total_reads 总读取次数（可选，传 NULL 跳过）
 * @param total_writes 总写入次数（可选，传 NULL 跳过）
 * @param avg_read_time_us 平均读取时间（微秒）（可选）
 */
void DarkSword_GetStats(uint64_t *total_reads, uint64_t *total_writes, uint64_t *avg_read_time_us);

#ifdef __cplusplus
}
#endif

#endif /* DarkSwordKRW_h */
