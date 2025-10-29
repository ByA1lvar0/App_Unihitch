# 📋 INSTRUCCIONES PARA CONFIGURAR LA BASE DE DATOS

## 🗄️ Base de Datos: PostgreSQL

### Pasos para configurar la base de datos:

#### 1. **Instalar PostgreSQL**
Si no lo tienes instalado, descarga PostgreSQL desde:
https://www.postgresql.org/download/

#### 2. **Crear la base de datos**
Abre la terminal/CMD y ejecuta:
```bash
psql -U postgres
```

Luego ejecuta:
```sql
CREATE DATABASE unihitch_db;
\q
```

#### 3. **Ejecutar el script SQL**
```bash
psql -U postgres -d unihitch_db -f database_setup.sql
```

#### 4. **Configurar el archivo .env**
Crea o edita el archivo `.env` en la carpeta `unihitch_backend`:

```env
# Base de Datos
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=tu_contraseña_aqui
DB_NAME=unihitch_db

# JWT
JWT_SECRET=tu_secret_key_muy_seguro_aqui_cambiar_esto

# Puerto del servidor
PORT=3000
```

**⚠️ IMPORTANTE:**
- Cambia `DB_PASSWORD` por tu contraseña de PostgreSQL
- Cambia `JWT_SECRET` por una cadena aleatoria segura (ej: openssl rand -base64 32)

#### 5. **Instalar dependencias del backend**
```bash
cd unihitch_backend
npm install
```

#### 6. **Iniciar el servidor**
```bash
npm start
```

---

## 📊 Estructura de Tablas Principales

### **usuario**
- Información de usuarios (conductores y pasajeros)
- Campos: id, nombre, correo, password, telefono, universidad, carrera, etc.

### **viaje**
- Viajes ofrecidos
- Campos: id, conductor, origen, destino, fecha_hora, precio, asientos, estado

### **reserva**
- Reservas de pasajeros en viajes
- Campos: id, id_viaje, id_pasajero, estado, calificación

### **wallet**
- Billeteras virtuales de usuarios
- Campos: id, id_usuario, saldo

### **transaccion**
- Historial de transacciones (recargas, pagos)
- Campos: id, id_usuario, tipo, monto, método_pago

### **notificacion**
- Sistema de notificaciones
- Campos: id, id_usuario, titulo, mensaje, tipo, leida

### **emergencia**
- Alertas de emergencia
- Campos: id, id_usuario, ubicación, contactos notificados

### **chat** y **mensaje**
- Sistema de mensajería
- Chat entre usuarios y mensajes

### **badge**
- Sistema de logros/insignias
- Campos: id, id_usuario, nombre_badge

---

## 🔐 Credenciales de Prueba

Después de ejecutar el script, puedes crear usuarios de prueba:

```sql
-- Usuario ejemplo
INSERT INTO usuario (nombre, correo, password, telefono, id_universidad, carrera) 
VALUES ('Juan Pérez', 'juan@test.com', '$2b$10$hashed_password_aqui', '987654321', 1, 'Ingeniería');
```

---

## ✅ Verificar que todo funciona

1. El servidor debe estar corriendo en `http://localhost:3000`
2. Prueba el endpoint: `http://localhost:3000/api/universidades`
3. Deberías ver una lista de universidades en JSON

---

## 🚀 Siguiente Paso

Ahora ya puedes usar todas las pantallas de la app Flutter:
- ✅ Login y Registro
- ✅ Pantalla Principal (Home)
- ✅ Buscar Viajes
- ✅ Ofrecer Viajes
- ✅ Mi Perfil
- ✅ Mi Wallet
- ✅ Configuración
- ✅ Chat (preparado)
- ✅ Sistema de emergencias (preparado)

¡Todo listo para usar! 🎉

