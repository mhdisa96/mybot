import makeWASocket,{useMultiFileAuthState,DisconnectReason} from '@whiskeysockets/baileys';
import P from 'pino'; import {handleMessage} from './handlers/message.js';
async function start(){
 const {state,saveCreds}=await useMultiFileAuthState('./auth_info_baileys');
 const sock=makeWASocket({auth:state,logger:P({level:'silent'}),printQRInTerminal:true});
 sock.ev.on('creds.update',saveCreds); sock.ev.on('messages.upsert',async({messages})=>{for(const m of messages)await handleMessage(sock,m)});
 sock.ev.on('connection.update',({connection,lastDisconnect})=>{if(connection==='close'){const retry=lastDisconnect?.error?.output?.statusCode!==DisconnectReason.loggedOut; if(retry)start(); else console.log('Logged out')}})
}
start();
