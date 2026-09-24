# Self-Hosting OpenCaller on Rocky Linux ("Polaris" VM)

This guide documents how to deploy the entire OpenCaller backend infrastructure on a resource-constrained Rocky Linux 9 / RHEL / AlmaLinux virtual machine ("Polaris"), utilizing Docker Compose and Cloudflare Tunnel.

---

## 1. Resource Footprint & System Requirements

The OpenCaller backend is engineered to consume **under 250 MB total RAM** in production idle/low-load states:

| Service | Technology | Configured RAM Limit | Measured Idle RAM |
| :--- | :--- | :--- | :--- |
| **Database** | PostgreSQL 16 Alpine | 160 MB | ~85 - 110 MB |
| **API** | Rust (Axum + Tokio + SQLx) | 64 MB | ~15 - 22 MB |
| **Crawler** | Rust (OSINT & Ingestion Daemon) | 48 MB | ~12 - 18 MB |
| **Tunnel** | Cloudflare Tunnel (`cloudflared`) | 32 MB | ~15 - 25 MB |
| **Total** | | **< 304 MB** | **~135 - 175 MB** |

---

## 2. Server Prerequisites (Rocky Linux 9)

### A. Install Docker & Docker Compose Plugin
```bash
# Update system packages
sudo dnf check-update
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker engine and Compose plugin
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable and start Docker daemon
sudo systemctl enable --now docker

# Add your user to the docker group
sudo usermod -aG docker $USER
newgrp docker
```

---

## 3. Deployment Steps

### Step 1: Clone Repository & Configure Environment
```bash
cd /opt
git clone https://github.com/BlackMatter-Studios/opencaller.git
cd opencaller

# Copy sample configuration
cp .env.example .env
```

Edit `.env` with your secure credentials:
```bash
nano .env
```
Key configuration items:
- `POSTGRES_PASSWORD`: Use a strong random password (e.g. `openssl rand -hex 24`).
- `JWT_SECRET`: Random 64-character secret for signing JWTs.
- `CLOUDFLARE_TUNNEL_TOKEN`: Your Cloudflare Tunnel token (see Step 2).

### Step 2: Set Up Cloudflare Ingress Tunnel
1. Log in to [Cloudflare One / Zero Trust Dashboard](https://one.dash.cloudflare.com/).
2. Navigate to **Networks** > **Tunnels** > **Create a Tunnel**.
3. Choose **Cloudflared**. Name the tunnel `opencaller-seed`.
4. Copy the tunnel connector token and place it in `.env`:
   ```env
   CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiZXhhbXBsZXRva2VuMS...
   ```
5. In the **Public Hostnames** tab of your tunnel configuration:
   - **Public Hostname**: `opencaller.blackmatter.cc`
   - **Service Type**: `HTTP`
   - **URL**: `opencaller-api:8080` (or `http://api:8080` within Docker network)

### Step 3: Launch the Stack
```bash
docker compose up -d --build
```

### Step 4: Verify Memory Consumption
Run `docker stats` to confirm memory targets:
```bash
docker stats --no-stream
```
Expected output:
```text
CONTAINER ID   NAME                 CPU %     MEM USAGE / LIMIT     MEM %
a1b2c3d4e5f6   opencaller-api       0.05%     18.4MiB / 64MiB       28.75%
b2c3d4e5f6a1   opencaller-crawler   0.02%     14.1MiB / 48MiB       29.38%
c3d4e5f6a1b2   opencaller-postgres  0.15%     98.2MiB / 160MiB      61.38%
d4e5f6a1b2c3   opencaller-tunnel    0.08%     19.6MiB / 32MiB       61.25%
```

---

## 4. Testing Endpoints Locally

### Health Check
```bash
curl -i http://localhost:8080/health
```

### Create User & Retrieve JWT Token
```bash
curl -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "SuperSecretPassword123!"}'
```

### Lookup a Phone Number
```bash
curl -i http://localhost:8080/v1/lookup/50688889999
```

### Test Delta Sync (with Strict Ascending Ordering & ETag)
```bash
curl -i "http://localhost:8080/v1/sync/delta?country=CR&limit=10"
```

---

## 5. Apple Developer & Xcode Signing Configuration

To compile and sign the iOS app and Call Directory extension for physical testing:

1. Open `apps/mobile/ios/Runner.xcworkspace` in Xcode.
2. In the **Runner** project settings:
   - Select the **Runner** target -> **Signing & Capabilities**.
   - Add the **App Groups** capability.
   - Check or add `group.cc.blackmatter.opencaller`.
   - Add the **Background Modes** capability -> check **Background fetch** and **Background processing**.
3. Create the Call Directory Extension target:
   - Select **File** -> **New** -> **Target...** -> **Call Directory Extension**.
   - Target name: `OpenCallerDirectoryExtension`.
   - Bundle Identifier: `cc.blackmatter.opencaller.OpenCallerDirectoryExtension`.
   - Replace the generated `CallDirectoryHandler.swift` with `apps/mobile/ios/OpenCallerDirectoryExtension/CallDirectoryHandler.swift`.
   - In **Signing & Capabilities** for `OpenCallerDirectoryExtension`:
     - Add the **App Groups** capability and check `group.cc.blackmatter.opencaller`.
4. Deploy to your iPhone and enable the extension under **Settings** > **Phone** > **Call Blocking & Identification**.
