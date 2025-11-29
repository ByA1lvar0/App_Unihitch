# UniHitch

Aplicación de carpooling para estudiantes universitarios.

## Descripción

UniHitch es una aplicación móvil desarrollada en Flutter que conecta a estudiantes de universidades para compartir viajes de manera segura y económica.

## Características

- 🔐 Autenticación de usuarios (Registro y Login)
- 🚗 Publicar y buscar viajes
- 📍 Ver viajes disponibles cerca de tu ubicación
- 💺 Sistema de reservas de asientos
- ⭐ Calificaciones de conductores
- 💬 Chat en tiempo real (próximamente)
- 👥 Gestión de perfil de usuario

## Tecnologías

- **Frontend**: Flutter
- **Backend**: Node.js + Express
- **Base de Datos**: PostgreSQL
- **Autenticación**: JWT (JSON Web Tokens)

## Configuración

1. Clonar el repositorio
2. Instalar dependencias:
   ```bash
   flutter pub get
   ```
3. Configurar la URL del backend en `lib/config.dart`
4. Ejecutar la aplicación:
   ```bash
   flutter run
   ```

## Estructura del Proyecto

```
lib/
├── config.dart          # Configuración de la app
├── main.dart            # Punto de entrada
├── screens/             # Pantallas de la app
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── create_trip_screen.dart
│   └── my_trips_screen.dart
└── services/            # Servicios API
    └── api_service.dart
```

## Estado del Proyecto

✅ Login y Registro
✅ Pantalla Principal con diseño moderno
✅ Crear y listar viajes
✅ Sistema de reservas
🚧 Chat entre usuarios
🚧 Notificaciones push
🚧 Mapa con ubicación en tiempo real

## Licencia

MIT
