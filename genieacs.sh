#!/bin/bash
set -e

echo "=== Update sistem ==="
apt update && apt upgrade -y

echo "=== Install prerequisite umum ==="
apt install -y curl gnupg apt-transport-https software-properties-common

echo "=== Install Node.js (versi stabil terbaru) ==="
curl -sL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
echo "Node.js version: $(node -v)"

echo "=== Install MongoDB ==="
# Tambah key dan repo MongoDB untuk Ubuntu 22.04 (jammy)
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-8.0.list
apt update
apt install -y mongodb-org
systemctl enable mongod
systemctl start mongod
echo "MongoDB version: $(mongod --version | head -n1)"

echo "=== Install GenieACS ==="
npm install -g genieacs@latest

# Buat user sistem
USERGEN="genieacs"
if ! id "$USERGEN" &>/dev/null; then
  useradd --system --no-create-home --user-group $USERGEN
fi

echo "=== Setup direktori dan hak akses ==="
mkdir -p /opt/genieacs/ext
chown $USERGEN:$USERGEN /opt/genieacs/ext

echo "=== Buat file environment untuk GenieACS ==="
ENVFILE=/opt/genieacs/genieacs.env
cat > $ENVFILE <<EOF
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
EOF

# Generate JWT secret untuk UI
echo "GENIEACS_UI_JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")" >> $ENVFILE

chown $USERGEN:$USERGEN $ENVFILE
chmod 600 $ENVFILE

echo "=== Buat direktori log dan atur hak akses ==="
mkdir -p /var/log/genieacs
chown $USERGEN:$USERGEN /var/log/genieacs

echo "=== Buat service systemd untuk GenieACS ==="

# CWMP
cat > /etc/systemd/system/genieacs-cwmp.service <<EOF
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=$USERGEN
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=$(which genieacs-cwmp)
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# NBI
cat > /etc/systemd/system/genieacs-nbi.service <<EOF
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
User=$USERGEN
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=$(which genieacs-nbi)
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# FS
cat > /etc/systemd/system/genieacs-fs.service <<EOF
[Unit]
Description=GenieACS FS
After=network.target

[Service]
User=$USERGEN
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=$(which genieacs-fs)
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# UI
cat > /etc/systemd/system/genieacs-ui.service <<EOF
[Unit]
Description=GenieACS UI
After=network.target

[Service]
User=$USERGEN
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=$(which genieacs-ui)
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reload systemd dan aktifkan layanan ==="
systemctl daemon-reload
systemctl enable --now genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo "=== Status layanan ==="
systemctl --no-pager --quiet is-active genieacs-cwmp && echo "✅ CWMP aktif"
systemctl --no-pager --quiet is-active genieacs-nbi && echo "✅ NBI aktif"
systemctl --no-pager --quiet is-active genieacs-fs && echo "✅ FS aktif"
systemctl --no-pager --quiet is-active genieacs-ui && echo "✅ UI aktif"

echo "=== Instalasi selesai ==="
echo "Akses Web UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "Port CWMP: 7547"
echo "File environment: $ENVFILE"
echo "Log ada di: /var/log/genieacs/"
