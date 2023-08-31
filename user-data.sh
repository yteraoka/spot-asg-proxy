#!/bin/bash
set -eox

OAUTH2_PROXY_VERSION=v7.4.0
S3_PROXY_VERSION=4.11.0
ARCH=amd64

cd /var/tmp

mkdir -p /opt/oauth2-proxy/bin /opt/s3-proxy

curl -LO https://github.com/oauth2-proxy/oauth2-proxy/releases/download/${OAUTH2_PROXY_VERSION}/oauth2-proxy-${OAUTH2_PROXY_VERSION}.linux-${ARCH}.tar.gz
tar -xvf oauth2-proxy-${OAUTH2_PROXY_VERSION}.linux-${ARCH}.tar.gz
install -o root -g root -m 0755 oauth2-proxy-${OAUTH2_PROXY_VERSION}.linux-${ARCH}/oauth2-proxy /opt/oauth2-proxy/bin/oauth2-proxy
rm -fr oauth2-proxy-${OAUTH2_PROXY_VERSION}.linux-${ARCH}.tar.gz oauth2-proxy-${OAUTH2_PROXY_VERSION}.linux-${ARCH}

curl -LO https://github.com/oxyno-zeta/s3-proxy/releases/download/v${S3_PROXY_VERSION}/s3-proxy_${S3_PROXY_VERSION}_linux_${ARCH}.tar.gz
tar -xvf s3-proxy_${S3_PROXY_VERSION}_linux_${ARCH}.tar.gz -C /opt/s3-proxy --owner root
rm s3-proxy_${S3_PROXY_VERSION}_linux_${ARCH}.tar.gz

OAUTH2_PROXY_DOMAIN=$(aws ssm get-parameter --name /spot-asg-proxy/OAUTH2_PROXY_DOMAIN --query Parameter.Value --output text)
OAUTH2_PROXY_CLIENT_ID=$(aws ssm get-parameter --name /spot-asg-proxy/OAUTH2_PROXY_CLIENT_ID --query Parameter.Value --output text)
OAUTH2_PROXY_CLIENT_SECRET=$(aws ssm get-parameter --name /spot-asg-proxy/OAUTH2_PROXY_CLIENT_SECRET --query Parameter.Value --output text --with-decryption)
OAUTH2_PROXY_COOKIE_SECRET=$(aws ssm get-parameter --name /spot-asg-proxy/OAUTH2_PROXY_COOKIE_SECRET --query Parameter.Value --output text --with-decryption)
EVIDENCE_BUCKET_NAME=$(aws ssm get-parameter --name /spot-asg-proxy/EVIDENCE_BUCKET_NAME --query Parameter.Value --output text)

cat > /etc/systemd/system/oauth2-proxy.service <<'EOF'
[Unit]
Description=OAuth2 Proxy
After=network-online.target remote-fs.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/oauth2-proxy/bin/oauth2-proxy --email-domain=* --upstream=http://127.0.0.1:8000
PrivateTmp=true
EnvironmentFile=/etc/sysconfig/oauth2-proxy
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/sysconfig/oauth2-proxy <<EOF
OAUTH2_PROXY_PROVIDER=github
OAUTH2_PROXY_GITHUB_REPO=yteraoka/spot-asg-proxy
OAUTH2_PROXY_CLIENT_ID=${OAUTH2_PROXY_CLIENT_ID}
OAUTH2_PROXY_CLIENT_SECRET=${OAUTH2_PROXY_CLIENT_SECRET}
OAUTH2_PROXY_COOKIE_SECRET=${OAUTH2_PROXY_COOKIE_SECRET}
OAUTH2_PROXY_COOKIE_SECURE=true
OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:8080
OAUTH2_PROXY_REDIRECT_URL=https://${OAUTH2_PROXY_DOMAIN}/oauth2/callback
OAUTH2_PROXY_SCOPE=user:email
EOF

cat > /etc/systemd/system/s3-proxy.service <<'EOF'
[Unit]
Description=S3 Proxy
After=network-online.target remote-fs.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/s3-proxy
ExecStart=/opt/s3-proxy/s3-proxy
PrivateTmp=true
Restart=always

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /opt/s3-proxy/conf

cat > /opt/s3-proxy/conf/config.yaml <<EOF
log:
  level: info
  format: text

server:
  listenAddr: 127.0.0.1
  port: 8000
  timeouts:
    readTimeout: 5s
    readHeaderTimeout: 10s
    writeTimeout: 60s
    idleTimeout: 10s
  compress:
    enabled: false

targets:
  first-bucket:
    mount:
      path:
        - /
    actions:
      GET:
        enabled: true
        config:
          indexDocument: index.html
          disableListing: true
      PUT:
        enabled: false
      DELETE:
        enabled: false
    bucket:
      name: ${EVIDENCE_BUCKET_NAME}
      prefix: ""
      region: ap-northeast-1
      disableSSL: false
EOF

systemctl daemon-reload

systemctl start s3-proxy
systemctl enable s3-proxy

systemctl start oauth2-proxy
systemctl enable oauth2-proxy
