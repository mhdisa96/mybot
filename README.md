# PPOB System

Sistem PPOB berbasis Node.js dengan:

* Backend API
* PostgreSQL
* WhatsApp Bot
* Admin Panel
* Digiflazz API
* Deposit manual
* Persiapan QRIS / Payment Gateway
* JWT Authentication
* Role & Permission
* Balance Mutation
* Transaction & Refund
* Webhook Idempotency
* Audit Log
* PM2
* Nginx

Arsitektur sistem:

```text
WhatsApp User
      |
      v
WhatsApp Bot
      |
      v
Backend API
      |
      +----------> PostgreSQL
      |
      +----------> Digiflazz
      |
      +----------> Payment Service
```

---

# 1. Struktur Project

```text
ppob/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── modules/
│   │   ├── repositories/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── validators/
│   │   └── app.js
│   ├── package.json
│   └── .env.example
│
├── bot/
│   ├── src/
│   ├── package.json
│   └── .env.example
│
├── admin/
│   ├── src/
│   ├── package.json
│   └── .env.example
│
├── database/
│   ├── migrations/
│   └── seeders/
│
├── nginx/
│   └── ppob.conf
│
├── scripts/
│   ├── install-vps.sh
│   └── backup-db.sh
│
├── ecosystem.config.cjs
├── .gitignore
├── package.json
└── README.md
```

---

# 2. Kebutuhan VPS

Rekomendasi:

```text
OS      : Ubuntu 24.04 LTS
RAM     : Minimal 2 GB
RAM     : Disarankan 4 GB
Storage : 40-60 GB SSD
IPv4    : 1
```

Software:

```text
Node.js
PostgreSQL
Nginx
PM2
Git
UFW
Certbot
```

---

# 3. Install dari GitHub

Login ke VPS:

```bash
ssh root@IP_VPS
```

Update server:

```bash
apt update && apt upgrade -y
```

Install Git:

```bash
apt install -y git
```

Clone repository:

```bash
git clone https://github.com/USERNAME/REPOSITORY.git /opt/ppob
```

Masuk directory:

```bash
cd /opt/ppob
```

Beri permission:

```bash
chmod +x scripts/install-vps.sh
chmod +x scripts/backup-db.sh
```

Jalankan installer:

```bash
sudo ./scripts/install-vps.sh
```

Installer akan membantu memasang:

```text
Node.js
PostgreSQL
Nginx
PM2
Dependency
Database
Migration
Build Admin
Environment
PM2 Service
```

---

# 4. Konfigurasi Environment

Jangan pernah menyimpan credential production ke GitHub.

Gunakan:

```text
.env
```

dan bukan:

```text
.env
```

di repository.

Contoh:

```env
NODE_ENV=production

PORT=3000

DATABASE_URL=postgresql://ppob_user:PASSWORD@127.0.0.1:5432/ppob

JWT_SECRET=GANTI_DENGAN_SECRET_PANJANG

BOT_API_KEY=GANTI_DENGAN_API_KEY_BOT

DIGIFLAZZ_USERNAME=USERNAME_DIGIFLAZZ
DIGIFLAZZ_API_KEY=API_KEY_DIGIFLAZZ

DIGIFLAZZ_WEBHOOK_SECRET=WEBHOOK_SECRET

ADMIN_USERNAME=admin
ADMIN_PASSWORD=GANTI_PASSWORD_ADMIN

APP_URL=https://domainanda.com
API_URL=https://api.domainanda.com
```

Generate JWT secret:

```bash
openssl rand -hex 64
```

Generate Bot API key:

```bash
openssl rand -hex 32
```

---

# 5. Database PostgreSQL

Masuk PostgreSQL:

```bash
sudo -u postgres psql
```

Buat database:

```sql
CREATE DATABASE ppob;
```

Buat user:

```sql
CREATE USER ppob_user WITH PASSWORD 'PASSWORD_DATABASE';
```

Berikan akses:

```sql
GRANT ALL PRIVILEGES ON DATABASE ppob TO ppob_user;
```

Keluar:

```sql
\q
```

Test:

```bash
psql "postgresql://ppob_user:PASSWORD_DATABASE@127.0.0.1:5432/ppob"
```

---

# 6. Migration Database

Dari directory project:

```bash
cd /opt/ppob
```

Jalankan migration:

```bash
npm run db:migrate
```

Seed data:

```bash
npm run db:seed
```

Database utama:

```text
users
products
balance_mutations
transactions
transaction_status_logs
deposits
payment_transactions
webhook_events
audit_logs
```

---

# 7. Backend

Install dependency:

```bash
cd /opt/ppob/backend
npm install
```

Build:

```bash
npm run build
```

Test:

```bash
npm test
```

Jalankan:

```bash
npm start
```

API default:

```text
http://127.0.0.1:3000
```

Health check:

```text
GET /health
```

Contoh:

```bash
curl http://127.0.0.1:3000/health
```

Response yang diharapkan:

```json
{
  "status": "ok"
}
```

---

# 8. Admin Panel

Masuk:

```bash
cd /opt/ppob/admin
```

Install:

```bash
npm install
```

Build:

```bash
npm run build
```

Hasil build:

```text
admin/dist/
```

Nginx digunakan untuk menyajikan file admin.

---

# 9. WhatsApp Bot

Masuk:

```bash
cd /opt/ppob/bot
```

Install dependency:

```bash
npm install
```

Jalankan bot:

```bash
npm start
```

Saat pertama kali dijalankan, WhatsApp akan meminta proses pairing/login sesuai implementasi bot.

Session WhatsApp jangan disimpan ke GitHub.

---

# 10. PM2

Gunakan PM2 untuk menjalankan service:

```bash
cd /opt/ppob
pm2 start ecosystem.config.cjs
```

Lihat status:

```bash
pm2 status
```

Lihat log:

```bash
pm2 logs
```

Simpan konfigurasi:

```bash
pm2 save
```

Agar otomatis start setelah reboot:

```bash
pm2 startup
```

Ikuti command yang diberikan PM2.

Kemudian:

```bash
pm2 save
```

Service yang dijalankan:

```text
PPOB Backend
PPOB WhatsApp Bot
```

---

# 11. Nginx

Contoh arsitektur domain:

```text
https://domainanda.com
        |
        v
     Admin

https://api.domainanda.com
        |
        v
     Backend API
```

Copy konfigurasi:

```bash
cp nginx/ppob.conf /etc/nginx/sites-available/ppob
```

Aktifkan:

```bash
ln -s /etc/nginx/sites-available/ppob /etc/nginx/sites-enabled/ppob
```

Test:

```bash
nginx -t
```

Reload:

```bash
systemctl reload nginx
```

---

# 12. Domain

Arahkan DNS:

```text
domainanda.com
      A
      |
      v
IP VPS

api.domainanda.com
      A
      |
      v
IP VPS
```

Contoh:

```text
@     -> 123.123.123.123
api   -> 123.123.123.123
```

Tunggu DNS aktif.

Test:

```bash
ping domainanda.com
ping api.domainanda.com
```

---

# 13. HTTPS SSL

Install Certbot:

```bash
apt install -y certbot python3-certbot-nginx
```

Jalankan:

```bash
certbot --nginx \
-d domainanda.com \
-d api.domainanda.com
```

Test renewal:

```bash
certbot renew --dry-run
```

---

# 14. Firewall

Aktifkan UFW:

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

Jangan membuka PostgreSQL ke internet jika tidak diperlukan.

Jangan membuka port backend:

```text
3000
```

secara publik.

Backend sebaiknya hanya diakses melalui Nginx.

---

# 15. Digiflazz

Credential Digiflazz disimpan di `.env`.

Contoh:

```env
DIGIFLAZZ_USERNAME=USERNAME
DIGIFLAZZ_API_KEY=SECRET
DIGIFLAZZ_WEBHOOK_SECRET=SECRET
```

Jangan:

```javascript
const API_KEY = "xxxxxxxx";
```

Credential harus tetap berada di environment server.

Flow:

```text
User
  |
  v
Pilih Produk
  |
  v
Cek Saldo
  |
  v
Konfirmasi
  |
  v
Lock Saldo
  |
  v
Potong Saldo
  |
  v
Digiflazz
  |
  v
PROCESS
  |
  v
Callback
  |
  +---- SUCCESS
  |
  +---- FAILED
          |
          v
        REFUND
```

---

# 16. Idempotency

Callback Digiflazz harus idempotent.

Flow:

```text
Callback #1
     |
     v
Process
     |
     v
SUCCESS

Callback #2
     |
     v
event sudah ada
     |
     v
Skip
```

Hal ini mencegah saldo diproses dua kali ketika provider mengirim callback berulang.

---

# 17. Deposit Manual

Flow awal:

```text
User
 |
 v
Request Deposit
 |
 v
Admin
 |
 v
Verifikasi
 |
 v
Tambah Saldo
 |
 v
Balance Mutation
```

Admin wajib dapat melihat:

```text
User
Nominal
Tanggal
Status
Bukti
Catatan
```

Setelah disetujui:

```text
Deposit APPROVED
       |
       v
Tambah Saldo
       |
       v
Balance Mutation
```

---

# 18. Update Source dari GitHub

Setiap ada update:

```bash
cd /opt/ppob
git pull origin main
```

Backend:

```bash
cd /opt/ppob/backend
npm install
npm run build
```

Admin:

```bash
cd /opt/ppob/admin
npm install
npm run build
```

Migration jika ada:

```bash
cd /opt/ppob
npm run db:migrate
```

Restart:

```bash
pm2 restart all
```

Lihat status:

```bash
pm2 status
```

Lihat log:

```bash
pm2 logs
```

---

# 19. Backup Database

Jalankan:

```bash
./scripts/backup-db.sh
```

Contoh backup:

```text
backup/
├── ppob-2026-09-05-160000.sql
├── ppob-2026-09-06-160000.sql
└── ...
```

Backup sebaiknya dipindahkan secara berkala ke server/storage terpisah.

---

# 20. Restore Database

Contoh:

```bash
psql \
"postgresql://ppob_user:PASSWORD@127.0.0.1:5432/ppob" \
< backup/ppob-2026-09-05-160000.sql
```

Pastikan backup diverifikasi sebelum dianggap sebagai backup production yang valid.

---

# 21. Monitoring

Status service:

```bash
pm2 status
```

Log:

```bash
pm2 logs
```

CPU/RAM:

```bash
htop
```

Disk:

```bash
df -h
```

PostgreSQL:

```bash
systemctl status postgresql
```

Nginx:

```bash
systemctl status nginx
```

---

# 22. Troubleshooting

## Backend tidak berjalan

```bash
pm2 logs
```

Check port:

```bash
ss -lntp | grep 3000
```

Check environment:

```bash
cd /opt/ppob/backend
cat .env
```

Jangan membagikan isi `.env` ke publik.

---

## PostgreSQL gagal

```bash
systemctl status postgresql
```

Test:

```bash
psql "$DATABASE_URL"
```

---

## Nginx gagal

```bash
nginx -t
```

Lihat log:

```bash
tail -f /var/log/nginx/error.log
```

---

## Admin tidak tampil

Build ulang:

```bash
cd /opt/ppob/admin
npm run build
```

Kemudian:

```bash
systemctl reload nginx
```

---

## Bot tidak berjalan

```bash
pm2 logs ppob-bot
```

Restart:

```bash
pm2 restart ppob-bot
```

Pastikan session WhatsApp masih tersedia.

---

# 23. Struktur Production

Setelah selesai:

```text
Internet
   |
   v
 Nginx
   |
   +----------------------+
   |                      |
   v                      v
Admin                  API
                         |
                         +------ PostgreSQL
                         |
                         +------ Digiflazz
                         |
                         +------ Payment Gateway

WhatsApp
   |
   v
Bot
   |
   v
API
```

---

# 24. Security Checklist

Sebelum production:

```text
[ ] SSH menggunakan key
[ ] Root login dibatasi
[ ] UFW aktif
[ ] HTTPS aktif
[ ] JWT_SECRET sudah diganti
[ ] DATABASE password kuat
[ ] Digiflazz API key tidak ada di GitHub
[ ] BOT_API_KEY tidak ada di GitHub
[ ] .env tidak masuk Git
[ ] WhatsApp session tidak masuk Git
[ ] PostgreSQL tidak terbuka publik
[ ] API menggunakan HTTPS
[ ] Rate limit aktif
[ ] Input validation aktif
[ ] Authentication aktif
[ ] Authorization aktif
[ ] Audit log aktif
[ ] Database transaction aktif
[ ] Row locking aktif
[ ] Idempotency aktif
[ ] Webhook verification aktif
[ ] Backup database aktif
[ ] Monitoring aktif
```

---

# 25. Workflow Development

Developer:

```text
Local PC
   |
   v
Git
   |
   v
GitHub
   |
   v
VPS
   |
   v
git pull
   |
   v
Build
   |
   v
PM2 restart
```

Source code:

```text
GitHub
```

Configuration production:

```text
VPS
└── .env
```

Database:

```text
VPS
└── PostgreSQL
```

WhatsApp session:

```text
VPS
└── session/
```

---

# 26. Jangan Upload File Berikut ke GitHub

```text
.env
.env.production
node_modules/
dist/
build/
logs/
*.log
WhatsApp session
private key
database password
JWT secret
Digiflazz API key
Admin password
```

Pastikan `.gitignore` mencakup file tersebut.

---

# 27. Quick Deployment

Untuk deployment pertama:

```bash
apt update && apt upgrade -y

apt install -y git

git clone https://github.com/USERNAME/REPOSITORY.git /opt/ppob

cd /opt/ppob

chmod +x scripts/install-vps.sh

sudo ./scripts/install-vps.sh
```

Setelah instalasi:

```bash
nano /opt/ppob/backend/.env
```

Masukkan konfigurasi production.

Kemudian:

```bash
cd /opt/ppob

npm run db:migrate

npm run db:seed

pm2 start ecosystem.config.cjs

pm2 save
```

Cek:

```bash
pm2 status
```

Test API:

```bash
curl http://127.0.0.1:3000/health
```

---

# 28. Production Rule

GitHub:

```text
SOURCE CODE
```

VPS:

```text
ENVIRONMENT
DATABASE
SESSION
LOG
BACKUP
```

Jangan menyimpan secret production di repository GitHub.

---

# 29. Status

Project ini dirancang modular agar dapat dikembangkan menjadi:

```text
PPOB
├── Pulsa
├── Paket Data
├── Token PLN
├── PLN Pascabayar
├── PDAM
├── BPJS
├── Telkom
├── Voucher Game
├── E-Wallet
├── TV
├── Internet
│
├── WhatsApp Bot
├── Admin Panel
├── Deposit
├── QRIS
├── GoPay
├── Payment Gateway
├── Agen
├── Komisi
└── Produk Tambahan
```

## License

Private Project.

Gunakan dan modifikasi sesuai kebutuhan sistem Anda.
