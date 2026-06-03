#!/bin/sh
# Relay desktop receiver — one-line installer for Linux & macOS.
#
#   curl -fsSL https://github.com/Abdk4Moura/relay-desktop/releases/latest/download/install.sh | sh
#
# Downloads the right prebuilt binary, installs it to ~/.local/bin, enables
# start-on-login, and launches it. No build tools needed.
set -eu

REPO="Abdk4Moura/relay-desktop"
BIN="relay-desktop"
INSTALL_DIR="${RELAY_INSTALL_DIR:-$HOME/.local/bin}"

say() { printf '\033[1;32m▸\033[0m %s\n' "$1"; }
err() { printf '\033[1;31m✗\033[0m %s\n' "$1" >&2; exit 1; }

os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Linux)  plat="linux" ;;
  Darwin) plat="macos" ;;
  *) err "Unsupported OS: $os (Windows? use the PowerShell installer)";;
esac
case "$arch" in
  x86_64|amd64) a="x86_64" ;;
  arm64|aarch64) a="aarch64" ;;
  *) err "Unsupported architecture: $arch" ;;
esac
# Linux only ships x86_64 today.
if [ "$plat" = "linux" ] && [ "$a" != "x86_64" ]; then a="x86_64"; fi

asset="${BIN}-${plat}-${a}.tar.gz"
url="https://github.com/${REPO}/releases/latest/download/${asset}"

say "Downloading $asset…"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if command -v curl >/dev/null 2>&1; then
  curl -fSL "$url" -o "$tmp/$asset" || err "Download failed: $url"
else
  wget -qO "$tmp/$asset" "$url" || err "Download failed: $url"
fi

say "Installing to $INSTALL_DIR…"
mkdir -p "$INSTALL_DIR"
tar -xzf "$tmp/$asset" -C "$tmp"
mv "$tmp/$BIN" "$INSTALL_DIR/$BIN"
chmod +x "$INSTALL_DIR/$BIN"

# Linux: the receiver injects input via /dev/uinput, which needs group access.
if [ "$plat" = "linux" ] && [ ! -w /dev/uinput ] 2>/dev/null; then
  say "Granting input access (uinput) — may prompt for your password…"
  if command -v sudo >/dev/null 2>&1; then
    sudo sh -c 'cat > /etc/udev/rules.d/99-relay-uinput.rules <<EOF
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF
    getent group input >/dev/null || groupadd input
    udevadm control --reload-rules && udevadm trigger || true' || true
    sudo usermod -aG input "$(id -un)" || true
    say "Added you to the 'input' group — log out/in once for it to take effect."
  else
    say "No sudo found. Run the receiver with sudo, or see the README for the uinput udev rule."
  fi
fi

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) say "Add to PATH:  export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
esac

say "Enabling start-on-login…"
"$INSTALL_DIR/$BIN" autostart on >/dev/null 2>&1 || true

say "Starting Relay…"
( "$INSTALL_DIR/$BIN" >/dev/null 2>&1 & ) || true
sleep 1

say "Done. Relay is running — control panel: http://127.0.0.1:47601"
say "Open the Relay app on your phone; it'll discover this computer automatically."
