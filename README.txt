╔══════════════════════════════════════════════════════════╗
║      DarkSword 内核读写库 - v1.0.0 发布包               ║
╚══════════════════════════════════════════════════════════╝

📦 包含文件
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

release/
├── DarkSwordKRW.h              公开 API 头文件
├── DarkSwordKRW_Advanced.h     高级功能头文件
├── DarkSwordKRW_Encrypted.m    核心实现源码
├── Example.m                   使用示例代码
├── Makefile                    编译配置
├── LICENSE                     MIT 开源许可
└── entitlements.plist          iOS 权限配置

README.md                       完整文档

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 快速使用
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 查看 API
   cat release/DarkSwordKRW.h

2. 查看示例
   cat release/Example.m

3. 编译（需要 macOS + Xcode）
   cd release && make all

4. 运行示例（需要 root）
   sudo ./darksword_example

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 集成到项目
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#import "DarkSwordKRW.h"

DarkSword_Init();
uint64_t kbase = DarkSword_GetKernelBase();
uint64_t value = DarkSword_kread64(kbase);

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ 重要
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ iOS 15.0 - 18.x
✓ arm64/arm64e
⚠ 需要 root 权限
⚠ 仅供学习研究

版本: v1.0.0 | 作者: 纽约 | 许可: MIT
