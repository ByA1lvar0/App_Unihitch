import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AdminRechargeApprovalScreen extends StatefulWidget {
  final int adminId;

  const AdminRechargeApprovalScreen({super.key, required this.adminId});

  @override
  State<AdminRechargeApprovalScreen> createState() =>
      _AdminRechargeApprovalScreenState();
}

class _AdminRechargeApprovalScreenState
    extends State<AdminRechargeApprovalScreen> {
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
        Uri.parse('${Config.apiUrl}/wallet/recarga-pendientes'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _solicitudes = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _aprobar(int id, double monto) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/admin/aprobar-recarga/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_revisor': widget.adminId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recarga de S/ $monto aprobada'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSolicitudes();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rechazar(int id) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        final motivoController = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar Recarga'),
          content: TextField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: 'Motivo del rechazo',
              hintText: 'Ej: Comprobante ilegible',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, motivoController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );

    if (motivo != null && motivo.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${Config.apiUrl}/admin/rechazar-recarga/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_revisor': widget.adminId,
            'motivo_rechazo': motivo,
          }),
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recarga rechazada'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobar Recargas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No hay solicitudes pendientes',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSolicitudes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = _solicitudes[index];
                      return _buildSolicitudCard(solicitud);
                    },
                  ),
                ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    final DateTime fechaSolicitud =
        DateTime.parse(solicitud['fecha_solicitud']);
    final String fechaFormateada =
        '${fechaSolicitud.day.toString().padLeft(2, '0')}/${fechaSolicitud.month.toString().padLeft(2, '0')}/${fechaSolicitud.year} ${fechaSolicitud.hour.toString().padLeft(2, '0')}:${fechaSolicitud.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(solicitud['usuario_nombre'][0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud['usuario_nombre'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        solicitud['usuario_correo'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      // TIMESTAMP AGREGADO
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Subido: $fechaFormateada',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'S/ ${solicitud['monto']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Comprobante con zoom
            const Text(
              'Comprobante:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (solicitud['comprobante_base64'] != null)
              GestureDetector(
                onTap: () =>
                    _mostrarComprobanteGrande(solicitud['comprobante_base64']),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(
                            _sanitizeBase64(solicitud['comprobante_base64'])),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Click para ampliar',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('Sin comprobante',
                  style: TextStyle(color: Colors.red)),

            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rechazar(solicitud['id']),
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _aprobar(
                      solicitud['id'],
                      double.parse(solicitud['monto'].toString()),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarComprobanteGrande(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comprobante Yape'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(_sanitizeBase64(base64Image)),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeBase64(String base64) {
    if (base64.contains(',')) {
      return base64.split(',').last;
    }
    return base64;
  }
}
