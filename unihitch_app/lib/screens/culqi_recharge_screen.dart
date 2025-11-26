import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class CulqiRechargeScreen extends StatefulWidget {
  final int userId;
  final String userEmail;

  const CulqiRechargeScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<CulqiRechargeScreen> createState() => _CulqiRechargeScreenState();
}

class _CulqiRechargeScreenState extends State<CulqiRechargeScreen> {
  final _montoController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _mesController = TextEditingController();
  final _anioController = TextEditingController();
  bool _isLoading = false;

  final String culqiPublicKey = 'pk_test_Id9C7V2eQVUS5Abo';

  Future<void> _procesarPago() async {
    if (_montoController.text.isEmpty ||
        _cardNumberController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _mesController.text.isEmpty ||
        _anioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto < 5 || monto > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El monto debe estar entre S/ 5 y S/ 500')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Paso 1: Crear token en Culqi
      final tokenResponse = await http.post(
        Uri.parse('https://secure.culqi.com/v2/tokens'),
        headers: {
          'Authorization': 'Bearer $culqiPublicKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'card_number': _cardNumberController.text.replaceAll(' ', ''),
          'cvv': _cvvController.text,
          'expiration_month': _mesController.text,
          'expiration_year': _anioController.text,
          'email': widget.userEmail,
        }),
      );

      if (tokenResponse.statusCode != 201) {
        final error = jsonDecode(tokenResponse.body);
        throw Exception(error['user_message'] ?? 'Error al crear token');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final token = tokenData['id'];

      // Paso 2: Procesar cargo en nuestro backend
      final chargeResponse = await http.post(
        Uri.parse('${Config.apiUrl}/wallet/recarga-culqi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': widget.userId,
          'monto': monto,
          'token_culqi': token,
          'email': widget.userEmail,
        }),
      );

      if (chargeResponse.statusCode == 200) {
        final result = jsonDecode(chargeResponse.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '¡Recarga exitosa! Nuevo saldo: S/ ${result['nuevo_saldo']}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final error = jsonDecode(chargeResponse.body);
        throw Exception(error['mensaje'] ?? error['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con Tarjeta'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Pago Instantáneo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tu saldo se acredita inmediatamente\nPago seguro procesado por Culqi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Monto
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto a recargar *',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
                helperText: 'Mínimo S/ 5, Máximo S/ 500',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Número de tarjeta
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Número de tarjeta *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
                hintText: '4111 1111 1111 1111',
              ),
              keyboardType: TextInputType.number,
              maxLength: 19,
            ),
            const SizedBox(height: 16),

            // CVV y Vencimiento
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV *',
                      border: OutlineInputBorder(),
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _mesController,
                    decoration: const InputDecoration(
                      labelText: 'Mes *',
                      border: OutlineInputBorder(),
                      hintText: '12',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _anioController,
                    decoration: const InputDecoration(
                      labelText: 'Año *',
                      border: OutlineInputBorder(),
                      hintText: '25',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjetas de prueba
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💳 Tarjetas de Prueba (Modo TEST):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visa: 4111 1111 1111 1111\nCVV: 123 | Venc: Cualquier fecha futura',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón pagar
            ElevatedButton(
              onPressed: _isLoading ? null : _procesarPago,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('PAGAR AHORA', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _mesController.dispose();
    _anioController.dispose();
    super.dispose();
  }
}
