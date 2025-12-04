import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/directions_service.dart';
import 'sos_emergency_screen.dart';

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
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Map<String, dynamic>? _user;
  List<dynamic> _ubicaciones = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
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
      setState(() {
        _errorMessage = 'Error al inicializar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    }
  }

  void _startLocationTracking() {
    _positionStreamSubscription =
        LocationService.getLocationStream().listen((Position position) async {
      setState(() {
        _currentPosition = position;
      });

      // Actualizar ubicación en el servidor
      try {
        await ApiService.updateUserLocation(
          userId: _user!['id'],
          tripId: widget.tripId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
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
    } catch (e) {
      debugPrint('Error cargando ubicaciones: $e');
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};

    for (var ubicacion in _ubicaciones) {
      if (ubicacion['latitud'] != null && ubicacion['longitud'] != null) {
        final isDriver = ubicacion['rol'] == 'conductor';
        final markerId = MarkerId('user_${ubicacion['id']}');

        markers.add(
          Marker(
            markerId: markerId,
            position: LatLng(
              ubicacion['latitud'].toDouble(),
              ubicacion['longitud'].toDouble(),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isDriver ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: ubicacion['nombre'],
              snippet: isDriver ? '🚗 Conductor' : '👤 Pasajero',
            ),
            zIndex: isDriver ? 2 : 1,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _drawRoute() async {
    // Intentar dibujar la ruta real usando Google Directions API
    try {
      // Necesitamos origen y destino
      // Por ahora, usaremos la ubicación actual como origen
      // y buscaremos el conductor para obtener su ubicación como referencia

      if (_currentPosition == null || _ubicaciones.isEmpty) {
        debugPrint('No hay suficiente información para dibujar la ruta');
        return;
      }

      // Encontrar al conductor
      final driver = _ubicaciones.firstWhere(
        (u) => u['rol'] == 'conductor',
        orElse: () => null,
      );

      if (driver == null ||
          driver['latitud'] == null ||
          driver['longitud'] == null) {
        debugPrint('No se encontró la ubicación del conductor');
        return;
      }

      final origin =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final destination = LatLng(
        driver['latitud'].toDouble(),
        driver['longitud'].toDouble(),
      );

      // Obtener la ruta desde Google Directions API
      final routePoints = await DirectionsService.getRoute(origin, destination);

      if (routePoints.isNotEmpty) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 5,
              geodesic: true,
            ),
          );
        });
        debugPrint('Ruta dibujada con ${routePoints.length} puntos');
      }
    } catch (e) {
      debugPrint('Error al dibujar la ruta: $e');
      // Si falla, no hacemos nada (no se mostrará la polilínea)
    }
  }

  void _centerOnMyLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _showRatingSheet() {
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

                            setModalState(() => isSubmitting = true);

                            try {
                              // Encontrar al conductor
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

  Future<void> _showEmergencyDialog() async {
    final userDetails = await ApiService.getUserDetails(_user!['id']);
    final emergencyNumber = userDetails['numero_emergencia'];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Emergencia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emergencyNumber != null && emergencyNumber.isNotEmpty) ...[
              const Text(
                'Tu número de emergencia:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                emergencyNumber,
                style: const TextStyle(fontSize: 24, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar llamada telefónica
                  _makePhoneCall(emergencyNumber);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Llamar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ] else ...[
              const Text(
                'No has configurado un número de emergencia.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ve a tu perfil para configurarlo.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo realizar la llamada')),
        );
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
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
              onPressed: _loadTripLocations,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Estilo de mapa limpio (opcional, se puede agregar JSON style)
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Botón de Mi Ubicación
          Positioned(
            bottom: 260,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: _centerOnMyLocation,
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

          // Botón Calificar (Demo)
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'rate',
              onPressed: _showRatingSheet,
              backgroundColor: Colors.amber,
              child: const Icon(Icons.star, color: Colors.white),
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
                      Text(
                        '${passengers.length} Pasajeros',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                        trailing: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isConnected ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isConnected ? Colors.green : Colors.grey)
                                        .withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
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
}
