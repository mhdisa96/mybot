import { api } from '../services/api.js';
import { mainMenu } from '../menus/main.js';
const sessions=new Map();
function waNumber(jid){return jid.split('@')[0].replace(/[^0-9]/g,'');}
export async function handleMessage(sock,msg){
  const jid=msg.key.remoteJid; if(!jid||msg.key.fromMe)return;
  const text=(msg.message?.conversation||msg.message?.extendedTextMessage?.text||'').trim(); if(!text)return;
  const number=waNumber(jid); const name=msg.pushName||'Member';
  let user=null;
  try{ user=(await api.post('/api/bot/users/register',{name,whatsappNumber:number})).data.data; }catch(_){ }
  if(text.toLowerCase()==='.menu'||text.toLowerCase()==='menu'||text==='0')return sock.sendMessage(jid,{text:mainMenu});
  if(text==='1'){
    if(!user) user=await api.get(`/api/bot/users/${number}`).then(r=>r.data.data).catch(()=>null);
    if(!user) return sock.sendMessage(jid,{text:'Akun belum dapat didaftarkan.'});
    return sock.sendMessage(jid,{text:`Saldo Anda: Rp${Number(user.balance||0).toLocaleString('id-ID')}`});
  }
  if(text==='2'){
    const products=(await api.get('/api/bot/products')).data.data;
    const body=products.slice(0,30).map((p,i)=>`${i+1}. ${p.name} - Rp${Number(p.selling_price).toLocaleString('id-ID')} (${p.code})`).join('\n');
    return sock.sendMessage(jid,{text:`DAFTAR PRODUK\n\n${body||'Belum ada produk.'}`});
  }
  if(text==='6')return sock.sendMessage(jid,{text:'Deposit saat ini diproses manual. Silakan hubungi admin untuk verifikasi deposit.'});
  if(/^deposit\s+/i.test(text)){
    const amount=Number(text.split(/\s+/)[1]); if(!amount)return sock.sendMessage(jid,{text:'Nominal deposit tidak valid.'});
    try{await api.post('/api/deposits',{amount,method:'MANUAL'});return sock.sendMessage(jid,{text:`Request deposit Rp${amount.toLocaleString('id-ID')} sudah dibuat. Tunggu verifikasi admin.`})}catch(e){return sock.sendMessage(jid,{text:'Gagal membuat request deposit.'})}
  }
  if(text==='7')return sock.sendMessage(jid,{text:'Bantuan: ketik MENU untuk melihat menu utama.'});
  if(/^beli\s+/i.test(text)){
    const [,code,destination]=text.split(/\s+/); const products=(await api.get('/api/bot/products')).data.data; const p=products.find(x=>x.code===code); if(!p)return sock.sendMessage(jid,{text:'Kode produk tidak ditemukan.'});
    try{
      const r=await api.post('/api/bot/transactions',{whatsappNumber:number,productId:p.id,destination}); return sock.sendMessage(jid,{text:`Transaksi dibuat: ${r.data.data.reference}\nStatus: ${r.data.data.status}`});
    }catch(e){return sock.sendMessage(jid,{text:e.response?.data?.message||'Transaksi gagal.'})}
  }
  return sock.sendMessage(jid,{text:'Perintah tidak dikenal. Ketik MENU.'});
}
