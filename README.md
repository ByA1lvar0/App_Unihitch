# 🚗 UniHitch - Plataforma de Ridesharing Universitario

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

UniHitch es una plataforma de ridesharing diseñada específicamente para comunidades universitarias, permitiendo a estudiantes y personal compartir viajes de manera segura, económica y sostenible.

## 📋 Tabla de Contenidos

- [Características Principales](#-características-principales)
- [Arquitectura del Sistema](#-arquitectura-del-sistema)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [API Documentation](#-api-documentation)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contribución](#-contribución)
- [Licencia](#-licencia)

## ✨ Características Principales

### Para Usuarios
- 🔐 **Autenticación Segura**: Sistema de registro y login con validación universitaria
- 🚗 **Publicación de Viajes**: Crea y gestiona viajes como conductor
- 🔍 **Búsqueda Inteligente**: Encuentra viajes disponibles según tu ruta
- 💰 **Wallet Integrado**: Sistema de billetera digital con integración Yape/Plin
- ⭐ **Sistema de Calificaciones**: Ratings bidireccionales conductor-pasajero
- 📍 **Tracking en Tiempo Real**: Seguimiento GPS de viajes activos
- 💬 **Chat Integrado**: Comunicación directa entre usuarios
- 🆘 **Botón SOS**: Emergencias con notificación a contactos
- 📊 **Estadísticas**: Dashboard personal con métricas de uso

### Para Administradores
- 📈 **Dashboard Analítico**: Métricas de negocio en tiempo real
- 👥 **Gestión de Usuarios**: Directorio completo con control de acceso
- 🚦 **Verificación**: Aprobación de usuarios y documentos
- 💳 **Gestión Financiera**: Aprobación de recargas y retiros
- 📜 **Historial Completo**: Registro de todos los viajes y transacciones

## 🏗 Arquitectura del Sistema

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└────────┬────────┘
         │ HTTP/REST
         │
┌────────▼────────┐
│  Node.js API    │
│  (Backend)      │
└────────┬────────┘
         │
┌────────▼────────┐
│  PostgreSQL     │
│  (Database)     │
└─────────────────┘
```

### Stack Tecnológico

**Frontend:**
- Flutter 3.0+
- Dart 3.0+
- Google Maps API
- WebSocket para tiempo real

**Backend:**
- Node.js 18+
- Express.js
- JWT Authentication
- bcrypt para encriptación

**Database:**
- PostgreSQL 14+
- Relaciones normalizadas
- Índices optimizados

## 📦 Requisitos Previos

- **Node.js** >= 18.0.0
- **Flutter** >= 3.0.0
- **PostgreSQL** >= 14.0
- **Git**
- Cuenta de Google Cloud (para Maps API)

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/unihitch.git
cd unihitch
```

### 2. Configurar Backend

```bash
cd unihitch_backend
npm install
```

Crear archivo `.env`:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=unihitch_db
DB_USER=postgres
DB_PASSWORD=tu_password
JWT_SECRET=tu_jwt_secret_super_seguro
GOOGLE_MAPS_API_KEY=tu_google_maps_key
```

### 3. Configurar Base de Datos

```bash
# Crear base de datos
psql -U postgres
CREATE DATABASE unihitch_db;
\q

# Ejecutar migraciones
node migrations/init_db.js
```

### 4. Configurar Frontend

```bash
cd ../unihitch_app
flutter pub get
```

Configurar `lib/config/config.dart`:

```dart
class Config {
  static const String apiUrl = 'http://localhost:3000/api';
  static const String googleMapsApiKey = 'TU_GOOGLE_MAPS_KEY';
}
```

## ⚙️ Configuración

### Variables de Entorno (Backend)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `PORT` | Puerto del servidor | Sí |
| `DB_HOST` | Host de PostgreSQL | Sí |
| `DB_PORT` | Puerto de PostgreSQL | Sí |
| `DB_NAME` | Nombre de la base de datos | Sí |
| `DB_USER` | Usuario de PostgreSQL | Sí |
| `DB_PASSWORD` | Contraseña de PostgreSQL | Sí |
| `JWT_SECRET` | Secreto para JWT | Sí |
| `GOOGLE_MAPS_API_KEY` | API Key de Google Maps | Sí |

### Configuración de Google Maps

1. Ir a [Google Cloud Console](https://console.cloud.google.com/)
2. Crear un nuevo proyecto
3. Habilitar APIs:
   - Maps JavaScript API
   - Directions API
   - Geocoding API
4. Crear credenciales (API Key)
5. Configurar restricciones de API Key

## 🎯 Uso

### Iniciar Backend

```bash
cd unihitch_backend
npm start
```

El servidor estará disponible en `http://localhost:3000`

### Iniciar Frontend

```bash
cd unihitch_app

# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Usuarios de Prueba

| Email | Contraseña | Rol |
|-------|-----------|-----|
| `admin@gmail.com` | `123456` | Administrador |
| `test@demo.com` | `123456` | Usuario |
| `sdfsdf435123@gmail.com` | `123456` | Usuario |

## 📚 API Documentation

### Autenticación

#### POST `/api/auth/register`
Registrar nuevo usuario

**Body:**
```json
{
  "nombre": "Juan Pérez",
  "correo": "juan@unp.edu.pe",
  "password": "123456",
  "telefono": "987654321",
  "id_universidad": 1,
  "codigo_universitario": "U12345"
}
```

#### POST `/api/auth/login`
Iniciar sesión

**Body:**
```json
{
  "correo": "juan@unp.edu.pe",
  "password": "123456"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "nombre": "Juan Pérez",
    "correo": "juan@unp.edu.pe",
    "rol": "USER"
  }
}
```

### Viajes

#### GET `/api/viajes`
Obtener viajes disponibles

**Headers:**
```
Authorization: Bearer {token}
```

#### POST `/api/viajes`
Crear nuevo viaje

**Body:**
```json
{
  "origen": "Universidad de Piura",
  "destino": "Real Plaza",
  "fecha_hora": "2024-12-10T14:00:00",
  "asientos_totales": 4,
  "precio": 5.00
}
```

### Wallet

#### GET `/api/wallet`
Obtener información de billetera

#### POST `/api/wallet/recharge`
Solicitar recarga

**Body:**
```json
{
  "monto": 50.00,
  "metodo_pago": "YAPE",
  "comprobante_url": "https://..."
}
```

## 📁 Estructura del Proyecto

```
unihitch/
├── unihitch_backend/
│   ├── config/
│   │   └── db.js                 # Configuración PostgreSQL
│   ├── controllers/
│   │   ├── auth.controller.js    # Lógica de autenticación
│   │   ├── trip.controller.js    # Lógica de viajes
│   │   ├── wallet.controller.js  # Lógica de billetera
│   │   └── admin.controller.js   # Lógica administrativa
│   ├── middleware/
│   │   ├── auth.middleware.js    # Validación JWT
│   │   └── driver-validation.js  # Validación documentos
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── trip.routes.js
│   │   ├── wallet.routes.js
│   │   └── admin.routes.js
│   ├── validators/
│   │   └── trip.validator.js     # Validaciones
│   ├── .env                      # Variables de entorno
│   ├── server.js                 # Punto de entrada
│   └── package.json
│
└── unihitch_app/
    ├── lib/
    │   ├── config/
    │   │   └── config.dart       # Configuración app
    │   ├── models/
    │   │   ├── user.dart
    │   │   ├── trip.dart
    │   │   └── wallet.dart
    │   ├── screens/
    │   │   ├── login_screen.dart
    │   │   ├── home_screen.dart
    │   │   ├── trip_tracking_screen.dart
    │   │   ├── wallet_screen.dart
    │   │   └── admin_screen.dart
    │   ├── services/
    │   │   └── api_service.dart  # Cliente HTTP
    │   ├── widgets/
    │   │   └── custom_widgets.dart
    │   └── main.dart             # Punto de entrada
    ├── pubspec.yaml
    └── README.md
```

## 🧪 Testing

### Backend Tests

```bash
cd unihitch_backend
npm test
```

### Frontend Tests

```bash
cd unihitch_app
flutter test
```

## 🚢 Deployment

### Backend (Heroku)

```bash
heroku create unihitch-api
heroku addons:create heroku-postgresql:hobby-dev
git push heroku main
```

### Frontend (Firebase Hosting)

```bash
flutter build web
firebase deploy
```

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Convenciones de Código

- **Backend**: ESLint + Prettier
- **Frontend**: Dart Analysis + Flutter Lints
- Commits en español
- Mensajes descriptivos

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 👥 Autores

- **Equipo UniHitch** - *Desarrollo Inicial*

## 🙏 Agradecimientos

- Universidad de Piura
- Comunidad Flutter
- Comunidad Node.js

## 📞 Soporte

Para soporte, email: soporte@unihitch.com o únete a nuestro Slack.

---

**Hecho con ❤️ por el equipo UniHitch**
