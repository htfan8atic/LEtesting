#!/usr/bin/env bash
# Build CroqueMr LibreELEC PR #106 on a dedicated x86_64 Ubuntu cloud VM.
# Run as a regular, sudo-capable user (NOT root).
set -Eeuo pipefail
trap 'echo "ERROR at line $LINENO: $BASH_COMMAND" >&2' ERR

UPSTREAM=https://github.com/CroqueMr/libreelec-x86-DV.git
PR_SHA=f48accba93b374e369b46dae18ac6530b3062688
ROOT="${LE_BUILD_ROOT:-$HOME/le-pr106}"
SRC="$ROOT/source"
OUT="$ROOT/output"
mkdir -p "$ROOT" "$OUT"
LOG="$ROOT/build.log"
exec > >(tee -a "$LOG") 2>&1

if [[ ${EUID} -eq 0 ]]; then
  echo "Do not run as root. Use a regular Ubuntu user with sudo access." >&2
  exit 1
fi
[[ $(uname -m) == x86_64 ]] || { echo 'This requires an x86_64 (Intel/AMD) VM.' >&2; exit 1; }
echo "Build root: $ROOT"
df -h "$HOME"
free -h
getent hosts github.com archive.ubuntu.com || { echo "DNS failure; check VM networking first." >&2; exit 1; }

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  bc bison build-essential bzip2 ccache curl flex gawk gcc g++ git \
  gperf gzip libdrm-dev libelf-dev libncurses-dev libssl-dev \
  make patch perl python3 python3-pip rsync tar unzip wget \
  xz-utils zip zstd autopoint gettext libtool pkg-config \
  libxml2-utils xsltproc meson ninja-build openjdk-11-jre-headless xfonts-utils

if [[ ! -d "$SRC/.git" ]]; then
  git clone "$UPSTREAM" "$SRC"
fi
cd "$SRC"
git remote set-url origin "$UPSTREAM"
git fetch origin refs/pull/106/head
git cat-file -e "$PR_SHA^{commit}"
git checkout --detach "$PR_SHA"
actual=$(git rev-parse HEAD)
[[ "$actual" == "$PR_SHA" ]] || { echo "Wrong commit: $actual" >&2; exit 1; }
git diff --check
python3 CB1/tools/verify.py
python3 scripts/cb1-stage.py --check
python3 scripts/cb1-stage.py

echo "Starting Generic x86_64 image compilation: $(date -Is)"
export CB1_HDR10_AI=yes PROJECT=Generic ARCH=x86_64 OFFICIAL=no
make image

echo "Collecting update archives"
mapfile -d '' tars < <(find target -maxdepth 2 -type f -name 'LibreELEC-*.tar' -print0)
if (( ${#tars[@]} != 1 )); then
  echo "Expected exactly one LibreELEC-*.tar; found ${#tars[@]}." >&2
  find target -maxdepth 2 -type f -print
  exit 1
fi
cp -v "${tars[0]}" "$OUT/"
name=$(basename "${tars[0]}")
tar -tf "$OUT/$name" >/dev/null
(cd "$OUT" && sha256sum "$name" > SHA256SUMS)
printf 'Source: %s\nPR commit: %s\nBuilt: %s\n' "$UPSTREAM" "$PR_SHA" "$(date -Is)" > "$OUT/BUILD_SOURCE.txt"
echo "SUCCESS: $OUT/$name"
echo "SHA256: $(cat "$OUT/SHA256SUMS")"
