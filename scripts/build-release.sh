#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLIENT_DIR="$ROOT_DIR/client"
OUTDIR="${OUTDIR:-$ROOT_DIR/dist}"

PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "darwin/amd64"
  "darwin/arm64"
  "windows/amd64"
)

mkdir -p "$OUTDIR"

for PLATFORM in "${PLATFORMS[@]}"; do
  GOOS="${PLATFORM%/*}"
  GOARCH="${PLATFORM#*/}"

  EXT=""
  [ "$GOOS" = "windows" ] && EXT=".exe"

  BINNAME="bnetscale${EXT}"
  TARNAME="bnetscale-${VERSION}-${GOOS}-${GOARCH}.tar.gz"

  echo "Building ${GOOS}/${GOARCH}..."
  cd "$CLIENT_DIR"
  GOOS="$GOOS" GOARCH="$GOARCH" CGO_ENABLED=0 \
    go build -ldflags="-s -w -X main.version=${VERSION}" \
    -o "$OUTDIR/$BINNAME" .
  cd "$ROOT_DIR"

  tar -czf "$OUTDIR/$TARNAME" -C "$OUTDIR" "$BINNAME"
  rm "$OUTDIR/$BINNAME"

  echo "  -> $OUTDIR/$TARNAME"
done

echo ""
echo "Release tarballs for ${VERSION}:"
ls -lh "$OUTDIR"/bnetscale-*.tar.gz
