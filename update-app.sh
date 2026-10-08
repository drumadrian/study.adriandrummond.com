#!/bin/bash
set -e
source .env

echo "Pushing updated Node.js app to the server..."
scp -r -o StrictHostKeyChecking=no -i "$KEY_PATH" app ec2-user@$PUBLIC_IP:/home/ec2-user/

echo "Applying SELinux and PM2 fixes on the server..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ec2-user@$PUBLIC_IP << 'EOF'
  # Allow Nginx to proxy network requests to the Node.js app (Fixes 502 Bad Gateway)
  sudo setsebool -P httpd_can_network_connect 1
  
  # Fix permissions from earlier install script
  sudo chown -R ec2-user:ec2-user /home/ec2-user/app
  
  # Install new dependencies (http-proxy-middleware) and restart the app
  cd /home/ec2-user/app
  npm install
  sudo -u root npx pm2 restart study-welcome-app || sudo -u root npx pm2 start app.js -n study-welcome-app
  sudo -u root npx pm2 save
EOF

echo "Done! The app is updated, Nginx proxying is permitted, and the 502 Bad Gateway should be resolved."
