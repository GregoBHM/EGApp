import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class SeleccionarEmpresaScreen extends ConsumerStatefulWidget {
  const SeleccionarEmpresaScreen({super.key});

  @override
  ConsumerState<SeleccionarEmpresaScreen> createState() => _SeleccionarEmpresaScreenState();
}

class _SeleccionarEmpresaScreenState extends ConsumerState<SeleccionarEmpresaScreen> {
  final _rucCtrl = TextEditingController();
  bool _creando = false;

  @override
  void dispose() {
    _rucCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearEmpresa() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _rucCtrl.text.length != 11) return;
    setState(() => _creando = true);
    try {
      final ruc = _rucCtrl.text.trim();
      final docRef = FirebaseFirestore.instance.collection('empresas').doc(ruc);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'ruc': ruc,
          'admin_uid': user.uid,
          'miembros': [user.uid],
          'estado_onboarding': 'pendiente',
          'creada_at': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snap.data()!;
        final miembros = List<String>.from(data['miembros'] as List? ?? []);
        if (!miembros.contains(user.uid)) {
          miembros.add(user.uid);
          await docRef.update({'miembros': miembros});
        }
      }
      ref.read(empresaActivaProvider.notifier).state = ruc;
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresas = ref.watch(empresasDelUsuarioProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Empresa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mis empresas', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            empresas.when(
              data: (lista) {
                if (lista.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text('No tienes empresas aún. Crea una abajo.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }
                return Column(
                  children: lista.map((e) {
                    final id = e['id'] as String;
                    final ruc = e['ruc'] as String? ?? id;
                    final estado = e['estado_onboarding'] as String? ?? 'pendiente';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.business, color: Color(0xFF6366F1)),
                        title: Text('RUC: $ruc', style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700)),
                        subtitle: Text('SUNAT: $estado', style: Theme.of(context).textTheme.bodySmall),
                        trailing: ElevatedButton(
                          onPressed: () {
                            ref.read(empresaActivaProvider.notifier).state = id;
                            context.go('/home');
                          },
                          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                          child: const Text('Seleccionar'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error cargando empresas.'),
            ),
            const SizedBox(height: 32),
            Text('Registrar nueva empresa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _rucCtrl,
                      decoration: const InputDecoration(labelText: 'RUC de la empresa (11 dígitos)'),
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _creando ? null : _crearEmpresa,
                      icon: _creando
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_business),
                      label: const Text('Registrar empresa'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
