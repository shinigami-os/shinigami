# Shinigami
> Kira Linux's kernel: a minimally-patched Linux fork.

Shinigami tracks upstream Linux stable closely and applies a small, deliberately short list of patches : a scheduler for interactive responsiveness, a couple of hardware-compatibility fixes : plus a Kira-specific `defconfig`. No out-of-tree drivers in the base kernel; hardware needing a proprietary module is handled at the package level via `flux-recipes`, not here.

This file (`README`, no extension) is the original upstream kernel README, kept as-is. This one, `README.md`, is Shinigami's own.

## Current base

Linux **7.1.3**, built exclusively with `clang 19+` (`LLVM=1` : gcc is not used for Shinigami builds) and Thin LTO.

## Patch philosophy

Every patch has a documented reason and lives under `patches/<category>/`, categorized as `perf/` (performance), `mem/` (memory), `sec/` (security hardening), or `compat/` (hardware compatibility). Upstream patches are never modified silently : if one needs a change to apply cleanly, that change is documented in the patch's own commit header, not silently dropped.

| Patch | Category | What it does |
|---|---|---|
| `patches/perf/0001-bore-cachy.patch` | perf | BORE scheduler (Burst-Oriented Response Enhancer, CachyOS port). Discriminates tasks by burst time and prioritizes low-burst ones (compositors, terminal emulators, widgets) for better interactive responsiveness with a small fairness tradeoff. Adds `CONFIG_SCHED_BORE` (default `y`) : applied with one manual hunk fix on 7.1.3 (upstream's `CONFIG_CACHY` context block is absent in vanilla, same fix needed on the earlier 6.12.85 base). |
| `patches/compat/0001-acpi-call.patch` | compat | Adds the `acpi_call` module (`/proc/acpi/call`), for direct ACPI method calls needed by some laptop hardware control tooling. Needed a `static` keyword added to `decodeHex()` to satisfy clang's `-Werror,-Wmissing-prototypes`. |

**Rejected:** CachyOS's `clang-polly` patch : Debian's packaged clang 19 has an `LLVMPolly.so` plugin conflict (`polly-dependences-computeout` registered twice), making it non-functional without building clang from source with Polly enabled. Not worth the build complexity for the gain.

## Config philosophy

Maintained as a Kira-specific `defconfig` (`arch/x86/configs/kira_defconfig`), not a monolithic checked-in `.config`. Modules over built-ins where reasonably possible, to keep the base image small : except where a driver needs to be available before the root filesystem exists (framebuffer console, EFI framebuffer, NVMe). `CONFIG_IKCONFIG` is on, so the running config is always inspectable via `/proc/config.gz`. A handful of KSPP (Kernel Self Protection Project) hardening options are enabled (`SLAB_FREELIST_HARDENED`, `FORTIFY_SOURCE`, `SECURITY_LOCKDOWN_LSM`, etc.).

Config gaps found from real hardware are fixed with `scripts/config --enable <OPTION>` + `olddefconfig` + `savedefconfig`, never by hand-editing `.config`. See the [Kira Linux specification](https://github.com/shinigami-os) for the full annotated option table and reasoning behind each one.

## Repo strategy

A single orphan commit per kernel version holds the full source tree : no upstream git history carried along. The `upstream` remote points at `kernel.org`'s stable tree, used only to fetch new tags when rebasing to a newer Linux release.

```
origin    https://github.com/shinigami-os/shinigami.git   (this repo)
upstream  https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git   (rebase source only)
```

**Never store this repo inside a file-sync folder** (Synology Drive, Dropbox, iCloud, etc.) : case-insensitive filesystems silently rename or corrupt kernel headers, breaking builds in ways that are miserable to track down.

**Upgrade cadence:** track Linux stable, move to a new major version once the BORE patch has confirmed support and the release has a few point releases behind it.

## Build

```sh
make LLVM=1 kira_defconfig
make LLVM=1 -j$(nproc)
```

Architecture baseline: `x86-64-v2`.

To pick up a hardware-driven config change:

```sh
scripts/config --enable <OPTION>
make LLVM=1 olddefconfig
make LLVM=1 savedefconfig
cp defconfig arch/x86/configs/kira_defconfig
```

Module install into a sysroot (used by `kira-base`):

```sh
sudo make LLVM=1 INSTALL_MOD_PATH=<sysroot> modules_install
```

## Versioning and release procedure

Tagged as `v<linux-version>-shinigami-<YY.MM>[-N]`, e.g. `v7.1.3-shinigami-26.08-3`. `uname -r` reports the same string via `CONFIG_LOCALVERSION`, which is what `flux kernel-update` parses to compare against the latest release.

Required after every kernel change:

```sh
# 1. Commit changes
git add <files> && git commit -m "description"

# 2. Bump LOCALVERSION (on meaningful releases)
scripts/config --set-str LOCALVERSION "-shinigami-YY.MM-N"
make LLVM=1 olddefconfig && make LLVM=1 savedefconfig
cp defconfig arch/x86/configs/kira_defconfig
git add arch/x86/configs/kira_defconfig && git commit -m "config: bump version"

# 3. Annotated tags (BOTH required : setlocalversion needs an annotated
#    v<linux-version> exactly at HEAD to suppress the "+" suffix; a lightweight
#    tag won't do it, and the base tag has to move to HEAD after every commit)
git tag -d v7.1.3 && git tag -a v7.1.3 -m "Linux 7.1.3 base"
git tag -a v7.1.3-shinigami-YY.MM-N -m "Shinigami YY.MM-N"

# 4. Build and verify (no + suffix in the output)
make LLVM=1 -j$(nproc) && cat include/config/kernel.release

# 5. Push
git push && git push --tags
```

`flux kernel-update` on an installed system reads `{binary_cache_url}/kira-kernel/latest`, and if it's newer than the running `uname -r`, downloads and verifies a signed `kira-kernel-<version>.tar.gz`, extracts it onto `/`, runs `depmod`, and updates GRUB. Always requires a reboot to take effect; never runs automatically.

## License
GPL-2.0, inherited from Linux.
