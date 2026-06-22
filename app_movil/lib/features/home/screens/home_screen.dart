import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empresaId = ref.watch(empresaActivaProvider);
    final user = ref.watch(currentUserProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buenos días 👋',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            user?.displayName ?? user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (empresaId == null)
            _NoEmpresaCard(onTap: () => context.push('/seleccionar-empresa'))
          else ...[
            _StatsRow(empresaId: empresaId),
            const SizedBox(height: 24),
            Text('Guías recientes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _GuiasRecientes(empresaId: empresaId),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: empresaId == null ? null : () => context.go('/emitir'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Emitir nueva guía'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEmpresaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoEmpresaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🏢', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Sin empresa seleccionada', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Crea o únete a una empresa para comenzar a emitir guías.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onTap, child: const Text('Configurar empresa')),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String empresaId;
  const _StatsRow({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('guias')
          .where('id_empresa', isEqualTo: empresaId)
          .snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        final hoy = snap.data?.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final ts = data['emitida_at'] as Timestamp?;
          if (ts == null) return false;
          final date = ts.toDate();
          final now = DateTime.now();
          return date.day == now.day && date.month == now.month && date.year == now.year;
        }).length ?? 0;

        return Row(
          children: [
            Expanded(child: _StatCard(label: 'Total guías', value: '$total', icon: '📄')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Hoy', value: '$hoy', icon: '🕐')),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFF1F5F9))),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _GuiasRecientes extends StatelessWidget {
  final String empresaId;
  const _GuiasRecientes({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('guias')
          .where('id_empresa', isEqualTo: empresaId)
          .orderBy('emitida_at', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Sin guías emitidas aún.', style: TextStyle(color: Color(0xFF64748B)))),
            ),
          );
        }
        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final estado = data['estado_sunat'] as String? ?? 'pendiente';
            final ts = data['emitida_at'] as Timestamp?;
            final fecha = ts != null ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) : '—';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  estado == 'aceptada' ? '✅' : '❌',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(data['numero_guia'] as String? ?? '—', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: Color(0xFF818CF8))),
                subtitle: Text(fecha, style: Theme.of(context).textTheme.bodySmall),
                trailing: _EstadoBadge(estado: estado),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isAceptada = estado == 'aceptada';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isAceptada ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAceptada ? 'Aceptada' : 'Rechazada',
        style: TextStyle(
          color: isAceptada ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
