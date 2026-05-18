#!/usr/bin/env bash
set -euo pipefail

BINDIR="${BINDIR:-/usr/local/bin}"
CONFIGDIR="${CONFIGDIR:-/etc/bnetscale}"

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

echo "Removing bnetscale..."

rm -f "$BINDIR/bnetscale"
echo "  Removed $BINDIR/bnetscale"

if [ -d "$CONFIGDIR" ]; then
  echo "  Config directory: $CONFIGDIR"
  read -rp "Remove config directory? [y/N] " ans
  case "$ans" in
    [yY]|[yY][eE][sS])
      rm -rf "$CONFIGDIR"
      echo "  Removed $CONFIGDIR"
      ;;
    *)
      echo "  Preserved $CONFIGDIR"
      ;;
  esac
fi

echo "bnetscale uninstalled."
