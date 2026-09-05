import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
export function auth(req,res,next){
  const h=req.headers.authorization||''; if(!h.startsWith('Bearer ')) return res.status(401).json({success:false,message:'Unauthorized'});
  try { req.user=jwt.verify(h.slice(7),env.jwtSecret); next(); } catch { return res.status(401).json({success:false,message:'Invalid token'}); }
}
export const roles = (...allowed) => (req,res,next) => allowed.includes(req.user.role) ? next() : res.status(403).json({success:false,message:'Forbidden'});
