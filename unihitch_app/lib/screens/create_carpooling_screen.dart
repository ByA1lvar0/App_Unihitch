import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'carpooling_groups_screen.dart';

class CreateCarpoolingScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CreateCarpoolingScreen({super.key, required this.user});

  @override
  State<CreateCarpoolingScreen> createState() => _CreateCarpoolingScreenState();
}

class _CreateCarpoolingScreenState extends State<CreateCarpoolingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutaController = TextEditingController();
  final _costoController = TextEditingController();
  final _descripcionController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _tipoGrupo = 'MISMA_CARRERA';
  int _numPasajeros = 4;

  @override
  Widget build(BuildContext context) {
    final costoPorPersona =
        _costoController.text.isNotEmpty && _numPasajeros > 0
            ? (double.tryParse(_costoController.text) ?? 0) / _numPasajeros
            : 0;

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Crear Carpooling',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.group, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Organizar viaje\ncompartido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ruta común
                      const Text('🚗 Ruta común:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _rutaController,
                        decoration: InputDecoration(
                          hintText: '"UDEP → Chulucanas"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Horario preferido
                      const Text('🕐 Horario preferido:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')} PM',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Buscar compañeros
                      const Text('👥 Buscar compañeros:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      RadioListTile(
                        title: const Text('Misma carrera'),
                        value: 'MISMA_CARRERA',
                        groupValue: _tipoGrupo,
                        onChanged: (value) {
                          setState(() {
                            _tipoGrupo = value as String;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      RadioListTile(
                        title: const Text('Misma universidad'),
                        value: 'MISMA_UNIVERSIDAD',
                        groupValue: _tipoGrupo,
                        onChanged: (value) {
                          setState(() {
                            _tipoGrupo = value as String;
                          });
                        },
                      ),
                      RadioListTile(
                        title: const Text('Cualquier estudiante'),
                        value: 'CUALQUIERA',
                        groupValue: _tipoGrupo,
                        onChanged: (value) {
                          setState(() {
                            _tipoGrupo = value as String;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Costo
                      const Text('💰 Costo por persona:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costoController,
                              decoration: InputDecoration(
                                labelText: 'Costo total:',
                                prefixText: 'S/. ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _numPasajeros.toString(),
                              decoration: InputDecoration(
                                labelText: 'Pasajeros:',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _numPasajeros = int.tryParse(value) ?? 4;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Por persona:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'S/. ${costoPorPersona.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Descripción
                      const Text('📝 Descripción:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await ApiService.createCarpoolingGroup(
                            organizadorId: widget.user['id'],
                            rutaComun: _rutaController.text,
                            horarioPreferido:
                                '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            tipoGrupo: _tipoGrupo,
                            costoTotal:
                                double.tryParse(_costoController.text) ?? 0.0,
                            numPasajeros: _numPasajeros,
                            descripcion: _descripcionController.text,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Grupo de carpooling creado con éxito'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
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
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CREAR GRUPO',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CarpoolingGroupsScreen(user: widget.user),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('BUSCAR GRUPOS',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
