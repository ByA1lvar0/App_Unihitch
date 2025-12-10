import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AdminDocumentsScreen extends StatefulWidget {
  final int adminId;

  const AdminDocumentsScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  List<dynamic> _pendingDocuments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingDocuments();
  }

  Future<void> _loadPendingDocuments() async {
    setState(() => _isLoading = true);
    try {
      final documents = await ApiService.getPendingDocuments();
      setState(() {
        _pendingDocuments = documents;
      });
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

  Future<void> _approveDocument(int documentId) async {
    try {
      await ApiService.approveDocument(
        documentId: documentId,
        adminId: widget.adminId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento aprobado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadPendingDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectDocument(int documentId) async {
    final TextEditingController motivoController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el motivo del rechazo:'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (result == true && motivoController.text.isNotEmpty) {
      try {
        await ApiService.rejectDocument(
          documentId: documentId,
          adminId: widget.adminId,
          motivo: motivoController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento rechazado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await _loadPendingDocuments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al rechazar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewDocument(dynamic document) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    document['tipo_documento'] ?? 'Documento',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Conductor: ${document['conductor_nombre']}'),
              Text('Correo: ${document['conductor_correo']}'),
              Text('Archivo: ${document['nombre_archivo']}'),
              Text('Tamaño: ${document['tamanio_kb']} KB'),
              if (document['fecha_vencimiento'] != null)
                Text('Vencimiento: ${document['fecha_vencimiento']}'),
              const SizedBox(height: 16),
              const Text(
                'Vista previa:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: document['mime_type']?.startsWith('image/') == true
                    ? Image.memory(
                        base64Decode(document['archivo_base64']),
                        fit: BoxFit.contain,
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description, size: 64),
                            SizedBox(height: 8),
                            Text('Vista previa no disponible para PDF'),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _rejectDocument(document['id']);
                    },
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _approveDocument(document['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Aprobar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingDocuments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No hay documentos pendientes',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _pendingDocuments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: const Icon(Icons.pending, color: Colors.white),
                        ),
                        title: Text(
                          doc['tipo_documento'] ?? 'Documento',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Conductor: ${doc['conductor_nombre']}'),
                            Text('Correo: ${doc['conductor_correo']}'),
                            Text('Archivo: ${doc['nombre_archivo']}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility,
                                  color: Colors.blue),
                              onPressed: () => _viewDocument(doc),
                              tooltip: 'Ver documento',
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveDocument(doc['id']),
                              tooltip: 'Aprobar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectDocument(doc['id']),
                              tooltip: 'Rechazar',
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
