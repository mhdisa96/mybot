import { register, login, list, get } from './service.js';
import { ok } from '../../utils/http.js';
export const registerUser=async(req,res)=>ok(res,await register(req.body),201);
export const loginUser=async(req,res)=>ok(res,await login(req.body.identifier,req.body.password));
export const listUsers=async(req,res)=>ok(res,await list(req.query));
export const getUser=async(req,res)=>{ const u=await get(req.params.id); if(!u)return res.status(404).json({success:false,message:'User not found'}); ok(res,u); };
