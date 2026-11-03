#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/fitai-bootstrap.log | logger -t fitai-bootstrap) 2>&1

dnf install -y git nodejs npm

mkdir -p /opt/fitai
git clone --depth 1 "${repository_url}" /opt/fitai

cd /opt/fitai
npm ci --omit=dev

chown -R ec2-user:ec2-user /opt/fitai

cat > /etc/fitai.env <<'ENV'
AWS_REGION=${aws_region}
PORT=${app_port}
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_SECRET_ARN=${db_secret_arn}
S3_BUCKET=${s3_bucket}
ENV

chmod 600 /etc/fitai.env

cat > /etc/systemd/system/fitai.service <<'SERVICE'
[Unit]
Description=FitAI Tracker API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/fitai
EnvironmentFile=/etc/fitai.env
ExecStart=/usr/bin/node /opt/fitai/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now fitai.service 
