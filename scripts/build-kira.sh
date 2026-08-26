#!/bin/sh
# Shinigami kernel build script
# Works on both Debian (default clang target) and Kira (musl, needs explicit target)

if [ -f /etc/kira-release ]; then
    # Building on Kira itself
    MUSL_GCC_PATH=$(ls -d /usr/lib/gcc/x86_64-linux-musl/*/  2>/dev/null | tail -1)
    HOST_FLAGS="HOSTCC=clang --target=x86_64-linux-musl -B${MUSL_GCC_PATH} HOSTCXX=clang++ --target=x86_64-linux-musl -B${MUSL_GCC_PATH}"
    exec make LLVM=1 $HOST_FLAGS "$@"
else
    # Building on Debian/other
    exec make LLVM=1 "$@"
fi
