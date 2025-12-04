import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final int userId;
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  Timer? _timer;
  int _secondsRemaining = 900; // 15 minutos
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 900; // Reset a 15 minutos
    _canResend = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _timeFormatted {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyCode(String code) async {
    if (code.length != 6) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.verifyEmailCode(
        userId: widget.userId,
        code: code,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Email verificado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirigir a home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        _codeController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      await ApiService.resendVerificationCode(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Código reenviado a tu email'),
            backgroundColor: Colors.blue,
          ),
        );
        _startTimer();
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.mark_email_read,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verifica tu email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enviamos un código de 6 dígitos a:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // PIN Code Input
            PinCodeTextField(
              appContext: context,
              length: 6,
              obscureText: false,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 60,
                fieldWidth: 50,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.blue.shade50,
                inactiveFillColor: Colors.grey.shade100,
                activeColor: Colors.blue,
                selectedColor: Colors.blue,
                inactiveColor: Colors.grey.shade300,
              ),
              animationDuration: const Duration(milliseconds: 300),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              controller: _codeController,
              keyboardType: TextInputType.number,
              onCompleted: (code) => _verifyCode(code),
              onChanged: (value) {},
            ),

            const SizedBox(height: 24),

            // Timer
            if (!_canResend)
              Text(
                'Código válido por: $_timeFormatted',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 16),

            // Botón Reenviar
            if (_canResend)
              TextButton(
                onPressed: _isLoading ? null : _resendCode,
                child: const Text('Reenviar código'),
              )
            else
              TextButton(
                onPressed: null,
                child: const Text('Reenviar código'),
              ),

            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 40),

            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¿No recibiste el código?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Revisa tu carpeta de spam\n• Verifica que el email sea correcto\n• Espera un momento y reenvía el código',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
