#!/usr/bin/env bash
set -euo pipefail

REPO="nlbs-labs/bnetlabs"
HOST="github.com"
VERSION="${1:-0.1.6}"
TAG="v${VERSION}"
BINDIR="${BINDIR:-/usr/bin}"
CONFIGDIR="${CONFIGDIR:-/etc/bnetscale}"

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

echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║   ${BOLD}BNetScale Client Installer v${VERSION}${NC}${CYAN}   ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════╝${NC}"
echo ""

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
  else
    echo -e "${RED}  ✗ No supported package manager found.${NC}"
    echo -e "${YELLOW}  ℹ Please install git and wireguard-tools manually, then re-run.${NC}"
    exit 1
  fi
  ok "Detected package manager: ${PKG_MANAGER}"
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

# --- Install Go if missing ---
if ! command -v go &>/dev/null; then
  step "Installing Go 1.26.3..."
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
  if ! grep -q "/usr/local/go/bin" /etc/profile 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
  fi
  ok "Go $(go version | grep -oP 'go\K\d+\.\d+\.\d+') installed"
else
  ok "Go $(go version | grep -oP 'go\K\d+\.\d+\.\d+') detected"
fi

# --- Check minimum Go version ---
GO_VER_NUM=$(go version | grep -oP 'go\K\d+\.\d+\.\d+')
if [[ "$(echo "$GO_VER_NUM" | cut -d. -f1)" -lt 1 ]] || { [[ "$(echo "$GO_VER_NUM" | cut -d. -f1)" -eq 1 ]] && [[ "$(echo "$GO_VER_NUM" | cut -d. -f2)" -lt 22 ]]; }; then
  echo -e "${RED}  ✗ Go $GO_VER_NUM is too old. Need 1.22+.${NC}"
  exit 1
fi

# --- Install system deps ---
detect_pkg_manager

DEPS=""
command -v git &>/dev/null || DEPS="$DEPS git"
command -v wg &>/dev/null || DEPS="$DEPS wireguard-tools"

if [ -n "$DEPS" ]; then
  step "Installing system dependencies:${DEPS}"
  PKG_LIST=""
  for d in $DEPS; do
    PKG_LIST="$PKG_LIST $(pkg_name "$d")"
  done
  $PKG_UPDATE &
  spinner $! "Updating package cache..."
  $PKG_INSTALL $PKG_LIST &
  spinner $! "Installing$PKG_LIST..."
  ok "System dependencies installed"
else
  ok "git + wireguard-tools detected"
fi

# --- Clone + build ---
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
CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION}" -o "$TMPDIR/bnetscale" . &
spinner $! "Compiling..."
ok "Build complete"

install -m 0755 "$TMPDIR/bnetscale" "$BINDIR/bnetscale"
mkdir -p "$CONFIGDIR"
chmod 0700 "$CONFIGDIR"

echo ""
echo -e "${GREEN}  ╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║   ${BOLD}BNetScale ${VERSION} Installed!${NC}${GREEN}        ║${NC}"
echo -e "${GREEN}  ╠══════════════════════════════════════╣${NC}"
echo -e "${GREEN}  ║  ${NC}Binary: ${BINDIR}/bnetscale${GREEN}            ║${NC}"
echo -e "${GREEN}  ║  ${NC}Config: ${CONFIGDIR}${GREEN}                 ║${NC}"
echo -e "${GREEN}  ╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Usage:${NC}"
echo -e "    ${BOLD}bnetscale join${NC} <token>          # Join (default: https://bnetscale.nlbs.me)"
echo -e "    ${BOLD}bnetscale join${NC} <token> ${YELLOW}--server${NC} <url>  # Custom server"
echo -e "    ${BOLD}bnetscale up${NC}"
echo -e "    ${BOLD}bnetscale down${NC}"
echo -e "    ${BOLD}bnetscale status${NC}"
echo ""
echo -e "  ${YELLOW}Example:${NC}"
echo -e "    bnetscale join eyJ...token"
echo -e "    bnetscale up"
echo -e "    bnetscale status"
echo ""
