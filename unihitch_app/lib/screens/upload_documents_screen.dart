import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final int userId;
  final bool esAgenteExterno;

  const UploadDocumentsScreen({
    super.key,
    required this.userId,
    this.esAgenteExterno = false,
  });

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Estado de documentos
  Map<String, dynamic> _documentos = {};
  Map<String, XFile?> _archivosSeleccionados = {};
  Map<String, DateTime?> _fechasVencimiento = {};

  @override
  void initState() {
    super.initState();
    _cargarDocumentos();
  }

  Future<void> _cargarDocumentos() async {
    setState(() => _isLoading = true);
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/documentos-conductor/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> docs = jsonDecode(response.body);
        setState(() {
          _documentos = {for (var doc in docs) doc['tipo_documento']: doc};
        });
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar documentos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarImagen(String tipoDocumento) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _archivosSeleccionados[tipoDocumento] = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _subirDocumento(String tipoDocumento) async {
    final archivo = _archivosSeleccionados[tipoDocumento];
    if (archivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona un archivo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtener token de autenticación
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception(
            'No se encontró token de autenticación. Por favor inicia sesión nuevamente.');
      }

      // Convertir a base64
      final bytes = await archivo.readAsBytes();
      final base64String = base64Encode(bytes);
      final tamanioKb = (bytes.length / 1024).round();

      // Determinar MIME type
      String mimeType = 'image/jpeg';
      if (archivo.path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (archivo.path.toLowerCase().endsWith('.pdf')) {
        mimeType = 'application/pdf';
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/documentos-conductor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_conductor': widget.userId,
          'tipo_documento': tipoDocumento,
          'archivo_base64': base64String,
          'nombre_archivo': archivo.path.split('/').last,
          'mime_type': mimeType,
          'tamanio_kb': tamanioKb,
          'fecha_vencimiento':
              _fechasVencimiento[tipoDocumento]?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento subido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _cargarDocumentos();
        setState(() {
          _archivosSeleccionados[tipoDocumento] = null;
        });
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['error'] ?? 'Error desconocido al subir documento');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(String tipoDocumento) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _fechasVencimiento[tipoDocumento] = picked;
      });
    }
  }

  Future<void> _subirTodosLosDocumentos() async {
    // Verificar que hay al menos un documento seleccionado
    if (_archivosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero selecciona al menos un documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que los documentos que requieren fecha tengan fecha seleccionada
    List<String> documentosSinFecha = [];
    final documentosConFecha = ['SOAT', 'LICENCIA', 'TARJETA_PROPIEDAD'];

    for (var entry in _archivosSeleccionados.entries) {
      final tipoDocumento = entry.key;
      final archivo = entry.value;

      if (archivo != null && documentosConFecha.contains(tipoDocumento)) {
        if (_fechasVencimiento[tipoDocumento] == null) {
          String nombreDoc = tipoDocumento == 'SOAT'
              ? 'SOAT'
              : tipoDocumento == 'LICENCIA'
                  ? 'Licencia'
                  : 'Tarjeta de Propiedad';
          documentosSinFecha.add(nombreDoc);
        }
      }
    }

    if (documentosSinFecha.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Falta seleccionar fecha de vencimiento para:\n${documentosSinFecha.join('\n')}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    int exitosos = 0;
    int fallidos = 0;
    List<String> errores = [];

    for (var entry in _archivosSeleccionados.entries) {
      final tipoDocumento = entry.key;
      final archivo = entry.value;

      if (archivo == null) continue;

      try {
        // Obtener token de autenticación
        final token = await ApiService.getToken();
        if (token == null) {
          throw Exception('Token no encontrado');
        }

        // Convertir a base64
        final bytes = await archivo.readAsBytes();
        final base64String = base64Encode(bytes);
        final tamanioKb = (bytes.length / 1024).round();

        // Obtener nombre del archivo (compatible con web)
        final nombreArchivo = archivo.name;

        // Determinar MIME type
        String mimeType = 'image/jpeg';
        if (nombreArchivo.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (nombreArchivo.toLowerCase().endsWith('.pdf')) {
          mimeType = 'application/pdf';
        }

        final response = await http.post(
          Uri.parse('${Config.apiUrl}/documentos-conductor'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'id_conductor': widget.userId,
            'tipo_documento': tipoDocumento,
            'archivo_base64': base64String,
            'nombre_archivo': nombreArchivo,
            'mime_type': mimeType,
            'tamanio_kb': tamanioKb,
            'fecha_vencimiento':
                _fechasVencimiento[tipoDocumento]?.toIso8601String(),
          }),
        );

        if (response.statusCode == 200) {
          exitosos++;
        } else {
          fallidos++;
          final errorData = jsonDecode(response.body);
          String nombreDoc = tipoDocumento == 'FOTO_PERFIL'
              ? 'Foto de Perfil'
              : tipoDocumento == 'SOAT'
                  ? 'SOAT'
                  : tipoDocumento == 'LICENCIA'
                      ? 'Licencia'
                      : tipoDocumento == 'TARJETA_PROPIEDAD'
                          ? 'Tarjeta de Propiedad'
                          : tipoDocumento;
          errores
              .add('$nombreDoc: ${errorData['error'] ?? 'Error desconocido'}');
        }
      } catch (e) {
        fallidos++;
        String nombreDoc = tipoDocumento == 'FOTO_PERFIL'
            ? 'Foto de Perfil'
            : tipoDocumento == 'SOAT'
                ? 'SOAT'
                : tipoDocumento == 'LICENCIA'
                    ? 'Licencia'
                    : tipoDocumento == 'TARJETA_PROPIEDAD'
                        ? 'Tarjeta de Propiedad'
                        : tipoDocumento;
        errores
            .add('$nombreDoc: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      // Mostrar resultado
      if (fallidos == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $exitosos documentos subidos exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ $exitosos exitosos, $fallidos fallidos\n${errores.join('\n')}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      // Recargar documentos y limpiar selección
      await _cargarDocumentos();
      setState(() {
        _archivosSeleccionados.clear();
      });
    }
  }

  Widget _buildDocumentoCard(String tipoDocumento, String nombreDocumento,
      {bool requiereFecha = false}) {
    final documento = _documentos[tipoDocumento];
    final archivoSeleccionado = _archivosSeleccionados[tipoDocumento];
    final fechaVencimiento = _fechasVencimiento[tipoDocumento];

    String estado = documento?['estado'] ?? 'NO_SUBIDO';
    Color estadoColor = Colors.grey;
    IconData estadoIcon = Icons.upload_file;

    switch (estado) {
      case 'APROBADO':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'PENDIENTE':
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
        break;
      case 'RECHAZADO':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreDocumento,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        estado == 'NO_SUBIDO' ? 'No subido' : estado,
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (documento?['motivo_rechazo'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motivo: ${documento['motivo_rechazo']}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (archivoSeleccionado != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        archivoSeleccionado.path.split('/').last,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _archivosSeleccionados[tipoDocumento] = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (requiereFecha) ...[
              OutlinedButton.icon(
                onPressed: () => _seleccionarFecha(tipoDocumento),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  fechaVencimiento == null
                      ? 'Seleccionar fecha de vencimiento'
                      : 'Vence: ${fechaVencimiento.day}/${fechaVencimiento.month}/${fechaVencimiento.year}',
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarImagen(tipoDocumento),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Seleccionar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: archivoSeleccionado == null || _isLoading
                        ? null
                        : () => _subirDocumento(tipoDocumento),
                    icon: const Icon(Icons.upload),
                    label: const Text('Subir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    // Contar documentos seleccionados
    final documentosSeleccionados =
        _archivosSeleccionados.values.where((file) => file != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos del Conductor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Documentos Requeridos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.esAgenteExterno
                              ? '• Foto de Perfil\n• SOAT\n• Licencia de Conducir\n• DNI\n• Tarjeta de Mantenimiento'
                              : '• Foto de Perfil\n• SOAT\n• Licencia de Conducir',
                          style: const TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Todos los documentos deben ser aprobados para poder ofrecer viajes.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Documentos obligatorios para todos
                  _buildDocumentoCard('FOTO_PERFIL', 'Foto de Perfil'),
                  _buildDocumentoCard('SOAT', 'SOAT', requiereFecha: true),
                  _buildDocumentoCard('LICENCIA', 'Licencia de Conducir',
                      requiereFecha: true),
                  _buildDocumentoCard('TARJETA_PROPIEDAD',
                      'Tarjeta de Propiedad / Mantenimiento',
                      requiereFecha: true),

                  // Documentos solo para agentes externos
                  if (widget.esAgenteExterno) ...[
                    _buildDocumentoCard('DNI', 'DNI'),
                  ],

                  // Espacio para el FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: documentosSeleccionados > 0
          ? FloatingActionButton.extended(
              onPressed: _subirTodosLosDocumentos,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text(
                'Subir Todos ($documentosSeleccionados)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
