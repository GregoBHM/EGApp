import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      } else {
        await AuthService.register(_emailCtrl.text.trim(), _passCtrl.text.trim(), _nombreCtrl.text.trim());
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
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nombreCtrl,
                            decoration: const InputDecoration(labelText: 'Nombre completo'),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 14),
                        ],
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
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isLogin ? 'Ingresar' : 'Registrarme'),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
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
