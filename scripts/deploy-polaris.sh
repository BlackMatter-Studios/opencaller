#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# OpenCaller Deployment Script for Rocky Linux VM ("Polaris")
# ==============================================================================

SSH_HOST="100.95.7.28"
SSH_USER="sgarita"
SSH_KEY="$HOME/.ssh/id_ed25519_polaris"
REMOTE_DIR="/home/sgarita/opencaller"

echo "======================================================="
echo "🛡️  Deploying OpenCaller Backend to Polaris VM"
echo "======================================================="

# 1. Test SSH Connection
echo "--> Testing SSH connectivity to Polaris ($SSH_HOST)..."
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes "${SSH_USER}@${SSH_HOST}" "echo 'Connection successful: ' \$(uname -n)"

# 2. Create remote directory
echo "--> Ensuring remote directory exists..."
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "${SSH_USER}@${SSH_HOST}" "mkdir -p ${REMOTE_DIR}/services"

# 3. Synchronize backend files (API, Crawler, Migrations, Compose files)
echo "--> Syncing files to Polaris..."
rsync -avz -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes" \
  --exclude 'target' \
  --exclude '.git' \
  --exclude 'apps' \
  --exclude '*.sqlite' \
  --exclude 'pgdata' \
  --exclude 'Cargo.lock' \
  ./docker-compose.yml \
  ./docker-compose.polaris.yml \
  ./.env.example \
  ./services \
  "${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}/"

# 4. Initialize .env on Polaris if missing
echo "--> Checking remote .env configuration..."
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "${SSH_USER}@${SSH_HOST}" "bash -s" << 'EOF'
if [ ! -f /home/sgarita/opencaller/.env ]; then
  echo "Creating /home/sgarita/opencaller/.env from .env.example..."
  cp /home/sgarita/opencaller/.env.example /home/sgarita/opencaller/.env
  # Generate cryptographically secure JWT secret and Postgres password
  DB_PASS=$(openssl rand -hex 16)
  JWT_SEC=$(openssl rand -hex 32)
  sed -i "s/opencaller_secure_password/${DB_PASS}/g" /home/sgarita/opencaller/.env
  sed -i "s/replace_this_with_a_64_char_random_hex_key_for_production/${JWT_SEC}/g" /home/sgarita/opencaller/.env
  echo ".env created with generated secrets."
fi
EOF

# 5. Check Cloudflare Tunnel configuration on Polaris
echo "--> Verifying Cloudflare ingress rule in ~/.cloudflared/config.yml..."
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "${SSH_USER}@${SSH_HOST}" "bash -s" << 'EOF'
CF_CONFIG="/home/sgarita/.cloudflared/config.yml"
if [ -f "$CF_CONFIG" ]; then
  if grep -q "opencaller.blackmatter.cc" "$CF_CONFIG"; then
    echo "Rule for opencaller.blackmatter.cc already present in Cloudflare config."
  else
    echo "Adding opencaller.blackmatter.cc ingress rule..."
    # Insert before the catch-all 404 rule
    sed -i '/service: http_status:404/i \  - hostname: opencaller.blackmatter.cc\n    service: http://opencaller-api:8080' "$CF_CONFIG"
    echo "Restarting cloudflared-central container..."
    docker restart cloudflared-central || true
  fi
fi
EOF

# 6. Build and launch containers via Docker Compose
echo "--> Building and starting Docker containers on Polaris..."
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "${SSH_USER}@${SSH_HOST}" "bash -s" << 'EOF'
cd /home/sgarita/opencaller
docker compose -f docker-compose.yml -f docker-compose.polaris.yml up -d --build

echo "Waiting for services to become healthy..."
sleep 5

echo "--> Checking local API health on Polaris (port 8085)..."
curl -s -i http://127.0.0.1:8085/health || true

echo "--> Checking resource footprint (RAM limit verification):"
docker stats --no-stream opencaller-api opencaller-crawler opencaller-postgres
EOF

echo "======================================================="
echo "✅ Deployment on Polaris completed successfully!"
echo "Public Domain: https://opencaller.blackmatter.cc"
echo "Local Port: http://127.0.0.1:8085"
echo "======================================================="
