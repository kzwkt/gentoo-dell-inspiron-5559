#!/usr/bin/env bash
set -euo pipefail

repo=kzwkt/gentoo-dell-inspiron-5559

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

# $ver still holds the previous version, which is the tag of the release whose
# build recorded the config that actually produced that bzImage.
base=$(mktemp)
trap 'rm -f "$base"' EXIT
base_url="https://github.com/$repo/releases/download/$ver/.config"
if ! curl -fsL --max-time 120 -o "$base" "$base_url"; then
	echo "note: no .config on release $ver, so .config stays as committed"
	exit 0
fi

changes=$(diff <(grep '^CONFIG' .config | sort) <(grep '^CONFIG' "$base" | sort) || true)
if [ -z "$changes" ]; then
	echo ".config already matches what release $ver was built with"
	exit 0
fi

echo "differences between committed .config and release $ver's built config (- committed, + built):"
printf '%s\n' "$changes"
read -r -p "adopt release $ver's config as the base for $latest? [y/N] " answer
if [ "${answer,,}" != y ]; then
	echo "kept committed .config"
	exit 0
fi

cp "$base" .config
echo ".config adopted from release $ver; $latest's new symbols will be resolved by CI"
