import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'upload_documents_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _precioController = TextEditingController();
  final _asientosController = TextEditingController(text: '4');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkDocumentStatus();
  }

  Future<void> _checkDocumentStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        final status = await ApiService.getDocumentStatus(user['id']);
        if (status != null && status['puede_ofrecer_viajes'] == false) {
          if (mounted) {
            _showRestrictionDialog(status, user['id']);
          }
        }
      }
    } catch (e) {
      print('Error checking documents: $e');
      if (mounted) {
        if (e.toString().contains('401') ||
            e.toString().toLowerCase().contains('unauthorized')) {
          // Token expirado o inválido, redirigir al login
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Tu sesión ha expirado. Por favor inicia sesión nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Otro error
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('No se pudo verificar tus documentos: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back
                  },
                  child: const Text('VOLVER'),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRestrictionDialog(Map<String, dynamic> status, int userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Documentos Requeridos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para ofrecer viajes, necesitas tener los siguientes documentos aprobados:',
            ),
            const SizedBox(height: 12),
            ...status['documentos_faltantes']
                .map<Widget>((doc) => ListTile(
                      leading:
                          const Icon(Icons.error_outline, color: Colors.red),
                      title: Text(doc.toString().replaceAll('_', ' ')),
                      dense: true,
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UploadDocumentsScreen(userId: userId),
                ),
              );
            },
            child: const Text('SUBIR DOCUMENTOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await ApiService.getUser();
      final fechaHora = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ApiService.createViaje(
        idConductor: user!['id'],
        origen: _origenController.text.trim(),
        destino: _destinoController.text.trim(),
        fechaHora: fechaHora.toIso8601String(),
        precio: double.parse(_precioController.text),
        asientosDisponibles: int.parse(_asientosController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Viaje creado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Viaje'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ofrece un viaje',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Origen
              TextFormField(
                controller: _origenController,
                decoration: const InputDecoration(
                  labelText: 'Origen *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trip_origin),
                  hintText: 'Ej: UDEP',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el origen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Destino
              TextFormField(
                controller: _destinoController,
                decoration: const InputDecoration(
                  labelText: 'Destino *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Ej: Plaza de Armas',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el destino';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Fecha
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              // Hora
              ListTile(
                title: const Text('Hora'),
                subtitle: Text(_selectedTime.format(context)),
                leading: const Icon(Icons.access_time),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              // Precio
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio por persona *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Ej: 5.00',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Asientos
              TextFormField(
                controller: _asientosController,
                decoration: const InputDecoration(
                  labelText: 'Asientos disponibles *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_seat),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa los asientos';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num < 1 || num > 8) {
                    return 'Entre 1 y 8 asientos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Botón Crear
              ElevatedButton(
                onPressed: _isLoading ? null : _createTrip,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREAR VIAJE', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    _precioController.dispose();
    _asientosController.dispose();
    super.dispose();
  }
}
