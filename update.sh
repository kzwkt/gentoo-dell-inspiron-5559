#!/usr/bin/env bash
set -euo pipefail

ver=$(< ver)
latest=$(curl -fsS --max-time 30 https://www.kernel.org/finger_banner \
	| awk '/^The latest stable version/{print $NF}')

if [ -z "$latest" ]; then
	echo "error: kernel.org did not report a latest stable version" >&2
	exit 1
fi

if [ "$latest" = "$ver" ]; then
	echo "already on the latest stable kernel: $ver"
	exit 0
fi

url="https://cdn.kernel.org/pub/linux/kernel/v${latest%%.*}.x/linux-${latest}.tar.xz"
if ! curl -fsSI --max-time 30 -o /dev/null "$url"; then
	echo "error: $url is not available, refusing to record $latest" >&2
	exit 1
fi

echo "current:       $ver"
echo "latest stable: $latest"
read -r -p "set ver to $latest? [y/N] " answer
if [ "${answer,,}" != y ]; then
	echo "left at $ver"
	exit 0
fi

printf '%s\n' "$latest" > ver
echo "ver: $ver -> $latest"
