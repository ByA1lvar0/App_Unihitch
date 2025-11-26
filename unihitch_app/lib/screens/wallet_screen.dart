import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'recharge_options_screen.dart';

class WalletScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const WalletScreen({super.key, required this.user});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  double _balance = 0.00;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final data = await ApiService.getWallet(widget.user['id']);
      if (mounted) {
        setState(() {
          _balance = double.parse(data['saldo'].toString());
          _transactions = data['transacciones'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar wallet: $e')),
        );
      }
    }
  }

  Future<void> _openRechargeScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RechargeOptionsScreen(
          userId: widget.user['id'],
          userEmail: widget.user['correo'] ?? 'user@unihitch.app',
        ),
      ),
    );

    // Recargar datos si hubo éxito
    if (result == true) {
      _loadWalletData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Wallet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Morada
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo actual:',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'S/. ${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Gastos este mes (simulado por ahora)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bar_chart,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gastos este mes:',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const Text(
                                    'S/. 0.00', // TODO: Calcular real
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Métodos de pago',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethod(
                      'Yape', '********4567', Icons.phone_android),
                  const SizedBox(height: 8),
                  _buildPaymentMethod('Visa', '****1234', Icons.credit_card),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {}, // TODO: Implementar agregar método
                      icon: const Icon(Icons.add),
                      label: const Text('AGREGAR MÉTODO'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openRechargeScreen,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('RECARGAR SALDO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E24AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Historial de Transacciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t['tipo'] == 'RECARGA'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            t['tipo'] == 'RECARGA'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: t['tipo'] == 'RECARGA'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(t['descripcion'] ?? 'Transacción'),
                        subtitle: Text(
                            t['fecha_transaccion'].toString().substring(0, 10)),
                        trailing: Text(
                          '${t['tipo'] == 'RECARGA' ? '+' : '-'} S/. ${t['monto']}',
                          style: TextStyle(
                            color: t['tipo'] == 'RECARGA'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethod(String name, String number, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(number, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
