import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class GestionarChoferesScreen extends ConsumerStatefulWidget {
  const GestionarChoferesScreen({super.key});

  @override
  ConsumerState<GestionarChoferesScreen> createState() => _GestionarChoferesScreenState();
}

class _GestionarChoferesScreenState extends ConsumerState<GestionarChoferesScreen> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _invitar() async {
    final empresaId = ref.read(empresaActivaProvider);
    final email = _emailCtrl.text.trim();
    if (empresaId == null || email.isEmpty) return;

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('invitaciones').add({
        'empresa_id': empresaId,
        'email_invitado': email,
        'estado': 'pendiente',
        'creada_at': FieldValue.serverTimestamp(),
      });
      _emailCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitación enviada a $email'), backgroundColor: const Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar invitación.'), backgroundColor: Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresaId = ref.watch(empresaActivaProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestionar Choferes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Invita a tus choferes por correo electrónico.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invitar chofer', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email del chofer', prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF64748B))),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _invitar,
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: const Text('Enviar invitación'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Invitaciones enviadas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (empresaId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('invitaciones')
                  .where('empresa_id', isEqualTo: empresaId)
                  .orderBy('creada_at', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Sin invitaciones enviadas.', style: TextStyle(color: Color(0xFF64748B)))),
                    ),
                  );
                }
                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final estado = data['estado'] as String? ?? 'pendiente';
                    final email = data['email_invitado'] as String? ?? '—';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: Color(0xFF818CF8)),
                        title: Text(email, style: const TextStyle(color: Color(0xFFF1F5F9))),
                        trailing: _EstadoChip(estado: estado),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = estado == 'aceptada' ? const Color(0xFF22C55E) : estado == 'rechazada' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final label = estado == 'aceptada' ? 'Aceptada' : estado == 'rechazada' ? 'Rechazada' : 'Pendiente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
