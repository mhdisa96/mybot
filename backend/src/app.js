import express from 'express'; import cors from 'cors'; import helmet from 'helmet'; import rateLimit from 'express-rate-limit'; import {env} from './config/env.js'; import {pool} from './config/db.js'; import {errorHandler} from './middleware/error.js';
import users from './modules/users/routes.js'; import products from './modules/products/routes.js'; import balance from './modules/balance/routes.js'; import transactions from './modules/transactions/routes.js'; import deposits from './modules/deposits/routes.js';
import bot from './modules/bot/routes.js';
import { handleCallback } from './modules/digiflazz/webhook.js';
const app=express(); app.use(helmet()); app.use(cors({origin:env.corsOrigin})); app.use(express.json({limit:'1mb'})); app.use(rateLimit({windowMs:60000,max:120}));
app.post('/api/webhooks/digiflazz',async(req,res,next)=>{try{const r=await handleCallback(req.body,req.headers['x-webhook-signature']);res.json({success:true,data:r});}catch(e){next(e)}}); app.get('/health',async(req,res)=>{await pool.query('SELECT 1');res.json({ok:true,service:'ppob-backend'})}); app.use('/api/users',users); app.use('/api/products',products); app.use('/api/balance',balance); app.use('/api/transactions',transactions); app.use('/api/deposits',deposits); app.use('/api/bot',bot); app.use(errorHandler);
app.listen(env.port,()=>console.log(`Backend listening on ${env.port}`));
