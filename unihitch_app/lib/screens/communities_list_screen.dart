import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'community_screen.dart';

class CommunitiesListScreen extends StatefulWidget {
  const CommunitiesListScreen({super.key});

  @override
  State<CommunitiesListScreen> createState() => _CommunitiesListScreenState();
}

class _CommunitiesListScreenState extends State<CommunitiesListScreen> {
  List<dynamic> _universidades = [];
  bool _isLoading = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Obtener usuario guardado localmente para tener el ID
      var localUser = await ApiService.getUser();

      if (localUser != null) {
        // 2. Obtener datos FRESCOS del servidor para asegurar el rol actualizado
        try {
          final freshUser = await ApiService.getUserDetails(localUser['id']);
          // Actualizar usuario local con datos frescos
          await ApiService.saveUser(freshUser);
          localUser = freshUser; // Usar datos frescos de aquí en adelante
        } catch (e) {
          print('Error actualizando usuario: $e');
          // Si falla, seguimos con el localUser que ya teníamos
        }

        // BLOQUEAR ACCESO A AGENTES EXTERNOS
        if (localUser!['es_agente_externo'] == true) {
          setState(() => _isLoading = false);
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Acceso Restringido'),
                  ],
                ),
                content: const Text(
                  'Los agentes externos no tienen acceso a las comunidades universitarias.\n\nSolo puedes ofrecer viajes.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context); // Salir de la pantalla
                    },
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          }
          return;
        }

        _isVerified = localUser['verificado'] == true;

        // Cargar universidades
        final todasUniversidades = await ApiService.getUniversidades();

        // Si es ADMIN, mostrar todas. Si es USER, solo su universidad
        if (localUser['rol'] == 'ADMIN') {
          // Admin ve todas las comunidades
          setState(() {
            _universidades = todasUniversidades;
          });
        } else {
          // Usuario normal solo ve su universidad
          final miUniversidadId = localUser['id_universidad'];
          final miUniversidad = todasUniversidades
              .where((uni) => uni['id'] == miUniversidadId)
              .toList();

          setState(() {
            _universidades = miUniversidad;
          });
        }
      }

      setState(() {
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

  String _getNombreCorto(String nombreCompleto) {
    if (nombreCompleto.contains('UTP')) return 'UTP';
    if (nombreCompleto.contains('UCV')) return 'UCV';
    if (nombreCompleto.contains('UNP')) return 'UNP';
    if (nombreCompleto.contains('UDEP')) return 'UDEP';
    if (nombreCompleto.contains('UPN')) return 'UPN';
    if (nombreCompleto.contains('USMP') ||
        nombreCompleto.contains('San Martín')) return 'USMP';
    return nombreCompleto.split(' ')[0];
  }

  Color _getColorForUniversity(String nombre) {
    if (nombre.contains('UTP')) return Colors.orange;
    if (nombre.contains('UCV')) return Colors.red;
    if (nombre.contains('UNP')) return Colors.blue;
    if (nombre.contains('UDEP')) return Colors.green;
    if (nombre.contains('UPN')) return Colors.purple;
    if (nombre.contains('USMP')) return Colors.indigo;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Comunidades'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, size: 80, color: Colors.orange.shade300),
                const SizedBox(height: 24),
                const Text(
                  'Cuenta Pendiente de Aprobación',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para acceder a las comunidades universitarias, un administrador debe verificar tu código universitario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Por favor espera a ser verificado.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_universidades.length > 1
            ? 'Comunidades Universitarias'
            : 'Mi Comunidad'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _universidades.length,
        itemBuilder: (context, index) {
          final universidad = _universidades[index];
          final nombreCorto = _getNombreCorto(universidad['nombre']);
          final color = _getColorForUniversity(universidad['nombre']);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: color,
                radius: 28,
                child: Text(
                  nombreCorto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              title: Text(
                'COMUNIDAD $nombreCorto',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                universidad['nombre'],
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityScreen(
                      universidadId: universidad['id'],
                      universidadNombre: 'COMUNIDAD $nombreCorto',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
