# Shinigami

Shinigami is the Linux kernel fork powering [Kira Linux](https://github.com/shinigami-os).  
Based on Linux **v6.12.85** (longterm), patched and configured for x86-64 developer workloads.

## Versioning

Shinigami releases follow the format `LINUX_VERSION-shinigami-SHINIGAMI_VERSION`:

```
6.12.85-shinigami-26.07
```

- **`LINUX_VERSION`** : the upstream Linux version this release is based on (e.g. `6.12.85`)
- **`SHINIGAMI_VERSION`** : the Kira patchset version, following the `YY.MM` scheme shared with `kira-base` and `flux`

The two components are independent:
- Pulling a new upstream kernel bumps `LINUX_VERSION` only (e.g. `7.0.0-shinigami-26.07`)
- Applying new Kira patches bumps `SHINIGAMI_VERSION` only (e.g. `6.12.85-shinigami-26.08`)
- Both can change at once

The full release string is produced at build time and stored in `include/config/kernel.release`.

## What's different from upstream

- **BORE scheduler** (v6.5.5): better interactive responsiveness under mixed workloads
- **Clang ThinLTO build**: compiled with `clang` + `LLVM=1`, no gcc
- **Stripped defconfig**: legacy drivers, old SCSI stacks, and unused subsystems removed
- **Kira config**: `arch/x86/configs/kira_defconfig` as the single source of truth

## Build

```bash
make LLVM=1 kira_defconfig
make LLVM=1 -j$(nproc)
make LLVM=1 prepare # remove the `-dirty` suffix
```

Requires `clang 19+` and standard kernel build dependencies (`bc`, `flex`, `bison`, `libssl-dev`, `libelf-dev`).

## Patches

All Kira-specific patches live in `patches/`, organized by category:

| Category | Purpose |
|----------|---------|
| `perf/` | Performance patches (BORE scheduler) |
| `mem/` | Memory tuning |
| `sec/` | Security hardening (KSPP) |
| `compat/` | Hardware compatibility fixes |
| `config/` | Config-only changes |

Apply all patches to a clean tree:
```bash
sh scripts/apply-patches.sh
```

## License

GPL-2.0 — see `COPYING`.