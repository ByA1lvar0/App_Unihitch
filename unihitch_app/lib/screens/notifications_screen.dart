import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

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
      final notifications = await ApiService.getNotifications(widget.userId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        // Marcar todas como leídas
        await ApiService.markAllNotificationsAsRead(widget.userId);
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForType(String? tipo) {
    switch (tipo) {
      case 'VIAJE_CANCELADO':
        return Icons.cancel;
      case 'ALERTA_SEGURIDAD':
        return Icons.warning;
      case 'VIAJE_CONFIRMADO':
        return Icons.check_circle;
      case 'PAGO_PROCESADO':
      case 'RECARGA_APROBADA':
      case 'SYSTEM':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? tipo) {
    switch (tipo) {
      case 'VIAJE_CANCELADO':
      case 'ALERTA_SEGURIDAD':
        return Colors.red;
      case 'VIAJE_CONFIRMADO':
        return Colors.green;
      case 'PAGO_PROCESADO':
      case 'RECARGA_APROBADA':
      case 'SYSTEM':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notifications.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(child: Text('No tienes notificaciones')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                _getIconForType(notif['tipo']),
                color: _getColorForType(notif['tipo']),
                size: 32,
              ),
              title: Text(
                notif['titulo'] ?? 'Notificación',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(notif['mensaje'] ?? ''),
                  const SizedBox(height: 4),
                  Text(
                    notif['fecha_creacion'] != null
                        ? notif['fecha_creacion'].toString().substring(0, 16)
                        : '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
