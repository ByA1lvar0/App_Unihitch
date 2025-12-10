import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_recharge_approval_screen.dart';
import 'admin_documents_screen.dart';
import 'admin_withdrawals_screen.dart';
import 'admin_dashboard_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingUsers = [];
  List<dynamic> _allUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  final _emailController = TextEditingController();
  int _userDirectoryKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadPendingUsers();
    _loadAllUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getPendingUsers();
      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await ApiService.getAllVerifiedUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando usuarios: $e')),
        );
      }
    }
  }

  Future<void> _verifyUser(int userId) async {
    try {
      await ApiService.verifyUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario verificado correctamente')),
      );
      _loadPendingUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addAdmin() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo')),
      );
      return;
    }

    try {
      await ApiService.addAdmin(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador agregado correctamente')),
      );
      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Directorio Global'),
            Tab(text: 'Historial de Viajes'),
            Tab(text: 'Verificar Usuarios'),
            Tab(text: 'Gestionar Admins'),
            Tab(text: 'Recargas'),
            Tab(text: 'Retiros'),
            Tab(text: 'Documentos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Dashboard
          const AdminDashboardTab(),

          // Tab 2: Directorio Global (Todos los usuarios)
          _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _allUsers.isEmpty
                  ? const Center(child: Text('No hay usuarios registrados'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];

                        return _UserDirectoryCard(
                          user: user,
                          onStatusChanged: () {
                            // Reload the entire user list
                            _loadAllUsers();
                          },
                        );
                      },
                    ),

          // Tab 3: Historial de Viajes
          FutureBuilder<List<dynamic>>(
            future: ApiService.getAdminTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final trips = snapshot.data ?? [];
              if (trips.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay viajes registrados',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  final fecha = DateTime.parse(trip['fecha_hora']);
                  final precio =
                      double.tryParse(trip['precio'].toString()) ?? 0.0;

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: trip['estado'] == 'COMPLETADO'
                            ? Colors.green
                            : Colors.orange,
                        child: const Icon(Icons.directions_car,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        '${trip['origen']} → ${trip['destino']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Conductor: ${trip['conductor_nombre'] ?? 'Desconocido'}\n${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'S/ ${precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            trip['estado'] ?? 'DESCONOCIDO',
                            style: TextStyle(
                              fontSize: 10,
                              color: trip['estado'] == 'COMPLETADO'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                        'Conductor: ${trip['conductor_correo'] ?? 'N/A'}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.airline_seat_recline_normal,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Asientos: ${trip['asientos_totales'] ?? 0}'),
                                  const SizedBox(width: 24),
                                  const Icon(Icons.people,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Reservas: ${trip['num_reservas'] ?? 0}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Tab 4: Verificar Usuarios
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingUsers.isEmpty
                  ? const Center(child: Text('No hay usuarios pendientes'))
                  : ListView.builder(
                      itemCount: _pendingUsers.length,
                      itemBuilder: (context, index) {
                        final user = _pendingUsers[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Text(
                                user['nombre'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(user['nombre']),
                            subtitle: Text(
                                '${user['universidad'] ?? 'Universidad'}\n${user['correo']}\nCódigo: ${user['codigo_universitario']}'),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              onPressed: () => _verifyUser(user['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Verificar'),
                            ),
                          ),
                        );
                      },
                    ),

          // Tab 2: Agregar Admin
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agregar Nuevo Administrador',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingresa el correo del usuario que deseas promover a administrador. Este usuario debe estar registrado previamente.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo del usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAdmin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('CONVERTIR EN ADMINISTRADOR'),
                  ),
                ),
              ],
            ),
          ),

          // Tab 3: Recargas
          FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data != null) {
                return AdminRechargeApprovalScreen(
                    adminId: snapshot.data!['id']);
              }
              return const Center(child: Text('Error al cargar usuario'));
            },
          ),

          // Tab 4: Retiros
          FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data != null) {
                return AdminWithdrawalsScreen(adminId: snapshot.data!['id']);
              }
              return const Center(child: Text('Error al cargar usuario'));
            },
          ),

          // Tab 5: Documentos
          FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data != null) {
                return AdminDocumentsScreen(adminId: snapshot.data!['id']);
              }
              return const Center(child: Text('Error al cargar usuario'));
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

// Widget para mostrar cada usuario con controles de habilitación
class _UserDirectoryCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onStatusChanged;

  const _UserDirectoryCard({
    required this.user,
    required this.onStatusChanged,
  });

  @override
  State<_UserDirectoryCard> createState() => _UserDirectoryCardState();
}

class _UserDirectoryCardState extends State<_UserDirectoryCard> {
  bool _isUpdating = false;

  Future<void> _toggleStatus(bool newValue) async {
    setState(() => _isUpdating = true);
    try {
      await ApiService.toggleUserStatus(
        userId: widget.user['id'],
        activo: newValue,
      );
      widget.user['activo'] = newValue; // Update local state
      widget.onStatusChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(newValue ? 'Usuario habilitado' : 'Usuario inhabilitado'),
            backgroundColor: newValue ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.user['verificado'] == true;
    final isActive = widget.user['activo'] ?? true;
    final role = widget.user['rol'] ?? 'USER';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? (isVerified ? Colors.blue : Colors.grey)
              : Colors.red.shade300,
          child: Text(
            widget.user['nombre'] != null
                ? widget.user['nombre'][0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          widget.user['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${widget.user['correo'] ?? ''}\nRol: $role | ${isActive ? "Activo" : "Inhabilitado"}',
          style: TextStyle(color: isActive ? Colors.black87 : Colors.grey),
        ),
        isThreeLine: true,
        trailing: _isUpdating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: isActive,
                onChanged: _toggleStatus,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              ),
      ),
    );
  }
}
