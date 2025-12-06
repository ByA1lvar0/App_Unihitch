import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _carreraController = TextEditingController();

  List<dynamic> _universidades = [];
  int? _universidadSeleccionada;
  bool _isLoading = false;
  bool _isLoadingUniversidades = true;
  bool _universidadDetectada = false;
  String _universidadDetectadaNombre = '';
  bool _isExternalUser = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUniversidades();
  }

  Future<void> _loadUniversidades() async {
    try {
      final universidades = await ApiService.getUniversidades();
      setState(() {
        _universidades = universidades;
        _isLoadingUniversidades = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar universidades: $e')),
        );
      }
    }
  }

  // Detectar universidad al escribir correo (con Debounce)
  Future<void> _onEmailChanged(String email) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (email.contains('@') && email.split('@')[1].contains('.')) {
        try {
          final result = await ApiService.detectUniversityByEmail(email);
          if (result['detected'] == true) {
            setState(() {
              _universidadSeleccionada = result['university']['id'];
              _universidadDetectada = true;
              _universidadDetectadaNombre = result['university']['nombre'];
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ Universidad detectada: ${result['university']['nombre']}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Si no se detectó, resetear solo si estaba detectada previamente
            if (_universidadDetectada) {
              setState(() {
                _universidadDetectada = false;
                _universidadDetectadaNombre = '';
                _universidadSeleccionada = null; // Resetear selección
              });
            }
          }
        } catch (e) {
          print('Error detecting university: $e');
        }
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isExternalUser && _universidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una universidad')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.register(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim().toLowerCase(), // NORMALIZAR
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
        idUniversidad: _isExternalUser ? null : _universidadSeleccionada,
        carreraNombre: _isExternalUser ? null : _carreraController.text.trim(),
        referralCode: _referralCodeController.text.trim().isNotEmpty
            ? _referralCodeController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: _isLoadingUniversidades
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Únete a UniHitch',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text(
                            'Soy conductor externo / No soy universitario'),
                        value: _isExternalUser,
                        onChanged: (value) {
                          setState(() {
                            _isExternalUser = value;
                            if (value) {
                              _universidadSeleccionada = null;
                              _carreraController.clear();
                              _universidadDetectada = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!_isExternalUser) ...[
                        // Universidad
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: _universidadDetectada
                                ? 'Universidad (Detectada automáticamente)'
                                : 'Universidad *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.school),
                            suffixIcon: _universidadDetectada
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                          ),
                          value: _universidadSeleccionada,
                          items: _universidades.map((uni) {
                            return DropdownMenuItem<int>(
                              value: uni['id'],
                              child: Text(uni['nombre']),
                            );
                          }).toList(),
                          onChanged: _universidadDetectada
                              ? null
                              : (value) {
                                  setState(
                                      () => _universidadSeleccionada = value);
                                },
                          validator: (value) {
                            if (!_isExternalUser && value == null) {
                              return 'Selecciona una universidad';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Correo
                      TextFormField(
                        controller: _correoController,
                        decoration: InputDecoration(
                          labelText: _isExternalUser
                              ? 'Correo Electrónico *'
                              : 'Correo Institucional *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          hintText: _isExternalUser
                              ? 'ejemplo@gmail.com'
                              : 'ejemplo@udep.edu.pe',
                          suffixIcon: _universidadDetectada
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _onEmailChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!value.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!_isExternalUser) ...[
                        // Carrera
                        TextFormField(
                          controller: _carreraController,
                          decoration: const InputDecoration(
                            labelText: '¿Qué carrera estudias? *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school_outlined),
                            hintText: 'Ej. Ingeniería de Sistemas',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (!_isExternalUser &&
                                (value == null || value.isEmpty)) {
                              return 'Ingresa tu carrera';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          hintText: '987654321',
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 9,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu teléfono';
                          }
                          if (value.length != 9) {
                            return 'Debe tener 9 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Contraseña
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          hintText: 'Mínimo 6 caracteres',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Confirmar Contraseña
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Contraseña *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Código de Referido
                      TextFormField(
                        controller: _referralCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Código de Referido (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.card_giftcard),
                          helperText:
                              '¿Te invitó un amigo? Ingresa su código aquí',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 32),
                      // Botón Registrar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('CREAR CUENTA',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _carreraController.dispose();
    super.dispose();
  }
}
