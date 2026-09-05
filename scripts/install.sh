```bash
#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# PPOB SYSTEM - VPS AUTO INSTALLER
# Repository:
# https://github.com/mhdisa96/mybot
#
# Target:
# Ubuntu 24.04 LTS
#
# Install:
#   sudo ./scripts/install.sh
# ============================================================

APP_DIR="${APP_DIR:-/opt/ppob}"

DB_NAME="${DB_NAME:-ppob}"
DB_USER="${DB_USER:-ppob_user}"

NODE_MAJOR="${NODE_MAJOR:-20}"

log() {
    echo
    echo "============================================================"
    echo " $1"
    echo "============================================================"
}

fail() {
    echo
    echo "[ERROR] $1"
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        fail "Jalankan script menggunakan sudo/root."
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Command '$1' tidak ditemukan."
}

require_root

# ============================================================
# CHECK OS
# ============================================================

if [[ ! -f /etc/os-release ]]; then
    fail "Tidak dapat membaca informasi OS."
fi

source /etc/os-release

if [[ "${ID}" != "ubuntu" ]]; then
    fail "Installer ini dibuat untuk Ubuntu."
fi

log "OS CHECK"

echo "OS      : ${PRETTY_NAME}"
echo "App Dir : ${APP_DIR}"

# ============================================================
# INPUT CONFIGURATION
# ============================================================

echo
read -r -p "Domain utama [contoh: panel.domain.com]: " DOMAIN

read -r -p "Nama admin [Administrator]: " ADMIN_NAME
ADMIN_NAME="${ADMIN_NAME:-Administrator}"

read -r -p "Username admin [admin]: " ADMIN_USERNAME
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"

read -r -p "Nomor WhatsApp admin [628xxxxxxxxxx]: " ADMIN_WHATSAPP

if [[ -z "${ADMIN_WHATSAPP}" ]]; then
    fail "Nomor WhatsApp admin wajib diisi."
fi

read -r -s -p "Password admin: " ADMIN_PASSWORD
echo

if [[ -z "${ADMIN_PASSWORD}" ]]; then
    fail "Password admin wajib diisi."
fi

read -r -s -p "Password PostgreSQL untuk ${DB_USER}: " DB_PASSWORD
echo

if [[ -z "${DB_PASSWORD}" ]]; then
    fail "Password database wajib diisi."
fi

read -r -p "Digiflazz Username [kosongkan bila belum ada]: " DIGIFLAZZ_USERNAME
read -r -s -p "Digiflazz API Key [kosongkan bila belum ada]: " DIGIFLAZZ_API_KEY
echo

read -r -s -p "Digiflazz Webhook Secret [kosongkan bila belum ada]: " DIGIFLAZZ_WEBHOOK_SECRET
echo

# ============================================================
# SYSTEM UPDATE
# ============================================================

log "UPDATE SYSTEM"

apt-get update

DEBIAN_FRONTEND=noninteractive \
apt-get upgrade -y

# ============================================================
# INSTALL BASIC PACKAGE
# ============================================================

log "INSTALL SYSTEM PACKAGE"

DEBIAN_FRONTEND=noninteractive \
apt-get install -y \
    curl \
    git \
    nginx \
    postgresql \
    postgresql-contrib \
    openssl \
    build-essential \
    ca-certificates \
    rsync \
    ufw

# ============================================================
# NODE.JS
# ============================================================

log "INSTALL NODE.JS ${NODE_MAJOR}"

if command -v node >/dev/null 2>&1; then

    CURRENT_NODE_MAJOR="$(
        node -p "process.versions.node.split('.')[0]"
    )"

else

    CURRENT_NODE_MAJOR=0

fi

if [[ "${CURRENT_NODE_MAJOR}" -lt "${NODE_MAJOR}" ]]; then

    curl -fsSL \
        "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" \
        | bash -

    apt-get install -y nodejs

fi

echo "Node:"
node --version

echo "NPM:"
npm --version

# ============================================================
# PM2
# ============================================================

log "INSTALL PM2"

if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2
fi

pm2 --version

# ============================================================
# CHECK PROJECT
# ============================================================

log "CHECK PROJECT"

if [[ ! -d "${APP_DIR}" ]]; then
    fail "Directory project ${APP_DIR} tidak ditemukan.

Clone repository terlebih dahulu:

git clone https://github.com/mhdisa96/mybot.git ${APP_DIR}
"
fi

if [[ ! -f "${APP_DIR}/package.json" ]]; then
    fail "package.json tidak ditemukan di ${APP_DIR}."
fi

if [[ ! -f "${APP_DIR}/backend/package.json" ]]; then
    fail "backend/package.json tidak ditemukan."
fi

if [[ ! -f "${APP_DIR}/bot/package.json" ]]; then
    fail "bot/package.json tidak ditemukan."
fi

if [[ ! -f "${APP_DIR}/admin/package.json" ]]; then
    fail "admin/package.json tidak ditemukan."
fi

# ============================================================
# CREATE APPLICATION USER
# ============================================================

log "CREATE SYSTEM USER"

if ! id ppob >/dev/null 2>&1; then

    useradd \
        --system \
        --create-home \
        --home-dir /var/lib/ppob \
        --shell /usr/sbin/nologin \
        ppob

fi

mkdir -p /var/lib/ppob
mkdir -p /var/log/ppob

# ============================================================
# POSTGRESQL
# ============================================================

log "CONFIGURE POSTGRESQL"

systemctl enable postgresql
systemctl start postgresql

DB_PASSWORD_SQL="${DB_PASSWORD//\'/\'\'}"

sudo -u postgres psql <<SQL

DO \$\$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = '${DB_USER}'
    ) THEN

        CREATE ROLE ${DB_USER}
        LOGIN
        PASSWORD '${DB_PASSWORD_SQL}';

    ELSE

        ALTER ROLE ${DB_USER}
        LOGIN
        PASSWORD '${DB_PASSWORD_SQL}';

    END IF;

END
\$\$;

SQL

DATABASE_EXISTS="$(
    sudo -u postgres psql \
        -tAc \
        "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'"
)"

if [[ "${DATABASE_EXISTS}" != "1" ]]; then

    sudo -u postgres \
        createdb \
        -O "${DB_USER}" \
        "${DB_NAME}"

fi

# ============================================================
# DATABASE PASSWORD URL ENCODING
# ============================================================

urlencode_db_password() {

    python3 - "$1" <<'PY'
import sys
from urllib.parse import quote

print(quote(sys.argv[1], safe=''))
PY

}

if ! command -v python3 >/dev/null 2>&1; then
    apt-get install -y python3
fi

DB_PASSWORD_ENCODED="$(
    urlencode_db_password "${DB_PASSWORD}"
)"

DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD_ENCODED}@127.0.0.1:5432/${DB_NAME}"

# ============================================================
# INSTALL PROJECT DEPENDENCIES
# ============================================================

log "INSTALL BACKEND"

cd "${APP_DIR}/backend"

npm install --omit=dev

log "INSTALL BOT"

cd "${APP_DIR}/bot"

npm install --omit=dev

log "INSTALL ADMIN"

cd "${APP_DIR}/admin"

npm install

# ============================================================
# GENERATE SECRET
# ============================================================

log "GENERATE SECURITY SECRET"

JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 64)}"
BOT_API_KEY="${BOT_API_KEY:-$(openssl rand -hex 32)}"

# ============================================================
# CREATE ENV BACKEND
# ============================================================

log "CREATE BACKEND ENV"

cat > "${APP_DIR}/backend/.env" <<EOF
NODE_ENV=production

PORT=3000

DATABASE_URL=${DATABASE_URL}

JWT_SECRET=${JWT_SECRET}

CORS_ORIGIN=https://${DOMAIN}

DIGIFLAZZ_USERNAME=${DIGIFLAZZ_USERNAME}
DIGIFLAZZ_API_KEY=${DIGIFLAZZ_API_KEY}
DIGIFLAZZ_BASE_URL=https://api.digiflazz.com/v1
DIGIFLAZZ_WEBHOOK_SECRET=${DIGIFLAZZ_WEBHOOK_SECRET}

BOT_API_KEY=${BOT_API_KEY}
EOF

chmod 600 "${APP_DIR}/backend/.env"

# ============================================================
# CREATE ENV BOT
# ============================================================

log "CREATE BOT ENV"

cat > "${APP_DIR}/bot/.env" <<EOF
BACKEND_URL=http://127.0.0.1:3000

BOT_API_KEY=${BOT_API_KEY}
EOF

chmod 600 "${APP_DIR}/bot/.env"

# ============================================================
# ADMIN BUILD
# ============================================================

log "BUILD ADMIN PANEL"

cd "${APP_DIR}/admin"

export VITE_API_URL="/api"

npm run build

if [[ ! -d "${APP_DIR}/admin/dist" ]]; then
    fail "Admin build gagal: directory admin/dist tidak ditemukan."
fi

# ============================================================
# DATABASE MIGRATION
# ============================================================

log "DATABASE MIGRATION"

chmod +x \
    "${APP_DIR}/scripts/run-migrations.sh"

(
    cd "${APP_DIR}"

    export DATABASE_URL="${DATABASE_URL}"

    ./scripts/run-migrations.sh
)

# ============================================================
# CREATE ADMIN PASSWORD HASH
# ============================================================

log "CREATE ADMIN ACCOUNT"

ADMIN_PASSWORD_HASH="$(
    ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
    node --input-type=module <<'NODE'
import bcrypt from "./backend/node_modules/bcryptjs/index.js";

const password = process.env.ADMIN_PASSWORD;

if (!password) {
    process.exit(1);
}

console.log(
    await bcrypt.hash(password, 12)
);
NODE
)"

if [[ -z "${ADMIN_PASSWORD_HASH}" ]]; then
    fail "Gagal membuat password hash admin."
fi

ADMIN_NAME_SQL="${ADMIN_NAME//\'/\'\'}"
ADMIN_USERNAME_SQL="${ADMIN_USERNAME//\'/\'\'}"
ADMIN_WHATSAPP_SQL="${ADMIN_WHATSAPP//\'/\'\'}"
ADMIN_PASSWORD_HASH_SQL="${ADMIN_PASSWORD_HASH//\'/\'\'}"

sudo -u postgres psql \
    -d "${DB_NAME}" <<SQL

INSERT INTO users (
    name,
    whatsapp_number,
    username,
    password_hash,
    role,
    status
)

VALUES (
    '${ADMIN_NAME_SQL}',
    '${ADMIN_WHATSAPP_SQL}',
    '${ADMIN_USERNAME_SQL}',
    '${ADMIN_PASSWORD_HASH_SQL}',
    'SUPER_ADMIN',
    'ACTIVE'
)

ON CONFLICT (username)
DO UPDATE SET

    name = EXCLUDED.name,

    whatsapp_number = EXCLUDED.whatsapp_number,

    password_hash = EXCLUDED.password_hash,

    role = 'SUPER_ADMIN',

    status = 'ACTIVE';

SQL

# ============================================================
# PERMISSION
# ============================================================

log "SET PERMISSION"

chown -R ppob:ppob "${APP_DIR}"
chown -R ppob:ppob /var/lib/ppob
chown -R ppob:ppob /var/log/ppob

# ============================================================
# NGINX
# ============================================================

log "CONFIGURE NGINX"

cat > /etc/nginx/sites-available/ppob.conf <<EOF

server {

    listen 80;

    server_name ${DOMAIN};

    root ${APP_DIR}/admin/dist;

    index index.html;

    client_max_body_size 20M;

    location / {

        try_files \$uri \$uri/ /index.html;

    }

    location /api/ {

        proxy_pass http://127.0.0.1:3000;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;

        proxy_set_header X-Real-IP \$remote_addr;

        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        proxy_set_header X-Forwarded-Proto \$scheme;

    }

}

EOF

ln -sfn \
    /etc/nginx/sites-available/ppob.conf \
    /etc/nginx/sites-enabled/ppob.conf

rm -f /etc/nginx/sites-enabled/default

nginx -t

systemctl enable nginx
systemctl restart nginx

# ============================================================
# PM2 CONFIG
# ============================================================

log "CONFIGURE PM2"

cat > "${APP_DIR}/ecosystem.config.cjs" <<EOF

module.exports = {

    apps: [

        {
            name: "ppob-api",

            cwd: "${APP_DIR}/backend",

            script: "src/app.js",

            interpreter: "node",

            env: {
                NODE_ENV: "production"
            },

            autorestart: true,

            restart_delay: 3000,

            max_restarts: 10
        },

        {
            name: "ppob-bot",

            cwd: "${APP_DIR}/bot",

            script: "src/index.js",

            interpreter: "node",

            env: {
                NODE_ENV: "production"
            },

            autorestart: true,

            restart_delay: 3000,

            max_restarts: 10
        }

    ]

};

EOF

chown ppob:ppob \
    "${APP_DIR}/ecosystem.config.cjs"

# ============================================================
# START PM2 AS PPOB USER
# ============================================================

log "START PM2"

sudo -u ppob \
    env \
        HOME=/var/lib/ppob \
        PM2_HOME=/var/lib/ppob/.pm2 \
    pm2 delete ppob-api >/dev/null 2>&1 || true

sudo -u ppob \
    env \
        HOME=/var/lib/ppob \
        PM2_HOME=/var/lib/ppob/.pm2 \
    pm2 delete ppob-bot >/dev/null 2>&1 || true

sudo -u ppob \
    env \
        HOME=/var/lib/ppob \
        PM2_HOME=/var/lib/ppob/.pm2 \
    pm2 start \
        "${APP_DIR}/ecosystem.config.cjs"

sudo -u ppob \
    env \
        HOME=/var/lib/ppob \
        PM2_HOME=/var/lib/ppob/.pm2 \
    pm2 save

# ============================================================
# PM2 SYSTEMD STARTUP
# ============================================================

log "CONFIGURE PM2 STARTUP"

cat > /etc/systemd/system/ppob-pm2.service <<EOF

[Unit]

Description=PPOB PM2 Service

After=network.target

[Service]

Type=forking

User=ppob

Environment=HOME=/var/lib/ppob

Environment=PM2_HOME=/var/lib/ppob/.pm2

LimitNOFILE=infinity

PIDFile=/var/lib/ppob/.pm2/pm2.pid

ExecStart=/usr/bin/pm2 resurrect

ExecReload=/usr/bin/pm2 reload all

ExecStop=/usr/bin/pm2 kill

Restart=on-failure

[Install]

WantedBy=multi-user.target

EOF

systemctl daemon-reload

systemctl enable ppob-pm2.service

systemctl restart ppob-pm2.service

# ============================================================
# FIREWALL
# ============================================================

log "CONFIGURE FIREWALL"

ufw allow OpenSSH || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true

ufw --force enable

# ============================================================
# HEALTH CHECK
# ============================================================

log "HEALTH CHECK"

sleep 5

if curl \
    --fail \
    --silent \
    --show-error \
    http://127.0.0.1:3000/health \
    >/dev/null
then

    echo "Backend: OK"

else

    echo "Backend: FAIL"

    echo
    echo "Check dengan:"
    echo
    echo "sudo -u ppob PM2_HOME=/var/lib/ppob/.pm2 pm2 status"
    echo "sudo -u ppob PM2_HOME=/var/lib/ppob/.pm2 pm2 logs ppob-api"

fi

# ============================================================
# FINAL
# ============================================================

log "INSTALLATION SELESAI"

echo
echo "Repository:"
echo "https://github.com/mhdisa96/mybot"
echo

echo "Application:"
echo "${APP_DIR}"
echo

echo "Domain:"
echo "http://${DOMAIN}"
echo

echo "Backend:"
echo "http://127.0.0.1:3000"
echo

echo "Admin Username:"
echo "${ADMIN_USERNAME}"
echo

echo "PM2:"
echo
sudo -u ppob \
    env \
        HOME=/var/lib/ppob \
        PM2_HOME=/var/lib/ppob/.pm2 \
    pm2 status

echo
echo "Health:"
echo "curl http://127.0.0.1:3000/health"

echo
echo "Next:"
echo "1. Pastikan DNS domain mengarah ke IP VPS."
echo "2. Pasang SSL dengan Certbot."
echo "3. Isi credential Digiflazz bila belum diisi."
echo "4. Pairing WhatsApp Bot."
echo "5. Test login Admin Panel."

echo
echo "============================================================"
echo " PPOB SYSTEM READY"
echo "============================================================"
```

### Cara pakainya

Di repository GitHub Anda:

```text
mhdisa96/mybot
└── scripts/
    └── install.sh
```

Kemudian VPS:

```bash
git clone https://github.com/mhdisa96/mybot.git /opt/ppob
cd /opt/ppob
chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

Installer ini mengikuti struktur source yang kita punya saat ini: `backend`, `bot`, `admin`, `database/migrations`, dan `scripts/run-migrations.sh`. Backend memang menggunakan `src/app.js`, bot `src/index.js`, dan admin menggunakan `npm run build`; jadi saya tidak menggunakan perintah seperti `npm run db:migrate` yang memang tidak ada di `package.json` root saat ini.
