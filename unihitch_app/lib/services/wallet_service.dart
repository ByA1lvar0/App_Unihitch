import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Obtener información de la wallet del usuario
  Future<Map<String, dynamic>> getWallet(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener wallet');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== MÉTODOS DE PAGO ====================

  // Obtener métodos de pago del usuario
  Future<List<Map<String, dynamic>>> getPaymentMethods(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-methods/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener métodos de pago');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Agregar método de pago
  Future<Map<String, dynamic>> addPaymentMethod({
    required int userId,
    required String tipo,
    required String numero,
    required String nombreTitular,
    bool esPrincipal = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment-methods'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'tipo': tipo,
          'numero': numero,
          'nombreTitular': nombreTitular,
          'esPrincipal': esPrincipal,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al agregar método de pago');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar método de pago
  Future<void> deletePaymentMethod(int methodId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payment-methods/$methodId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar método de pago');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Establecer método como principal
  Future<void> setPrimaryPaymentMethod(int methodId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payment-methods/$methodId/set-primary'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al establecer método principal');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== RECARGAS ====================

  // Obtener cuentas de pago disponibles (Yape/Plin)
  Future<List<Map<String, dynamic>>> getPaymentAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-accounts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener cuentas de pago');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Solicitar recarga con comprobante (Yape/Plin)
  Future<Map<String, dynamic>> submitRechargeRequest({
    required int userId,
    required double amount,
    required String method,
    required String imageBase64,
    String? operationNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/recharge-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'method': method,
          'imageBase64': imageBase64,
          'operationNumber': operationNumber,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al procesar recarga');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Recarga con tarjeta
  Future<Map<String, dynamic>> rechargeWithCard({
    required int userId,
    required double amount,
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
    required String cvv,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/recharge-card'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'cardNumber': cardNumber,
          'cardHolder': cardHolder,
          'expiryDate': expiryDate,
          'cvv': cvv,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['error'] ?? 'Error al procesar recarga con tarjeta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener historial de recargas
  Future<List<Map<String, dynamic>>> getRechargeHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/recharge-history/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener historial');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== RETIROS ====================

  // Solicitar retiro
  Future<Map<String, dynamic>> requestWithdrawal({
    required int userId,
    required double amount,
    required String method,
    required String numeroDestino,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/withdrawal-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'method': method,
          'numeroDestino': numeroDestino,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al solicitar retiro');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener historial de retiros
  Future<List<Map<String, dynamic>>> getWithdrawals(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/withdrawals/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener historial de retiros');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estadísticas de CO2
  Future<Map<String, dynamic>> getCO2Stats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/co2-stats/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
