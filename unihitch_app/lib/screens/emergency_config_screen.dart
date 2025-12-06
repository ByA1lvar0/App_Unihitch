import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmergencyConfigScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EmergencyConfigScreen({super.key, required this.user});

  @override
  State<EmergencyConfigScreen> createState() => _EmergencyConfigScreenState();
}

class _EmergencyConfigScreenState extends State<EmergencyConfigScreen> {
  List<dynamic> _contacts = [];
  Map<String, dynamic> _config = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = widget.user['id'];
      final contacts = await ApiService.getEmergencyContacts(userId);
      final config = await ApiService.getEmergencyConfig(userId);

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _config = config ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addContact(
      String nombre, String telefono, String relacion, bool esPrincipal) async {
    try {
      final success = await ApiService.addEmergencyContact(
        userId: widget.user['id'],
        nombre: nombre,
        telefono: telefono,
        relacion: relacion,
        esPrincipal: esPrincipal,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacto agregado correctamente')),
          );
        }
        _loadData(); // Reload list
      } else {
        throw Exception('Error al agregar contacto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteContact(int contactId) async {
    try {
      final success = await ApiService.deleteEmergencyContact(contactId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacto eliminado')),
          );
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    try {
      final success = await ApiService.updateEmergencyConfig(
        userId: widget.user['id'],
        autoEnvioUbicacion: _config['auto_envio_ubicacion'] ?? false,
        notificarUniversidad: _config['notificar_universidad'] ?? true,
        grabarAudio: _config['grabar_audio'] ?? true,
        alertasVelocidad: _config['alertas_velocidad'] ?? false,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    bool isPrincipal = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Contacto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(
                    labelText: 'Relación (ej: Mamá, Papá)',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Contacto principal'),
                  value: isPrincipal,
                  onChanged: (value) {
                    setDialogState(() {
                      isPrincipal = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _addContact(
                    nameController.text,
                    phoneController.text,
                    relationController.text,
                    isPrincipal,
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Configurar Emergencias',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contacts Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contactos de Emergencia:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact List
                  _contacts.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No hay contactos agregados',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _contacts.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            return ListTile(
                              leading: Icon(
                                Icons.person,
                                color: contact['es_principal'] == true
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              title: Text(contact['nombre'] ?? 'Sin nombre'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contact['telefono'] ?? ''),
                                  if (contact['relacion'] != null)
                                    Text(
                                      contact['relacion'],
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteContact(contact['id']),
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 16),

                  // Add Contact Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddContactDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('AGREGAR CONTACTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Advanced Configuration Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración Avanzada:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto-envío ubicación'),
                    subtitle: const Text('Enviar ubicación automáticamente'),
                    value: _config['auto_envio_ubicacion'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _config['auto_envio_ubicacion'] = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notificar a universidad'),
                    subtitle: const Text('Alertar a seguridad del campus'),
                    value: _config['notificar_universidad'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _config['notificar_universidad'] = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  SwitchListTile(
                    title: const Text('Grabar audio emergencia'),
                    subtitle: const Text('Grabar audio durante emergencia'),
                    value: _config['grabar_audio'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _config['grabar_audio'] = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  SwitchListTile(
                    title: const Text('Alertas por velocidad'),
                    subtitle: const Text('Notificar si excede velocidad'),
                    value: _config['alertas_velocidad'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _config['alertas_velocidad'] = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'GUARDAR CAMBIOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
