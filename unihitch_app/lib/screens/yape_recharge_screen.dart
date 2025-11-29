import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../config.dart';

class YapeRechargeScreen extends StatefulWidget {
  final int userId;

  const YapeRechargeScreen({super.key, required this.userId});

  @override
  State<YapeRechargeScreen> createState() => _YapeRechargeScreenState();
}

class _YapeRechargeScreenState extends State<YapeRechargeScreen> {
  final _montoController = TextEditingController();
  final _numeroOperacionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _comprobanteImage;
  bool _isLoading = false;

  final String yapeNumber = "928318308"; // Tu número de Yape

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _comprobanteImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _enviarSolicitud() async {
    if (_montoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el monto')),
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

    if (_comprobanteImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes subir el comprobante de Yape')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertir imagen a base64
      final bytes = await _comprobanteImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Enviar solicitud
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/wallet/recarga-manual'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': widget.userId,
          'monto': monto,
          'metodo': 'YAPE',
          'comprobante_base64': base64Image,
          'numero_operacion': _numeroOperacionController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Solicitud enviada! Será revisada en breve.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true = success
        }
      } else {
        final error = jsonDecode(response.body)['error'];
        throw Exception(error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Recargar con Yape'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info, color: Colors.purple, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Pasos para recargar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Yapea el monto a:\n2. Toma captura del comprobante\n3. Sube la captura aquí\n4. Espera aprobación (5-30 min)',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Número de Yape grande
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Número Yape',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              yapeNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Número copiado')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Ej: 50',
                helperText: 'Mínimo S/ 5, Máximo S/ 500',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Número de operación (opcional)
            TextFormField(
              controller: _numeroOperacionController,
              decoration: const InputDecoration(
                labelText: 'Número de operación (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 24),

            // Seleccionar comprobante
            if (_comprobanteImage != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_comprobanteImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _selectImage,
                icon: const Icon(Icons.edit),
                label: const Text('Cambiar comprobante'),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _selectImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir Comprobante de Yape'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Botón enviar
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarSolicitud,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENVIAR SOLICITUD',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _numeroOperacionController.dispose();
    super.dispose();
  }
}
