# Chat VIP - Versión iPhone

Aplicación de chat P2P para iPhone, equivalente a la versión Android. Compatible con el mismo servidor WebSocket (`signaling-server`).

## Requisitos

- **macOS** con Xcode 15 o superior
- iPhone con iOS 15+
- Cuenta de desarrollador Apple (para instalar en dispositivo físico)

## Cómo compilar

### Opción 1: Desde Xcode (recomendado)

1. Abre `ChatVIP.xcodeproj` en Xcode
2. Selecciona tu equipo de desarrollo: **Signing & Capabilities** → Team
3. Conecta tu iPhone o selecciona un simulador
4. Pulsa **Run** (⌘R)

### Opción 2: Línea de comandos (macOS)

```bash
cd ios
xcodebuild -project ChatVIP.xcodeproj -scheme ChatVIP -sdk iphoneos -configuration Release
```

El `.app` generado estará en `build/Release-iphoneos/ChatVIP.app`.

### Opción 3: GitHub Actions (sin Mac)

Si subes el proyecto a GitHub, puedes usar el workflow en `.github/workflows/build-ios.yml` para compilar en la nube. El IPA se generará como artefacto.

## Uso

1. **Arranca el servidor** (en tu PC o servidor):
   ```bash
   cd signaling-server
   npm install
   node server.js
   ```

2. **Configura la app** en el iPhone:
   - Número de teléfono (ej: +34686522038)
   - URL del servidor: `ws://IP_SERVIDOR:9090`  
     (Si el servidor está en tu Mac: `ws://IP_DE_TU_MAC:9090`)

3. **Añade contactos** y chatea.

## Estructura

```
ios/
├── ChatVIP.xcodeproj/    # Proyecto Xcode
├── ChatVIP/              # Código fuente Swift
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   └── Views/
└── README.md
```

## Nota sobre Windows

Las apps iOS **solo pueden compilarse en macOS** con Xcode. Si tienes un PC Windows:

- Usa un Mac para compilar (físico, Mac en la nube, o GitHub Actions)
- O usa el mismo servidor con la app Android en tus dispositivos Android
