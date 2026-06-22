import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _codigoVerificacionCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  int _registerStep = 0; // 0: DNI, 1: Codigo, 2: Email/Pass
  Map<String, dynamic>? _dniData;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _dniCtrl.dispose();
    _codigoVerificacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _validarDNI() async {
    final dni = _dniCtrl.text.trim();
    if (dni.length != 8) {
      setState(() => _error = 'El DNI debe tener 8 dígitos.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('https://api.sparkingcraft.com/egapp/dni/$dni'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          setState(() {
            _dniData = body['data'];
            _registerStep = 1;
            _error = null;
          });
        } else {
          setState(() => _error = body['message'] ?? 'Error al validar DNI.');
        }
      } else {
        setState(() => _error = 'Error servidor (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _validarCodigo() {
    final codigo = _codigoVerificacionCtrl.text.trim();
    if (codigo.isEmpty) {
      setState(() => _error = 'Ingresa el código de verificación.');
      return;
    }
    if (_dniData != null && codigo == _dniData!['codigoVerificacion']) {
      setState(() {
        _registerStep = 2;
        _error = null;
      });
    } else {
      setState(() => _error = 'Código incorrecto. Revisa tu DNI físico.');
    }
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      } else {
        final fullName = "${_dniData!['nombres']} ${_dniData!['apellidoPaterno']}".trim();
        await AuthService.register(_emailCtrl.text.trim(), _passCtrl.text.trim(), fullName);
      }
    } catch (e) {
      setState(() => _error = _mapError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String e) {
    if (e.contains('invalid-credential') || e.contains('wrong-password')) return 'Credenciales incorrectas.';
    if (e.contains('user-not-found')) return 'No existe una cuenta con ese email.';
    if (e.contains('email-already-in-use')) return 'Ese email ya está registrado.';
    if (e.contains('weak-password')) return 'La contraseña debe tener al menos 6 caracteres.';
    return 'Error inesperado. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(child: Text('📋', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 16),
                Text('EGApp', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Motor de Guías SUNAT',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        
                        if (_isLogin) ...[
                          TextField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passCtrl,
                            decoration: const InputDecoration(labelText: 'Contraseña'),
                            obscureText: true,
                          ),
                        ] else ...[
                          // === REGISTRO ===
                          if (_registerStep == 0) ...[
                            const Text('Paso 1: Identidad', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _dniCtrl,
                              decoration: const InputDecoration(labelText: 'DNI (8 dígitos)'),
                              keyboardType: TextInputType.number,
                              maxLength: 8,
                            ),
                          ] else if (_registerStep == 1) ...[
                            const Text('Paso 2: Validación', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                            const SizedBox(height: 10),
                            Text('Hola ${_dniData?['nombres'] ?? ''}, ingresa el dígito aislado que aparece al lado de tu DNI físico (Código de Verificación).'),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _codigoVerificacionCtrl,
                              decoration: const InputDecoration(labelText: 'Código de Verificación (1 dígito)'),
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                            ),
                          ] else if (_registerStep == 2) ...[
                            const Text('Paso 3: Credenciales', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passCtrl,
                              decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6 caracteres)'),
                              obscureText: true,
                            ),
                          ],
                        ],

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            ),
                            child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        
                        ElevatedButton(
                          onPressed: _loading ? null : () {
                            if (_isLogin) {
                              _submit();
                            } else {
                              if (_registerStep == 0) _validarDNI();
                              else if (_registerStep == 1) _validarCodigo();
                              else if (_registerStep == 2) _submit();
                            }
                          },
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isLogin 
                                  ? 'Ingresar' 
                                  : (_registerStep == 0 ? 'Validar DNI' : _registerStep == 1 ? 'Verificar Código' : 'Registrarme')),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() { 
                              _isLogin = !_isLogin; 
                              _error = null; 
                              _registerStep = 0; 
                              _dniData = null;
                            }),
                            child: Text(
                              _isLogin ? '¿Sin cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión',
                              style: const TextStyle(color: Color(0xFF818CF8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
