import * as s from './service.js'; import {ok} from '../../utils/http.js'; export const history=async(req,res)=>ok(res,await s.history(req.params.userId));
export const adminMutate=async(req,res)=>ok(res,await s.mutate(req.params.userId,req.body.amount,req.body.type,'ADMIN',null,req.body.description||null,req.user.id));
