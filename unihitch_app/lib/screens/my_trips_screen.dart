import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'trip_tracking_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _misViajes = [];
  List<dynamic> _misReservas = [];
  bool _isLoading = true;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadData();
    });
  }

  String _getStatusText(String status, String fechaHora) {
    // Si la fecha ya pasó
    final fecha = DateTime.parse(fechaHora);
    if (fecha.isBefore(DateTime.now())) {
      if (status == 'CONFIRMADA') return 'USADA';
      if (status == 'DISPONIBLE') return 'PASADA';
    }
    return status;
  }

  Color _getStatusColor(String statusText) {
    switch (statusText) {
      case 'USADA':
      case 'COMPLETADA':
        return Colors.blue;
      case 'PASADA':
        return Colors.grey;
      case 'CONFIRMADA':
      case 'DISPONIBLE':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _loadData() async {
    // Cargar datos sin borrar estado actual para evitar parpadeo
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        final viajes = await ApiService.getMisViajes(user['id']);
        final reservas = await ApiService.getMisReservas(user['id']);

        if (mounted) {
          setState(() {
            _misViajes = viajes;
            _misReservas = reservas;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error polling trips: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Viajes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Como Conductor'),
            Tab(text: 'Como Pasajero'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConductorTab(),
                _buildPasajeroTab(),
              ],
            ),
    );
  }

  Widget _buildConductorTab() {
    if (_misViajes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No has creado viajes aún',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _misViajes.length,
      itemBuilder: (context, index) {
        final viaje = _misViajes[index];
        final fecha = DateTime.parse(viaje['fecha_hora']);
        final precio = double.tryParse(viaje['precio'].toString()) ?? 0.0;
        final statusText = _getStatusText(viaje['estado'], viaje['fecha_hora']);
        final statusColor = _getStatusColor(statusText);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trip_origin, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viaje['origen'],
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viaje['destino'],
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (viaje['estado'] == 'DISPONIBLE' ||
                    viaje['estado'] == 'EN_CURSO') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final tripData = {
                          'id': viaje['id'],
                          'origen': viaje['origen'],
                          'destino': viaje['destino'],
                          'conductor_nombre': 'Tú (Conductor)',
                          'fecha_hora': viaje['fecha_hora'],
                        };

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TripTrackingScreen(
                                      tripId: viaje['id'],
                                      tripData: tripData,
                                    )));
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('INICIAR RUTA / SEGUIMIENTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasajeroTab() {
    if (_misReservas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No has reservado viajes aún',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _misReservas.length,
      itemBuilder: (context, index) {
        final reserva = _misReservas[index];
        final fecha = DateTime.parse(reserva['fecha_hora']);
        final precio = double.tryParse(reserva['precio'].toString()) ?? 0.0;
        final statusText =
            _getStatusText(reserva['estado'], reserva['fecha_hora']);
        final statusColor = _getStatusColor(statusText);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 20,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conductor',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            reserva['conductor_nombre'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trip_origin, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reserva['origen'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reserva['destino'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (reserva['estado'] == 'CONFIRMADA' ||
                    reserva['estado'] == 'EN_CURSO') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final tripData = {
                          'id': reserva['id_viaje'],
                          'origen': reserva['origen'],
                          'destino': reserva['destino'],
                          'conductor_nombre': reserva['conductor_nombre'],
                          'fecha_hora': reserva['fecha_hora'],
                        };

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TripTrackingScreen(
                                      tripId: reserva['id_viaje'],
                                      tripData: tripData,
                                    )));
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('SEGUIR VIAJE EN TIEMPO REAL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}
