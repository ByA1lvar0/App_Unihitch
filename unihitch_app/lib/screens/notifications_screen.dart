import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = await ApiService.getUser();
      if (user == null) return;

      final notifications = await ApiService.getNotifications(user['id']);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notificaciones: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
      setState(() {
        _notifications[index]['leido'] = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar notificación: $e')),
        );
      }
    }
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RESERVA':
        return Icons.event_seat;
      case 'VIAJE':
        return Icons.directions_car;
      case 'PAGO':
        return Icons.payment;
      case 'SISTEMA':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RESERVA':
        return Colors.blue;
      case 'VIAJE':
        return Colors.green;
      case 'PAGO':
        return Colors.orange;
      case 'SISTEMA':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Justo ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['leido'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notificaciones'),
            if (unreadCount > 0)
              Text(
                '$unreadCount sin leer',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                // Marcar todas como leídas
                for (var i = 0; i < _notifications.length; i++) {
                  if (_notifications[i]['leido'] == false) {
                    await _markAsRead(_notifications[i]['id'], i);
                  }
                }
              },
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes notificaciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isUnread = notification['leido'] == false;
                      final tipo = notification['tipo'] ?? 'SISTEMA';
                      final fecha =
                          DateTime.parse(notification['fecha_creacion']);

                      return Dismissible(
                        key: Key(notification['id'].toString()),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Marcar como leída
                            await _markAsRead(notification['id'], index);
                            return false;
                          }
                          return true; // Permitir eliminar
                        },
                        onDismissed: (direction) {
                          setState(() {
                            _notifications.removeAt(index);
                          });
                        },
                        child: Container(
                          color: isUnread
                              ? Colors.blue.shade50
                              : Colors.transparent,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForType(tipo),
                              child: Icon(
                                _getIconForType(tipo),
                                color: Colors.white,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['titulo'] ?? 'Notificación',
                                    style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['mensaje'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(fecha),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (isUnread) {
                                _markAsRead(notification['id'], index);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
