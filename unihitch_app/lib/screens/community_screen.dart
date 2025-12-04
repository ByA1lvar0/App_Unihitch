import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityScreen extends StatefulWidget {
  final int? universidadId;
  final String? universidadNombre;

  const CommunityScreen({
    super.key,
    this.universidadId,
    this.universidadNombre,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoading = true;
  bool _isVerified = false;
  int? _userId;
  int? _universidadId;
  String _universidadNombre = '';
  String _userRol = 'USER';

  List<dynamic> _messages = [];
  final _messageController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        setState(() {
          _userId = user['id'];
          _isVerified = user['verificado'] == true;
          _userRol = user['rol'] ?? 'USER';

          // Si ya se pasó una universidad específica, usar esa
          if (widget.universidadId != null) {
            _universidadId = widget.universidadId;
            _universidadNombre = widget.universidadNombre ?? 'Comunidad';
          } else {
            // Si no, usar la universidad del usuario
            _universidadId = user['id_universidad'];
            _universidadNombre = user['universidad_nombre'] != null
                ? 'Comunidad ${user['universidad_nombre']}'
                : 'Tu Comunidad';
          }
        });

        if (_isVerified && _universidadId != null) {
          _loadMessages();
          // Polling cada 5 segundos para nuevos mensajes
          _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
            _loadMessages();
          });
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error checking verification: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_universidadId == null) return;
    try {
      final messages = await ApiService.getCommunityMessages(_universidadId!);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    try {
      await ApiService.sendCommunityMessage(
        userId: _userId!,
        universidadId: _universidadId!,
        mensaje: message,
      );
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  Future<void> _showMembers() async {
    try {
      final members = await ApiService.getCommunityMembers(_universidadId!);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.group, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Miembros (${members.length})'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final esAdmin = member['rol'] == 'ADMIN';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esAdmin ? Colors.orange : Colors.indigo,
                    child: Text(
                      member['nombre'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title:
                      Text('${member['nombre']}${esAdmin ? ' (Admin)' : ''}'),
                  subtitle: Text(member['correo']),
                  trailing: _userRol == 'ADMIN' && !esAdmin
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteUser(
                              member['id'], member['nombre']),
                        )
                      : null,
                );
              },
            ),
          ),
          actions: [
            if (_userRol == 'ADMIN')
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddUserDialog();
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Añadir'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar miembros: $e')),
      );
    }
  }

  Future<void> _confirmDeleteUser(int userId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Estás seguro de eliminar a $nombre? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ApiService.deleteUser(userId);
        Navigator.pop(context); // Cerrar diálogo de miembros
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
        _loadMessages(); // Recargar mensajes
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    try {
      // Obtener TODOS los usuarios
      final allUsers = await ApiService.getAllVerifiedUsers();

      if (!mounted) return;

      // Filtrar usuarios que NO están en esta comunidad
      final currentMembers =
          await ApiService.getCommunityMembers(_universidadId!);
      final currentMemberIds = currentMembers.map((m) => m['id']).toList();

      final availableUsers = allUsers
          .where((user) => !currentMemberIds.contains(user['id']))
          .toList();

      if (availableUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Todos los usuarios ya están en esta comunidad')),
        );
        return;
      }

      String searchQuery = '';

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            final filteredUsers = availableUsers.where((user) {
              final nombre = user['nombre'].toString().toLowerCase();
              final correo = user['correo'].toString().toLowerCase();
              final query = searchQuery.toLowerCase();
              return nombre.contains(query) || correo.contains(query);
            }).toList();

            return AlertDialog(
              title: const Text('Añadir Usuario a la Comunidad'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Barra de búsqueda
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o correo...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Lista de usuarios
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? const Center(
                              child: Text('No se encontraron usuarios'))
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      user['nombre'][0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user['nombre']),
                                  subtitle: Text(user['correo']),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.green),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _confirmAddUser(
                                          user['id'], user['nombre']);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar usuarios: $e')),
      );
    }
  }

  Future<void> _confirmAddUser(int userId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir usuario'),
        content: Text(
            '¿Agregar a $nombre a esta comunidad?\nSe verificará automáticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ApiService.changeUserUniversity(userId, _universidadId!);
        Navigator.pop(context); // Cerrar diálogo de añadir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario añadido correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir: $e')),
        );
      }
    }
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
        appBar: AppBar(title: const Text('Comunidad')),
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
        title: Text(_universidadNombre),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Ver miembros',
            onPressed: () => _showMembers(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No hay mensajes aún. ¡Sé el primero!'),
                  )
                : ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['id_usuario'] == _userId;
                      final date = DateTime.parse(msg['fecha_envio']);

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.indigo.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight:
                                  isMe ? const Radius.circular(0) : null,
                              bottomLeft:
                                  !isMe ? const Radius.circular(0) : null,
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  msg['nombre_usuario'] ?? 'Usuario',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              if (!isMe) const SizedBox(height: 4),
                              Text(
                                msg['mensaje'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(date, locale: 'es'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
