import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CarpoolingGroupsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CarpoolingGroupsScreen({super.key, required this.user});

  @override
  State<CarpoolingGroupsScreen> createState() => _CarpoolingGroupsScreenState();
}

class _CarpoolingGroupsScreenState extends State<CarpoolingGroupsScreen> {
  List<dynamic> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await ApiService.getCarpoolingGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
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

  Future<void> _joinGroup(int groupId) async {
    try {
      await ApiService.joinCarpoolingGroup(
        groupId: groupId,
        userId: widget.user['id'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido al grupo exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadGroups(); // Reload to update UI
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos de Carpooling'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Text(
                    'No hay grupos disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return _buildGroupCard(group);
                    },
                  ),
                ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final miembrosActuales = group['miembros_actuales'] ?? 0;
    final numPasajeros = group['num_pasajeros'] ?? 0;
    final isComplete = miembrosActuales >= numPasajeros;
    final costoPorPersona = group['costo_por_persona'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.group, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['ruta_comun'] ?? 'Ruta no especificada',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Organizador: ${group['organizador_nombre'] ?? 'Desconocido'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.grey : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isComplete ? 'COMPLETO' : 'ABIERTO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time,
                    'Horario',
                    group['horario_preferido'] ?? 'No especificado',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.people,
                    'Miembros',
                    '$miembrosActuales/$numPasajeros',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.school,
                    'Tipo',
                    _getTipoGrupoLabel(group['tipo_grupo']),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.attach_money,
                    'Costo',
                    'S/. ${costoPorPersona.toStringAsFixed(1)}/persona',
                  ),
                ),
              ],
            ),

            if (group['descripcion'] != null &&
                group['descripcion'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                group['descripcion'],
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],

            const SizedBox(height: 16),

            // Join Button
            if (!isComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _joinGroup(group['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('UNIRSE AL GRUPO'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTipoGrupoLabel(String? tipo) {
    switch (tipo) {
      case 'MISMA_CARRERA':
        return 'Misma carrera';
      case 'MISMA_UNIVERSIDAD':
        return 'Misma universidad';
      case 'CUALQUIERA':
        return 'Cualquier estudiante';
      default:
        return 'No especificado';
    }
  }
}
