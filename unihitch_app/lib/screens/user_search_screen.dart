import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _users = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final users = await ApiService.searchUsers(query);
      setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar usuarios: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    try {
      // Obtener o crear chat
      final chat = await MessageService.getOrCreateChat(user['id']);

      if (!mounted) return;

      if (chat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar chat')),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chat['id'],
            otherUserName: user['nombre'],
            otherUserId: user['id'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        // Extract message from Exception: ...
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar personas...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            // Debounce simple
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && value == _searchController.text) {
                _searchUsers(value);
              }
            });
          },
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Busca por nombre o correo',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          user['nombre'][0].toUpperCase(),
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(user['nombre'])),
                          if (user['es_agente_externo'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.orange.shade300),
                              ),
                              child: Text(
                                'Externo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(user['correo']),
                      onTap: () => _startChat(user),
                    );
                  },
                ),
    );
  }
}
