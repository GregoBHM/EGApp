import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/providers/auth_provider.dart';

const _kAccent = Color(0xFF6366F1);
const _kSurface = Color(0xFF0D0D14);
const _kCard = Color(0xFF13131A);
const _kBorder = Color(0xFF1E1E2E);
const _kMuted = Color(0xFF64748B);
const _kText = Color(0xFFF1F5F9);
const _kSubtext = Color(0xFF94A3B8);
const _kError = Color(0xFFEF4444);
const _kSuccess = Color(0xFF22C55E);

const _backendUrl = 'https://api.sparkingcraft.com/egapp';

const _motivoItems = [
  ('01', 'Venta'),
  ('02', 'Compra'),
  ('03', 'Venta con entrega a terceros'),
  ('04', 'Traslado entre establecimientos'),
  ('08', 'Importación'),
  ('09', 'Exportación'),
  ('13', 'Otros'),
  ('14', 'Venta sujeta a confirmación'),
  ('18', 'Traslado emisor itinerante'),
  ('19', 'Traslado a zona primaria'),
  ('21', 'Devolución'),
  ('22', 'Recojo de bienes transformados'),
  ('23', 'Traslado por recaudación SUNAT'),
  ('24', 'Traslado por devolución'),
];

class EmitirGuiaScreen extends ConsumerStatefulWidget {
  const EmitirGuiaScreen({super.key});

  @override
  ConsumerState<EmitirGuiaScreen> createState() => _EmitirGuiaScreenState();
}

class _EmitirGuiaScreenState extends ConsumerState<EmitirGuiaScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;
  bool _loadingDni = false;
  Map<String, dynamic>? _resultado;

  late AnimationController _stepAnimCtrl;
  late Animation<double> _stepFade;

  String _tipoGuia = 'REMITENTE';
  String _motivoCodigo = '01';
  String _modalidad = 'PRIVADO';

  final _fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _pesoCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _dniChoferCtrl = TextEditingController();
  final _rucTransportistaCtrl = TextEditingController();
  final _razonSocialCtrl = TextEditingController();
  final _origenUbigeoCtrl = TextEditingController();
  final _origenDireccionCtrl = TextEditingController();
  final _destinoUbigeoCtrl = TextEditingController();
  final _destinoDireccionCtrl = TextEditingController();
  final _destinatarioDniCtrl = TextEditingController();
  final _destinatarioNombreCtrl = TextEditingController();
  final List<Map<String, dynamic>> _bienes = [];

  final _bienCodigoCtrl = TextEditingController();
  final _bienDescCtrl = TextEditingController();
  final _bienCantCtrl = TextEditingController();
  String _bienUnidad = 'NIU';

  @override
  void initState() {
    super.initState();
    _stepAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _stepFade = CurvedAnimation(parent: _stepAnimCtrl, curve: Curves.easeInOut);
    _stepAnimCtrl.forward();
  }

  @override
  void dispose() {
    _stepAnimCtrl.dispose();
    _fechaCtrl.dispose(); _pesoCtrl.dispose(); _placaCtrl.dispose();
    _dniChoferCtrl.dispose(); _rucTransportistaCtrl.dispose(); _razonSocialCtrl.dispose();
    _origenUbigeoCtrl.dispose(); _origenDireccionCtrl.dispose();
    _destinoUbigeoCtrl.dispose(); _destinoDireccionCtrl.dispose();
    _destinatarioDniCtrl.dispose(); _destinatarioNombreCtrl.dispose();
    _bienCodigoCtrl.dispose(); _bienDescCtrl.dispose(); _bienCantCtrl.dispose();
    super.dispose();
  }

  void _goStep(int next) {
    _stepAnimCtrl.reverse().then((_) {
      setState(() => _step = next);
      _stepAnimCtrl.forward();
    });
  }

  void _addBien() {
    if (_bienDescCtrl.text.trim().isEmpty || _bienCantCtrl.text.trim().isEmpty) return;
    setState(() {
      _bienes.add({
        'codigo': _bienCodigoCtrl.text.isEmpty ? 'PROD${_bienes.length + 1}' : _bienCodigoCtrl.text,
        'descripcion': _bienDescCtrl.text.trim(),
        'cantidad': int.tryParse(_bienCantCtrl.text) ?? 1,
        'unidad_medida': _bienUnidad,
      });
      _bienCodigoCtrl.clear(); _bienDescCtrl.clear(); _bienCantCtrl.clear();
    });
  }

  Future<void> _buscarDni(String dni) async {
    if (dni.length != 8) return;
    setState(() => _loadingDni = true);
    try {
      final response = await Dio().get('$_backendUrl/api/dni/$dni');
      final data = response.data['data'] as Map<String, dynamic>;
      setState(() {
        _destinatarioNombreCtrl.text =
            '${data['nombres']} ${data['apellidoPaterno']} ${data['apellidoMaterno']}';
      });
    } catch (_) {
      _showError('No se encontraron datos para ese DNI.');
    } finally {
      if (mounted) setState(() => _loadingDni = false);
    }
  }

  Future<void> _emitir() async {
    final empresaId = ref.read(empresaActivaProvider);
    if (empresaId == null) { _showError('Selecciona una empresa primero.'); return; }
    if (_bienes.isEmpty) { _showError('Agrega al menos un bien.'); return; }
    setState(() => _loading = true);
    try {
      final trasladoData = {
        'motivo_codigo': _motivoCodigo,
        'modalidad': _modalidad,
        'fecha_inicio': _fechaCtrl.text,
        'peso_total_kg': double.tryParse(_pesoCtrl.text) ?? 0,
        'punto_partida': {'ubigeo': _origenUbigeoCtrl.text, 'direccion': _origenDireccionCtrl.text},
        'punto_llegada': {'ubigeo': _destinoUbigeoCtrl.text, 'direccion': _destinoDireccionCtrl.text},
      };
      if (_modalidad == 'PRIVADO') {
        trasladoData['placa_vehiculo'] = _placaCtrl.text;
        trasladoData['dni_chofer'] = _dniChoferCtrl.text;
      } else {
        trasladoData['ruc_transportista'] = _rucTransportistaCtrl.text;
        trasladoData['razon_social_transportista'] = _razonSocialCtrl.text;
      }
      final response = await Dio().post('$_backendUrl/api/emitir-guia', data: {
        'id_empresa': empresaId,
        'tipo_guia': _tipoGuia,
        'datos_traslado': trasladoData,
        'bienes_transportados': _bienes,
      });
      setState(() => _resultado = response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _showError(e.response?.data?['message'] as String? ?? 'Error al conectar con el servidor.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: _kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resultado != null) {
      return _ResultadoView(
        data: _resultado!,
        onNueva: () => setState(() { _resultado = null; _step = 0; _bienes.clear(); }),
      );
    }

    const stepLabels = ['Traslado', 'Ruta', 'Bienes'];

    return Form(
      key: _formKey,
      child: Column(
        children: [
          _StepHeader(current: _step, labels: stepLabels),
          Expanded(
            child: FadeTransition(
              opacity: _stepFade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: [
                      _buildPaso1(),
                      _buildPaso2(),
                      _buildPaso3(),
                    ][_step],
                  ),
                ),
              ),
            ),
          ),
          _BottomBar(
            step: _step,
            loading: _loading,
            canAdvance: _step < 2 ? true : _bienes.isNotEmpty,
            onBack: () => _goStep(_step - 1),
            onNext: () => _goStep(_step + 1),
            onEmitir: _emitir,
          ),
        ],
      ),
    );
  }

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.description_outlined, label: 'Tipo y Motivo'),
        const SizedBox(height: 16),
        _ToggleGroup(
          label: 'Tipo de Guía',
          options: const [('REMITENTE', 'Remitente'), ('TRANSPORTISTA', 'Transportista')],
          selected: _tipoGuia,
          onChanged: (v) => setState(() => _tipoGuia = v),
        ),
        const SizedBox(height: 16),
        _AppDropdown<String>(
          label: 'Motivo de Traslado',
          value: _motivoCodigo,
          items: _motivoItems.map((m) => DropdownMenuItem(value: m.$1, child: Text('${m.$1} — ${m.$2}'))).toList(),
          onChanged: (v) => setState(() => _motivoCodigo = v!),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(icon: Icons.person_outline, label: 'Destinatario'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AppField(
                controller: _destinatarioDniCtrl,
                label: 'DNI / RUC del Destinatario',
                keyboard: TextInputType.number,
                onChanged: (v) { if (v.length == 8) _buscarDni(v); },
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              child: _loadingDni
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent)))
                  : Container(
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.search, color: _kAccent, size: 20),
                    ),
            ),
          ],
        ),
        if (_destinatarioNombreCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoChip(label: _destinatarioNombreCtrl.text, icon: Icons.check_circle_outline),
        ],
        const SizedBox(height: 24),
        const _SectionTitle(icon: Icons.local_shipping_outlined, label: 'Modalidad de Transporte'),
        const SizedBox(height: 16),
        _ToggleGroup(
          label: 'Modalidad',
          options: const [('PRIVADO', '🚘 Privado'), ('PUBLICO', '🚚 Público')],
          selected: _modalidad,
          onChanged: (v) => setState(() => _modalidad = v),
        ),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _modalidad == 'PRIVADO' ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              _AppField(
                controller: _placaCtrl,
                label: 'Placa del Vehículo',
                capitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: _dniChoferCtrl,
                label: 'DNI del Chofer',
                keyboard: TextInputType.number,
              ),
            ],
          ),
          secondChild: Column(
            children: [
              _AppField(
                controller: _rucTransportistaCtrl,
                label: 'RUC Empresa de Transportes',
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _AppField(
                controller: _razonSocialCtrl,
                label: 'Razón Social Transportista',
                capitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(icon: Icons.calendar_today_outlined, label: 'Fecha'),
        const SizedBox(height: 16),
        _AppField(
          controller: _fechaCtrl,
          label: 'Fecha de Inicio (YYYY-MM-DD)',
          keyboard: TextInputType.datetime,
        ),
        const SizedBox(height: 14),
        _AppField(
          controller: _pesoCtrl,
          label: 'Peso Bruto Total (KG)',
          keyboard: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.location_on_outlined, label: 'Punto de Partida'),
        const SizedBox(height: 16),
        _AppField(controller: _origenUbigeoCtrl, label: 'Ubigeo Origen (ej: 150101)', keyboard: TextInputType.number),
        const SizedBox(height: 14),
        _AppField(controller: _origenDireccionCtrl, label: 'Dirección de Origen', capitalization: TextCapitalization.sentences),
        const SizedBox(height: 28),
        _DottedDivider(),
        const SizedBox(height: 28),
        const _SectionTitle(icon: Icons.flag_outlined, label: 'Punto de Llegada'),
        const SizedBox(height: 16),
        _AppField(controller: _destinoUbigeoCtrl, label: 'Ubigeo Destino (ej: 040101)', keyboard: TextInputType.number),
        const SizedBox(height: 14),
        _AppField(controller: _destinoDireccionCtrl, label: 'Dirección de Destino', capitalization: TextCapitalization.sentences),
      ],
    );
  }

  Widget _buildPaso3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.inventory_2_outlined, label: 'Agregar Bien'),
        const SizedBox(height: 16),
        _AppCard(
          child: Column(
            children: [
              _AppField(controller: _bienCodigoCtrl, label: 'Código (opcional)'),
              const SizedBox(height: 12),
              _AppField(controller: _bienDescCtrl, label: 'Descripción *', capitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AppField(controller: _bienCantCtrl, label: 'Cantidad *', keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AppDropdown<String>(
                      label: 'Unidad',
                      value: _bienUnidad,
                      items: const [
                        DropdownMenuItem(value: 'NIU', child: Text('NIU — Unidad')),
                        DropdownMenuItem(value: 'KGM', child: Text('KGM — Kg')),
                        DropdownMenuItem(value: 'TNE', child: Text('TNE — Ton')),
                        DropdownMenuItem(value: 'LTR', child: Text('LTR — Litro')),
                        DropdownMenuItem(value: 'MTR', child: Text('MTR — Metro')),
                      ],
                      onChanged: (v) => setState(() => _bienUnidad = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addBien,
                  icon: const Icon(Icons.add_circle_outline, color: _kAccent),
                  label: const Text('Agregar Bien', style: TextStyle(color: _kAccent, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: _kAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_bienes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(icon: Icons.checklist_rtl_outlined, label: '${_bienes.length} bien(es) registrado(s)'),
          const SizedBox(height: 12),
          ...List.generate(_bienes.length, (i) => _BienCard(
            bien: _bienes[i],
            onDelete: () => setState(() => _bienes.removeAt(i)),
          )),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _kAccent),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  const _AppField({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      onChanged: onChanged,
      style: const TextStyle(color: _kText),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _AppDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _AppDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      dropdownColor: _kCard,
      style: const TextStyle(color: _kText, fontSize: 14),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _AppCard extends StatelessWidget {
  final Widget child;
  const _AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final String label;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ToggleGroup({required this.label, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _kAccent : _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _kAccent : _kBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                opt.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : _kMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kSuccess.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kSuccess),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: _kSuccess, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.more_vert, color: _kBorder, size: 20),
        Expanded(child: Container(height: 1, color: _kBorder)),
        const Icon(Icons.arrow_downward, color: _kAccent, size: 18),
        Expanded(child: Container(height: 1, color: _kBorder)),
      ],
    );
  }
}

class _BienCard extends StatelessWidget {
  final Map<String, dynamic> bien;
  final VoidCallback onDelete;
  const _BienCard({required this.bien, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _kAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bien['descripcion'] as String, style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${bien['cantidad']} ${bien['unidad_medida']} · ${bien['codigo']}', style: const TextStyle(color: _kMuted, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: _kError, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int current;
  final List<String> labels;
  const _StepHeader({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: stepIndex < current ? _kAccent : _kBorder,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < current;
          final isActive = stepIndex == current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive ? _kAccent : _kCard,
                  border: Border.all(color: isDone || isActive ? _kAccent : _kBorder, width: 2),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${stepIndex + 1}', style: TextStyle(
                          color: isActive ? Colors.white : _kMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        )),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[stepIndex], style: TextStyle(
                color: isActive ? _kText : _kMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              )),
            ],
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final bool loading;
  final bool canAdvance;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onEmitir;
  const _BottomBar({required this.step, required this.loading, required this.canAdvance, required this.onBack, required this.onNext, required this.onEmitir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          if (step > 0) ...[
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                onPressed: loading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: _kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.arrow_back, color: _kSubtext),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loading || !canAdvance ? null : (step < 2 ? onNext : onEmitir),
                style: ElevatedButton.styleFrom(
                  backgroundColor: step < 2 ? _kAccent : _kSuccess,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(step < 2 ? Icons.arrow_forward : Icons.bolt_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(step < 2 ? 'Siguiente' : 'Emitir a SUNAT', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoView extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNueva;
  const _ResultadoView({required this.data, required this.onNueva});

  @override
  Widget build(BuildContext context) {
    final aceptada = data['estado_sunat'] == 'aceptada';
    final docs = data['documentos'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (aceptada ? _kSuccess : _kError).withValues(alpha: 0.15),
              border: Border.all(color: aceptada ? _kSuccess : _kError, width: 2),
            ),
            child: Icon(
              aceptada ? Icons.check_rounded : Icons.close_rounded,
              color: aceptada ? _kSuccess : _kError,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            aceptada ? 'Guía Emitida con Éxito' : 'Guía Rechazada',
            style: TextStyle(color: aceptada ? _kSuccess : _kError, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            data['numero_guia'] as String? ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 20, color: _kAccent, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
          const SizedBox(height: 40),
          if (docs != null) ...[
            _DocButton(label: '📄 Ver PDF', url: docs['url_pdf'] as String?),
            const SizedBox(height: 12),
            _DocButton(label: '🗂 Descargar XML', url: docs['url_xml'] as String?),
            const SizedBox(height: 12),
            _DocButton(label: '📋 Descargar CDR', url: docs['url_cdr'] as String?),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onNueva,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Emitir Nueva Guía', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocButton extends StatelessWidget {
  final String label;
  final String? url;
  const _DocButton({required this.label, this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: url == null ? null : () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abriendo: $url'), behavior: SnackBarBehavior.floating));
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(color: _kSubtext, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
