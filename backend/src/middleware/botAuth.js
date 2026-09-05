import crypto from 'node:crypto';
import { pool } from '../config/db.js';
export function botAuth(req,res,next){
  const configured=process.env.BOT_API_KEY||''; const provided=String(req.headers['x-bot-api-key']||'');
  if(!configured || !provided || configured.length!==provided.length || !crypto.timingSafeEqual(Buffer.from(configured),Buffer.from(provided))) return res.status(401).json({success:false,message:'Unauthorized bot'});
  next();
}
export async function findUserByWhatsapp(number){return (await pool.query("SELECT id,name,whatsapp_number,balance,role,status FROM users WHERE whatsapp_number=$1",[number])).rows[0];}
