import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await MessageService.getChats();
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return _buildChatItem(chat);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSearchScreen()),
          ).then((_) => _loadChats());
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes conversaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia una conversación desde un viaje',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final unreadCount = chat['mensajes_no_leidos'] ?? 0;
    final hasUnread = unreadCount > 0;
    final hasViajeContext = chat['viaje_origen'] != null;

    // Extract university abbreviation from full name
    String userName = chat['otro_usuario_nombre'] ?? 'Usuario';
    final universidadCompleta = chat['otro_usuario_universidad'];

    if (universidadCompleta != null) {
      // Extract abbreviation from parentheses, e.g., "Universidad César Vallejo (UCV)" -> "UCV"
      final match = RegExp(r'\(([^)]+)\)').firstMatch(universidadCompleta);
      if (match != null) {
        final abreviacion = match.group(1);
        userName = '$userName - COMUNIDAD $abreviacion';
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasViajeContext ? Colors.blue.shade600 : Colors.grey,
        child: Icon(
          hasViajeContext ? Icons.directions_car : Icons.chat,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        userName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasViajeContext) ...[
            Row(
              children: [
                Icon(Icons.route, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${chat['viaje_origen']} → ${chat['viaje_destino']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
          Text(
            chat['ultimo_mensaje'] ?? 'Sin mensajes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread ? Colors.black87 : Colors.grey.shade600,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat['id'],
              otherUserName: chat['otro_usuario_nombre'] ?? 'Usuario',
              otherUserId: chat['otro_usuario_id'],
              otherUserUniversity: chat['otro_usuario_universidad'],
            ),
          ),
        ).then((_) => _loadChats());
      },
    );
  }
}
