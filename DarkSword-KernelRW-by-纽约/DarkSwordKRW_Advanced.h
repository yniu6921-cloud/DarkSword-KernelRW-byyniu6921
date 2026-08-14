//
//  DarkSwordKRW_Advanced.h
//  DarkSword 高级功能扩展
//
//  提供更高级的内核操作功能
//

#ifndef DarkSwordKRW_Advanced_h
#define DarkSwordKRW_Advanced_h

#include "DarkSwordKRW.h"

#ifdef __cplusplus
extern "C" {
#endif

// ==================== 进程操作 ====================

/**
 * 提升进程权限为 root
 * @param pid 进程 ID (0 表示当前进程)
 * @return 0 成功, -1 失败
 */
int DarkSword_ElevateToRoot(uint32_t pid);

/**
 * 移除进程的代码签名限制
 * @param pid 进程 ID
 * @return 0 成功, -1 失败
 */
int DarkSword_RemoveCodeSignature(uint32_t pid);

/**
 * 允许进程执行无签名代码
 * @param pid 进程 ID
 * @return 0 成功, -1 失败
 */
int DarkSword_AllowInvalidCode(uint32_t pid);

/**
 * 设置进程为平台二进制
 * @param pid 进程 ID
 * @return 0 成功, -1 失败
 */
int DarkSword_SetPlatformBinary(uint32_t pid);

// ==================== 内存操作 ====================

/**
 * 搜索内核内存中的特征码
 * @param pattern 特征码
 * @param pattern_size 特征码长度
 * @param start_addr 起始地址
 * @param end_addr 结束地址
 * @param mask 掩码 (NULL 表示全匹配)
 * @return 找到的地址，失败返回 0
 */
uint64_t DarkSword_SearchPattern(const uint8_t *pattern,
                                  size_t pattern_size,
                                  uint64_t start_addr,
                                  uint64_t end_addr,
                                  const uint8_t *mask);

/**
 * 转储内核内存区域到文件
 * @param kaddr 内核起始地址
 * @param size 大小
 * @param file_path 保存路径
 * @return 0 成功, -1 失败
 */
int DarkSword_DumpMemory(uint64_t kaddr, size_t size, const char *file_path);

/**
 * 从文件加载数据到内核内存
 * @param file_path 文件路径
 * @param kaddr 目标内核地址
 * @return 0 成功, -1 失败
 */
int DarkSword_LoadMemory(const char *file_path, uint64_t kaddr);

// ==================== 符号解析 ====================

/**
 * 查找内核符号地址
 * @param symbol_name 符号名称 (如 "_current_proc")
 * @return 符号地址，失败返回 0
 */
uint64_t DarkSword_FindKernelSymbol(const char *symbol_name);

/**
 * 获取内核函数指针
 * @param function_name 函数名
 * @return 函数地址，失败返回 0
 */
uint64_t DarkSword_GetKernelFunction(const char *function_name);

// ==================== 内核调用 ====================

/**
 * 执行内核函数调用 (需要 PAC bypass)
 * @param func_addr 函数地址
 * @param argc 参数数量
 * @param args 参数数组
 * @param ret_value 返回值 (可选)
 * @return 0 成功, -1 失败
 */
int DarkSword_KernelCall(uint64_t func_addr,
                         int argc,
                         const uint64_t *args,
                         uint64_t *ret_value);

// ==================== 沙盒操作 ====================

/**
 * 完全禁用进程沙盒
 * @param pid 进程 ID
 * @return 0 成功, -1 失败
 */
int DarkSword_DisableSandbox(uint32_t pid);

/**
 * 为进程添加沙盒例外
 * @param pid 进程 ID
 * @param exception 例外规则 (如 "file-read*")
 * @return 0 成功, -1 失败
 */
int DarkSword_AddSandboxException(uint32_t pid, const char *exception);

// ==================== 文件系统 ====================

/**
 * 隐藏文件/目录 (对系统不可见)
 * @param path 文件路径
 * @return 0 成功, -1 失败
 */
int DarkSword_HideFile(const char *path);

/**
 * 显示隐藏的文件
 * @param path 文件路径
 * @return 0 成功, -1 失败
 */
int DarkSword_UnhideFile(const char *path);

// ==================== 网络操作 ====================

/**
 * 隐藏网络连接 (对 netstat 不可见)
 * @param local_port 本地端口
 * @return 0 成功, -1 失败
 */
int DarkSword_HideConnection(uint16_t local_port);

/**
 * 获取所有进程的网络连接
 * @param connections 输出连接列表
 * @param count 连接数量
 * @return 0 成功, -1 失败
 */
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

// ==================== 内核模块 ====================

/**
 * 加载内核扩展
 * @param kext_path kext 路径
 * @return 0 成功, -1 失败
 */
int DarkSword_LoadKext(const char *kext_path);

/**
 * 卸载内核扩展
 * @param bundle_id Bundle ID
 * @return 0 成功, -1 失败
 */
int DarkSword_UnloadKext(const char *bundle_id);

// ==================== 系统信息 ====================

/**
 * 获取所有运行进程列表
 * @param processes 输出进程数组
 * @param count 进程数量
 * @return 0 成功, -1 失败
 */
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

/**
 * 获取系统内核版本信息
 * @param major 主版本号
 * @param minor 次版本号
 * @param patch 补丁版本号
 * @return 0 成功, -1 失败
 */
int DarkSword_GetKernelVersion(int *major, int *minor, int *patch);

/**
 * 获取设备型号
 * @param model 输出缓冲区
 * @param size 缓冲区大小
 * @return 0 成功, -1 失败
 */
int DarkSword_GetDeviceModel(char *model, size_t size);

// ==================== 调试功能 ====================

/**
 * 附加调试器到进程 (绕过反调试)
 * @param pid 目标进程 ID
 * @return 0 成功, -1 失败
 */
int DarkSword_AttachDebugger(uint32_t pid);

/**
 * 注入动态库到进程
 * @param pid 目标进程 ID
 * @param dylib_path 动态库路径
 * @return 0 成功, -1 失败
 */
int DarkSword_InjectDylib(uint32_t pid, const char *dylib_path);

// ==================== 性能监控 ====================

/**
 * 监控内核函数调用
 * @param func_addr 函数地址
 * @param callback 回调函数
 * @return 0 成功, -1 失败
 */
typedef void (*DarkSword_HookCallback)(uint64_t *args, int argc, uint64_t ret_value);
int DarkSword_HookKernelFunction(uint64_t func_addr, DarkSword_HookCallback callback);

/**
 * 获取内核内存使用统计
 * @param free_mem 空闲内存 (字节)
 * @param wired_mem 固定内存 (字节)
 * @param active_mem 活动内存 (字节)
 * @return 0 成功, -1 失败
 */
int DarkSword_GetMemoryStats(uint64_t *free_mem, uint64_t *wired_mem, uint64_t *active_mem);

#ifdef __cplusplus
}
#endif

#endif /* DarkSwordKRW_Advanced_h */
