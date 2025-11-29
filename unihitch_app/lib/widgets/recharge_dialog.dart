import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/wallet_service.dart';

class RechargeDialog extends StatefulWidget {
  final int userId;
  final Function() onSuccess;

  const RechargeDialog({
    super.key,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<RechargeDialog> createState() => _RechargeDialogState();
}

class _RechargeDialogState extends State<RechargeDialog> {
  final _walletService = WalletService();
  final _amountController = TextEditingController();
  final _operationController = TextEditingController();

  int _currentStep = 0;
  String _selectedMethod = 'YAPE';
  String _phoneNumber = '';
  bool _isLoading = false;
  String _imageBase64 = '';

  @override
  void initState() {
    super.initState();
    _loadPaymentAccount();
  }

  Future<void> _loadPaymentAccount() async {
    try {
      final accounts = await _walletService.getPaymentAccounts();
      if (accounts.isNotEmpty) {
        setState(() {
          _phoneNumber = accounts[0]['numero_celular'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading account: $e');
    }
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _submitRecharge() async {
    if (_amountController.text.isEmpty) {
      _showError('Por favor ingresa un monto');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 10) {
      _showError('El monto mínimo es S/. 10.00');
      return;
    }

    if (_imageBase64.isEmpty) {
      _showError('Por favor selecciona un comprobante');
      return;
    }

    if (_operationController.text.isEmpty) {
      _showError('Por favor ingresa el número de operación');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.submitRechargeRequest(
        userId: widget.userId,
        amount: amount,
        method: _selectedMethod,
        imageBase64: _imageBase64,
        operationNumber: _operationController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess(
            '¡Recarga exitosa! Nuevo saldo: S/. ${result['newBalance']}');
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al procesar recarga: $e');
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recargar Saldo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _submitRecharge();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                steps: [
                  Step(
                    title: const Text('Monto'),
                    content: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monto a recargar',
                            prefixText: 'S/. ',
                            hintText: '50.00',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mínimo: S/. 10.00',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Pagar'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Realiza el pago a:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.phone_android,
                                      size: 40, color: Colors.purple),
                                  const SizedBox(width: 16),
                                  Text(
                                    _phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: _phoneNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Número copiado')),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copiar número'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '1. Abre tu app de Yape\n2. Envía el monto a este número\n3. Toma captura del comprobante',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: const Text('Comprobante'),
                    content: Column(
                      children: [
                        if (_imageBase64.isEmpty)
                          ElevatedButton.icon(
                            onPressed: _selectImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Subir comprobante'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 48),
                              const SizedBox(height: 8),
                              const Text('Comprobante seleccionado'),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _imageBase64 = ''),
                                child: const Text('Cambiar'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _operationController,
                          decoration: const InputDecoration(
                            labelText: 'Número de operación (Requerido)',
                            hintText: 'Ej. 1234567',
                            border: OutlineInputBorder(),
                            helperText:
                                'Código único del comprobante para verificar tu pago',
                          ),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 2,
                  ),
                ],
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Atrás'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _currentStep < 2 ? 'Continuar' : 'Confirmar'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _operationController.dispose();
    super.dispose();
  }
}
