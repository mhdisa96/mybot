import crypto from 'node:crypto';
import { env } from '../../config/env.js';
import { pool, tx } from '../../config/db.js';
import { mutate } from '../balance/service.js';

export async function handleCallback(payload, signature){
  if(env.digiflazz.webhookSecret){
    const expected=crypto.createHmac('sha256',env.digiflazz.webhookSecret).update(JSON.stringify(payload)).digest('hex');
    if(!signature || !crypto.timingSafeEqual(Buffer.from(expected),Buffer.from(signature))) throw Object.assign(new Error('Invalid webhook signature'),{status:401});
  }
  const eventId=payload.event_id || payload.data?.event_id || payload.data?.ref_id || payload.ref_id;
  if(!eventId) throw Object.assign(new Error('Missing event id'),{status:400});
  const inserted=await pool.query(`INSERT INTO webhook_events(provider,event_id,reference,payload) VALUES('DIGIFLAZZ',$1,$2,$3) ON CONFLICT(event_id) DO NOTHING RETURNING id`,[eventId,payload.data?.ref_id||payload.ref_id||null,payload]);
  if(!inserted.rowCount) return {duplicate:true};
  const d=payload.data||payload; const ref=d.ref_id; const status=String(d.status||'').toUpperCase();
  const terminal=status.includes('SUKSES')||status.includes('SUCCESS')||status.includes('GAGAL')||status.includes('FAILED');
  if(ref && terminal){ await tx(async c=>{
      const t=(await c.query('SELECT * FROM transactions WHERE reference=$1 FOR UPDATE',[ref])).rows[0]; if(!t)return;
      if(['SUCCESS','REFUNDED'].includes(t.status))return;
      let newStatus='PROCESS'; let serial=d.sn||d.serial_number||null;
      if(status.includes('SUKSES')||status.includes('SUCCESS')) newStatus='SUCCESS';
      else if(status.includes('GAGAL')||status.includes('FAILED')) newStatus='FAILED';
      await c.query('UPDATE transactions SET status=$1,provider_reference=$2,serial_number=$3,completed_at=CASE WHEN $1 IN (\'SUCCESS\',\'FAILED\') THEN NOW() ELSE completed_at END,updated_at=NOW() WHERE id=$4',[newStatus,d.tr_id||d.provider_reference||null,serial,t.id]);
      await c.query(`INSERT INTO transaction_status_logs(transaction_id,old_status,new_status,message) VALUES($1,$2,$3,$4)`,[t.id,t.status,newStatus,'Digiflazz callback']);
    });
    if(status.includes('GAGAL')||status.includes('FAILED')){
      const t=(await pool.query('SELECT * FROM transactions WHERE reference=$1',[ref])).rows[0];
      if(t && t.status==='FAILED'){
        const m=await pool.query(`SELECT id FROM balance_mutations WHERE reference_type='TRANSACTION' AND reference_id=$1 AND type='REFUND' LIMIT 1`,[t.id]);
        if(!m.rowCount) { await mutate(t.user_id,Number(t.price),'REFUND','TRANSACTION',t.id,'Digiflazz callback refund'); await pool.query('UPDATE transactions SET status=\'REFUNDED\',updated_at=NOW() WHERE id=$1',[t.id]); }
      }
    }
  }
  await pool.query('UPDATE webhook_events SET processed=true,processed_at=NOW() WHERE event_id=$1',[eventId]);
  return {duplicate:false,processed:true};
}
