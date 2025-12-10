import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/wallet_service.dart';
import '../widgets/recharge_dialog.dart';
import 'withdrawal_screen.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  final _walletService = WalletService();
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        final wallet = await _walletService.getWallet(user['id']);
        if (mounted) {
          setState(() {
            _user = user;
            _walletData = wallet;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _showRechargeDialog() {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (context) => RechargeDialog(
        userId: _user!['id'],
        onSuccess: () {
          _loadData(); // Recargar datos después de una recarga exitosa
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final saldo = _walletData?['saldo'] ?? '0.00';
    final transacciones = _walletData?['transacciones'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'Saldo actual:',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/. $saldo',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.history,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Última actualización:',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    'Hace un momento',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Acciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showRechargeDialog,
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        label: const Text('RECARGAR',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WithdrawalScreen()),
                          );
                        },
                        icon: const Icon(Icons.money_off, color: Colors.purple),
                        label: const Text('RETIRAR',
                            style: TextStyle(color: Colors.purple)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.purple.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Transacciones recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (transacciones.isEmpty &&
                    (_walletData?['recargas_pendientes'] as List?)?.isEmpty ==
                        true)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay transacciones recientes'),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Mostrar recargas pendientes primero
                      if ((_walletData?['recargas_pendientes'] as List?)
                              ?.isNotEmpty ==
                          true)
                        ...(_walletData!['recargas_pendientes'] as List)
                            .map((solicitud) {
                          return _buildTransaction(
                            Icons.access_time,
                            'Recarga en proceso',
                            'S/. ${solicitud['monto']}',
                            Colors.orange,
                            solicitud['fecha_solicitud'],
                            isPending: true,
                          );
                        }),

                      // Mostrar transacciones completadas
                      ...transacciones.map((tx) {
                        final isPositive = tx['tipo'] == 'RECARGA' ||
                            tx['tipo'] == 'INGRESO_VIAJE';
                        return _buildTransaction(
                          isPositive ? Icons.add_circle : Icons.remove_circle,
                          tx['descripcion'] ?? 'Transacción',
                          '${isPositive ? '+' : '-'}S/. ${tx['monto']}',
                          isPositive ? Colors.green : Colors.red,
                          tx['fecha_transaccion'],
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransaction(IconData icon, String description, String amount,
      Color color, String? date,
      {bool isPending = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(description),
        subtitle: date != null
            ? Text(
                date.substring(0, 16).replaceAll('T', ' '),
                style: const TextStyle(fontSize: 12),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (isPending)
              const Text(
                'PENDIENTE',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
