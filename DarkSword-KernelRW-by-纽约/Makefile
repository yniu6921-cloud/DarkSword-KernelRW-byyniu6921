# Makefile for DarkSword Kernel R/W Library
# 编译带有代码保护的 DarkSword 内核读写库

TARGET = libdarksword.dylib
EXAMPLE = darksword_example

# 编译器配置
CC = clang
CFLAGS = -Wall -O2 -arch arm64 -arch arm64e
LDFLAGS = -framework Foundation -framework IOKit -framework IOSurface
PROTECTION_FLAGS = -mllvm -fla -mllvm -sub -mllvm -bcf

# 源文件
SOURCES = DarkSwordKRW_Encrypted.m
HEADERS = DarkSwordKRW.h
EXAMPLE_SRC = Example.m

# 目标文件
OBJECTS = $(SOURCES:.m=.o)

# 输出目录
BUILD_DIR = build
LIB_OUTPUT = $(BUILD_DIR)/$(TARGET)
EXAMPLE_OUTPUT = $(BUILD_DIR)/$(EXAMPLE)

.PHONY: all clean lib example install protect

# 默认目标：编译库和示例
all: lib example

# 编译动态库
lib: $(LIB_OUTPUT)

$(LIB_OUTPUT): $(OBJECTS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -dynamiclib -o $@ $^
	@echo "[✓] 动态库编译完成: $@"
	@codesign -s - $@ 2>/dev/null || true

# 编译目标文件（带保护）
%.o: %.m $(HEADERS)
	$(CC) $(CFLAGS) $(PROTECTION_FLAGS) -c $< -o $@

# 编译示例程序
example: $(EXAMPLE_OUTPUT)

$(EXAMPLE_OUTPUT): $(EXAMPLE_SRC) $(LIB_OUTPUT)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(EXAMPLE_SRC) -L$(BUILD_DIR) -ldarksword
	@echo "[✓] 示例程序编译完成: $@"
	@install_name_tool -change libdarksword.dylib @rpath/libdarksword.dylib $@
	@codesign -s - --entitlements entitlements.plist $@ 2>/dev/null || true

# 代码混淆保护（需要 OLLVM）
protect:
	@echo "[*] 应用 OLLVM 混淆保护..."
	@if command -v obfuscator-llvm >/dev/null 2>&1; then \
		obfuscator-llvm $(SOURCES) -o $(SOURCES).protected; \
		mv $(SOURCES).protected $(SOURCES); \
		echo "[✓] 代码混淆完成"; \
	else \
		echo "[!] OLLVM 未安装，跳过混淆"; \
	fi

# 安装到系统
install: lib
	@echo "[*] 安装库文件..."
	@sudo cp $(LIB_OUTPUT) /usr/local/lib/
	@sudo cp $(HEADERS) /usr/local/include/
	@sudo ldconfig 2>/dev/null || true
	@echo "[✓] 安装完成"

# 清理编译产物
clean:
	@rm -rf $(BUILD_DIR) *.o *.dylib
	@echo "[✓] 清理完成"

# 帮助信息
help:
	@echo "DarkSword 编译系统"
	@echo ""
	@echo "可用目标:"
	@echo "  make all      - 编译库和示例（默认）"
	@echo "  make lib      - 仅编译动态库"
	@echo "  make example  - 编译示例程序"
	@echo "  make protect  - 应用 OLLVM 代码混淆"
	@echo "  make install  - 安装到系统（需要 sudo）"
	@echo "  make clean    - 清理编译产物"
	@echo ""
	@echo "编译选项:"
	@echo "  DEBUG=1       - 启用调试符号"
	@echo "  STRIP=1       - 剥离符号表"
	@echo ""
	@echo "示例:"
	@echo "  make all DEBUG=1"
	@echo "  make lib STRIP=1"

# 调试版本
ifdef DEBUG
CFLAGS += -g -DDEBUG
endif

# 发布版本（剥离符号）
ifdef STRIP
LDFLAGS += -Wl,-x -Wl,-S
endif
