#!/usr/bin/env bash
set -euo pipefail

# Ubuntu 24.04, x86-64. No Windows runner or Windows VM is used.
root=$(cd "$(dirname "$0")/../.." && pwd)
tools="$root/build/windows-toolchain"
mkdir -p "$tools"
sudo dpkg --add-architecture i386
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key |
  sudo tee /etc/apt/keyrings/winehq-archive.key >/dev/null
curl -fsSL https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources |
  sudo tee /etc/apt/sources.list.d/winehq-noble.sources >/dev/null
sudo apt-get update
sudo apt-get install -y --install-recommends \
  winehq-devel=11.21~noble-1 wine-devel=11.21~noble-1 \
  wine-devel-amd64=11.21~noble-1 wine-devel-i386:i386=11.21~noble-1 \
  clang-19 lld-19 llvm-19 cmake ninja-build osslsigncode innoextract xvfb

curl -fsSL https://github.com/Jake-Shadle/xwin/releases/download/0.10.0/xwin-0.10.0-x86_64-unknown-linux-musl.tar.gz \
  -o "$tools/xwin.tar.gz"
echo "d870eb4b2f390878af6da1ccd3cf321d22fcb72720984853b4be732ae597fc88  $tools/xwin.tar.gz" | sha256sum -c -
tar -xzf "$tools/xwin.tar.gz" -C "$tools"
"$tools/xwin-0.10.0-x86_64-unknown-linux-musl/xwin" --accept-license \
  --cache-dir "$tools/downloads" --sdk-version 10.0.26100 --crt-version 14.44.17.14 \
  splat --output "$tools/sysroot"
