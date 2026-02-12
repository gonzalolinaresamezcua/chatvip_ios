# Chat Móvil - Servidor Centro de Mensajes

Aplicaciones de chat estilo WhatsApp para **Android** e **iPhone**. **Sin WebRTC** - los mensajes pasan por el servidor, que los almacena encriptados y los redirige.

## Características

- **Chat por número de teléfono**: Identificación con +34686522038, +34610957099, etc.
- **Servidor centro de mensajes**: Recibe, almacena encriptados y redirige mensajes
- **Interfaz tipo WhatsApp**: Burbujas verdes (tuyos) y grises (del otro)
- **Sin WebRTC**: Solo WebSocket - funciona en todos los Android

## Requisitos

1. **Servidor de mensajes**: Incluido en `signaling-server/`
2. **Dos dispositivos** (Android o iPhone) con la app instalada

## Compilación

### Android
```powershell
$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
.\gradlew assembleDebug
```
APK en: `app\build\outputs\apk\debug\app-debug.apk`

### iPhone
Requiere **macOS** con Xcode. Ver `ios/README.md` para instrucciones detalladas.

## Uso

### 1. Arrancar el servidor

```bash
cd signaling-server
npm install
node server.js
```

### 2. Instalar la APK en cada móvil

### 3. Configurar cada móvil

- Número de teléfono (ej: +34686522038)
- URL del servidor: `ws://IP_SERVIDOR:9090`

### 4. Chatear

Pulsa "+" e introduce el número del contacto. Los mensajes se envían y reciben a través del servidor.

## Arquitectura

```
[Móvil A] ----WebSocket----> [Servidor] <----WebSocket---- [Móvil B]
                \                    /
                 \  Almacena        /
                  \ encriptado     /
                   \______________/
```

El servidor recibe mensajes, los cifra, los guarda y los envía al destinatario (o los pone en cola si está desconectado).
