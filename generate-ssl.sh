#!/bin/bash
set -e

DOMAIN="study.adriandrummond.com"

echo "Setting up Let's Encrypt SSL for $DOMAIN..."

# Ensure certbot is installed
if ! command -v certbot &> /dev/null; then
    sudo dnf install -y epel-release
    sudo dnf install -y certbot python3-certbot-nginx
fi

# Request SSL and automatically configure Nginx to redirect HTTP to HTTPS
# Note: You must ensure your domain's DNS A record points to this server's Public IP,
# and that Security Group allows port 80/443 from 0.0.0.0/0 for Certbot to validate!
sudo certbot --nginx -d "$DOMAIN" -d "wiki.adriandrummond.com" --non-interactive --agree-tos -m admin@adriandrummond.com --redirect

echo "SSL Certificate generated and Nginx configured successfully!"
