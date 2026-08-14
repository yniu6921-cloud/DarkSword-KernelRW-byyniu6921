#!/bin/bash

set -e

echo "[*] Building DarkSword KRW (Obfuscated Version)"
echo "[*] Created by 纽约 on 2026/08/15"
echo ""

SRCFILE="DarkSwordKRW_Obfuscated.m"
EXAMPLE="Example_Clean.m"
TARGET="darksword_krw"

if [ ! -f "$SRCFILE" ]; then
    echo "[!] Error: $SRCFILE not found"
    exit 1
fi

if [ ! -f "$EXAMPLE" ]; then
    echo "[!] Error: $EXAMPLE not found"
    exit 1
fi

echo "[*] Compiling with maximum optimization and symbol stripping..."

clang \
    -O3 \
    -fvisibility=hidden \
    -ffunction-sections \
    -fdata-sections \
    -fno-stack-protector \
    -fomit-frame-pointer \
    -arch arm64 \
    -arch arm64e \
    -framework Foundation \
    -framework IOSurface \
    -framework IOKit \
    -Wl,-dead_strip \
    -Wl,-unexported_symbols_list,/dev/null \
    -o "$TARGET" \
    "$SRCFILE" \
    "$EXAMPLE" \
    2>&1 | grep -v "warning:" || true

if [ ! -f "$TARGET" ]; then
    echo "[!] Compilation failed"
    exit 1
fi

echo "[*] Stripping symbols..."
strip -x "$TARGET"

echo "[*] Code signing..."
codesign -s - --entitlements entitlements.plist -f "$TARGET" 2>/dev/null

SIZE=$(du -h "$TARGET" | cut -f1)
echo ""
echo "[✓] Build complete!"
echo "[✓] Output: $TARGET ($SIZE)"
echo ""
echo "[*] To run:"
echo "    ./$TARGET"
