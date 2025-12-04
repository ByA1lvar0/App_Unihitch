import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Términos y Condiciones',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Aceptación de Términos',
            'Al usar UniHitch, aceptas estos términos y condiciones. Si no estás de acuerdo, por favor no uses nuestros servicios.',
          ),
          _buildSection(
            'Uso del Servicio',
            'UniHitch es una plataforma de carpooling universitario. Los usuarios deben:\n• Ser mayores de 18 años\n• Proporcionar información veraz\n• Respetar a otros usuarios\n• Cumplir con las leyes de tránsito',
          ),
          _buildSection(
            'Responsabilidades',
            'Los conductores son responsables de:\n• Mantener su vehículo en buen estado\n• Tener licencia de conducir válida\n• Contar con seguro vehicular\n\nLos pasajeros deben:\n• Llegar puntualmente\n• Respetar el vehículo\n• Pagar el monto acordado',
          ),
          _buildSection(
            'Pagos y Reembolsos',
            'Los pagos se procesan a través de nuestra plataforma. Las cancelaciones deben hacerse con al menos 2 horas de anticipación para obtener reembolso completo.',
          ),
          _buildSection(
            'Limitación de Responsabilidad',
            'UniHitch actúa como intermediario. No somos responsables por:\n• Accidentes durante el viaje\n• Pérdida de objetos personales\n• Disputas entre usuarios',
          ),
          _buildSection(
            'Suspensión de Cuenta',
            'Nos reservamos el derecho de suspender cuentas que:\n• Violen estos términos\n• Tengan comportamiento inapropiado\n• Proporcionen información falsa',
          ),
          _buildSection(
            'Modificaciones',
            'Podemos modificar estos términos en cualquier momento. Los cambios entrarán en vigor al publicarse en la aplicación.',
          ),
          _buildSection(
            'Ley Aplicable',
            'Estos términos se rigen por las leyes de Perú. Cualquier disputa se resolverá en los tribunales de Piura.',
          ),
          _buildSection(
            'Contacto Legal',
            'Para asuntos legales, contáctanos en:\nlegal@unihitch.com',
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
