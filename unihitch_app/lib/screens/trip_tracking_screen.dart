import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/directions_service.dart';
import 'package:geocoding/geocoding.dart';
import 'sos_emergency_screen.dart';
import 'chat_screen.dart';
import '../services/message_service.dart';

class TripTrackingScreen extends StatefulWidget {
  final int tripId;
  final Map<String, dynamic> tripData;

  const TripTrackingScreen({
    super.key,
    required this.tripId,
    required this.tripData,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  Map<String, dynamic>? _user;
  List<dynamic> _ubicaciones = [];
  List<Marker> _markers = [];
  List<LatLng> _routePoints = [];
  Map<String, dynamic>? _tripStats;
  Position? _lastPosition;
  double _currentBearing = 0.0;
  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRatingShown = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _user = await ApiService.getUser();
      await _getCurrentLocation();
      await _loadTripLocations();
      _startLocationTracking();
      _startPeriodicRefresh();
      _drawRoute();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        // Set initial bearing if available
        if (position.heading > 0) {
          _currentBearing = position.heading;
        }
      });
    }
  }

  void _startLocationTracking() {
    _positionStreamSubscription =
        LocationService.getLocationStream().listen((Position position) async {
      if (mounted) {
        // Calculate bearing for smooth rotation
        if (_lastPosition != null) {
          final bearing = Geolocator.bearingBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          // Only update if moved significantly to avoid jitter
          if (Geolocator.distanceBetween(
                  _lastPosition!.latitude,
                  _lastPosition!.longitude,
                  position.latitude,
                  position.longitude) >
              2) {
            _currentBearing = bearing;
          }
        }

        setState(() {
          _lastPosition = _currentPosition;
          _currentPosition = position;
        });
      }

      // Actualizar ubicación en el servidor
      try {
        if (_user != null) {
          await ApiService.updateUserLocation(
            userId: _user!['id'],
            tripId: widget.tripId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      } catch (e) {
        debugPrint('Error actualizando ubicación: $e');
      }
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadTripLocations();
    });
  }

  Future<void> _loadTripLocations() async {
    try {
      final data = await ApiService.getTripLocations(widget.tripId);

      if (!mounted) return;

      // Build ubicaciones list from conductor and pasajeros
      final List<dynamic> ubicaciones = [];

      if (data['conductor'] != null) {
        ubicaciones.add({
          ...data['conductor'],
          'rol': 'conductor',
        });
      }

      if (data['pasajeros'] != null) {
        for (var pasajero in data['pasajeros']) {
          ubicaciones.add({
            ...pasajero,
            'rol': 'pasajero',
          });
        }
      }

      setState(() {
        _ubicaciones = ubicaciones;
        _updateMarkers();
      });

      // Intentar dibujar la ruta nuevamente con las nuevas ubicaciones
      _drawRoute();
    } catch (e) {
      debugPrint('Error cargando ubicaciones: $e');
    }
  }

  void _updateMarkers() {
    final List<Marker> markers = [];

    for (var ubicacion in _ubicaciones) {
      if (ubicacion['latitud'] != null && ubicacion['longitud'] != null) {
        final isDriver = ubicacion['rol'] == 'conductor';

        // Use computed bearing for current user driver, otherwise 0 or estimted
        double rotation = 0.0;
        if (isDriver &&
            _user != null &&
            ubicacion['id_usuario'] == _user!['id']) {
          rotation = _currentBearing; // My car
        }
        // Note: For other drivers we would need their heading from server,
        // but for now we only rotate our own car or if we tracked history.
        // Static for others is safer than random rotation.

        markers.add(
          Marker(
            point: LatLng(
              ubicacion['latitud'].toDouble(),
              ubicacion['longitud'].toDouble(),
            ),
            width: 80,
            height: 80,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(blurRadius: 2, color: Colors.black26)
                    ],
                  ),
                  child: Text(
                    ubicacion['nombre'] ?? 'Usuario',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Transform.rotate(
                    angle: isDriver ? (rotation * 3.14159 / 180) : 0,
                    child: Icon(
                      isDriver
                          ? Icons.directions_car_filled
                          : Icons.person_pin_circle,
                      color: isDriver ? Colors.blue : Colors.green,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _drawRoute() async {
    try {
      if (_currentPosition == null || _ubicaciones.isEmpty) return;

      final driver = _ubicaciones.firstWhere(
        (u) => u['rol'] == 'conductor',
        orElse: () => null,
      );

      if (driver == null ||
          driver['latitud'] == null ||
          driver['longitud'] == null) {
        return;
      }

      // Lógica de ruta: Siempre desde el Conductor hacia el Destino/Pasajero
      final myId = _user?['id'];
      final driverId =
          driver['id_usuario']; // Asegurarse que coincida con la DB
      final isDriver = myId == driverId;

      LatLng origin;
      LatLng destination;

      if (!isDriver) {
        // Soy Pasajero: Ruta desde Conductor (Origen) -> Yo (Destino)
        origin = LatLng(
          driver['latitud'].toDouble(),
          driver['longitud'].toDouble(),
        );
        destination =
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      } else {
        // Soy Conductor: Ruta desde Yo (Origen) -> Hacia:
        // 1. Primer Pasajero (si está conectado y tiene ubicación)
        // 2. Destino del viaje (Geocodificado)

        final firstPassenger = _ubicaciones.firstWhere(
          (u) => u['rol'] == 'pasajero' && u['latitud'] != null,
          orElse: () => null,
        );

        if (firstPassenger != null) {
          // Opción 1: Ruta hacia el pasajero
          origin =
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
          destination = LatLng(
            firstPassenger['latitud'].toDouble(),
            firstPassenger['longitud'].toDouble(),
          );
        } else {
          // Opción 2: Ruta hacia el destino del viaje (Geocoding)
          // Si no hay pasajeros con ubicación, intentamos ir al destino del viaje
          final String? destinoTexto = widget.tripData['destino'];
          if (destinoTexto == null || destinoTexto.isEmpty) return;

          try {
            // Intentar obtener coordenadas del texto del destino
            List<Location> locations = await locationFromAddress(destinoTexto);
            if (locations.isNotEmpty) {
              origin = LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude);
              destination =
                  LatLng(locations.first.latitude, locations.first.longitude);
            } else {
              debugPrint('No se pudo geocodificar el destino: $destinoTexto');
              return;
            }
          } catch (e) {
            debugPrint('Error geocodificando destino: $e');
            return;
          }
        }
      }

      final routeData = await DirectionsService.getRoute(origin, destination);
      final routePoints = routeData['points'] as List<LatLng>;

      if (routePoints.isNotEmpty && mounted) {
        setState(() {
          _routePoints = routePoints;
          _tripStats = {
            'duration': routeData['duration'],
            'distance': routeData['distance'],
            'eta_seconds': routeData['duration_value']
          };
        });
      }
    } catch (e) {
      debugPrint('Error al dibujar la ruta: $e');
    }
  }

  void _centerOnMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0, // Zoom level
      );
    }
  }

  void _showRatingSheet() {
    // ... Implementación idéntica a la anterior (solo UI local) ...
    // Copiamos la lógica existente para no perder funcionalidad
    if (_isRatingShown) return;
    _isRatingShown = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          int selectedRating = 0;
          final commentController = TextEditingController();
          bool isSubmitting = false;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Califica tu viaje',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Qué tal estuvo el conductor?',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        size: 40,
                      ),
                      color: Colors.amber,
                      onPressed: () {
                        setModalState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Deja un comentario (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (selectedRating == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Por favor selecciona una calificación')),
                              );
                              return;
                            }

                            // RF-015: Comentarios obligatorios para ratings < 3
                            if (selectedRating < 3 &&
                                commentController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Por favor deja un comentario explicando tu calificación baja'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            try {
                              final driver = _ubicaciones.firstWhere(
                                (u) => u['rol'] == 'conductor',
                                orElse: () => null,
                              );

                              if (driver == null) {
                                throw Exception(
                                    'No se encontró información del conductor');
                              }

                              await ApiService.rateUser(
                                tripId: widget.tripId,
                                authorId: _user!['id'],
                                targetUserId: driver['id'],
                                rating: selectedRating,
                                comment: commentController.text,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '¡Gracias por tu calificación!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: ${e.toString()}')),
                                );
                                setModalState(() => isSubmitting = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('ENVIAR CALIFICACIÓN'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => _isRatingShown = false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionStreamSubscription?.cancel();
    // _mapController.dispose(); // MapController doesn't have dispose in FlutterMap 6+ usually
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando mapa...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          // Share Button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: _shareTrip,
              tooltip: 'Compartir viaje',
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                HapticFeedback.selectionClick();
                _loadTripLocations();
              },
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa (FlutterMap + OSM)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(-12.046374, -77.042793), // Lima por defecto
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.unihitch.app',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  // Marcador de mi ubicación
                  if (_currentPosition != null)
                    Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 60,
                        height: 60,
                        child: Column(
                          children: [
                            // Only show arrow if I'm NOT the driver (otherwise logic above handles it)
                            // Actually above logic handles "My Car" if I am driver.
                            // If I am passenger, I am a "person_pin", maybe no rotation needed.
                            // But let's rotate the "My Location" arrow anyway for realism.
                            Transform.rotate(
                              angle: _currentBearing * 3.14159 / 180,
                              child: const Icon(Icons.navigation,
                                  color: Colors.blueAccent, size: 30),
                            ),
                          ],
                        )),
                ],
              ),
            ],
          ),

          // Botón de Mi Ubicación
          Positioned(
            bottom: 260,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: () {
                HapticFeedback.selectionClick();
                _centerOnMyLocation();
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // Botón de Emergencia SOS
          Positioned(
            bottom: 190,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'emergency',
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SOSEmergencyScreen(
                      tripData: widget.tripData,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.sos, color: Colors.white, size: 28),
            ),
          ),

          // Botón Calificar
          Positioned(
            bottom: 120,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat with Driver Button (Only for Passengers)
                if (_user != null && !_isUserDriver())
                  FloatingActionButton(
                    heroTag: 'chat_driver',
                    onPressed: _openChatWithDriver,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.chat, color: Colors.white),
                  ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'rate',
                  onPressed: _showRatingSheet,
                  backgroundColor: Colors.amber,
                  child: const Icon(Icons.star, color: Colors.white),
                ),
              ],
            ),
          ),

          // Trip Stats Card
          if (_tripStats != null)
            Positioned(
              top: 100, // Below AppBar
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(height: 4),
                          Text(_tripStats!['duration'] ?? '--',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.directions_car,
                              color: Colors.black87),
                          const SizedBox(height: 4),
                          Text('En ruta',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.straighten, color: Colors.orange),
                          const SizedBox(height: 4),
                          Text(_tripStats!['distance'] ?? '--',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Panel de pasajeros
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPassengersPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersPanel() {
    final passengers =
        _ubicaciones.where((u) => u['rol'] == 'pasajero').toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'En viaje',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          '${passengers.length} Pasajeros',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de pasajeros
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: passengers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_outline,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Esperando pasajeros...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: passengers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(indent: 70),
                    itemBuilder: (context, index) {
                      final passenger = passengers[index];
                      final isConnected =
                          passenger['estado_conexion'] == 'conectado';

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            passenger['nombre'][0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          passenger['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.star,
                                size: 14, color: Colors.amber.shade600),
                            const SizedBox(width: 4),
                            const Text('4.8', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.message, color: Colors.blue),
                              onPressed: () => _openChatWithUser(
                                  passenger['id_usuario'], passenger['nombre']),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isConnected ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isConnected
                                            ? Colors.green
                                            : Colors.grey)
                                        .withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool _isUserDriver() {
    if (_user == null || _ubicaciones.isEmpty) return false;
    final driver = _ubicaciones.firstWhere((u) => u['rol'] == 'conductor',
        orElse: () => null);
    return driver != null && driver['id_usuario'] == _user!['id'];
  }

  Future<void> _openChatWithDriver() async {
    final driver = _ubicaciones.firstWhere((u) => u['rol'] == 'conductor',
        orElse: () => null);
    if (driver != null) {
      await _openChatWithUser(driver['id_usuario'], driver['nombre']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Información del conductor no disponible')));
    }
  }

  Future<void> _openChatWithUser(int userId, String userName) async {
    try {
      // Create or Get Chat
      final chat =
          await MessageService.getOrCreateChat(userId, idViaje: widget.tripId);
      if (chat != null && mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                      chatId: chat['id'],
                      otherUserName: userName,
                      otherUserId: userId,
                    )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al abrir chat: $e')));
      }
    }
  }

  Future<void> _shareTrip() async {
    HapticFeedback.mediumImpact();
    // Construir mensaje
    final origen = widget.tripData['origen'] ?? 'Origen desconocido';
    final destino = widget.tripData['destino'] ?? 'Destino desconocido';
    final conductor = widget.tripData['conductor_nombre'] ?? 'un conductor';
    String eta = '';

    if (_tripStats != null && _tripStats!['duration'] != null) {
      eta = '. Llegaré en aprox ${_tripStats!['duration']}';
    }

    final String message =
        '🚗 Hola, voy en un viaje UniHitch de *$origen* a *$destino* con $conductor$eta. \n\n¡Sigue mi viaje en UniHitch secure!';

    final url =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // Fallback
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo abrir WhatsApp')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error al compartir')));
    }
  }
}
