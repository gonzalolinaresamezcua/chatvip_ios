/**
 * Servidor de reenvío de mensajes (sin almacenamiento)
 * Solo recibe y redirige mensajes. Las conversaciones se guardan
 * en cada teléfono en archivos encriptados.
 *
 * Ejecutar: node server.js
 * Puerto por defecto: 9090
 *
 * Ejemplo: ws://0.0.0.0:9090
 */

const WebSocket = require('ws');
const http = require('http');

const PORT = process.env.PORT || 9090;

const peers = new Map();
const pendingMessages = new Map();

const server = http.createServer();
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws, req) => {
  let myPhone = null;

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString());
      console.log('Mensaje:', msg.type, msg.from || '');

      switch (msg.type) {
        case 'register':
          myPhone = msg.phoneNumber;
          if (myPhone) {
            peers.set(myPhone, ws);
            ws.send(JSON.stringify({ type: 'registered', phoneNumber: myPhone }));

            const pending = pendingMessages.get(myPhone);
            if (pending && pending.length > 0) {
              pending.forEach(m => ws.send(JSON.stringify(m)));
              pendingMessages.delete(myPhone);
            }
          }
          break;

        case 'message': {
          const { to, content, contentType } = msg;
          if (!myPhone || !to || content === undefined) {
            ws.send(JSON.stringify({ type: 'error', code: 'invalid', msg: 'Faltan campos' }));
            break;
          }

          const id = 'msg_' + Date.now() + '_' + Math.random().toString(36).slice(2);
          const timestamp = new Date().toISOString();
          const payload = {
            type: 'message',
            id,
            from: myPhone,
            to,
            content,
            contentType: contentType || 'text',
            timestamp
          };

          const destWs = peers.get(to);
          if (destWs && destWs.readyState === WebSocket.OPEN) {
            destWs.send(JSON.stringify(payload));
          } else {
            if (!pendingMessages.has(to)) pendingMessages.set(to, []);
            pendingMessages.get(to).push(payload);
          }

          ws.send(JSON.stringify({ type: 'ack', id, timestamp }));
          break;
        }

        case 'sync':
          ws.send(JSON.stringify({ type: 'sync_done', count: 0 }));
          break;

        case 'conversations':
          ws.send(JSON.stringify({ type: 'conversations', list: [] }));
          break;

        default:
          ws.send(JSON.stringify({ type: 'error', code: 'unknown', msg: 'Tipo desconocido' }));
      }
    } catch (e) {
      console.error('Error:', e);
      ws.send(JSON.stringify({ type: 'error', code: 'parse', msg: 'Mensaje inválido' }));
    }
  });

  ws.on('close', () => {
    if (myPhone) {
      peers.delete(myPhone);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor ChatVIP en ws://0.0.0.0:${PORT}`);
  console.log('Solo reenvío - sin almacenamiento');
});
