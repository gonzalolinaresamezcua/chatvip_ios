# Servidor Centro de Mensajes - ChatP2

Servidor WebSocket que actúa como **centro de mensajes**: recibe, almacena (encriptados) y redirige mensajes entre los teléfonos. **Sin WebRTC** - compatible con todas las versiones de Android.

## Arquitectura

- **Servidor**: centro único de mensajes
- **Clientes**: envían y reciben vía WebSocket
- **Almacenamiento**: mensajes cifrados en disco (messages.json)
- **Sin WebRTC**: solo WebSocket, funciona en todos los Android

## Protocolo WebSocket (JSON)

### 1. Registrarse
```json
{ "type": "register", "phoneNumber": "+34612345678" }
```
Respuesta: `{ "type": "registered", "phoneNumber": "+34612345678" }`

### 2. Enviar mensaje
```json
{ "type": "message", "to": "+34698765432", "content": "Hola, ¿qué tal?" }
```
Respuesta: `{ "type": "ack", "id": "msg_...", "timestamp": "..." }`

### 3. Recibir mensaje (push)
```json
{ "type": "message", "id": "msg_...", "from": "+34698765432", "to": "...", "content": "Respuesta", "timestamp": "..." }
```

### 4. Sincronizar conversaciones
```json
{ "type": "sync", "since": "2025-02-01T00:00:00.000Z" }
```
El servidor envía todos los mensajes desde esa fecha. Sin `since` = todos.

### 5. Listar conversaciones
```json
{ "type": "conversations" }
```
Respuesta: `{ "type": "conversations", "list": ["+34...", "+34..."] }`

## Instalación

```bash
cd signaling-server
npm install
```

## Ejecutar

```bash
node server.js
```

Por defecto escucha en el puerto **9090**.

## Variables de entorno

- `PORT`: puerto (default 9090)
- `ENCRYPTION_KEY`: clave de 32 caracteres para cifrar mensajes (cambiar en producción)

## Configuración en la app Android

- **Emulador**: `ws://10.0.2.2:9090`
- **Móvil misma WiFi**: `ws://IP_SERVIDOR:9090`
- **Internet**: `wss://tudominio.com` (necesita proxy/SSL)
