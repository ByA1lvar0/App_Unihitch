# Configuración de Google Directions API

Para que las polilíneas (rutas) funcionen en el mapa, necesitas habilitar la **Directions API** en Google Cloud Console.

## Pasos:

1. **Ir a Google Cloud Console:**
   - Ve a [https://console.cloud.google.com/](https://console.cloud.google.com/)
   - Selecciona tu proyecto (el mismo que usas para Google Maps).

2. **Habilitar Directions API:**
   - En el menú lateral, ve a **APIs & Services > Library**.
   - Busca **"Directions API"**.
   - Haz clic en **"Directions API"**.
   - Haz clic en **"Enable"** (Habilitar).

3. **Configurar la clave API:**
   - Abre el archivo `lib/services/directions_service.dart`.
   - Reemplaza `'YOUR_GOOGLE_MAPS_API_KEY'` con tu clave de API real.
   - **Importante:** Usa la misma clave que configuraste en `AndroidManifest.xml`.

4. **Ejecutar flutter pub get:**
   - Abre una terminal en la carpeta `unihitch_app`.
   - Ejecuta: `flutter pub get`
   - Esto descargará la dependencia `flutter_polyline_points`.

5. **Probar:**
   - Inicia un viaje en la app.
   - Deberías ver una línea azul siguiendo las calles entre tu ubicación y el conductor.

## Notas:
- La API de Directions tiene un límite de uso gratuito (generalmente suficiente para desarrollo).
- Si ves errores en la consola sobre "API key not valid", verifica que la clave esté correcta y que Directions API esté habilitada.
