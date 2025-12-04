# Panel de Monitoreo de Rutas con Leaflet - UniHitch

## 📋 Descripción

Sistema de monitoreo de viajes en tiempo real usando Leaflet.js (OpenStreetMap). Este panel web permite visualizar rutas de viajes, ubicaciones de conductores y pasajeros, y monitorear el estado de los viajes activos.

## ✨ Características

- 🗺️ **Mapa interactivo** con Leaflet y OpenStreetMap (sin necesidad de API keys)
- 🛣️ **Visualización de rutas** calculadas automáticamente entre origen y destino
- 📍 **Marcadores en tiempo real** para conductores y pasajeros
- 🔄 **Actualización automática** cada 10 segundos
- 🎯 **Filtros** por estado de viaje (Disponible, En Curso)
- 📊 **Panel de información** detallada de cada viaje
- 📏 **Cálculo de distancia y duración** de rutas

## 🚀 Instalación

### 1. Instalar dependencias

```bash
cd unihitch_backend
npm install axios
```

### 2. Ejecutar migración de base de datos

```bash
node create_rutas_table.js
```

Esto creará la tabla `rutas` en tu base de datos PostgreSQL.

### 3. Iniciar el servidor

```bash
node server.js
```

El servidor estará corriendo en `http://localhost:3000`

## 📖 Uso

### Acceder al Panel Web

Abre tu navegador y ve a:

```
http://localhost:3000/trip-monitor.html
```

### API Endpoints

#### Obtener ruta de un viaje
```
GET /api/routes/:tripId
```

#### Crear/actualizar ruta
```
POST /api/routes
Body: {
  "id_viaje": 1,
  "origen": { "lat": 4.7110, "lng": -74.0721 },
  "destino": { "lat": 4.6097, "lng": -74.0817 }
}
```

#### Obtener rutas activas
```
GET /api/routes/active/all
```

#### Calcular preview de ruta (sin guardar)
```
POST /api/routes/calculate/preview
Body: {
  "origen": { "lat": 4.7110, "lng": -74.0721 },
  "destino": { "lat": 4.6097, "lng": -74.0817 }
}
```

## 🔧 Configuración

### API de Rutas (OpenRouteService)

El sistema usa OpenRouteService para calcular rutas. La clave API demo está incluida, pero para uso en producción debes obtener tu propia clave gratuita:

1. Regístrate en https://openrouteservice.org/dev/#/signup
2. Obtén tu API key
3. Actualiza la clave en `services/route.service.js`:

```javascript
const ORS_API_KEY = 'TU_API_KEY_AQUI';
```

**Límites de la API gratuita:**
- 2000 solicitudes por día
- 40 solicitudes por minuto

### Fallback

Si la API de OpenRouteService falla o alcanza el límite, el sistema automáticamente usa una ruta en línea recta como respaldo.

## 📁 Estructura de Archivos

```
unihitch_backend/
├── controllers/
│   └── routes.controller.js      # Controlador de rutas
├── routes/
│   └── routes.routes.js           # Endpoints API
├── services/
│   └── route.service.js           # Servicio de cálculo de rutas
├── public/
│   ├── trip-monitor.html          # Panel web principal
│   ├── css/
│   │   └── leaflet-styles.css     # Estilos personalizados
│   └── js/
│       └── trip-monitor.js        # Lógica del mapa
├── create_rutas_table.js          # Migración de BD
└── server.js                      # Servidor principal (actualizado)
```

## 🗄️ Esquema de Base de Datos

### Tabla `rutas`

```sql
CREATE TABLE rutas (
    id SERIAL PRIMARY KEY,
    id_viaje INTEGER NOT NULL REFERENCES viaje(id) ON DELETE CASCADE,
    coordenadas JSONB NOT NULL,
    distancia_km DECIMAL(10, 2),
    duracion_minutos INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_viaje)
);
```

## 🎨 Características del Panel Web

### Sidebar
- Lista de viajes activos
- Filtros por estado
- Botón de actualización manual
- Información resumida de cada viaje

### Mapa
- Visualización de rutas con polilíneas
- Marcadores de origen (🚩) y destino (🎯)
- Zoom y navegación interactiva
- Ajuste automático para mostrar todas las rutas

### Panel de Información
- Detalles completos del viaje seleccionado
- Conductor, origen, destino
- Distancia y duración estimada
- Estado y fecha del viaje

## 🔄 Actualización en Tiempo Real

El panel se actualiza automáticamente cada 10 segundos para mostrar:
- Nuevos viajes disponibles
- Cambios de estado
- Ubicaciones actualizadas

Puedes modificar el intervalo en `public/js/trip-monitor.js`:

```javascript
const REFRESH_INTERVAL = 10000; // milisegundos
```

## 🌐 Compatibilidad

- ✅ Chrome, Firefox, Safari, Edge (últimas versiones)
- ✅ Responsive (funciona en tablets y móviles)
- ✅ No requiere API keys de Google Maps
- ✅ Funciona sin conexión a internet (excepto tiles del mapa)

## 📝 Notas Importantes

1. **No afecta la app móvil**: La app Flutter sigue usando Google Maps sin cambios
2. **Complementario**: Este panel es adicional para administradores/monitoreo
3. **Gratuito**: Usa OpenStreetMap y OpenRouteService (niveles gratuitos)
4. **Escalable**: Fácil de extender con más funcionalidades

## 🐛 Solución de Problemas

### El mapa no carga
- Verifica que el servidor esté corriendo en puerto 3000
- Revisa la consola del navegador para errores
- Asegúrate de tener conexión a internet (para tiles de OSM)

### No aparecen viajes
- Verifica que existan viajes en la base de datos
- Ejecuta la migración: `node create_rutas_table.js`
- Revisa que los endpoints `/api/routes/active/all` respondan

### Error al calcular rutas
- Verifica tu API key de OpenRouteService
- Revisa los límites de la API gratuita
- El sistema usará rutas en línea recta como fallback

## 🚀 Próximos Pasos

Para usar el sistema completo:

1. Crea algunos viajes de prueba desde la app móvil
2. Abre el panel web en `http://localhost:3000/trip-monitor.html`
3. Las rutas se calcularán automáticamente
4. Selecciona un viaje para ver detalles
5. El mapa se actualizará automáticamente

## 📞 Soporte

Si encuentras problemas, revisa:
- Logs del servidor (`node server.js`)
- Consola del navegador (F12)
- Estado de la base de datos

---

**Desarrollado para UniHitch** 🚗✨
