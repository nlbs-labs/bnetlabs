# Architecture Decision Records

## ADR-001: Go + Gin + GORM for Control Plane

**Status:** Accepted

**Context:** Need a performant, secure backend for a networking control plane that handles cryptographic operations and concurrent device connections.

**Decision:** Use Go with Gin framework and GORM ORM.

**Rationale:**
- Single binary deployment
- Excellent standard library crypto support (`crypto/rand`, `crypto/sha256`, `crypto/hmac`)
- `golang.org/x/crypto` provides Curve25519 and HKDF without external deps
- Gin is lightweight and mature for REST APIs
- GORM provides productive PostgreSQL integration with auto-migration

---

## ADR-002: PostgreSQL over MySQL/MongoDB

**Status:** Accepted

**Context:** Need a database for relational project/device/user data, JSONB for flexible ACL configs, and time-series telemetry.

**Decision:** PostgreSQL.

**Rationale:**
- Superior JSONB support for ACL rules and notification configs
- Strong ACID compliance for device registration and IP allocation
- Good time-series querying for telemetry data
- Permissive license (PostgreSQL License vs GPL/SSPL)

---

## ADR-003: Per-Project WireGuard Interface Isolation

**Status:** Accepted

**Context:** Multi-tenant system where each project must be isolated from others at the network level.

**Decision:** One WireGuard interface per project instead of sharing one interface.

**Rationale:**
- Natural kernel-level isolation (each interface has independent peer list)
- `wg show <interface>` per project for telemetry
- Simpler ACL enforcement (peer lists are already scoped)
- Trade-off: more interfaces to manage, but projects are typically <100

---

## ADR-004: Custom 5-Step Handshake over Noise Protocol

**Status:** Accepted

**Context:** Need mutual authentication with forward secrecy before WireGuard tunnel.

**Decision:** Custom protocol using Curve25519 + HKDF instead of standard Noise Protocol.

**Rationale:**
- Academic novelty (thesis requirement)
- Token binding: handshake is tied to a specific join token
- Lighter implementation than full Noise Protocol framework
- Simpler audit trail (explicit step tracking)

---

## ADR-005: Static IP Allocation from 10.0.0.0/8 Pool

**Status:** Accepted

**Context:** Need to assign IPs to devices within project subnets without conflicts.

**Decision:** Static IP allocation, first-come-first-served within each project's `/24`.

**Rationale:**
- No DHCP server dependency
- IPs persist across device reconnects
- Easy to track and audit from database
- `/24` per project allows up to 253 devices (more than enough)

---

## ADR-006: Vue 3 + Pinia + Tailwind CSS for Dashboard

**Status:** Accepted

**Context:** Need a modern, lightweight frontend for device/project management.

**Decision:** Vue 3 with Composition API, Pinia for state, Tailwind CSS for styling.

**Rationale:**
- Composition API enables clean store patterns with `defineStore`
- Pinia is the official Vue 3 state manager, minimal boilerplate
- Tailwind CSS enables fast prototyping without leaving HTML
- No heavy UI framework dependency
