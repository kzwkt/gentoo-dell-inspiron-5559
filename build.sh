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

make -C "$src" olddefconfig
make -C "$src" -j"$(nproc)" KCFLAGS="-march=skylake -pipe" bzImage

tar -cJf firmware.tar.xz -C fw .
