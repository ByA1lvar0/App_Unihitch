import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _carreraController;
  late TextEditingController _emergencyContact1Controller;
  late TextEditingController _emergencyContact2Controller;
  bool _isLoading = false;
  String _metodoPreferido = 'WHATSAPP';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user['nombre']);
    _telefonoController =
        TextEditingController(text: widget.user['telefono'] ?? '');
    _carreraController =
        TextEditingController(text: widget.user['carrera'] ?? '');

    // Parse emergency contacts
    String contactsStr = widget.user['contactos_emergencia'] ?? '';
    List<String> contacts = contactsStr.split(',');
    _emergencyContact1Controller =
        TextEditingController(text: contacts.isNotEmpty ? contacts[0] : '');
    _emergencyContact2Controller =
        TextEditingController(text: contacts.length > 1 ? contacts[1] : '');

    // Load emergency preference
    _loadEmergencyPreference();
  }

  Future<void> _loadEmergencyPreference() async {
    try {
      final preference =
          await ApiService.getEmergencyPreference(widget.user['id']);
      setState(() {
        _metodoPreferido = preference['metodo_preferido'] ?? 'WHATSAPP';
      });
    } catch (e) {
      print('Error loading emergency preference: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _telefonoController.dispose();
    _carreraController.dispose();
    _emergencyContact1Controller.dispose();
    _emergencyContact2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user profile
      await ApiService.updateUser(
        id: widget.user['id'],
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        carrera: _carreraController.text.trim(),
        contactosEmergencia: [
          _emergencyContact1Controller.text.trim(),
          _emergencyContact2Controller.text.trim()
        ].where((c) => c.isNotEmpty).join(','),
      );

      // Update emergency preference
      await ApiService.updateEmergencyPreference(
        widget.user['id'],
        _metodoPreferido,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
            context, true); // Retornar true para indicar que se guardó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExternalAgent = widget.user['es_agente_externo'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        widget.user['nombre'][0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!isExternalAgent) ...[
                TextFormField(
                  controller: _carreraController,
                  decoration: InputDecoration(
                    labelText: 'Carrera / Facultad',
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Ej. Ingeniería de Sistemas',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '+51 987 654 321',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 9) {
                      return 'El teléfono debe tener al menos 9 dígitos';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Contactos de Emergencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContact1Controller,
                decoration: InputDecoration(
                  labelText: 'Contacto de Emergencia 1',
                  prefixIcon:
                      const Icon(Icons.contact_phone, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Ej. Mamá: 999888777',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContact2Controller,
                decoration: InputDecoration(
                  labelText: 'Contacto de Emergencia 2 (Opcional)',
                  prefixIcon:
                      const Icon(Icons.contact_phone, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Ej. Papá: 999888777',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              const Text(
                'Configuración de Emergencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _metodoPreferido,
                decoration: InputDecoration(
                  labelText: 'Método de envío preferido',
                  prefixIcon: Icon(
                    _metodoPreferido == 'WHATSAPP' ? Icons.message : Icons.sms,
                    color: _metodoPreferido == 'WHATSAPP'
                        ? Colors.green
                        : Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Si falla, se usará el otro método como respaldo',
                  helperMaxLines: 2,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'WHATSAPP',
                    child: Row(
                      children: [
                        Icon(Icons.message, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('WhatsApp'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'SMS',
                    child: Row(
                      children: [
                        Icon(Icons.sms, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('SMS'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _metodoPreferido = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.user['correo'],
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El correo no puede ser modificado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
