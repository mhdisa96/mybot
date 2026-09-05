import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';
import { pool, tx } from '../../config/db.js';

export async function register({name,whatsappNumber,username,password}){
  const hash=password?await bcrypt.hash(password,12):null;
  const {rows}=await pool.query(`INSERT INTO users(name,whatsapp_number,username,password_hash) VALUES($1,$2,$3,$4) RETURNING id,name,whatsapp_number,username,balance,role,status,registered_at,last_activity_at`,[name,whatsappNumber,username||null,hash]);
  return rows[0];
}
export async function login(identifier,password){
  const {rows}=await pool.query(`SELECT * FROM users WHERE (username=$1 OR whatsapp_number=$1) AND status='ACTIVE' LIMIT 1`,[identifier]);
  const u=rows[0]; if(!u || !u.password_hash || !(await bcrypt.compare(password,u.password_hash))) throw Object.assign(new Error('Invalid credentials'),{status:401});
  await pool.query('UPDATE users SET last_activity_at=NOW() WHERE id=$1',[u.id]);
  const token=jwt.sign({id:u.id,role:u.role,name:u.name},env.jwtSecret,{expiresIn:'12h'});
  delete u.password_hash; return {user:u,token};
}
export async function list({q='',limit=50,offset=0}){ const {rows}=await pool.query(`SELECT id,name,whatsapp_number,username,balance,role,status,registered_at,last_activity_at FROM users WHERE ($1='' OR name ILIKE '%'||$1||'%' OR whatsapp_number ILIKE '%'||$1||'%') ORDER BY created_at DESC LIMIT $2 OFFSET $3`,[q,limit,offset]); return rows; }
export async function get(id){ const {rows}=await pool.query('SELECT id,name,whatsapp_number,username,balance,role,status,registered_at,last_activity_at FROM users WHERE id=$1',[id]); return rows[0]; }
