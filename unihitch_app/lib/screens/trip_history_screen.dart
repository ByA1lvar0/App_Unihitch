import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _passengerTrips = [];
  List<dynamic> _driverTrips = [];
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        final history = await ApiService.getTripHistory(user['id']);
        if (mounted) {
          setState(() {
            _user = user;
            _passengerTrips = history['passenger_trips'] ?? [];
            _driverTrips = history['driver_trips'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Como Pasajero'),
            Tab(text: 'Como Conductor'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripList(_passengerTrips, isDriver: false),
                _buildTripList(_driverTrips, isDriver: true),
              ],
            ),
    );
  }

  Widget _buildTripList(List<dynamic> trips, {required bool isDriver}) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isDriver
                  ? 'No has realizado viajes como conductor'
                  : 'No has realizado viajes como pasajero',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        final date = DateTime.parse(trip['fecha_hora']);
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDriver ? Colors.blue[100] : Colors.green[100],
              child: Icon(
                isDriver ? Icons.directions_car : Icons.person,
                color: isDriver ? Colors.blue : Colors.green,
              ),
            ),
            title: Text('${trip['origen']} → ${trip['destino']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(formattedDate),
                Text(
                  'S/. ${trip['precio']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                trip['estado'] ?? 'FINALIZADO',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getStatusColor(trip['estado']),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PROGRAMADO':
        return Colors.blue;
      case 'EN_CURSO':
        return Colors.orange;
      case 'FINALIZADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
