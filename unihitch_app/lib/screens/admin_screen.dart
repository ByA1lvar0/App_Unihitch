import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_recharge_approval_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingUsers = [];
  bool _isLoading = false;
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingUsers();
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
          tabs: const [
            Tab(text: 'Verificar Usuarios'),
            Tab(text: 'Gestionar Admins'),
            Tab(text: 'Recargas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Verificar Usuarios
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
