import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egapp_movil/features/auth/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/home', label: 'Inicio', icon: Icons.home_rounded),
    (path: '/emitir', label: 'Emitir', icon: Icons.add_circle_rounded),
    (path: '/historial', label: 'Historial', icon: Icons.receipt_long_rounded),
    (path: '/configurar-sunat', label: 'Config.', icon: Icons.settings_rounded),
  ];

  int _indexFromPath(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empresas = ref.watch(empresasDelUsuarioProvider);
    final empresaActiva = ref.watch(empresaActivaProvider);
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('EGApp'),
            const SizedBox(width: 8),
            Expanded(
              child: empresas.when(
                data: (lista) {
                  if (lista.isEmpty) {
                    return TextButton.icon(
                      onPressed: () => context.push('/seleccionar-empresa'),
                      icon: const Icon(Icons.add,
                          size: 16, color: Color(0xFF6366F1)),
                      label: const Text('Crear empresa',
                          style: TextStyle(
                              color: Color(0xFF6366F1), fontSize: 12)),
                    );
                  }
                  final nombre = lista.firstWhere(
                        (e) => e['id'] == empresaActiva,
                        orElse: () => lista.first,
                      )['ruc'] as String? ??
                      'Empresa';
                  return GestureDetector(
                    onTap: () => context.push('/seleccionar-empresa'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business,
                              size: 12, color: Color(0xFF818CF8)),
                          const SizedBox(width: 4),
                          Text(nombre,
                              style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Icon(Icons.arrow_drop_down,
                              size: 16, color: Color(0xFF818CF8)),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFFBBF24)),
            tooltip: 'Asistente IA',
            onPressed: () => _abrirAsistenteIA(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService.logout();
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFromPath(location),
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs
            .map((t) =>
                BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }

  void _abrirAsistenteIA(BuildContext context) {
    final textCtrl = TextEditingController();
    bool procesando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFFFBBF24), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Asistente IA',
                            style: TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        Text('Describe tu guía en lenguaje natural',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  style:
                      const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Ej: Llevo 50kg de cemento a la obra en Lima, transporte privado placa ABC-123, chofer DNI 12345678...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF475569), fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E1E2E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E1E2E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F0F1A),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: procesando
                        ? null
                        : () async {
                            if (textCtrl.text.trim().isEmpty) return;
                            setModalState(() => procesando = true);
                            await Future.delayed(const Duration(seconds: 2));
                            setModalState(() => procesando = false);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    icon: procesando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                        procesando ? 'Procesando...' : 'Autocompletar Guía',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
