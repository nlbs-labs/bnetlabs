#!/usr/bin/env bash
set -euo pipefail

REPO="Labs/bnetscale"
HOST="git.nafi-labs.tech"
VERSION="${1:-0.1.5}"
TAG="v${VERSION}"
BINDIR="${BINDIR:-/usr/bin}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

CURRENT=""
if command -v bnetscale &>/dev/null; then
  CURRENT=$(bnetscale version 2>/dev/null || echo "unknown")
fi

echo -e "${CYAN}Current: ${CURRENT}  →  Target: ${VERSION}${NC}"
if [ "$CURRENT" = "$VERSION" ]; then
  echo -e "${GREEN}Already up to date.${NC}"
  exit 0
fi

echo -e "${YELLOW}Update bnetscale to ${VERSION}? [Y/n]${NC}"
if [ -t 0 ]; then
  read -r yn
else
  read -r yn </dev/tty 2>/dev/null || yn="Y"
fi
yn="${yn:-Y}"
if [[ ! "$yn" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Aborted.${NC}"
  exit 1
fi

if ! command -v go &>/dev/null; then
  echo -e "${RED}Go is required. Run install.sh first.${NC}"
  exit 1
fi
if ! command -v git &>/dev/null; then
  echo -e "${RED}git is required.${NC}"
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "${GREEN}Cloning bnetscale ${VERSION}...${NC}"
if ! git clone --depth 1 --branch "$TAG" "https://${HOST}/${REPO}.git" "$TMPDIR/repo" 2>/dev/null; then
  echo -e "${YELLOW}Tag $TAG not found, cloning main...${NC}"
  git clone --depth 1 "https://${HOST}/${REPO}.git" "$TMPDIR/repo"
fi

echo -e "${GREEN}Building...${NC}"
cd "$TMPDIR/repo/client"
CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION}" -o "$TMPDIR/bnetscale" .

install -m 0755 "$TMPDIR/bnetscale" "$BINDIR/bnetscale"
echo -e "${GREEN}Updated to ${VERSION}${NC}"
