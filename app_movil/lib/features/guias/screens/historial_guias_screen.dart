import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';

class HistorialGuiasScreen extends ConsumerStatefulWidget {
  const HistorialGuiasScreen({super.key});

  @override
  ConsumerState<HistorialGuiasScreen> createState() => _HistorialGuiasScreenState();
}

class _HistorialGuiasScreenState extends ConsumerState<HistorialGuiasScreen> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final empresaId = ref.watch(empresaActivaProvider);

    if (empresaId == null) {
      return const Center(child: Text('Selecciona una empresa para ver el historial.', style: TextStyle(color: Color(0xFF64748B))));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por número de guía...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guias')
                .where('id_empresa', isEqualTo: empresaId)
                .orderBy('emitida_at', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = (snap.data?.docs ?? []).where((d) {
                final data = d.data() as Map<String, dynamic>;
                final num = (data['numero_guia'] as String? ?? '').toLowerCase();
                return _filtro.isEmpty || num.contains(_filtro);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('Sin resultados.', style: TextStyle(color: Color(0xFF64748B))));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final estado = data['estado_sunat'] as String? ?? 'pendiente';
                  final ts = data['emitida_at'] as Timestamp?;
                  final fecha = ts != null ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) : '—';
                  final aceptada = estado == 'aceptada';
                  final docs2 = data['documentos'] as Map<String, dynamic>?;
                  final urlPdf = data['url_pdf'] as String?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      leading: Text(aceptada ? '✅' : '❌', style: const TextStyle(fontSize: 22)),
                      title: Text(
                        data['numero_guia'] as String? ?? '—',
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: Color(0xFF818CF8)),
                      ),
                      subtitle: Text(fecha, style: Theme.of(context).textTheme.bodySmall),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (aceptada ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          aceptada ? 'Aceptada' : 'Rechazada',
                          style: TextStyle(color: aceptada ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              if (data['sunat_descripcion'] != null)
                                _InfoRow(label: 'Resp. SUNAT', value: data['sunat_descripcion'] as String),
                              if (data['qr_data'] != null)
                                _InfoRow(label: 'QR Data', value: data['qr_data'] as String),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _MiniDocBtn(label: 'PDF', url: urlPdf ?? docs2?['url_pdf'] as String?)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _MiniDocBtn(label: 'XML', url: data['url_xml'] as String? ?? docs2?['url_xml'] as String?)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _MiniDocBtn(label: 'CDR', url: data['url_cdr'] as String? ?? docs2?['url_cdr'] as String?)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11))),
        ],
      ),
    );
  }
}

class _MiniDocBtn extends StatelessWidget {
  final String label;
  final String? url;
  const _MiniDocBtn({required this.label, this.url});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: url == null ? null : () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL: $url')));
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: const BorderSide(color: Color(0xFF6366F1)),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
    );
  }
}
