# PPOB System

Repository:

```text
https://github.com/mhdisa96/mybot
```

## Auto Install VPS

Installer dibuat untuk **Ubuntu 24.04 LTS**.

Installer akan otomatis memasang dan menyiapkan:

* Node.js
* PostgreSQL
* Nginx
* PM2
* Backend API
* WhatsApp Bot
* Admin Panel
* Database
* Migration
* `.env`
* User `SUPER_ADMIN`
* Firewall

---

## 1. Login VPS

Login sebagai root:

```bash
ssh root@IP_VPS
```

Contoh:

```bash
ssh root@123.123.123.123
```

---

## 2. Jalankan Auto Installer

Copy dan jalankan perintah berikut:

```bash
apt update -y && apt install -y git && \
git clone https://github.com/mhdisa96/mybot.git /opt/ppob && \
cd /opt/ppob && \
chmod +x scripts/install.sh && \
sudo ./scripts/install.sh
```

Selesai.

Installer akan melanjutkan instalasi secara otomatis.

---

## 3. Data yang Akan Diminta

Saat installer berjalan, Anda akan diminta mengisi:

```text
Domain
Nama Admin
Username Admin
Nomor WhatsApp Admin
Password Admin
Password Database PostgreSQL
Digiflazz Username
Digiflazz API Key
Digiflazz Webhook Secret
```

Contoh:

```text
Domain:
panel.domain.com

Nama Admin:
Administrator

Username Admin:
admin

Nomor WhatsApp:
628123456789
```

Untuk Digiflazz, boleh dikosongkan terlebih dahulu jika belum tersedia.

---

## 4. Setelah Installer Selesai

Cek PM2:

```bash
pm2 status
```

Cek Backend:

```bash
curl http://127.0.0.1:3000/health
```

Cek log Backend:

```bash
pm2 logs ppob-api
```

Cek log WhatsApp Bot:

```bash
pm2 logs ppob-bot
```

---

## 5. Akses Website

Jika DNS domain sudah diarahkan ke VPS:

```text
http://panel.domain.com
```

API:

```text
http://panel.domain.com/api
```

---

## 6. Pasang HTTPS

Setelah domain sudah aktif:

```bash
apt install -y certbot python3-certbot-nginx
```

Kemudian:

```bash
certbot --nginx \
-d panel.domain.com
```

Ikuti proses Certbot sampai selesai.

Setelah itu akses:

```text
https://panel.domain.com
```

---

## 7. Login Admin

Gunakan username dan password yang dibuat saat proses instalasi:

```text
Username:
admin

Password:
password yang Anda masukkan saat install
```

---

## 8. WhatsApp Bot

Lihat log:

```bash
pm2 logs ppob-bot
```

Ikuti proses pairing WhatsApp yang ditampilkan oleh bot.

Setelah berhasil:

```bash
pm2 status
```

Bot harus berada pada status:

```text
online
```

---

## 9. Update dari GitHub

Jika ada perubahan source code:

```bash
cd /opt/ppob
git pull origin main
```

Kemudian:

```bash
npm install
```

Build Admin:

```bash
cd admin
npm install
npm run build
```

Kembali:

```bash
cd /opt/ppob
```

Restart:

```bash
pm2 restart all
```

---

## 10. Restart VPS

Setelah VPS reboot:

```bash
pm2 status
```

Backend dan Bot seharusnya otomatis aktif kembali.

---

## 11. Perintah Penting

### Status

```bash
pm2 status
```

### Log semua service

```bash
pm2 logs
```

### Log API

```bash
pm2 logs ppob-api
```

### Log Bot

```bash
pm2 logs ppob-bot
```

### Restart semua

```bash
pm2 restart all
```

### Stop semua

```bash
pm2 stop all
```

### Start semua

```bash
pm2 start ecosystem.config.cjs
```

---

## 12. Lokasi Project

```text
/opt/ppob
```

Backend:

```text
/opt/ppob/backend
```

Bot:

```text
/opt/ppob/bot
```

Admin:

```text
/opt/ppob/admin
```

Database:

```text
PostgreSQL
```

Environment:

```text
/opt/ppob/backend/.env
/opt/ppob/bot/.env
```

---

## 13. Security

Jangan upload file berikut ke GitHub:

```text
.env
password
API Key
JWT Secret
Database Password
WhatsApp Session
Private Key
```

Semua credential production disimpan di VPS.

---

# Auto Install

Untuk instalasi baru, cukup jalankan:

```bash
apt update -y && apt install -y git && \
git clone https://github.com/mhdisa96/mybot.git /opt/ppob && \
cd /opt/ppob && \
chmod +x scripts/install.sh && \
sudo ./scripts/install.sh
```

Repository:

```text
https://github.com/mhdisa96/mybot
```

Setelah installer selesai, VPS sudah memiliki:

```text
Backend API
WhatsApp Bot
Admin Panel
PostgreSQL
Nginx
PM2
```
