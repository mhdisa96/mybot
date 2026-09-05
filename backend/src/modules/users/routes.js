import { Router } from 'express'; import { z } from 'zod'; import { validate } from '../../middleware/validate.js'; import { auth, roles } from '../../middleware/auth.js'; import * as c from './controller.js';
const r=Router();
r.post('/register',validate(z.object({name:z.string().min(2),whatsappNumber:z.string().min(8),username:z.string().min(3).optional(),password:z.string().min(8).optional()})),c.registerUser);
r.post('/login',validate(z.object({identifier:z.string().min(3),password:z.string().min(8)})),c.loginUser);
r.get('/',auth,roles('SUPER_ADMIN','ADMIN'),c.listUsers); r.get('/:id',auth,roles('SUPER_ADMIN','ADMIN'),c.getUser);
export default r;
