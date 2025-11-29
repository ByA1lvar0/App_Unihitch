# 📧 CONFIGURACIÓN RÁPIDA DE GMAIL PARA VERIFICACIÓN DE EMAIL

## Paso 1: Obtener App Password de Gmail

1. Ve a [https://myaccount.google.com/](https://myaccount.google.com/)
2. Selecciona **Seguridad** en el menú lateral
3. En "Inicio de sesión en Google", activa **Verificación en 2 pasos** (si no está)
4. Después, busca **Contraseñas de aplicaciones**
5. Selecciona app: **Correo**
6. Selecciona dispositivo: **Otro** (escribe "UniHitch Backend")
7. Haz clic en **Generar**
8. Copia la contraseña de 16 caracteres generada

## Paso 2: Configurar en `.env`

Edita `unihitch_backend/.env`:

```env
EMAIL_USER=tu_correo@gmail.com
EMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

**Reemplaza:**
- `tu_correo@gmail.com` → Tu email de Gmail
- `xxxx xxxx xxxx xxxx` → La App Password que copiaste

## Paso 3: Reiniciar Backend

```bash
# Detén el servidor actual (Ctrl+C)
# Luego ejecuta:
cd c:\Users\USUARIO\Downloads\Unitich\App_Unihitch\unihitch_backend
node server.js
```

## Paso 4: Agregar Endpoints al server.js

Copia el contenido de `email_verification_endpoints.js` y pégalo en `server.js` después de la línea que dice:

```javascript
// ==================== RUTAS DE NOTIFICACIONES ====================
```

¡Listo! 🎉 Los emails de verificación funcionarán.

## ⚠️ Problemas Comunes

**Error: "Invalid login"**
- Verifica que la App Password esté correcta
- Asegúrate que la verificación en 2 pasos esté activada

**No llegan los emails**
- Revisa carpeta de Spam
- Verifica que el EMAIL_USER sea correcto
