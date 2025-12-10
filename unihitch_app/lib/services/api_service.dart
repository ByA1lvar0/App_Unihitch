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
    int? idUniversidad,
    String? carreraNombre,
    String? codigoUniversitario,
    String? referralCode,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'telefono': telefono,
        if (idUniversidad != null) 'id_universidad': idUniversidad,
        if (carreraNombre != null) 'carrera_nombre': carreraNombre,
        if (codigoUniversitario != null)
          'codigo_universitario': codigoUniversitario,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
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
    final token = await getToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Error al cargar viajes: ${response.statusCode}');
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
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/viajes'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
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
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/reservas'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
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
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener detalles del usuario');
    }
  }

  // ACTUALIZAR PERFIL DE USUARIO
  static Future<Map<String, dynamic>> updateUser({
    required int id,
    required String nombre,
    required String telefono,
    required String carrera,
    required String contactosEmergencia,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'telefono': telefono,
        'carrera': carrera,
        'contactos_emergencia': contactosEmergencia,
      }),
    );
    if (response.statusCode == 200) {
      final updatedUser = jsonDecode(response.body);
      await saveUser(updatedUser); // Update local storage
      return updatedUser;
    } else {
      throw Exception('Error al actualizar perfil');
    }
  }

  // ACTUALIZAR CONTACTO DE EMERGENCIA
  static Future<void> updateEmergencyContact({
    required int userId,
    required String emergencyNumber,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/users/$userId/emergency'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
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
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/viajes/conductor/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
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

  // CANCELAR RESERVA
  static Future<Map<String, dynamic>> cancelReservation({
    required int reservationId,
    required int userId,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/reservas/$reservationId/cancelar'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // OBTENER ESTADO DE DOCUMENTOS DEL CONDUCTOR
  static Future<Map<String, dynamic>> getDriverDocumentStatus(
      int userId) async {
    final token = await getToken();
    final response = await http.get(
        Uri.parse('${Config.apiUrl}/documentos-conductor/$userId/estado'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener estado de documentos');
    }
  }

  // BUSCAR USUARIOS
  static Future<List<dynamic>> searchUsers(String query) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/usuarios/search?q=$query'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al buscar usuarios');
    }
  }

  // ==================== COMMUNITY METHODS ====================

  // OBTENER MENSAJES DE COMUNIDAD
  static Future<List<dynamic>> getCommunityMessages(int universidadId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/community/messages/$universidadId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener mensajes de comunidad');
    }
  }

  // ENVIAR MENSAJE A COMUNIDAD
  static Future<Map<String, dynamic>> sendCommunityMessage({
    required int userId,
    required int universidadId,
    required String mensaje,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/community/messages'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'universidadId': universidadId,
        'mensaje': mensaje,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al enviar mensaje');
    }
  }

  // OBTENER MIEMBROS DE COMUNIDAD
  static Future<List<dynamic>> getCommunityMembers(int universidadId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/community/members/$universidadId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener miembros');
    }
  }

  // OBTENER TODOS LOS USUARIOS VERIFICADOS
  static Future<List<dynamic>> getAllVerifiedUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  // CAMBIAR UNIVERSIDAD DE USUARIO
  static Future<void> changeUserUniversity(
      int userId, int universidadId) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/admin/users/$userId/university'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_universidad': universidadId,
        'verificado': true,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cambiar universidad');
    }
  }

  // ALIAS PARA COMPATIBILIDAD
  static Future<Map<String, dynamic>> getDocumentStatus(int userId) async {
    return getDriverDocumentStatus(userId);
  }

  // ELIMINAR USUARIO
  static Future<void> deleteUser(int userId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario');
    }
  }

  // OBTENER USUARIOS PENDIENTES
  static Future<List<dynamic>> getPendingUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/admin/users/pending'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener usuarios pendientes');
    }
  }

  // VERIFICAR USUARIO
  static Future<void> verifyUser(int userId) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/admin/users/$userId/verify'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al verificar usuario');
    }
  }

  // AGREGAR ADMIN
  static Future<void> addAdmin(String email) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/admin/add'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al agregar administrador');
    }
  }

  // HABILITAR/INHABILITAR USUARIO
  static Future<void> toggleUserStatus({
    required int userId,
    required bool activo,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/admin/users/$userId/toggle-status'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'activo': activo}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cambiar estado del usuario');
    }
  }

  // OBTENER TODOS LOS VIAJES (ADMIN)
  static Future<List<dynamic>> getAdminTrips() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/admin/trips'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener viajes');
    }
  }

  // CREAR GRUPO DE CARPOOLING
  static Future<void> createCarpoolingGroup({
    required int organizadorId,
    required String rutaComun,
    required String horarioPreferido,
    required String tipoGrupo,
    required double costoTotal,
    required int numPasajeros,
    required String descripcion,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/carpooling/groups'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_organizador': organizadorId,
        'ruta_comun': rutaComun,
        'horario_preferido': horarioPreferido,
        'tipo_grupo': tipoGrupo,
        'costo_total': costoTotal,
        'num_pasajeros': numPasajeros,
        'descripcion': descripcion,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear grupo de carpooling');
    }
  }

  // OBTENER GRUPOS DE CARPOOLING
  static Future<List<dynamic>> getCarpoolingGroups() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/carpooling/groups'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener grupos de carpooling');
    }
  }

  // UNIRSE A GRUPO DE CARPOOLING
  static Future<void> joinCarpoolingGroup({
    required int groupId,
    required int userId,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/carpooling/groups/$groupId/join'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id_usuario': userId}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al unirse al grupo');
    }
  }

  // OBTENER ESTADÍSTICAS DE USUARIO
  static Future<Map<String, dynamic>> getUserStatistics(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/history/statistics/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener estadísticas');
    }
  }

  // OBTENER CONTACTOS DE EMERGENCIA
  static Future<List<dynamic>> getEmergencyContacts(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/emergency/contacts/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // OBTENER CONFIGURACIÓN DE EMERGENCIA
  static Future<Map<String, dynamic>> getEmergencyConfig(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/emergency/config/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {};
    }
  }

  // AGREGAR CONTACTO DE EMERGENCIA
  static Future<bool> addEmergencyContact({
    required int userId,
    required String nombre,
    required String telefono,
    required String relacion,
    bool esPrincipal = false,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/emergency/contacts'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'telefono': telefono,
        'relacion': relacion,
        'es_principal': esPrincipal,
      }),
    );
    return response.statusCode == 201;
  }

  // ELIMINAR CONTACTO DE EMERGENCIA
  static Future<bool> deleteEmergencyContact(int contactId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/emergency/contacts/$contactId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // ACTUALIZAR CONFIGURACIÓN DE EMERGENCIA
  static Future<bool> updateEmergencyConfig({
    required int userId,
    required bool autoEnvioUbicacion,
    required bool notificarUniversidad,
    required bool grabarAudio,
    required bool alertasVelocidad,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/emergency/config/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'auto_envio_ubicacion': autoEnvioUbicacion,
        'notificar_universidad': notificarUniversidad,
        'grabar_audio': grabarAudio,
        'alertas_velocidad': alertasVelocidad,
      }),
    );
    return response.statusCode == 200;
  }

  // OBTENER NOTIFICACIONES
  static Future<List<dynamic>> getNotifications(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/notifications/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener notificaciones');
    }
  }

  // MARCAR TODAS LAS NOTIFICACIONES COMO LEIDAS
  static Future<void> markAllNotificationsAsRead(int userId) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/notifications/$userId/read-all'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al marcar notificaciones como leídas');
    }
  }

  // ENVIAR ALERTA DE EMERGENCIA
  static Future<void> sendEmergencyLocation({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/emergency/alert'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'latitud': latitude,
        'longitud': longitude,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar alerta de emergencia');
    }
  }

  // VERIFICAR CÓDIGO DE EMAIL
  static Future<void> verifyEmailCode({
    required int userId,
    required String code,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/auth/verify-email'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Código inválido';
      throw Exception(error);
    }
  }

  // REENVIAR CÓDIGO DE VERIFICACIÓN
  static Future<void> resendVerificationCode(int userId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/auth/resend-verification'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      final error =
          jsonDecode(response.body)['error'] ?? 'Error al reenviar código';
      throw Exception(error);
    }
  }

  // ACTUALIZAR UBICACIÓN DE USUARIO EN VIAJE
  static Future<void> updateUserLocation({
    required int userId,
    required int tripId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/viajes/$tripId/ubicacion'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'latitud': latitude,
        'longitud': longitude,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar ubicación');
    }
  }

  // OBTENER UBICACIONES DE VIAJE
  static Future<Map<String, dynamic>> getTripLocations(int tripId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/viajes/$tripId/ubicaciones'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener ubicaciones del viaje');
    }
  }

  // CALIFICAR USUARIO
  static Future<void> rateUser({
    required int tripId,
    required int authorId,
    required int targetUserId,
    required int rating,
    String? comment,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/ratings'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_viaje': tripId,
        'id_autor': authorId,
        'id_usuario_calificado': targetUserId,
        'calificacion': rating,
        if (comment != null && comment.isNotEmpty) 'comentario': comment,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final error =
          jsonDecode(response.body)['error'] ?? 'Error al enviar calificación';
      throw Exception(error);
    }
  }

  // OBTENER PREFERENCIA DE MÉTODO DE EMERGENCIA
  static Future<Map<String, dynamic>> getEmergencyPreference(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/emergency/preference/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Return default if error
      return {'metodo_preferido': 'WHATSAPP'};
    }
  }

  // ACTUALIZAR PREFERENCIA DE MÉTODO DE EMERGENCIA
  static Future<void> updateEmergencyPreference(
      int userId, String metodoPreferido) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/emergency/preference/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'metodo_preferido': metodoPreferido}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ??
          'Error al actualizar preferencia';
      throw Exception(error);
    }
  }

  // ==================== ADMIN DOCUMENT MANAGEMENT ====================

  // OBTENER DOCUMENTOS PENDIENTES (ADMIN)
  static Future<List<dynamic>> getPendingDocuments() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/documentos-conductor/admin/pending'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener documentos pendientes');
    }
  }

  // APROBAR DOCUMENTO (ADMIN)
  static Future<void> approveDocument({
    required int documentId,
    required int adminId,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(
          '${Config.apiUrl}/documentos-conductor/admin/$documentId/approve'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id_revisor': adminId}),
    );

    if (response.statusCode != 200) {
      final error =
          jsonDecode(response.body)['error'] ?? 'Error al aprobar documento';
      throw Exception(error);
    }
  }

  // RECHAZAR DOCUMENTO (ADMIN)
  static Future<void> rejectDocument({
    required int documentId,
    required int adminId,
    required String motivo,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(
          '${Config.apiUrl}/documentos-conductor/admin/$documentId/reject'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_revisor': adminId,
        'motivo_rechazo': motivo,
      }),
    );

    if (response.statusCode != 200) {
      final error =
          jsonDecode(response.body)['error'] ?? 'Error al rechazar documento';
      throw Exception(error);
    }
  }

  // DETECTAR UNIVERSIDAD POR CORREO
  static Future<Map<String, dynamic>> detectUniversityByEmail(
      String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/university/detect-by-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'detected': false};
      }
    } catch (e) {
      return {'detected': false};
    }
  }

  // OBTENER ESTADÍSTICAS DASHBOARD ADMIN
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/admin/dashboard-stats'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener estadísticas del dashboard');
    }
  }
}
