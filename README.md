# DarkSword 内核读写库

一个封装完整的 DarkSword 内核读写库，核心代码经过加密保护，仅暴露简洁的公开接口。

## 📦 项目结构

```
DarkSword内核读取/
├── DarkSwordKRW.h              # 公开头文件（所有 API 接口）
├── DarkSwordKRW_Encrypted.m    # 加密实现（核心代码保护）
├── Example.m                   # 使用示例
├── Makefile                    # 编译脚本
├── entitlements.plist          # 必要的权限配置
└── README.md                   # 本文件
```

## 🚀 快速开始

### 1. 编译库文件

```bash
# 编译动态库和示例程序
make all

# 仅编译动态库
make lib

# 仅编译示例
make example
```

编译产物位于 `build/` 目录：
- `build/libdarksword.dylib` - 动态库
- `build/darksword_example` - 示例程序

### 2. 运行示例

```bash
cd build
sudo ./darksword_example
```

**注意**：
- 需要 root 权限运行
- 首次初始化需要 3-8 秒
- 需要在 iOS 15.0-18.x 的越狱或未越狱设备上运行

### 3. 集成到你的项目

#### 方式 A：链接动态库

```objective-c
// 在你的代码中引入头文件
#import "DarkSwordKRW.h"

// 初始化
DarkSword_Init();

// 读取内核内存
uint64_t kernel_base = DarkSword_GetKernelBase();
uint64_t value = DarkSword_kread64(kernel_base);

// 写入内核内存（谨慎！）
DarkSword_kwrite64(some_address, new_value);
```

编译时链接：
```bash
clang -o myapp myapp.m -L./build -ldarksword -framework Foundation
```

#### 方式 B：静态集成

直接将 `DarkSwordKRW_Encrypted.m` 添加到你的项目中。

## 📖 API 文档

### 初始化与状态

```c
// 初始化内核读写（阻塞 3-8 秒）
int DarkSword_Init(void);

// 检查是否已初始化
bool DarkSword_IsReady(void);

// 获取内核基地址
uint64_t DarkSword_GetKernelBase(void);

// 获取内核滑动值
uint64_t DarkSword_GetKernelSlide(void);

// 清理资源
void DarkSword_Deinit(void);
```

### 内核读取

```c
// 读取不同大小的值
uint64_t DarkSword_kread64(uint64_t kaddr);
uint32_t DarkSword_kread32(uint64_t kaddr);
uint16_t DarkSword_kread16(uint64_t kaddr);
uint8_t  DarkSword_kread8(uint64_t kaddr);

// 读取缓冲区
int DarkSword_kreadbuf(uint64_t kaddr, void *buffer, size_t size);
```

### 内核写入

```c
// 写入不同大小的值
int DarkSword_kwrite64(uint64_t kaddr, uint64_t value);
int DarkSword_kwrite32(uint64_t kaddr, uint32_t value);
int DarkSword_kwrite16(uint64_t kaddr, uint16_t value);
int DarkSword_kwrite8(uint64_t kaddr, uint8_t value);

// 写入缓冲区
int DarkSword_kwritebuf(uint64_t kaddr, const void *buffer, size_t size);
```

### 便捷功能

```c
// 进程相关
uint64_t DarkSword_proc_find(uint32_t pid);
uint64_t DarkSword_proc_task(uint64_t proc);
uint64_t DarkSword_proc_ucred(uint64_t proc);

// 内存管理相关
uint64_t DarkSword_task_vm_map(uint64_t task);
uint64_t DarkSword_vm_map_pmap(uint64_t vm_map);
```

### 调试与日志

```c
// 设置日志回调
typedef void (*DarkSword_LogCallback)(const char *message);
void DarkSword_SetLogCallback(DarkSword_LogCallback callback);

// 获取错误信息
const char* DarkSword_GetLastError(void);

// 性能统计
void DarkSword_GetStats(uint64_t *total_reads, 
                        uint64_t *total_writes, 
                        uint64_t *avg_read_time_us);
```

## 💡 使用示例

### 示例 1: 基本读写

```objective-c
#import "DarkSwordKRW.h"

int main() {
    // 初始化
    if (DarkSword_Init() != 0) {
        printf("初始化失败: %s\n", DarkSword_GetLastError());
        return 1;
    }

    // 获取内核基地址
    uint64_t kbase = DarkSword_GetKernelBase();
    printf("Kernel Base: 0x%llx\n", kbase);

    // 读取内核魔数
    uint32_t magic = DarkSword_kread32(kbase);
    printf("Kernel Magic: 0x%x\n", magic);

    // 清理
    DarkSword_Deinit();
    return 0;
}
```

### 示例 2: 查找进程

```objective-c
// 查找当前进程
pid_t my_pid = getpid();
uint64_t proc_addr = DarkSword_proc_find(my_pid);

if (proc_addr) {
    printf("进程结构: 0x%llx\n", proc_addr);
    
    // 获取 task
    uint64_t task = DarkSword_proc_task(proc_addr);
    printf("Task: 0x%llx\n", task);
    
    // 获取 vm_map
    uint64_t vm_map = DarkSword_task_vm_map(task);
    printf("VM Map: 0x%llx\n", vm_map);
}
```

### 示例 3: 批量读取

```objective-c
// 读取内核前 256 字节
uint8_t buffer[256];
int ret = DarkSword_kreadbuf(kernel_base, buffer, sizeof(buffer));

if (ret == 0) {
    printf("成功读取 %zu 字节\n", sizeof(buffer));
    
    // 处理数据
    for (int i = 0; i < sizeof(buffer); i++) {
        printf("%02x ", buffer[i]);
        if ((i + 1) % 16 == 0) printf("\n");
    }
}
```

### 示例 4: 日志回调

```objective-c
void my_log(const char *msg) {
    NSLog(@"[DarkSword] %s", msg);
}

int main() {
    // 设置日志回调
    DarkSword_SetLogCallback(my_log);
    
    // 初始化（会触发日志）
    DarkSword_Init();
    
    // ... 你的代码 ...
}
```

## 🔒 代码保护

核心实现采用多层保护：

1. **编译时保护**
   - 字符串加密（XOR + 运行时解密）
   - 关键函数使用 `__attribute__((section("__TEXT,__encrypted")))`
   - 编译时可选 OLLVM 混淆（`make protect`）

2. **运行时保护**
   - 关键数据结构 packed 存储
   - 敏感字符串运行时解密
   - 防调试检测（可选）

3. **符号隐藏**
   - 内部函数使用 `static` + `__attribute__((noinline))`
   - 发布版本剥离符号表（`make lib STRIP=1`）

## ⚙️ 高级编译选项

```bash
# 调试版本（保留符号）
make all DEBUG=1

# 发布版本（剥离符号）
make lib STRIP=1

# 应用 OLLVM 混淆（需要安装 OLLVM）
make protect

# 安装到系统
sudo make install
```

## 📊 性能特性

- **初始化时间**: 3-8 秒（首次）
- **读取速度**: 
  - iOS 15: ~50 微秒/次（Socket 方式）
  - iOS 16+: ~10 微秒/次（IOSurface 快速路径）
- **内存占用**: ~5MB（初始化后）
- **支持设备**: iPhone 8 - iPhone 16 Pro Max
- **支持系统**: iOS 15.0 - 18.x

## ⚠️ 重要警告

1. **内核写入极其危险**
   - 错误的写入会导致立即 panic
   - 建议仅在沙盒环境测试
   - 写入前务必验证地址有效性

2. **初始化成本**
   - 首次初始化需要 3-8 秒
   - 会分配大量内存（~3GB 临时）
   - 不适合频繁初始化的场景

3. **兼容性**
   - A18 设备支持可能不完整
   - 部分 iOS 版本可能需要调整
   - 建议在目标设备充分测试

## 🛠️ 故障排查

### 初始化失败

```bash
# 检查权限
sudo ./darksword_example

# 检查日志
DarkSword_SetLogCallback(your_log_func);
```

### 读取返回 0

```bash
# 检查地址有效性
if (kaddr < 0xfffffff000000000ULL) {
    printf("无效的内核地址\n");
}

# 检查是否已初始化
if (!DarkSword_IsReady()) {
    printf("未初始化\n");
}
```

### 编译错误

```bash
# 确保有 IOSurface 框架
clang -framework IOSurface ...

# 确保签名文件存在
ls entitlements.plist
```

## 📝 与 MagKui 集成示例

```objective-c
// 在 MagKui 中替换底层读写
namespace KFD {
    static uint64_t KextRW_kread64_darksword(void **handle, uint64_t kaddr) {
        // 如果 libjailbreak 不可用，使用 DarkSword
        static bool darksword_fallback = false;
        
        if (!*handle && !darksword_fallback) {
            if (DarkSword_Init() == 0) {
                darksword_fallback = true;
                NSLog(@"[KFD] 回退到 DarkSword 内核读写");
            }
        }
        
        if (darksword_fallback) {
            return DarkSword_kread64(kaddr);
        }
        
        // 原始实现
        typedef uint64_t (*kread64_t)(uint64_t);
        kread64_t kread64 = (kread64_t)dlsym(*handle, "kread64");
        return kread64 ? kread64(kaddr) : 0;
    }
}
```

## 🔗 相关资源

- **原始 Dopamine**: [github.com/opa334/Dopamine](https://github.com/opa334/Dopamine)
- **DarkSword 原理**: 见项目 `源码分析报告.md`
- **KFD 漏洞**: [github.com/felix-pb/kfd](https://github.com/felix-pb/kfd)

## 📄 许可证

本项目基于 Dopamine 的 DarkSword 实现，遵循原项目许可证。

**仅供学习研究使用，禁止用于非法目的。**

---

## 🙋 常见问题

**Q: 为什么初始化这么慢？**  
A: DarkSword 需要扫描物理内存找到可利用的 socket PCB，这需要时间。

**Q: 可以在未越狱设备使用吗？**  
A: 理论上可以，但需要特殊的签名和权限配置。

**Q: 与其他内核读写方式的区别？**  
A: DarkSword 不依赖现有越狱环境，可以从零开始建立 KRW 能力。

**Q: 为什么有些函数返回 0？**  
A: 部分便捷功能需要额外的内核偏移信息，当前版本未完全实现。

**Q: 可以商用吗？**  
A: 本项目仅供学习研究，不建议用于商业产品。

---

**作者**: 纽约  
**创建时间**: 2026-08-15  
**版本**: 1.0.0
