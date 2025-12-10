import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await ApiService.getAdminDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    // Prepare data for display
    final totalUsers = _stats!['totalUsers'] ?? 0;
    final completedTrips = _stats!['completedTrips'] ?? 0;
    final avgRating = _stats!['avgRating']?.toString() ?? '0.0';
    final activeUsers = _stats!['activeUsersLast30d'] ?? 0;
    final avgMatchTime = _stats!['avgMatchTimeMin'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Métricas de Negocio',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Resumen del rendimiento de la plataforma',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Usuarios Registrados',
                totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Viajes Completados',
                completedTrips.toString(),
                Icons.directions_car,
                Colors.green,
              ),
              _buildStatCard(
                'Calificación Prom.',
                avgRating,
                Icons.star,
                Colors.amber,
              ),
              _buildStatCard(
                'Retención (30d)',
                '$activeUsers Activos',
                Icons.repeat,
                Colors.purple,
              ),
              _buildStatCard(
                'Tiempo Emparejamiento',
                '$avgMatchTime min',
                Icons.timer,
                Colors.orange,
              ),
              _buildStatCard(
                'Estado del Sistema',
                'Operativo',
                Icons.check_circle,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
