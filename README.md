<div align="center">
  <h1>BNetScale</h1>
  <p>
    <strong>Zero-Trust Mesh VPN Platform — v0.1.6</strong>
  </p>
  <p>
    Self-hosted mesh VPN built on WireGuard. Connect machines securely across the internet with peer-to-peer encrypted tunnels.
  </p>
  <p>
    <a href="https://bnetscale.nlbs.me"><strong>Web Dashboard &raquo;</strong></a>
    &nbsp;|&nbsp;
    <a href="https://bnetscale.nlbs.me/docs"><strong>Documentation &raquo;</strong></a>
  </p>
  <p>
    <a href="https://github.com/nlbs-labs/bnetlabs/releases">Releases</a>
    &nbsp;|&nbsp;
    <a href="mailto:nafiurohman@bezn.me">Contact</a>
  </p>
</div>

---

## Quick Start

### Install the CLI

**Universal (auto-detects distro):**

```bash
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```

**Per-distro (manual steps):**

<details>
<summary><b>Debian / Ubuntu</b></summary>

```bash
sudo apt update
sudo apt install -y git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>Fedora</b></summary>

```bash
sudo dnf install -y git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>Arch Linux</b></summary>

```bash
sudo pacman -Sy --noconfirm git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>openSUSE</b></summary>

```bash
sudo zypper install -y git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>Alpine Linux</b></summary>

```bash
sudo apk add git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>Void Linux</b></summary>

```bash
sudo xbps-install -Sy git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>Solus</b></summary>

```bash
sudo eopkg install -y git wireguard-tools
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

<details>
<summary><b>Gentoo</b></summary>

```bash
sudo emerge --ask net-wireless/wireguard-tools dev-vcs/git
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```
</details>

**macOS:**

```bash
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.sh | sudo bash
```

**Windows (PowerShell as Admin):**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString("https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/install.ps1"))
```

### Join a Project

```bash
bnetscale join <JOIN_TOKEN>
bnetscale up
```

### Check Status

```bash
bnetscale status
```

### Update CLI

```bash
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/update.sh | sudo bash
```

### Uninstall

```bash
curl -fsSL https://github.com/nlbs-labs/bnetlabs/raw/main/scripts/uninstall.sh | sudo bash
```

---

## Repository Structure

| Directory | Contents |
|---|---|
| `client/` | CLI client source code (Go) |
| `docs/` | Documentation and changelogs |
| `scripts/` | Install, update, build, and release scripts |

---

## Architecture

BNetScale connects machines using WireGuard with a mesh topology:

- **Zero-trust authentication** via a 5-step cryptographic handshake (Curve25519 + HKDF)
- **Peer-to-peer mesh** — traffic flows directly between devices, not through a central server
- **Self-hosted** — full control over your data and infrastructure

---

## Testing Status

| Platform | Install | Update | CLI |
|---|---|---|---|
| Ubuntu Desktop | Testing | Testing | Testing |
| Ubuntu Server | Testing | Testing | Testing |
| EndeavourOS (Arch) | Testing | Untested | Testing |
| Windows | Untested | Untested | Untested |
| macOS | Untested | Untested | Untested |
| Debian/Fedora/openSUSE/Alpine/Void/Solus/Gentoo | Untested | Untested | Untested |

---

## Contact

- Email: [nafiurohman@bezn.me](mailto:nafiurohman@bezn.me)
- WhatsApp: [+62 813-5819-8565](https://wa.me/6281358198565)
- Trakteer: [teer.id/nafiurohman](https://teer.id/nafiurohman)

> **Experimental:** BNetScale is in active development. Features and APIs may change.

---

<p align="center">
  Built with WireGuard &middot; Self-hosted &middot; Open-core
</p>
