#!/bin/sh
# Shinigami kernel build script
# Works on both Debian (default clang target) and Kira (musl, needs explicit target)

if [ -f /etc/kira-release ]; then
    MUSL_GCC_PATH=$(ls -d /usr/lib/gcc/x86_64-linux-musl/*/ 2>/dev/null | tail -1)
    exec make LLVM=1 \
        "HOSTCC=clang --target=x86_64-linux-musl -B${MUSL_GCC_PATH}" \
        "HOSTCXX=clang++ --target=x86_64-linux-musl -B${MUSL_GCC_PATH}" \
        "$@"
else
    exec make LLVM=1 "$@"
fi
