import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsService {
  // Clave de API de Google Maps
  static const String _apiKey = 'AIzaSyBEs717e874R4RIOORgIj4eQm2yxtg-f2Y';

  static Future<Map<String, dynamic>> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final polylinePoints = route['overview_polyline']['points'];

          // Decodificar la polilínea
          PolylinePoints polylinePointsDecoder = PolylinePoints();
          List<PointLatLng> decodedPoints =
              polylinePointsDecoder.decodePolyline(polylinePoints);

          // Convertir a LatLng
          final routePoints = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          return {
            'points': routePoints,
            'distance': leg['distance']['text'], // e.g., "5.2 km"
            'distance_value': leg['distance']['value'], // en metros
            'duration': leg['duration']['text'], // e.g., "15 mins"
            'duration_value': leg['duration']['value'], // en segundos
          };
        } else {
          throw Exception('No se encontró una ruta: ${data['status']}');
        }
      } else {
        throw Exception('Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener la ruta: $e');
    }
  }
}
