import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'api_service.dart';

class MessageService {
  static const String baseUrl = Config.apiUrl;

  /// Obtener ID del usuario actual
  static Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = json.decode(userJson);
      return user['id'];
    }
    return null;
  }

  /// Obtener lista de chats del usuario
  static Future<List<dynamic>> getChats() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return [];

      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error obteniendo chats: $e');
      return [];
    }
  }

  /// Obtener o crear chat con otro usuario
  static Future<Map<String, dynamic>?> getOrCreateChat(int otherUserId,
      {int? idViaje, int? idReserva, String tipoChat = 'VIAJE'}) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('Usuario no identificado');

      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chats'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_usuario1': userId,
          'id_usuario2': otherUserId,
          if (idViaje != null) 'id_viaje': idViaje,
          if (idReserva != null) 'id_reserva': idReserva,
          'tipo_chat': tipoChat,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear chat');
      }
    } catch (e) {
      print('Error creando chat: $e');
      rethrow;
    }
  }

  /// Obtener mensajes de un chat
  static Future<List<dynamic>> getMessages(int chatId) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error obteniendo mensajes: $e');
      return [];
    }
  }

  /// Enviar mensaje
  static Future<bool> sendMessage(int chatId, String mensaje) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_chat': chatId,
          'id_remitente': userId,
          'mensaje': mensaje,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error enviando mensaje: $e');
      return false;
    }
  }

  /// Marcar mensajes como leídos
  static Future<bool> markAsRead(int chatId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final token = await ApiService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/chats/$chatId/read/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marcando como leído: $e');
      return false;
    }
  }

  /// Obtener contador de mensajes no leídos
  static Future<int> getUnreadCount() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return 0;

      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$userId/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error obteniendo contador: $e');
      return 0;
    }
  }
}
