import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/providers/auth_provider.dart';

class ConfigurarSunatScreen extends ConsumerStatefulWidget {
  const ConfigurarSunatScreen({super.key});

  @override
  ConsumerState<ConfigurarSunatScreen> createState() => _ConfigurarSunatScreenState();
}

class _ConfigurarSunatScreenState extends ConsumerState<ConfigurarSunatScreen> {
  final _rucCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _loading = false;
  String? _statusMsg;
  bool _success = false;

  static const _backendUrl = 'https://api.sparkingcraft.com/egapp';

  @override
  void dispose() {
    _rucCtrl.dispose(); _usuarioCtrl.dispose(); _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final empresaId = ref.read(empresaActivaProvider);
    if (empresaId == null) {
      setState(() { _statusMsg = 'Selecciona una empresa primero.'; _success = false; });
      return;
    }
    setState(() { _loading = true; _statusMsg = null; });
    try {
      final dio = Dio();
      await dio.post('$_backendUrl/setup-sunat', data: {
        'id_empresa': empresaId,
        'ruc': _rucCtrl.text.trim(),
        'usuario_sol': _usuarioCtrl.text.trim(),
        'clave_sol': _claveCtrl.text,
      });
      setState(() {
        _success = true;
        _statusMsg = 'Proceso encolado. El bot de SUNAT está configurando las credenciales en segundo plano. Recibirás una confirmación en unos minutos.';
        _rucCtrl.clear(); _usuarioCtrl.clear(); _claveCtrl.clear();
      });
    } on DioException catch (e) {
      setState(() {
        _success = false;
        _statusMsg = e.response?.data?['message'] as String? ?? 'Error al conectar con el servidor.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configurar SUNAT', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('El bot ingresará al portal SUNAT automáticamente.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('ℹ️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Al enviar este formulario, un robot abrirá el portal SUNAT, navegará hasta la sección de credenciales API y las guardará encriptadas con AES-256.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _rucCtrl,
            decoration: const InputDecoration(labelText: 'RUC'),
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _usuarioCtrl,
            decoration: const InputDecoration(labelText: 'Usuario SOL'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _claveCtrl,
            decoration: const InputDecoration(labelText: 'Clave SOL'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          if (_statusMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_success ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (_success ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(_success ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_statusMsg!, style: TextStyle(color: _success ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _loading ? null : _enviar,
            icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.settings),
            label: Text(_loading ? 'Procesando...' : 'Iniciar configuración'),
          ),
        ],
      ),
    );
  }
}
