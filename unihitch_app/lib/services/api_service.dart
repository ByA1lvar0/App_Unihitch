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
  static Future<Map<String, dynamic>> login(
      String correo, String password) async {
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
    String? carreraNombre,
    String? codigoUniversitario,
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
        if (carreraNombre != null) 'carrera_nombre': carreraNombre,
        if (codigoUniversitario != null)
          'codigo_universitario': codigoUniversitario,
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
    final response =
        await http.get(Uri.parse('${Config.apiUrl}/universidades'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar universidades');
    }
  }

  // OBTENER VIAJES
  static Future<List<dynamic>> getViajes(
      {String? origen, String? destino}) async {
    String url = '${Config.apiUrl}/viajes';
    if (origen != null || destino != null) {
      url += '?';
      if (origen != null) url += 'origen=$origen&';
      if (destino != null) url += 'destino=$destino';
    }
    final response = await http.get(Uri.parse(url));

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
    bool? aceptaEfectivo,
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
        if (aceptaEfectivo != null) 'acepta_efectivo': aceptaEfectivo,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
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

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // OBTENER HISTORIAL DE VIAJES
  static Future<Map<String, dynamic>> getTripHistory(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/history/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener historial');
    }
  }

  // OBTENER ESTADÍSTICAS DE USUARIO
  static Future<Map<String, dynamic>> getUserStatistics(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/history/statistics/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener estadísticas');
    }
  }

  // MÉTODO GET GENÉRICO
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}$endpoint'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error en GET: $endpoint');
    }
  }

  // MÉTODO POST GENÉRICO
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error en POST');
    }
  }

  // OBTENER DETALLES DE USUARIO
  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/users/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener detalles del usuario');
    }
  }

  // ACTUALIZAR CONTACTO DE EMERGENCIA
  static Future<void> updateEmergencyContact({
    required int userId,
    required String emergencyNumber,
  }) async {
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/users/$userId/emergency'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'numero_emergencia': emergencyNumber}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar contacto de emergencia');
    }
  }

  // OBTENER CALIFICACIONES DE USUARIO
  static Future<List<dynamic>> getUserRatings(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/ratings/user/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // OBTENER WALLET
  static Future<Map<String, dynamic>> getWallet(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/wallet/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener wallet');
    }
  }

  // OBTENER MIS VIAJES (COMO CONDUCTOR)
  static Future<List<dynamic>> getMisViajes(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/viajes/conductor/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // OBTENER MIS RESERVAS (COMO PASAJERO)
  static Future<List<dynamic>> getMisReservas(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/reservas/pasajero/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }
}