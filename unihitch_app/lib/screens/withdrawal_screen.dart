import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wallet_service.dart';
import '../services/api_service.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _walletService = WalletService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedMethod = 'YAPE';
  bool _isLoading = false;
  double _currentBalance = 0.0;
  List<Map<String, dynamic>> _withdrawals = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getUser();
      _userId = user?['id'];

      if (_userId != null) {
        try {
          // Obtener saldo actual
          final walletData = await _walletService.getWallet(_userId!);

          // Intentar obtener retiros (puede fallar si no hay ninguno)
          List<Map<String, dynamic>> withdrawals = [];
          try {
            withdrawals = await _walletService.getWithdrawals(_userId!);
          } catch (e) {
            print('No hay retiros o error al obtenerlos: $e');
            // No es crítico, continuamos con lista vacía
          }

          setState(() {
            _currentBalance =
                double.tryParse(walletData['saldo'].toString()) ?? 0.0;
            _withdrawals = withdrawals;
            _isLoading = false;
          });
        } catch (e) {
          print('Error al cargar wallet: $e');
          setState(() => _isLoading = false);
          if (mounted) {
            _showError(
                'Error al cargar datos de wallet. Verifica tu conexión.');
          }
        }
      } else {
        // No hay usuario logueado
        setState(() => _isLoading = false);
        if (mounted) {
          _showError('Debes iniciar sesión para ver esta pantalla');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error general: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Error al cargar datos: $e');
      }
    }
  }

  Future<void> _requestWithdrawal() async {
    if (_amountController.text.isEmpty) {
      _showError('Por favor ingresa un monto');
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError('Por favor ingresa el número de destino');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 20) {
      _showError('El monto mínimo de retiro es S/. 20.00');
      return;
    }

    if (amount > _currentBalance) {
      _showError('Saldo insuficiente');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _walletService.requestWithdrawal(
        userId: _userId!,
        amount: amount,
        method: _selectedMethod,
        numeroDestino: _phoneController.text,
      );

      setState(() => _isLoading = false);
      _showSuccess('Solicitud de retiro enviada. Se procesará en 24-48 horas.');

      // Limpiar formulario
      _amountController.clear();
      _phoneController.clear();

      // Recargar datos
      _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al solicitar retiro: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'PROCESADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _withdrawals.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retirar Fondos'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo disponible
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade800],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo disponible:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/. ${_currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulario de retiro
            const Text(
              'Solicitar Retiro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a retirar',
                prefixText: 'S/. ',
                hintText: '50.00',
                border: OutlineInputBorder(),
                helperText: 'Mínimo: S/. 20.00',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              items: ['YAPE', 'PLIN']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMethod = value!),
              decoration: const InputDecoration(
                labelText: 'Método de retiro',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Número de teléfono',
                hintText: '987654321',
                border: OutlineInputBorder(),
                helperText: 'Número donde recibirás el dinero',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SOLICITAR RETIRO'),
              ),
            ),
            const SizedBox(height: 32),

            // Historial de retiros
            const Text(
              'Historial de Retiros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_withdrawals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No hay retiros registrados'),
                ),
              )
            else
              ..._withdrawals.map((withdrawal) {
                final amount =
                    double.tryParse(withdrawal['monto'].toString()) ?? 0.0;
                final status = withdrawal['estado'] ?? 'PENDIENTE';
                final method = withdrawal['metodo'] ?? '';
                final phone = withdrawal['numero_destino'] ?? '';
                final date = withdrawal['fecha_solicitud'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      child: Icon(
                        status == 'PROCESADO'
                            ? Icons.check_circle
                            : status == 'RECHAZADO'
                                ? Icons.cancel
                                : Icons.pending,
                        color: _getStatusColor(status),
                      ),
                    ),
                    title: Text('S/. ${amount.toStringAsFixed(2)}'),
                    subtitle: Text(
                        '$method - $phone\n${date.toString().substring(0, 10)}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
