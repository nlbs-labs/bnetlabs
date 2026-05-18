<div align="center">
  <h1>BNetScale</h1>
  <p>
    <strong>Zero-Trust Mesh VPN Platform</strong>
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
    <a href="mailto:nafiurohman@nlbs.me">Contact</a>
  </p>
</div>

---

## Quick Start

### Install the CLI

**Linux / macOS:**

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

## Contact

- Email: [nafiurohman@nlbs.me](mailto:nafiurohman@nlbs.me)
- WhatsApp: [+62 813-5819-8565](https://wa.me/6281358198565)

---

<p align="center">
  Built with WireGuard &middot; Self-hosted &middot; Open-core
</p>
