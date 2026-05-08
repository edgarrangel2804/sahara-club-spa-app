import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

const _kCats = [
  (key: 'masajes',    label: 'Masajes',    color: Color(0xFF8B5CF6)),
  (key: 'faciales',   label: 'Faciales',   color: Color(0xFFEC4899)),
  (key: 'corporales', label: 'Corporales', color: Color(0xFF10B981)),
  (key: 'rituales',   label: 'Rituales',   color: Color(0xFFC6A76A)),
  (key: 'otros',      label: 'Otros',      color: Color(0xFF64B5F6)),
];

const _kDurations = [30, 45, 60, 75, 90, 120, 150, 180];

class AdminServiciosPage extends StatefulWidget {
  const AdminServiciosPage({super.key});

  @override
  State<AdminServiciosPage> createState() => _AdminServiciosPageState();
}

class _AdminServiciosPageState extends State<AdminServiciosPage> {
  final _repo    = SaharaAdminRepository();
  final _currFmt = NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: 0);
  bool   _loading   = true;
  List<Map<String, dynamic>> _services = [];
  String _filterCat = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await _repo.getCatalogServices();
    if (!mounted) return;
    setState(() {
      _services = raw;
      _loading  = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _filterCat == 'all'
      ? _services
      : _services.where((s) => s['category'] == _filterCat).toList();

  Future<void> _openSheet({Map<String, dynamic>? service}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceSheet(repo: _repo, service: service),
    );
    if (changed == true) _load();
  }

  Color _catColor(String? cat) =>
      _kCats.where((c) => c.key == cat).firstOrNull?.color ?? const Color(0xFF64B5F6);

  String _catLabel(String? cat) =>
      _kCats.where((c) => c.key == cat).firstOrNull?.label ?? (cat ?? '');

  IconData _catIcon(String? cat) {
    switch (cat) {
      case 'masajes':    return Icons.self_improvement_rounded;
      case 'faciales':   return Icons.face_retouching_natural_rounded;
      case 'corporales': return Icons.spa_outlined;
      case 'rituales':   return Icons.auto_awesome_rounded;
      default:           return Icons.medical_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(),
        backgroundColor: SaharaColors.gold,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SaharaColors.grayDark),
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: SaharaColors.grayText, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servicios', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w300,
                  )),
                  Text('Catálogo de tratamientos', style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText,
                  )),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SaharaColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
                ),
                child: Text('${_services.length}', style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  // ── Category filter ───────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterPill(
              label: 'Todos',
              active: _filterCat == 'all',
              onTap: () => setState(() => _filterCat = 'all'),
            ),
            ..._kCats.map((c) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterPill(
                label: c.label,
                active: _filterCat == c.key,
                activeColor: c.color,
                onTap: () => setState(() => _filterCat = c.key),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ── Service card ──────────────────────────────────────────────────────────

  Widget _buildCard(Map<String, dynamic> s) {
    final active   = s['is_active'] as bool? ?? true;
    final cat      = s['category'] as String?;
    final catColor = _catColor(cat);
    final price    = (s['price'] as num?)?.toDouble() ?? 0;
    final duration = s['duration_min'] as int? ?? 60;

    return GestureDetector(
      onTap: () => _openSheet(service: s),
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? catColor.withValues(alpha: 0.2)
                  : const Color(0xFF1E1E1E),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_catIcon(cat), color: catColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w600,
                      )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(_catLabel(cat), style: GoogleFonts.inter(
                            fontSize: 9, color: catColor,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          )),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_outlined, size: 11,
                            color: SaharaColors.grayText.withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                        Text('$duration min', style: GoogleFonts.inter(
                          fontSize: 11,
                          color: SaharaColors.grayText.withValues(alpha: 0.7),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currFmt.format(price), style: GoogleFonts.inter(
                    fontSize: 15, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w800,
                  )),
                  if (!active)
                    Text('Inactivo', style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFFEF5350),
                    )),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: SaharaColors.grayText, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.spa_outlined, color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sin servicios en esta categoría',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w300,
            )),
          const SizedBox(height: 8),
          Text('Toca + para agregar un servicio.',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText)),
        ],
      ),
    );
  }
}

// ── Service Sheet ─────────────────────────────────────────────────────────────

class _ServiceSheet extends StatefulWidget {
  final SaharaAdminRepository repo;
  final Map<String, dynamic>? service;
  const _ServiceSheet({required this.repo, this.service});

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtr  = TextEditingController();
  final _descCtr  = TextEditingController();
  final _priceCtr = TextEditingController();

  String _category = 'masajes';
  int    _duration = 60;
  bool   _isActive = true;
  bool   _saving   = false;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.service!;
      _nameCtr.text  = s['name']        as String? ?? '';
      _descCtr.text  = s['description'] as String? ?? '';
      _priceCtr.text = ((s['price'] as num?)?.toInt() ?? 0).toString();
      _category      = s['category']    as String? ?? 'masajes';
      _duration      = s['duration_min'] as int?    ?? 60;
      _isActive      = s['is_active']   as bool?    ?? true;
    }
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
    _priceCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name':         _nameCtr.text.trim(),
        'description':  _descCtr.text.trim(),
        'category':     _category,
        'price':        double.parse(_priceCtr.text),
        'duration_min': _duration,
        'is_active':    _isActive,
      };
      if (_isEdit) {
        await widget.repo.updateService(widget.service!['id'] as String, data);
      } else {
        await widget.repo.createService(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFF2A1010),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isEdit ? 'Editar Servicio' : 'Nuevo Servicio',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w300,
                      )),
                    const SizedBox(height: 24),

                    // ── Nombre ────────────────────────────────────────────
                    _label('NOMBRE'),
                    const SizedBox(height: 8),
                    _textField(_nameCtr, 'ej. Masaje Relajante',
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Requerido' : null),
                    const SizedBox(height: 18),

                    // ── Categoría ─────────────────────────────────────────
                    _label('CATEGORÍA'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _kCats.map((c) {
                        final sel = _category == c.key;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? c.color.withValues(alpha: 0.15)
                                  : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? c.color.withValues(alpha: 0.5)
                                    : const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Text(c.label, style: GoogleFonts.inter(
                              fontSize: 12,
                              color: sel ? c.color : SaharaColors.grayText,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // ── Precio y Duración ──────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('PRECIO (MXN)'),
                              const SizedBox(height: 8),
                              _textField(
                                _priceCtr, '850',
                                inputType: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (v) => (v?.isEmpty ?? true)
                                    ? 'Requerido'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('DURACIÓN'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF2A2A2A)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _kDurations.contains(_duration)
                                        ? _duration
                                        : 60,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1A1A1A),
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: SaharaColors.whiteSoft),
                                    icon: const Icon(
                                        Icons.expand_more_rounded,
                                        color: SaharaColors.grayText,
                                        size: 18),
                                    isDense: true,
                                    items: _kDurations
                                        .map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text('$d min'),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _duration = v ?? 60),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Descripción ───────────────────────────────────────
                    _label('DESCRIPCIÓN (opcional)'),
                    const SizedBox(height: 8),
                    _textField(_descCtr,
                        'Breve descripción del servicio...',
                        maxLines: 3),
                    const SizedBox(height: 18),

                    // ── Activo toggle (edit only) ─────────────────────────
                    if (_isEdit) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _isActive
                                  ? const Color(0xFF4CAF50)
                                  : SaharaColors.grayText,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Servicio activo',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: SaharaColors.whiteSoft)),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (v) =>
                                  setState(() => _isActive = v),
                              activeThumbColor: const Color(0xFF4CAF50),
                              activeTrackColor: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.25),
                              inactiveThumbColor: SaharaColors.grayText
                                  .withValues(alpha: 0.4),
                              inactiveTrackColor:
                                  Colors.white.withValues(alpha: 0.06),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // ── Save ──────────────────────────────────────────────
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _saving
                              ? SaharaColors.gold.withValues(alpha: 0.5)
                              : SaharaColors.gold,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _saving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : Text(
                                  _isEdit
                                      ? 'Guardar cambios'
                                      : 'Crear servicio',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, color: SaharaColors.grayText,
    fontWeight: FontWeight.w700, letterSpacing: 1.2,
  ));

  Widget _textField(
    TextEditingController ctr,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? inputType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctr,
      validator: validator,
      keyboardType: inputType,
      inputFormatters: formatters,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: SaharaColors.grayText.withValues(alpha: 0.5)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: SaharaColors.gold.withValues(alpha: 0.5))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5350))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Filter Pill ───────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor = SaharaColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.4)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12,
          color: active ? activeColor : SaharaColors.grayText,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        )),
      ),
    );
  }
}
