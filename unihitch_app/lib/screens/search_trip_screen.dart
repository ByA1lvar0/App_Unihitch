import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key});

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  double maxPrice = 10;
  int numPasajeros = 1;
  List<dynamic> _viajes = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _buscarViajes() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final viajes = await ApiService.getViajes(
        origen:
            _origenController.text.isNotEmpty ? _origenController.text : null,
        destino:
            _destinoController.text.isNotEmpty ? _destinoController.text : null,
      );

      // Filtrar por precio máximo
      final viajesFiltrados = viajes.where((viaje) {
        final precio = double.tryParse(viaje['precio'].toString()) ?? 0;
        return precio <= maxPrice;
      }).toList();

      if (mounted) {
        setState(() {
          _viajes = viajesFiltrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Viaje'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origen
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.pink.shade300),
                          const SizedBox(width: 8),
                          const Text(
                            'Desde:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _origenController,
                        decoration: InputDecoration(
                          hintText: 'Ingresa el origen',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Destino
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red.shade300),
                          const SizedBox(width: 8),
                          const Text(
                            'Hasta:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _destinoController,
                        decoration: InputDecoration(
                          hintText: 'Ingresa el destino',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pasajeros
                      Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 8),
                          const Text(
                            'Pasajeros:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: numPasajeros,
                            items: [1, 2, 3, 4].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                numPasajeros = newValue ?? 1;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Precio máximo
                      Text(
                        'Precio máximo: S/. ${maxPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: maxPrice,
                        min: 0,
                        max: 50,
                        divisions: 10,
                        activeColor: Colors.purple,
                        label: 'S/. ${maxPrice.toStringAsFixed(0)}',
                        onChanged: (value) {
                          setState(() {
                            maxPrice = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón de búsqueda
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buscarViajes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : const Text('BUSCAR VIAJES'),
                ),
              ),
              const SizedBox(height: 32),

              // Resultados
              if (_hasSearched) ...[
                Text(
                  _viajes.isEmpty
                      ? 'No se encontraron viajes'
                      : 'Viajes Disponibles (${_viajes.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_viajes.isNotEmpty)
                  ..._viajes.map((viaje) => _buildTripCard(viaje)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> viaje) {
    final precio = double.tryParse(viaje['precio'].toString()) ?? 0;
    final asientosDisponibles = viaje['asientos_disponibles'] ?? 0;
    final asientosTotales = viaje['asientos_totales'] ?? 0;
    final conductorNombre = viaje['conductor_nombre'] ?? 'Conductor';
    final calificacion = viaje['calificacion_promedio']?.toString() ?? '0.0';

    // Formatear fecha
    String fechaTexto = 'Próximamente';
    if (viaje['fecha_hora'] != null) {
      try {
        final fecha = DateTime.parse(viaje['fecha_hora']);
        final ahora = DateTime.now();
        final diferencia = fecha.difference(ahora);

        if (diferencia.inMinutes < 60) {
          fechaTexto = 'Sale en ${diferencia.inMinutes} min';
        } else if (diferencia.inHours < 24) {
          fechaTexto = 'Sale en ${diferencia.inHours} h';
        } else {
          fechaTexto = DateFormat('dd/MM HH:mm').format(fecha);
        }
      } catch (e) {
        fechaTexto = viaje['fecha_hora'].toString();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_car, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conductorNombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(calificacion),
                    ],
                  ),
                  Text(
                    '${viaje['origen']} → ${viaje['destino']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      Text(' $fechaTexto'),
                      const SizedBox(width: 12),
                      const Icon(Icons.people, size: 14),
                      Text(' $asientosDisponibles/$asientosTotales asientos'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'S/ ${precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: asientosDisponibles > 0
                      ? () async {
                          try {
                            final user = await ApiService.getUser();
                            await ApiService.createReserva(
                              idViaje: viaje['id'],
                              idPasajero: user!['id'],
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('¡Reserva realizada con éxito!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _buscarViajes(); // Refresh
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
                      : null,
                  child: const Text('SOLICITAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    super.dispose();
  }
}
