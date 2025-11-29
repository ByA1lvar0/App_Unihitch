# 🗺️ Trip Tracking con Ubicación en Tiempo Real - UniHitch

## 📋 Resumen

Se ha implementado un sistema completo de tracking de viajes con mapa en tiempo real que permite a los conductores ver la ubicación de todos sus pasajeros durante un viaje activo, además de un botón de emergencia para contacto rápido.

## ✨ Características Implementadas

### Para Conductores:
- ✅ Ver mapa con ubicación de todos los pasajeros
- ✅ Marcadores diferenciados (azul = conductor, verde = pasajeros)
- ✅ Actualización automática de ubicaciones cada 10 segundos
- ✅ Panel con lista de pasajeros y estado de conexión
- ✅ Botón "Mi Ubicación" para centrar el mapa
- ✅ Botón de emergencia flotante

### Para Todos los Usuarios:
- ✅ Configuración de número de emergencia personal
- ✅ Tracking automático de ubicación durante viajes
- ✅ Indicador de estado de conexión

## 🚀 Pasos para Completar la Instalación

### 1. Migrar la Base de Datos

```bash
cd c:\Users\USUARIO\Downloads\Unitich\App_Unihitch\unihitch_backend
node run_location_migration.js
```

Esto agregará:
- Columnas de ubicación a la tabla `usuario`
- Columna `numero_emergencia`
- Tabla `ubicacion_viaje` para tracking

### 2. Obtener Google Maps API Key

> [!IMPORTANT]
> **REQUERIDO** para que el mapa funcione

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto o usa uno existente
3. Habilita estas APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (si usarás iOS)
4. Ve a Credenciales → Crear Credenciales → API Key
5. Copia la API Key generada

### 3. Configurar Android

Edita `unihitch_app/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    
    <!-- AGREGAR ANTES DEL CIERRE DE </application> -->
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="TU_API_KEY_AQUI"/>
      
  </application>
  
  <!-- AGREGAR ANTES DEL CIERRE DE </manifest> -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  
</manifest>
```

### 4. Instalar Dependencias Flutter

```bash
cd c:\Users\USUARIO\Downloads\Unitich\App_Unihitch\unihitch_app
flutter pub get
flutter pub upgrade
```

### 5. Ejecutar la Aplicación

```bash
# Asegúrate de que el backend esté corriendo
cd c:\Users\USUARIO\Downloads\Unitich\App_Unihitch\unihitch_backend
node server.js

# En otra terminal, ejecuta Flutter
cd c:\Users\USUARIO\Downloads\Unitich\App_Unihitch\unihitch_app
flutter run
```

## 📖 Cómo Usar

### Configurar Número de Emergencia:
1. Inicia sesión
2. Ve a **Configuración** (ícono de engranaje)
3. Toca **"Número de Emergencia"**
4. Ingresa tu número (ej: 911 o +51 999 999 999)
5. Guarda

### Ver Mapa en Tiempo Real (Como Conductor):
1. Crea un viaje
2. Espera a que pasajeros reserven
3. Ve a **Mis Viajes** → Tab **"Como Conductor"**
4. Toca el botón **"Ver Mapa"** en tu viaje activo
5. ¡El mapa se abrirá mostrando tu ubicación y la de tus pasajeros!

### Usar Botón de Emergencia:
1. Dentro del mapa, presiona el botón rojo en la esquina inferior derecha
2. Se mostrará tu número de emergencia configurado
3. Presiona "Llamar" para marcar (funcionalidad próximamente)

## 📁 Archivos Modificados/Creados

### Backend:
- `location_tracking_migration.sql` - Nueva migración
- `run_location_migration.js` - Script para ejecutar migración
- `server.js` - 5 endpoints nuevos agregados

### Frontend:
- `pubspec.yaml` - Dependencias agregadas
- `lib/services/api_service.dart` - 5 métodos nuevos
- `lib/services/location_service.dart` - Stream de ubicación
- `lib/screens/trip_tracking_screen.dart` - **NUEVA** pantalla principal
- `lib/screens/my_trips_screen.dart` - Botón "Ver Mapa" agregado
- `lib/screens/settings_screen.dart` - Configuración de emergencia

## 🔧 Solución de Problemas

### El mapa no se muestra (pantalla en blanco):
**Causa:** API Key no configurada  
**Solución:** Verifica el paso 3 arriba

### "Ubicación no disponible":
**Causa:** Permisos no otorgados  
**Solución:** Ve a configuración del teléfono → Apps → UniHitch → Permisos → Ubicación → Permitir

### Los pasajeros no aparecen:
**Causa:** Los pasajeros necesitan abrir la app  
**Solución:** Pide a los pasajeros que abran la app para que compartan su ubicación

### Error de migración:
**Causa:** Base de datos no accesible  
**Solución:** Verifica que PostgreSQL esté corriendo y las credenciales en `.env`

## 🎯 Próximas Mejoras Sugeridas

- [ ] Implementar llamada real con `url_launcher`
- [ ] Agregar ruta sugerida en el mapa
- [ ] Notificaciones cuando todos los pasajeros estén listos
- [ ] Chat en tiempo real dentro del mapa
- [ ] Compartir ubicación por WhatsApp

## 📚 Documentación Completa

Ver [walkthrough.md](file:///C:/Users/USUARIO/.gemini/antigravity/brain/bd58747e-1059-4023-809c-3ff3157d98bf/walkthrough.md) para documentación técnica detallada.

---

**¡Listo!** 🎉 Ahora los conductores pueden ver las ubicaciones de sus pasajeros en tiempo real y tener acceso rápido a emergencias.
