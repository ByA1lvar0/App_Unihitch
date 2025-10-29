import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String correo, String password) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      await saveUser(data['user']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // REGISTRO
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String correo,
    required String password,
    required String telefono,
    required int idUniversidad,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'telefono': telefono,
        'id_universidad': idUniversidad,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      await saveUser(data['user']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // OBTENER UNIVERSIDADES
  static Future<List<dynamic>> getUniversidades() async {
    final response = await http.get(Uri.parse('${Config.apiUrl}/universidades'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar universidades');
    }
  }

  // OBTENER VIAJES
  static Future<List<dynamic>> getViajes() async {
    final response = await http.get(Uri.parse('${Config.apiUrl}/viajes'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar viajes');
    }
  }

  // CREAR VIAJE
  static Future<Map<String, dynamic>> createViaje({
    required int idConductor,
    required String origen,
    required String destino,
    required String fechaHora,
    required double precio,
    required int asientosDisponibles,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/viajes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_conductor': idConductor,
        'origen': origen,
        'destino': destino,
        'fecha_hora': fechaHora,
        'precio': precio,
        'asientos_disponibles': asientosDisponibles,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear viaje');
    }
  }

  // CREAR RESERVA
  static Future<Map<String, dynamic>> createReserva({
    required int idViaje,
    required int idPasajero,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/reservas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_viaje': idViaje,
        'id_pasajero': idPasajero,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // MIS VIAJES (CONDUCTOR)
  static Future<List<dynamic>> getMisViajes(int idConductor) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/viajes/conductor/$idConductor'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar viajes');
    }
  }

  // MIS RESERVAS (PASAJERO)
  static Future<List<dynamic>> getMisReservas(int idPasajero) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/reservas/pasajero/$idPasajero'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar reservas');
    }
  }
}