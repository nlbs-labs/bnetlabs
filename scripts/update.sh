#!/usr/bin/env bash
set -euo pipefail

REPO="nlbs-labs/bnetlabs"
HOST="github.com"
VERSION="${1:-0.1.6}"
TAG="v${VERSION}"
BINDIR="${BINDIR:-/usr/bin}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

spinner() {
  local pid=$1 msg=$2
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  printf "  ${CYAN}%s${NC}  " "$msg"
  while kill -0 "$pid" 2>/dev/null; do
    printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    printf "  ${CYAN}%s${NC}  %s" "${spin:$i:1}" "$msg"
    i=$(( (i+1) % ${#spin} ))
    sleep 0.1
  done
  printf "\r\033[K"
  wait "$pid"
}

step() {
  echo -e "\n${BOLD}${CYAN}▸ $1${NC}"
}

ok() {
  echo -e "  ${GREEN}✓${NC} $1"
}

info() {
  echo -e "  ${YELLOW}ℹ${NC} $1"
}

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# --- Detect package manager ---
detect_pkg_manager() {
  if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    PKG_INSTALL="apt install -y -qq"
    PKG_UPDATE="apt update -qq"
  elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="dnf install -y -q"
    PKG_UPDATE="dnf makecache -q"
  elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
    PKG_INSTALL="yum install -y -q"
    PKG_UPDATE="yum makecache -q"
  elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="pacman -S --noconfirm"
    PKG_UPDATE="pacman -Sy"
  elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
    PKG_INSTALL="zypper install -y"
    PKG_UPDATE="zypper refresh"
  elif command -v apk &>/dev/null; then
    PKG_MANAGER="apk"
    PKG_INSTALL="apk add"
    PKG_UPDATE="apk update"
  elif command -v xbps-install &>/dev/null; then
    PKG_MANAGER="xbps"
    PKG_INSTALL="xbps-install -Sy"
    PKG_UPDATE="xbps-install -S"
  elif command -v eopkg &>/dev/null; then
    PKG_MANAGER="eopkg"
    PKG_INSTALL="eopkg install -y"
    PKG_UPDATE="eopkg update-repo"
  elif command -v emerge &>/dev/null; then
    PKG_MANAGER="emerge"
    PKG_INSTALL="emerge"
    PKG_UPDATE="emerge --sync"
  elif command -v brew &>/dev/null; then
    PKG_MANAGER="brew"
    PKG_INSTALL="brew install"
    PKG_UPDATE="brew update"
  else
    info "No supported package manager found."
  fi
}

# --- Ensure Go is available ---
ensure_go() {
  if command -v go &>/dev/null; then
    GO_EXEC="go"
    return 0
  fi
  for candidate in /usr/local/go/bin/go /usr/bin/go /usr/lib/go/bin/go; do
    if [ -x "$candidate" ]; then
      export PATH="$PATH:$(dirname "$candidate")"
      GO_EXEC="$candidate"
      ok "Found Go at $candidate"
      return 0
    fi
  done
  info "Go not found. Installing Go 1.26.3..."
  ARCH_GO=$(uname -m)
  case "$ARCH_GO" in
    x86_64)  GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
    *)       GO_ARCH="amd64" ;;
  esac
  curl -fsSL "https://go.dev/dl/go1.26.3.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz &
  spinner $! "Downloading Go..."
  rm -rf /usr/local/go
  tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  GO_EXEC="/usr/local/go/bin/go"
  if ! grep -q "/usr/local/go/bin" /etc/profile 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
  fi
  ok "Go $(go version | grep -oP 'go\K\d+\.\d+\.\d+') installed"
}

# --- Map package names per distro ---
pkg_name() {
  local pkg=$1
  case "$pkg" in
    wireguard-tools)
      case "$PKG_MANAGER" in
        emerge) echo "net-wireless/wireguard-tools" ;;
        *)      echo "wireguard-tools" ;;
      esac
      ;;
    git)
      echo "git"
      ;;
  esac
}

CURRENT=""
if command -v bnetscale &>/dev/null; then
  CURRENT=$(bnetscale version 2>/dev/null || echo "unknown")
fi

echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║   ${BOLD}BNetScale Updater v${VERSION}${NC}${CYAN}            ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Current: ${CURRENT}  →  Target: ${VERSION}${NC}"
if [ "$CURRENT" = "bnetscale v${VERSION}" ]; then
  echo -e "  ${GREEN}Already up to date.${NC}"
  exit 0
fi

echo ""
echo -e "  ${YELLOW}Update bnetscale to ${VERSION}? [Y/n]${NC}"
if [ -t 0 ]; then
  read -r yn
else
  read -r yn </dev/tty 2>/dev/null || yn="Y"
fi
yn="${yn:-Y}"
if [[ ! "$yn" =~ ^[Yy]$ ]]; then
  echo -e "  ${RED}Aborted.${NC}"
  exit 1
fi

step "Ensuring Go + git"
detect_pkg_manager
DEPS=""
command -v git &>/dev/null || DEPS="$DEPS git"
if [ -n "$DEPS" ] && [ -n "${PKG_MANAGER:-}" ]; then
  PKG_LIST=""
  for d in $DEPS; do
    PKG_LIST="$PKG_LIST $(pkg_name "$d")"
  done
  $PKG_UPDATE &
  spinner $! "Updating package cache..."
  $PKG_INSTALL $PKG_LIST &
  spinner $! "Installing$PKG_LIST..."
  ok "System dependencies installed"
fi
ensure_go

# --- Check minimum Go version ---
GO_EXEC="${GO_EXEC:-go}"
GO_VER_NUM=$($GO_EXEC version | grep -oP 'go\K\d+\.\d+\.\d+')
if [[ "$(echo "$GO_VER_NUM" | cut -d. -f1)" -lt 1 ]] || { [[ "$(echo "$GO_VER_NUM" | cut -d. -f1)" -eq 1 ]] && [[ "$(echo "$GO_VER_NUM" | cut -d. -f2)" -lt 22 ]]; }; then
  echo -e "  ${RED}✗ Go $GO_VER_NUM is too old. Need 1.22+.${NC}"
  exit 1
fi
ok "Go $GO_VER_NUM detected"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

step "Cloning bnetscale ${VERSION}..."
export GIT_TERMINAL_PROMPT=0
if git clone --depth 1 --branch "$TAG" "https://${HOST}/${REPO}.git" "$TMPDIR/repo" 2>/dev/null; then
  ok "Cloned tag ${TAG}"
else
  info "Tag ${TAG} not found, cloning main branch..."
  git clone --depth 1 "https://${HOST}/${REPO}.git" "$TMPDIR/repo"
  ok "Cloned main branch"
fi

step "Building binary..."
cd "$TMPDIR/repo/client"
CGO_ENABLED=0 $GO_EXEC build -ldflags="-s -w -X main.version=${VERSION}" -o "$TMPDIR/bnetscale" . &
spinner $! "Compiling..."
ok "Build complete"

install -m 0755 "$TMPDIR/bnetscale" "$BINDIR/bnetscale"

echo ""
echo -e "${GREEN}  ╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║   ${BOLD}BNetScale Updated to ${VERSION}!${NC}${GREEN}     ║${NC}"
echo -e "${GREEN}  ╚══════════════════════════════════════╝${NC}"
