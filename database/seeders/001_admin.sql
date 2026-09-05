-- Ganti HASH_PASSWORD dengan hasil bcrypt hash sebelum dijalankan.
-- Contoh membuat hash: node -e "console.log(require('bcryptjs').hashSync('GantiPasswordKuat',12))"
INSERT INTO users(name,whatsapp_number,username,password_hash,role,status)
VALUES('Administrator','628000000000','admin','HASH_PASSWORD','SUPER_ADMIN','ACTIVE')
ON CONFLICT (username) DO NOTHING;
