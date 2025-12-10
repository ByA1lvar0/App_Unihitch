import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  static Future<Map<String, dynamic>> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // OSRM usa formato longitud,latitud (al revés que Google)
      final String url = 'http://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convertir coordenadas [long, lat] a LatLng(lat, long)
          final routePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          return {
            'points': routePoints,
            'distance': route['distance'] is int
                ? '${(route['distance'] / 1000).toStringAsFixed(1)} km'
                : '${route['distance']}',
            'distance_value': route['distance'], // en metros
            'duration': route['duration'] is int
                ? '${(route['duration'] / 60).round()} mins'
                : '${route['duration']}',
            'duration_value': route['duration'], // en segundos
          };
        } else {
          throw Exception('No se encontró una ruta: ${data['code']}');
        }
      } else {
        throw Exception('Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener la ruta: $e');
    }
  }
}
