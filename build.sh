#!/bin/bash
# Build ducter LPK: download the upstream release tarball at build time
# (never stored in this repository), verify SHA-256 against the upstream
# SHA256SUMS.txt, and stage the exec launcher + binary into dist/.
set -euo pipefail

ARCH="${LAZYCAT_TARGET_ARCH:-amd64}"
case "$ARCH" in
  amd64 | x86_64) UPARCH="x64" ;;
  arm64 | aarch64) UPARCH="arm64" ;;
  *) echo "unsupported target arch: $ARCH" >&2; exit 1 ;;
esac

VERSION="$(grep '^version:' package.yml | awk '{print $2}')"
NAME="ducter-${VERSION}-linux-${UPARCH}"
URL="https://github.com/wey-gu/ducter/releases/download/v${VERSION}/${NAME}.tar.gz"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# socks5 proxy for the build machine when direct GitHub access is slow (set
# LAZYCAT_BUILD_PROXY=socks5://127.0.0.1:10808 in the workflow env to enable).
CURL_PROXY=()
if [ -n "${LAZYCAT_BUILD_PROXY:-}" ]; then
  CURL_PROXY=(--proxy "${LAZYCAT_BUILD_PROXY}")
fi

echo ">>> downloading ${URL}"
curl -fsSL --retry 3 --connect-timeout 30 "${CURL_PROXY[@]}" -o "$WORK/${NAME}.tar.gz" "$URL"
curl -fsSL --retry 3 --connect-timeout 30 "${CURL_PROXY[@]}" -o "$WORK/SHA256SUMS.txt" \
  "https://github.com/wey-gu/ducter/releases/download/v${VERSION}/SHA256SUMS.txt"

echo ">>> verifying SHA-256"
grep "  ${NAME}.tar.gz$" "$WORK/SHA256SUMS.txt" | (cd "$WORK" && sha256sum -c -)

echo ">>> extracting"
tar -xzf "$WORK/${NAME}.tar.gz" -C "$WORK"
test -x "$WORK/${NAME}/ducter"

mkdir -p dist
cp "$WORK/${NAME}/ducter" dist/ducter
chmod 0755 dist/ducter

cat > dist/ducter-launcher.sh <<'LAUNCHER'
#!/bin/sh
# LazyCat exec launcher for Ducter.
# The binary is a Bun single-file executable; it listens on DUCTER_HOST:DUCTER_PORT.
# All state (conversation, tasks, agent credentials) lives in the data dir
# bound to $HOME/.ducter so upgrades keep everything.
export HOME=/lzcapp/var/home
mkdir -p "$HOME/.ducter"
export DUCTER_PORT=8080
# 懒猫网关是唯一入口：bind loopback only, all external access goes through the gateway.
export DUCTER_HOST=127.0.0.1
# Language follows the box locale; zh/en both supported.
export DUCTER_LOCALE="${DUCTER_LOCALE:-zh}"
exec /lzcapp/pkg/content/ducter up --headless
LAUNCHER
chmod 0755 dist/ducter-launcher.sh

echo ">>> dist ready: $(ls -la dist)"
