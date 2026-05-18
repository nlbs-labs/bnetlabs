# BNetScale Architecture

## System Overview

```
┌─────────────────────────────────────────────────┐
│                  CONTROL PLANE                   │
│              (REST API - Port 1313)               │
│                                                   │
│  ┌──────────────┐    ┌──────────────┐             │
│  │  Vue 3       │    │  Go Backend  │             │
│  │  Dashboard   │◄──►│  Gin + GORM  │             │
│  │  (Port 1212) │    │  (Port 1313) │             │
│  └──────────────┘    └──────┬───────┘             │
│                             │                      │
│                      ┌──────▼───────┐              │
│                      │  PostgreSQL  │              │
│                      └──────────────┘              │
└───────────────────────────────────────────────────┘
```

**Two separate communication planes:**
- **Control Plane (HTTP/REST):** Authentication, key distribution, device management, telemetry
- **Data Plane (WireGuard/UDP):** Encrypted P2P tunnels between devices (server coordinates but never sees traffic)

## Project Structure

```
back/           # Go control plane server
├── main.go          # Entry point
├── config/          # Environment-based configuration
└── internal/
    ├── api/         # HTTP handlers (Gin)
    ├── db/          # PostgreSQL via GORM
    ├── handshake/   # 5-step Curve25519+HKDF protocol
    ├── ipam/        # IP allocation from 10.0.0.0/8 pool
    └── wireguard/   # WireGuard interface orchestration

front/          # Vue 3 dashboard
└── src/
    ├── api/         # Axios client + TypeScript types
    ├── stores/      # Pinia stores (auth, projects, devices)
    ├── views/       # Page components
    └── router/      # Vue Router config
```

## Key Design Decisions

### Per-Project WireGuard Interface
Each project gets its own WireGuard interface (`wg-proj-{id}`) on the server. This provides:
- Independent peer lists (devices can only see their project peers)
- Independent subnet isolation via kernel routing tables

### IP Allocation
- Pool: `10.0.0.0/8` divided into `/24` subnets per project
- Project N → `10.{block}.{offset}.0/24` where `block = (N*16)/256`, `offset = (N*16)%256`
- First IP in subnet reserved for server gateway
- Static allocation per device (no DHCP)

### Custom Handshake Protocol
A 5-step mutual authentication protocol run before WireGuard tunnel establishment:
1. **HELLO** — Client sends ephemeral public key + token hash
2. **CHALLENGE** — Server responds with own ephemeral key + challenge nonce
3. **RESPONSE** — Client proves identity via HMAC of challenge
4. **CONFIRMATION** — Server sends WireGuard config (encrypted with session key)
5. **ACK** — Client confirms readiness

Properties: mutual authentication, forward secrecy, replay attack prevention, token binding.
