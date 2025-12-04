import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        final stats = await ApiService.getUserStatistics(user['id']);
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('No hay estadísticas disponibles'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Como Conductor
                      _buildSectionTitle('Como Conductor', Icons.drive_eta),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        'Viajes Realizados',
                        _stats!['as_driver']['total_trips'].toString(),
                        Icons.directions_car,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Pasajeros Transportados',
                        _stats!['as_driver']['total_passengers'].toString(),
                        Icons.people,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Dinero Ganado',
                        'S/. ${_stats!['as_driver']['money_earned']}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Calificación Promedio',
                        '⭐ ${_stats!['as_driver']['average_rating']}',
                        Icons.star,
                        Colors.amber,
                      ),

                      const SizedBox(height: 24),

                      // Como Pasajero
                      _buildSectionTitle('Como Pasajero', Icons.person),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        'Viajes Realizados',
                        _stats!['as_passenger']['total_trips'].toString(),
                        Icons.directions_car,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Dinero Gastado',
                        'S/. ${_stats!['as_passenger']['money_spent']}',
                        Icons.payment,
                        Colors.red,
                      ),

                      const SizedBox(height: 24),

                      // Impacto Ambiental
                      _buildSectionTitle('Impacto Ambiental', Icons.eco),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade700
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.eco,
                                  size: 48, color: Colors.white),
                              const SizedBox(height: 12),
                              Text(
                                '${_stats!['overall']['co2_saved_kg']} kg',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'de CO₂ ahorrado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
