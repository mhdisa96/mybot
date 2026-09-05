# PPOB System

Arsitektur mengikuti spesifikasi: WhatsApp Bot -> Backend Node.js API -> PostgreSQL + Digiflazz, dengan payment service yang dapat ditambahkan kemudian.

## Komponen
- `backend`: Express + PostgreSQL + JWT
- `bot`: WhatsApp bot berbasis Baileys
- `admin`: React + Vite admin panel dark
- `database`: migration dan seeder PostgreSQL
- `nginx`: reverse proxy production

## Prasyarat
- Node.js 20+
- PostgreSQL 15+
- WhatsApp untuk nomor bot

## Setup
1. Salin `backend/.env.example` menjadi `backend/.env`.
2. Isi `DATABASE_URL`, `JWT_SECRET`, dan kredensial Digiflazz.
3. Jalankan migration SQL dari `database/migrations` secara berurutan.
4. Jalankan seeder `database/seeders/001_admin.sql` setelah membuat user admin.
5. Install dependency: `npm run install:all`.
6. Jalankan backend, bot, dan admin.

API default: `http://localhost:3000`
Admin default: `http://localhost:5173`

## Catatan keamanan
Jangan commit API key Digiflazz, password database, JWT secret, atau kredensial admin.
