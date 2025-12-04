import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class SOSEmergencyScreen extends StatefulWidget {
  final Map<String, dynamic>? tripData;

  const SOSEmergencyScreen({super.key, this.tripData});

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen> {
  bool _emergencyActivated = false;
  Position? _currentPosition;
  bool _locationShared = false;
  bool _policeNotified = false;
  bool _emergencyContactNotified = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _activateEmergency() async {
    setState(() {
      _emergencyActivated = true;
    });

    // Compartir ubicación automáticamente
    await _shareLocation();

    // Notificar a contactos de emergencia
    await _notifyEmergencyContacts();
  }

  Future<void> _shareLocation() async {
    if (_currentPosition != null) {
      try {
        // 1. Obtener usuario actual
        final user = await ApiService.getUser();
        if (user == null) return;

        // 2. Enviar al backend (Log)
        await ApiService.sendEmergencyLocation(
          userId: user['id'],
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );

        setState(() {
          _locationShared = true;
        });

        // 3. Obtener contactos de emergencia
        final contacts = await ApiService.getEmergencyContacts(user['id']);

        if (contacts.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('No tienes contactos de emergencia configurados')),
            );
          }
          return;
        }

        // 4. Preguntar método de envío
        if (mounted) {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enviar ubicación vía:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.sms, color: Colors.blue),
                    title: const Text('SMS (A todos los contactos)'),
                    onTap: () {
                      Navigator.pop(context);
                      _sendSMS(contacts);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.message,
                        color: Colors.green), // WhatsApp icon replacement
                    title: const Text('WhatsApp (Contacto principal)'),
                    onTap: () {
                      Navigator.pop(context);
                      _sendWhatsApp(contacts);
                    },
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        print('Error sharing location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al compartir ubicación: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando señal GPS...')),
      );
    }
  }

  Future<void> _sendSMS(List<dynamic> contacts) async {
    final numbers = contacts.map((c) => c['telefono']).join(',');
    final mapLink =
        'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final message = 'SOS! Necesito ayuda. Mi ubicación es: $mapLink';

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      // Fallback for some Android devices
      final Uri smsUriAndroid = Uri.parse('sms:$numbers?body=$message');
      if (await canLaunchUrl(smsUriAndroid)) {
        await launchUrl(smsUriAndroid);
      }
    }
  }

  Future<void> _sendWhatsApp(List<dynamic> contacts) async {
    // Buscar contacto principal o usar el primero
    final mainContact = contacts.firstWhere(
      (c) => c['es_principal'] == true,
      orElse: () => contacts.first,
    );

    final number = mainContact['telefono'];
    final mapLink =
        'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final message = 'SOS! Necesito ayuda. Mi ubicación es: $mapLink';

    // WhatsApp URL format
    final whatsappUrl =
        Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  Future<void> _notifyEmergencyContacts() async {
    // Aquí notificarías a los contactos de emergencia
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _emergencyContactNotified = true;
    });
  }

  Future<void> _callPolice() async {
    final Uri phoneUri =
        Uri(scheme: 'tel', path: '105'); // Número de policía en Perú
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      setState(() {
        _policeNotified = true;
      });
    }
  }

  Future<void> _callEmergency() async {
    final Uri phoneUri =
        Uri(scheme: 'tel', path: '911'); // Número de emergencia
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _cancelAlert() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade700,
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        title: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _emergencyActivated ? 'EMERGENCIA ACTIVA' : 'EMERGENCIA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Status Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_emergencyActivated) ...[
                          _buildStatusItem(
                            icon: Icons.warning,
                            text: 'Has activado el\nbotón de emergencia',
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildStatusItem(
                          icon: _locationShared
                              ? Icons.check_circle
                              : Icons.location_on,
                          text: 'Ubicación compartida con contactos',
                          color: _locationShared ? Colors.green : Colors.grey,
                        ),

                        const SizedBox(height: 12),

                        _buildStatusItem(
                          icon: _emergencyContactNotified
                              ? Icons.check_circle
                              : Icons.notifications,
                          text: 'Notificado a:',
                          color: _emergencyContactNotified
                              ? Colors.green
                              : Colors.grey,
                        ),

                        if (_emergencyContactNotified) ...[
                          const Padding(
                            padding: EdgeInsets.only(left: 40, top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Seguridad UDEP'),
                                Text('• Contacto: Mamá'),
                                Text('• Emergencias: 105'),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        _buildActionButton(
                          label: 'LLAMAR POLICÍA',
                          icon: Icons.local_police,
                          color: Colors.grey.shade800,
                          onPressed: _callPolice,
                        ),

                        const SizedBox(height: 12),

                        _buildActionButton(
                          label: 'LLAMAR EMERGENCIA',
                          icon: Icons.phone,
                          color: Colors.red.shade600,
                          onPressed: _callEmergency,
                        ),

                        const SizedBox(height: 12),

                        _buildActionButton(
                          label: 'ENVIAR UBICACIÓN',
                          icon: Icons.my_location,
                          color: Colors.green.shade600,
                          onPressed: _shareLocation,
                        ),

                        const SizedBox(height: 12),

                        _buildActionButton(
                          label: 'CANCELAR ALERTA',
                          icon: Icons.cancel,
                          color: Colors.grey.shade600,
                          onPressed: _cancelAlert,
                          outlined: true,
                        ),

                        const SizedBox(height: 24),

                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'Mantén la calma.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ayuda está en camino.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: color),
              label: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white),
              label: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }
}
