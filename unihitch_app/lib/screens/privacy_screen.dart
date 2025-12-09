import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Política de Privacidad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Recopilación de Datos',
            'UniHitch recopila información personal como nombre, correo electrónico, número de teléfono y ubicación para proporcionar nuestros servicios de carpooling de manera efectiva.',
          ),
          _buildSection(
            'Uso de la Información',
            'Utilizamos tu información para:\n• Conectarte con otros usuarios\n• Procesar pagos\n• Mejorar nuestros servicios\n• Enviar notificaciones importantes',
          ),
          _buildSection(
            'Compartir Información',
            'Tu información de perfil (nombre, foto, calificación) es visible para otros usuarios con quienes compartes viajes. Nunca vendemos tu información personal a terceros.',
          ),
          _buildSection(
            'Seguridad',
            'Implementamos medidas de seguridad para proteger tu información personal. Todos los datos sensibles están encriptados.',
          ),
          _buildSection(
            'Tus Derechos',
            'Tienes derecho a:\n• Acceder a tu información personal\n• Corregir datos incorrectos\n• Eliminar tu cuenta\n• Exportar tus datos',
          ),
          _buildSection(
            'Cookies y Tracking',
            'Utilizamos cookies para mejorar tu experiencia. Puedes desactivarlas en la configuración de tu navegador.',
          ),
          _buildSection(
            'Contacto',
            'Si tienes preguntas sobre nuestra política de privacidad, contáctanos en:\nprivacy@unihitch.com',
          ),
          const SizedBox(height: 16),
          Text(
            'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
