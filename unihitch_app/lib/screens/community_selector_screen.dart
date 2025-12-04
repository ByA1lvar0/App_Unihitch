import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'community_screen.dart';

class CommunitySelectorScreen extends StatefulWidget {
  const CommunitySelectorScreen({super.key});

  @override
  State<CommunitySelectorScreen> createState() =>
      _CommunitySelectorScreenState();
}

class _CommunitySelectorScreenState extends State<CommunitySelectorScreen> {
  List<dynamic> _universidades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUniversidades();
  }

  Future<void> _loadUniversidades() async {
    try {
      final universidades = await ApiService.getUniversidades();
      if (mounted) {
        setState(() {
          _universidades = universidades;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Comunidad'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _universidades.isEmpty
              ? const Center(
                  child: Text('No hay comunidades disponibles'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _universidades.length,
                  itemBuilder: (context, index) {
                    final universidad = _universidades[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Icon(
                            Icons.school,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          universidad['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          universidad['direccion'] ?? 'Sin dirección',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityScreen(
                                universidadId: universidad['id'],
                                universidadNombre:
                                    'Comunidad ${universidad['nombre']}',
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
