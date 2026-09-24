<p align="center">
  <img src="https://raw.githubusercontent.com/BlackMatter-Studios/opencaller/main/assets/banner.png" alt="OpenCaller Banner" width="100%" onerror="this.style.display='none'"/>
</p>

<h1 align="center">🛡️ OpenCaller</h1>

<p align="center">
  <strong>Ultra-lightweight, 100% open-source, community-driven, and federated alternative to Truecaller.</strong><br>
  Built with extreme privacy sovereignty, Rust Axum backend (<25MB RAM), and native CallKit & CallScreening telephony bridges.
</p>

<p align="center">
  <a href="#-architecture"><img src="https://img.shields.io/badge/Architecture-Federated%20Mesh-00E5FF?style=for-the-badge&logo=diagramsdotnet" alt="Architecture"></a>
  <a href="#-backend"><img src="https://img.shields.io/badge/Backend-Rust%20%7C%20Axum%20%7C%20Tokio-DEA584?style=for-the-badge&logo=rust" alt="Rust"></a>
  <a href="#-database"><img src="https://img.shields.io/badge/Database-PostgreSQL%2016%20Tuned-336791?style=for-the-badge&logo=postgresql" alt="PostgreSQL"></a>
  <a href="#-mobile"><img src="https://img.shields.io/badge/Mobile-Flutter%20%7C%20Riverpod%20%7C%20Drift-02569B?style=for-the-badge&logo=flutter" alt="Flutter"></a>
  <a href="#-license"><img src="https://img.shields.io/badge/License-MIT-10B981?style=for-the-badge" alt="License"></a>
</p>

---

## ⚡ Why OpenCaller?

Proprietary caller ID applications like Truecaller monetize user surveillance, commercialize contact books, inject intrusive ads, and lock premium spam protection behind recurring paywalls. 

**OpenCaller** reclaims incoming call defense for the open web:

| Feature | Truecaller | OpenCaller |
| :--- | :---: | :---: |
| **Open Source** | ❌ Proprietary | ✅ **100% Open Source** (MIT) |
| **Self-Hostable** | ❌ Closed Cloud | ✅ **Docker Compose (< 200MB RAM)** |
| **Privacy Sovereignty** | ❌ Contact Harvesting & Data Brokerage | ✅ **Zero Data Selling / Privacy Controls** |
| **Community Consensus** | ❌ Arbitrary | ✅ **3-Vote Quorum Algorithm** |
| **Right to be Forgotten** | ⚠️ Opaque Request Form | ✅ **Instant Self-Service Delisting API** |
| **Android Interception** | ✅ Native Screening | ✅ **Sub-150ms SQLite `CallScreeningService`** |
| **iOS Integration** | ⚠️ Battery Drain / Subscription Gate | ✅ **Offline `CXCallDirectoryProvider` + App Intents** |
| **UI Aesthetics** | ⚠️ Cluttered Ads | ✅ **Futuristic Glassmorphic Dark UI** |

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph Mobile ["Cross-Platform Mobile App (apps/mobile)"]
        UI["Flutter UI (Riverpod v2)\nFuturistic Glassmorphism"]
        DriftDB[("Local SQLite (Drift)\nApp Group Storage")]
        
        AndroidCS["Android CallScreeningService\n(Synchronous < 150ms Query)"]
        iOSCD["iOS CXCallDirectoryProvider\n(Strict Int64 Ascending Order)"]
        SiriIntent["Siri & Action Button\n(App Intent Live Lookup)"]
        
        UI <-->|Local Cache / Read| DriftDB
        AndroidCS -->|Sync Pre-Ring Lookup| DriftDB
        iOSCD -->|Batch Directory Reload| DriftDB
    end

    subgraph Edge ["Cloudflare Ingress & Edge Caching"]
        CFTunnel["Cloudflare Tunnel\n(opencaller.blackmatter.cc)"]
        EdgeCache["ETag Conditional Cache\n(max-age=60, stale-while-revalidate=300)"]
    end

    subgraph Backend ["Self-Hosted Backend (< 200MB Total RAM)"]
        API["Rust API (Axum + Tokio + SQLx)\n~18 MB RAM"]
        Crawler["OSINT & Feed Daemon\n~14 MB RAM"]
        Postgres[("PostgreSQL 16 Alpine\n(shared_buffers=128MB)\n~95 MB RAM")]
        
        API <-->|High-Concurrency Pool| Postgres
        Crawler -->|Upsert E.164 De-duplicated| Postgres
    end

    subgraph Mesh ["Federated Nodes Network"]
        Peer["Peer OpenCaller Node"]
    end

    UI -->|HTTPS Delta Sync & Reports| CFTunnel
    SiriIntent -->|Live Caller ID Query| CFTunnel
    CFTunnel --> EdgeCache
    EdgeCache --> API
    API <-->|Ed25519 Signed Delta Exchange| Peer
```

---

## 📱 Mobile Client Features

### 1. Futuristic Glassmorphic UI (with Android Optimization)
Inspired by the design system of `portal-master`, OpenCaller features deep space blacks (`#090A0F`), neon cyan (`#00E5FF`), cyber purple (`#9333EA`), and glowing alert badges.
* **Android Performance Guarantee**: Automatically detects Android and **bypasses GPU `BackdropFilter` shaders**, utilizing GPU-accelerated translucent surface layers and gradient borders to ensure **fluid 60/120 FPS scrolling**.
* **iOS / Desktop**: Full frosted glassmorphism with real-time backdrop blur.

### 2. Native Telephony Subsystems
* **Android (`CallScreeningService`)**: Queries the local Drift database synchronously in **<150ms** before the phone rings. If a number has a `spam_score >= 0.80`, the call is rejected and silenced without alerting the user.
* **iOS (`CXCallDirectoryProvider`)**: Pre-compiles and loads numbers into iOS telephony storage via CallKit. 
  > [!IMPORTANT]
  > Apple requires phone numbers in Call Directory extensions to be **strictly sequential `Int64` numbers in ASCENDING numerical order**. Any unsorted item triggers a silent iOS rejection. OpenCaller guarantees numerical ordering both in the backend SQL query and in the Swift iterator.
* **iOS 16+ Siri App Intent**: Call on-demand lookups hands-free ("Hey Siri, search in OpenCaller") or map it to the **iPhone 15/16 Action Button** while on an incoming call.

### 3. Privacy-First Community Phonebook
* **Consent-Driven**: Sharing contacts to the community directory is **strictly disabled by default**.
* **3-Vote Quorum Consensus**: A crowdsourced caller name is only promoted to the global index once **3 or more independent contributors** submit matching names.
* **Privacy Filters**: Toggle to exclude favorite/starred family contacts and strip all personal notes, emails, and physical addresses on-device.

### 4. Right to be Forgotten (Self-Service Delisting)
Anyone can permanently remove their number from OpenCaller's global index via the in-app tool or via direct REST API call. Delisted numbers are immediately purged and permanently blacklisted from re-ingestion.

---

## 🚀 Quickstart & Development

### Monorepo Structure
```text
opencaller/
├── docker-compose.yml          # Production backend compose configuration
├── .env.example                # Sample environment secrets
├── SELF_HOSTING.md             # Rocky Linux / Polaris VM deployment & Xcode signing
├── services/
│   ├── api/                    # Rust Axum High-Performance API (~18 MB RAM)
│   ├── crawler/                # Background OSINT ingestion daemon (~14 MB RAM)
│   └── migrations/             # PostgreSQL DDL migrations
└── apps/
    └── mobile/                 # Flutter cross-platform client (iOS & Android)
```

### Running the Backend Locally
```bash
# 1. Start PostgreSQL
docker compose up -d postgres

# 2. Run Rust API unit tests & start server
cd services/api
cargo test
cargo run

# 3. In another terminal, run OSINT Crawler
cd services/crawler
cargo test
cargo run
```

### Running the Mobile Client (Flutter)
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

---

## 📡 REST API Reference

All endpoints return JSON and are optimized for edge caching using `ETag` and `If-None-Match`.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Service health status and version |
| `POST` | `/v1/auth/register` | Create user account with Argon2id hashing |
| `POST` | `/v1/auth/login` | Authenticate user and receive Ed25519/HMAC JWT |
| `GET` | `/v1/lookup/{number}` | Live caller ID, spam score, and business badge |
| `POST` | `/v1/report` | Submit community spam report (Bayesian updater) |
| `GET` | `/v1/sync/delta` | Delta synchronization stream (strictly ascending `Int64` with ETag) |
| `POST` | `/v1/contacts/contribute` | Privacy-controlled contact upload with consensus |
| `POST` | `/v1/privacy/delist` | Permanent self-service number delisting / purge |
| `GET` | `/v1/privacy/status/{number}` | Check delist status of a number |
| `POST` | `/v1/federation/sync` | Cryptographically signed node-to-node replication |

### Example: Live Number Lookup
```bash
curl -i https://opencaller.blackmatter.cc/v1/lookup/50688889999
```
**Response (200 OK):**
```json
{
  "e164_number": 50688889999,
  "country_code": "CR",
  "caller_name": "Prison Cell Extortion Ring",
  "name_confidence": 0.98,
  "is_verified_business": false,
  "spam_score": 0.99,
  "report_count": 42,
  "category": "scam",
  "is_spam": true,
  "is_private": false,
  "last_reported_at": "2026-09-23T21:15:00Z"
}
```

### Example: Delisting a Number (Right to be Forgotten)
```bash
curl -X POST https://opencaller.blackmatter.cc/v1/privacy/delist \
  -H "Content-Type: application/json" \
  -d '{"e164_number": 50688888888, "reason": "Owner requested removal"}'
```

---

## 🌐 Self-Hosting on Rocky Linux ("Polaris" VM)

See [SELF_HOSTING.md](file:///home/sgarita/Documents/Github/opencaller/SELF_HOSTING.md) for full step-by-step instructions on deploying OpenCaller inside a Rocky Linux VM behind Cloudflare Tunnel with an idle RAM footprint < 200 MB.

---

## 📄 License & Community

OpenCaller is released under the **MIT License**. Contributions, bug reports, and pull requests from privacy advocates and telecom engineers are warmly welcomed!
