import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

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

      final response = await http.get(
        Uri.parse('$baseUrl/chats/$userId'),
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
  static Future<Map<String, dynamic>?> getOrCreateChat(int otherUserId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/chats'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_usuario1': userId,
          'id_usuario2': otherUserId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error creando chat: $e');
      return null;
    }
  }

  /// Obtener mensajes de un chat
  static Future<List<dynamic>> getMessages(int chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
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

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_chat': chatId,
          'id_remitente': userId,
          'mensaje': mensaje,
        }),
      );

      return response.statusCode == 200;
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

      final response = await http.put(
        Uri.parse('$baseUrl/chats/$chatId/read/$userId'),
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

      final response = await http.get(
        Uri.parse('$baseUrl/chats/$userId/unread-count'),
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
