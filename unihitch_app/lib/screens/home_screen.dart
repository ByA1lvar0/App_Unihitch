import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../services/api_service.dart';
import 'login_screen.dart';
import 'create_trip_screen.dart';
import 'my_trips_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'search_trip_screen.dart';
import 'my_wallet_screen.dart';
import 'communities_list_screen.dart';
import 'chat_list_screen.dart';
import 'admin_screen.dart';
import 'notifications_screen.dart';
import 'sos_emergency_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _user;
  List<dynamic> _viajes = [];
  bool _isLoading = true;
  Position? _currentPosition;
  String _locationText = 'Buscando ubicación...';
  bool _locationError = false;
  LocationPermission? _permissionStatus;

  Timer? _notificationTimer;
  int _unreadNotificationsCount = 0;
  int _lastNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadData();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    _checkNotifications(); // Check immediately
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNotifications();
    });
  }

  Future<void> _checkNotifications() async {
    if (_user == null) return;
    try {
      final notifications = await ApiService.getNotifications(_user!['id']);
      // Simple logic: if count increases, we have new notifications
      // In a real app, we would check IDs or 'read' status
      int currentCount = notifications.length;

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = currentCount;
        });

        if (currentCount > _lastNotificationCount &&
            _lastNotificationCount != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Tienes nuevas notificaciones!'),
              backgroundColor: Colors.blue.shade700,
              action: SnackBarAction(
                label: 'VER',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationsScreen(userId: _user!['id']),
                    ),
                  );
                },
              ),
            ),
          );
        }
        _lastNotificationCount = currentCount;
      }
    } catch (e) {
      print('Error polling notifications: $e');
    }
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _permissionStatus = permission;
      });
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (mounted) {
        setState(() {
          _permissionStatus = permission;
        });
      }
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationError = false;
      _locationText = 'Buscando ubicación...';
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationText = 'Ubicación GPS activa';
          _locationError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Error al obtener ubicación';
          _locationError = true;
        });
      }
    }
  }

  Future<void> _loadData() async {
    final user = await ApiService.getUser();
    final viajes = await ApiService.getViajes();

    setState(() {
      _user = user;
      _viajes = viajes;
      _isLoading = false;
    });
  }

  Future<void> _reservarViaje(int idViaje) async {
    try {
      await ApiService.createReserva(
        idViaje: idViaje,
        idPasajero: _user!['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reserva realizada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Recargar viajes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Personalizado
              _buildCustomHeader(),
              // Banner con Información
              _buildInfoBanner(),
              // Botones de Acción
              _buildActionButtons(),
              // Lista de Viajes
              _buildViajesList(),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SOSEmergencyScreen(),
            ),
          );
        },
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.sos, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCustomHeader() {
    final userName = _user?['nombre']?.split(' ')[0] ?? 'Usuario';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 50, 8, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showDrawer,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hola, $userName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  if (_user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NotificationsScreen(userId: _user!['id']),
                      ),
                    );
                  }
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Mapa Dinámico con Leaflet (flutter_map)
            if (_currentPosition != null)
              FlutterMap(
                options: MapOptions(
                  initialCenter: latlng.LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.unihitch.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latlng.LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (_permissionStatus == LocationPermission.denied ||
                _permissionStatus == LocationPermission.deniedForever)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade800, Colors.grey.shade900],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_disabled,
                          color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Ubicación requerida',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _checkPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Activar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_locationError)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red.shade800, Colors.red.shade900],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Error de ubicación',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Fondo de carga si no hay ubicación y no está denegada
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.green.shade600,
                    ],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Overlay con gradiente para legibilidad del texto
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Contenido overlay (Texto)
            Positioned(
              left: 16,
              bottom: 16,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      Icons.location_on,
                      _locationText,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      Icons.directions_car,
                      '$_viajesCerca viajes cerca',
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      Icons.people,
                      '2 compañeros online',
                      color: Colors.white,
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

  int get _viajesCerca => _viajes.length > 3 ? 3 : _viajes.length;

  Widget _buildInfoItem(IconData icon, String text,
      {Color color = Colors.black}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buscando viajes...')),
                );
              },
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'BUSCAR VIAJE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateTripScreen()),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'OFRECER VIAJE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViajesList() {
    if (_viajes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          children: [
            Icon(Icons.directions_car, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay viajes disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Viajes Disponibles Cerca',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _viajes.length,
          itemBuilder: (context, index) {
            final viaje = _viajes[index];
            return _buildViajeCard(viaje);
          },
        ),
      ],
    );
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    final fecha = DateTime.parse(viaje['fecha_hora']);
    // final ahora = DateTime.now();
    // final diferencia = fecha.difference(ahora);
    // final minutosRestantes = diferencia.inMinutes; // Unused
    // final asientosTotales = (viaje['asientos_disponibles'] as int) +
    //     (viaje['asientos_totales'] ?? viaje['asientos_disponibles'] + 2) -
    //     viaje['asientos_disponibles'];
    // final asientosUsados = asientosTotales - (viaje['asientos_disponibles'] as int); // Unused

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                viaje['conductor_nombre'][0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          viaje['conductor_nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.9',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${viaje['carrera'] ?? 'Estudiante'} - ${viaje['universidad'] ?? 'Universidad'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        viaje['origen'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: Colors.grey),
                      Text(
                        viaje['destino'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Salida: ${DateFormat('HH:mm').format(fecha)}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${viaje['costo']}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _reservarViaje(viaje['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reservar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final userName = _user?['nombre'] ?? 'Usuario';
    final userEmail = _user?['correo'] ?? 'correo@ejemplo.com';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final bool isAdmin = _user?['es_admin'] == true || _user?['es_admin'] == 1;
    final bool isExternalAgent = _user?['es_agente_externo'] == true;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.green.shade600],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    userInitial,
                    style: TextStyle(fontSize: 24, color: Colors.blue.shade600),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Mis Viajes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTripsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Buscar Viaje'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SearchTripScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Ofrecer Viaje'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateTripScreen()),
              ).then((_) => _loadData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Billetera'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyWalletScreen()),
              );
            },
          ),
          if (!isExternalAgent)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Comunidades'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CommunitiesListScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chats'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.orange),
              title: const Text('Panel de Administrador',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchTripScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripScreen()),
          ).then((_) => _loadData());
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Publicar',
        ),
      ],
    );
  }
}
