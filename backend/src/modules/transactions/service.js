import crypto from 'node:crypto'; import {pool,tx} from '../../config/db.js'; import {mutate} from '../balance/service.js'; import {topup} from '../digiflazz/client.js';
export async function create(userId,productId,destination){
  const refId=crypto.randomUUID();
  const result=await tx(async c=>{
    const p=(await c.query('SELECT * FROM products WHERE id=$1 AND status=\'ACTIVE\' FOR SHARE',[productId])).rows[0]; if(!p) throw Object.assign(new Error('Product not found'),{status:404});
    const u=(await c.query('SELECT balance FROM users WHERE id=$1 FOR UPDATE',[userId])).rows[0]; if(!u) throw Object.assign(new Error('User not found'),{status:404}); if(Number(u.balance)<Number(p.selling_price)) throw Object.assign(new Error('Insufficient balance'),{status:400});
    const t=(await c.query(`INSERT INTO transactions(user_id,product_id,destination,price,cost_price,status,provider,reference,idempotency_key) VALUES($1,$2,$3,$4,$5,'PROCESS','DIGIFLAZZ',$6,$6) RETURNING *`,[userId,productId,destination,p.selling_price,p.cost_price,refId])).rows[0];
    const before=Number(u.balance), after=before-Number(p.selling_price); await c.query('UPDATE users SET balance=$1,updated_at=NOW() WHERE id=$2',[after,userId]);
    await c.query(`INSERT INTO balance_mutations(user_id,type,amount,balance_before,balance_after,reference_type,reference_id,description) VALUES($1,'PURCHASE',$2,$3,$4,'TRANSACTION',$5,$6)`,[userId,-Number(p.selling_price),before,after,t.id,`Purchase ${p.code}`]);
    return {t,p};
  });
  try { const provider=await topup({sku:result.p.digiflazz_sku,customerNo:destination,refId}); await pool.query(`UPDATE transactions SET status=$1,provider_reference=$2,updated_at=NOW() WHERE id=$3`,[provider.data?.status==='Sukses'?'SUCCESS':'PROCESS',provider.data?.tr_id||null,result.t.id]); }
  catch(e){ await pool.query('UPDATE transactions SET status=\'FAILED\',failure_reason=$1,updated_at=NOW() WHERE id=$2',[e.message,result.t.id]); await mutate(userId,Number(result.p.selling_price),'REFUND','TRANSACTION',result.t.id,'Automatic refund after provider failure'); }
  return (await pool.query('SELECT * FROM transactions WHERE id=$1',[result.t.id])).rows[0];
}
export async function get(id){return (await pool.query(`SELECT t.*,p.code product_code,p.name product_name,u.name user_name,u.whatsapp_number FROM transactions t JOIN products p ON p.id=t.product_id JOIN users u ON u.id=t.user_id WHERE t.id=$1`,[id])).rows[0];}
export async function list(){return (await pool.query(`SELECT t.*,p.code product_code,p.name product_name,u.name user_name FROM transactions t JOIN products p ON p.id=t.product_id JOIN users u ON u.id=t.user_id ORDER BY t.created_at DESC LIMIT 500`)).rows;}
