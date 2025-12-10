import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../services/api_service.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  final int adminId;

  const AdminWithdrawalsScreen({super.key, required this.adminId});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  List<dynamic> _solicitudes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/wallet/withdrawals-pending'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _solicitudes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar solicitudes');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _procesarRetiro(int id, String estado, {String? motivo}) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/wallet/withdrawal/$id/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': widget.adminId,
          'estado': estado,
          'observaciones': motivo ??
              (estado == 'APROBADO' ? 'Aprobado por admin' : 'Rechazado'),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(estado == 'PROCESADO'
                  ? 'Retiro aprobado'
                  : 'Retiro rechazado'),
              backgroundColor:
                  estado == 'PROCESADO' ? Colors.green : Colors.orange,
            ),
          );
          _loadSolicitudes();
        }
      } else {
        throw Exception('Error al procesar: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dialogoRechazo(int id) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar Retiro'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Motivo (ej: Número inválido)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );

    if (motivo != null && motivo.isNotEmpty) {
      _procesarRetiro(id, 'RECHAZADO', motivo: motivo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobar Retiros'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay retiros pendientes',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _solicitudes.length,
                  itemBuilder: (context, index) {
                    final s = _solicitudes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('S/ ${s['monto']}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(s['estado'],
                                      style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Usuario: ${s['usuario_nombre']}'),
                            Text('Método: ${s['metodo']}'),
                            Text('Destino: ${s['numero_destino']}'),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _dialogoRechazo(s['id']),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Rechazar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _procesarRetiro(s['id'],
                                        'PROCESADO'), // backend expects PROCESADO for approval
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white),
                                    child: const Text('Aprobar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
