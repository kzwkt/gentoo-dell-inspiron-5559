#!/usr/bin/env bash
set -euo pipefail

ver=$(< ver)
major=${ver%%.*}
src=kext
kernel_url="https://cdn.kernel.org/pub/linux/kernel/v${major}.x/linux-${ver}.tar.xz"

curl -fL --retry 3 "$kernel_url" -o kernel.tar.xz
mkdir -p "$src"
tar -xf kernel.tar.xz -C "$src" --strip-components=1
cp .config "$src/.config"

# CONFIG_EXTRA_FIRMWARE_DIR="fw" is relative to $(srctree), so the blobs have to
# live inside the source tree for drivers/base/firmware_loader/builtin.
mkdir -p "$src/fw"
cp -a fw/. "$src/fw/"

make -C "$src" olddefconfig
make -C "$src" -j"$(nproc)" KCFLAGS="-march=skylake -pipe" bzImage
