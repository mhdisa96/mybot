import axios from 'axios';
export const api=axios.create({baseURL:process.env.BACKEND_URL||'http://localhost:3000',headers:{'x-bot-api-key':process.env.BOT_API_KEY||''}});
export async function registerOrGet(name,number){return (await api.post('/api/bot/users/register',{name,whatsappNumber:number})).data.data}
