#!/bin/bash
# Description: Master Orchestrator for study.adriandrummond.com (Wiki.JS + OpenSearch)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
if [ -f "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
else
  echo "Error: .env file not found. Please copy sample.env to .env and configure it."
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (using sudo)."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOG_FILE="${SCRIPT_DIR}/install_$(date +%F_%T).log"

{
echo "Starting study.adriandrummond.com Deployment..."

# --- 1. System Preparation & AWS CLI ---
hostnamectl set-hostname "$DOMAIN_NAME"

dnf update -y
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y policycoreutils-python-utils certbot python3-certbot-nginx unzip wget curl java-21-openjdk-headless nodejs npm nginx postgresql-server postgresql-contrib

if ! command -v aws &> /dev/null; then
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip
fi



# --- 3. Database: PostgreSQL for Wiki.js ---
postgresql-setup --initdb || true
systemctl enable --now postgresql
sleep 3
sudo -u postgres psql -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';" || true
sudo -u postgres psql -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;" || true
sudo -u postgres psql -d $POSTGRES_DB -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" || true

# --- 4. OpenSearch Setup (For ingested Meet transcripts) ---
curl -SL https://artifacts.opensearch.org/releases/bundle/opensearch/3.x/opensearch-3.x.repo -o /etc/yum.repos.d/opensearch-3.x.repo
curl -SL https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/3.x/opensearch-dashboards-3.x.repo -o /etc/yum.repos.d/opensearch-dashboards-3.x.repo

env OPENSEARCH_INITIAL_ADMIN_PASSWORD="$OPENSEARCH_ADMIN_PASSWORD" dnf install -y opensearch opensearch-dashboards
echo "network.host: 127.0.0.1" >> /etc/opensearch/opensearch.yml
echo "plugins.security.disabled: true" >> /etc/opensearch/opensearch.yml
echo "discovery.type: single-node" >> /etc/opensearch/opensearch.yml
systemctl enable --now opensearch opensearch-dashboards

# --- 5. Application: Wiki.JS ---
mkdir -p /var/www/wikijs
cd /var/www/wikijs
wget https://github.com/Requarks/wiki/releases/download/v2.5.301/wiki-js.tar.gz
tar xzf wiki-js.tar.gz && rm wiki-js.tar.gz
cp config.sample.yml config.yml
sed -i "s/db: 'wiki'/db: '${POSTGRES_DB}'/g" config.yml
sed -i "s/user: 'wikijs'/user: '${POSTGRES_USER}'/g" config.yml
sed -i "s/pass: 'wikijsrocks'/pass: '${POSTGRES_PASSWORD}'/g" config.yml
sed -i "s/port: 3000/port: 3001/g" config.yml

npm install -g pm2
npx pm2 start server -n wikijs
npx pm2 save
npx pm2 startup systemd -u root --hp /root || true

# --- 6. Node.js Welcome App & Nginx Configuration ---
echo "Configuring Node.js Welcome App..."
if [ -d "/home/ec2-user/app" ]; then
    cd /home/ec2-user/app
    npm install
    npx pm2 start app.js -n study-welcome-app
    npx pm2 save
    # Note: pm2 startup for ec2-user can be run manually if needed, or we just rely on root's pm2 for simplicity.
fi

echo "Configuring Nginx Reverse Proxy..."
cat << 'EOF' > /etc/nginx/conf.d/study-server.conf
server {
    listen 80;
    server_name study.adriandrummond.com;

    access_log /var/log/nginx/study.adriandrummond.com-access.log main;
    error_log /var/log/nginx/study.adriandrummond.com-error.log;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
systemctl enable --now nginx
systemctl restart nginx

# --- 7. Desktop UI & Google Antigravity IDE ---
dnf groupinstall -y "Server with GUI" || dnf install -y @gnome-desktop
dnf install -y gnome-remote-desktop
systemctl enable --now gnome-remote-desktop.service
systemctl set-default graphical.target

# Install Google Antigravity IDE (Assuming standard AppImage/Binary distribution)
mkdir -p /opt/google/antigravity
curl -sL "https://dl.google.com/antigravity/latest/antigravity-linux-x86_64.tar.gz" | tar xz -C /opt/google/antigravity || echo "IDE download requires manual auth or URL update."
ln -sf /opt/google/antigravity/bin/antigravity /usr/local/bin/antigravity

echo "Deployment complete. UI enabled for RDP."
} 2>&1 | tee -a "$LOG_FILE"