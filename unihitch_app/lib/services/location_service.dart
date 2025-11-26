import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  /// Verifica y solicita permisos de ubicación
  /// Verifica y solicita permisos de ubicación
  static Future<LocationPermission> handleLocationPermission() async {
    if (kIsWeb) {
      return LocationPermission.always;
    }

    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission
          .denied; // O un estado específico para servicio deshabilitado
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  /// Obtiene la ubicación actual del usuario
  static Future<Position?> getCurrentLocation() async {
    // Usar geolocator para móvil y web
    final permission = await handleLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Convierte coordenadas a dirección legible
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Construir dirección
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        return addressParts.isNotEmpty
            ? addressParts.join(', ')
            : 'Ubicación desconocida';
      }

      return 'Ubicación desconocida';
    } catch (e) {
      print('Error obteniendo dirección: $e');
      return 'Ubicación desconocida';
    }
  }

  /// Obtiene la ubicación actual con dirección
  static Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
    };
  }

  /// Calcula la distancia entre dos puntos en kilómetros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Inicia tracking en tiempo real de la ubicación
  static Stream<Position> getLocationStream() {
    if (kIsWeb) {
      // Para web, crear un stream manual
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        return await getCurrentLocation();
      })
          .asyncMap((event) async => await event)
          .where((pos) => pos != null)
          .cast<Position>();
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Verifica si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) {
      return true;
    }
    return await Geolocator.isLocationServiceEnabled();
  }
}
