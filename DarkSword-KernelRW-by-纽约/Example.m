//
//  Example.m
//  DarkSword 使用示例
//
//  Created by 纽约 on 2026/08/15.
//

#import <Foundation/Foundation.h>
#import "DarkSwordKRW.h"

// 日志回调函数
void log_callback(const char *message) {
    NSLog(@"[DarkSword] %s", message);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        // ==================== 示例 1: 基本初始化 ====================

        NSLog(@"========================================");
        NSLog(@"DarkSword 内核读写示例程序");
        NSLog(@"========================================\n");

        // 设置日志回调
        DarkSword_SetLogCallback(log_callback);

        // 初始化内核读写（这一步需要 3-8 秒）
        NSLog(@"[*] 正在初始化 DarkSword 内核读写能力...");
        NSLog(@"[!] 注意：首次初始化需要 3-8 秒，请耐心等待");

        int ret = DarkSword_Init();
        if (ret != 0) {
            NSLog(@"[✗] 初始化失败: %s", DarkSword_GetLastError());
            return 1;
        }

        NSLog(@"[✓] 初始化成功！\n");

        // ==================== 示例 2: 获取内核信息 ====================

        uint64_t kernel_base = DarkSword_GetKernelBase();
        uint64_t kernel_slide = DarkSword_GetKernelSlide();

        NSLog(@"[*] 内核信息:");
        NSLog(@"    Kernel Base:  0x%016llx", kernel_base);
        NSLog(@"    Kernel Slide: 0x%016llx\n", kernel_slide);

        // ==================== 示例 3: 读取内核内存 ====================

        NSLog(@"[*] 测试内核读取功能:");

        // 读取内核 Mach-O 头部魔数
        uint32_t magic = DarkSword_kread32(kernel_base);
        NSLog(@"    Kernel Magic: 0x%08x %s",
              magic,
              magic == 0xFEEDFACF ? "(正确)" : "(错误!)");

        // 读取 64 位值
        uint64_t header = DarkSword_kread64(kernel_base);
        NSLog(@"    Kernel Header: 0x%016llx", header);

        // 读取缓冲区（前 32 字节）
        uint8_t buffer[32];
        ret = DarkSword_kreadbuf(kernel_base, buffer, sizeof(buffer));
        if (ret == 0) {
            NSLog(@"    前 32 字节:");
            for (int i = 0; i < 32; i++) {
                if (i % 16 == 0) NSLog(@"      ");
                printf("%02x ", buffer[i]);
                if ((i + 1) % 16 == 0) printf("\n");
            }
        }
        NSLog(@"");

        // ==================== 示例 4: 查找当前进程 ====================

        NSLog(@"[*] 查找当前进程结构:");

        pid_t my_pid = getpid();
        NSLog(@"    当前 PID: %d", my_pid);

        uint64_t proc_addr = DarkSword_proc_find(my_pid);
        if (proc_addr) {
            NSLog(@"    进程结构地址: 0x%016llx", proc_addr);

            uint64_t task_addr = DarkSword_proc_task(proc_addr);
            NSLog(@"    Task 地址: 0x%016llx", task_addr);

            uint64_t ucred_addr = DarkSword_proc_ucred(proc_addr);
            NSLog(@"    UCred 地址: 0x%016llx", ucred_addr);

            if (task_addr) {
                uint64_t vm_map = DarkSword_task_vm_map(task_addr);
                NSLog(@"    VM Map 地址: 0x%016llx", vm_map);

                if (vm_map) {
                    uint64_t pmap = DarkSword_vm_map_pmap(vm_map);
                    NSLog(@"    Pmap 地址: 0x%016llx", pmap);
                }
            }
        } else {
            NSLog(@"    [!] 未能找到进程结构（功能未完全实现）");
        }
        NSLog(@"");

        // ==================== 示例 5: 写入测试（谨慎使用） ====================

        NSLog(@"[*] 内核写入测试:");
        NSLog(@"    [!] 警告：写入内核内存极其危险！");
        NSLog(@"    [!] 此示例仅读取后立即写回原值");

        // 读取一个内核地址
        uint64_t test_addr = kernel_base + 0x1000;
        uint64_t original_value = DarkSword_kread64(test_addr);
        NSLog(@"    测试地址: 0x%016llx", test_addr);
        NSLog(@"    原始值: 0x%016llx", original_value);

        // 写回相同的值（安全测试）
        ret = DarkSword_kwrite64(test_addr, original_value);
        if (ret == 0) {
            NSLog(@"    [✓] 写入成功");

            // 验证写入
            uint64_t verify = DarkSword_kread64(test_addr);
            if (verify == original_value) {
                NSLog(@"    [✓] 验证通过");
            } else {
                NSLog(@"    [✗] 验证失败！");
            }
        } else {
            NSLog(@"    [✗] 写入失败: %s", DarkSword_GetLastError());
        }
        NSLog(@"");

        // ==================== 示例 6: 性能统计 ====================

        NSLog(@"[*] 性能统计:");

        uint64_t total_reads = 0;
        uint64_t total_writes = 0;
        uint64_t avg_time = 0;

        DarkSword_GetStats(&total_reads, &total_writes, &avg_time);

        NSLog(@"    总读取次数: %llu", total_reads);
        NSLog(@"    总写入次数: %llu", total_writes);
        NSLog(@"    平均读取时间: %llu 微秒", avg_time);
        NSLog(@"");

        // ==================== 示例 7: 高级用法 - 批量读取 ====================

        NSLog(@"[*] 高级用法 - 批量读取:");

        // 读取内核文本段前 256 字节
        uint8_t kernel_text[256];
        ret = DarkSword_kreadbuf(kernel_base, kernel_text, sizeof(kernel_text));

        if (ret == 0) {
            NSLog(@"    已读取 %zu 字节内核文本段", sizeof(kernel_text));

            // 统计特征字节
            int zero_count = 0;
            int ff_count = 0;
            for (int i = 0; i < sizeof(kernel_text); i++) {
                if (kernel_text[i] == 0x00) zero_count++;
                if (kernel_text[i] == 0xFF) ff_count++;
            }

            NSLog(@"    零字节数量: %d", zero_count);
            NSLog(@"    0xFF 字节数量: %d", ff_count);
        }
        NSLog(@"");

        // ==================== 示例 8: 不同大小的读取 ====================

        NSLog(@"[*] 测试不同大小的读取:");

        uint64_t test_base = kernel_base + 0x100;

        uint8_t val8 = DarkSword_kread8(test_base);
        NSLog(@"    8位读取:  0x%02x", val8);

        uint16_t val16 = DarkSword_kread16(test_base);
        NSLog(@"    16位读取: 0x%04x", val16);

        uint32_t val32 = DarkSword_kread32(test_base);
        NSLog(@"    32位读取: 0x%08x", val32);

        uint64_t val64 = DarkSword_kread64(test_base);
        NSLog(@"    64位读取: 0x%016llx", val64);
        NSLog(@"");

        // ==================== 示例 9: 清理与退出 ====================

        NSLog(@"[*] 清理资源...");
        DarkSword_Deinit();
        NSLog(@"[✓] 完成！\n");

        NSLog(@"========================================");
        NSLog(@"DarkSword 示例程序执行完毕");
        NSLog(@"========================================");
    }
    return 0;
}
