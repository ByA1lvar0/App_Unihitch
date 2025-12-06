import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'trip_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService.getUser();
  }

  void _refreshUser() {
    setState(() {
      _userFuture = ApiService.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Perfil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(user: user),
                    ),
                  );
                  if (result == true) {
                    _refreshUser();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    user['nombre'][0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user['nombre'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${user['carrera'] ?? 'Sin carrera'} - ${user['universidad_nombre'] ?? ''}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(user['correo']),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(user['telefono'] ?? 'Sin teléfono'),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                          Icons.star, Colors.amber, '4.8', 'Calificación'),
                      _buildStat(
                          Icons.directions_car, Colors.blue, '127', 'Viajes'),
                      _buildStat(
                          Icons.savings, Colors.green, 'S/. 890', 'Ahorrados'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Badges conseguidos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBadge(
                            'Top Rider', Colors.amber, Icons.workspace_premium),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _buildBadge('5 Estrellas', Colors.blue, Icons.star),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBadge(
                            'Eco-Friendly', Colors.green, Icons.eco),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person, color: Colors.white),
                      label: const Text('EDITAR PERFIL',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TripHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('VER HISTORIAL'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('CONFIGURACIÓN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
