import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

const _kSpecialties = [
  (key: 'massage',        label: 'Masajes'),
  (key: 'facial',         label: 'Faciales'),
  (key: 'body_treatment', label: 'Corporales'),
  (key: 'nail_care',      label: 'Uñas'),
  (key: 'hair_removal',   label: 'Depilación'),
  (key: 'hydrotherapy',   label: 'Hidroterapia'),
  (key: 'general',        label: 'General'),
];

class AdminEquipoPage extends StatefulWidget {
  const AdminEquipoPage({super.key});

  @override
  State<AdminEquipoPage> createState() => _AdminEquipoPageState();
}

class _AdminEquipoPageState extends State<AdminEquipoPage> {
  final _repo = SaharaAdminRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _therapists = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await _repo.getCatalogTherapists();
    if (!mounted) return;
    setState(() {
      _therapists = raw;
      _loading    = false;
    });
  }

  Future<void> _openSheet(Map<String, dynamic> t) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TerapeutaSheet(repo: _repo, therapist: t),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5))
                : _therapists.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        itemCount: _therapists.length,
                        itemBuilder: (_, i) => _buildCard(_therapists[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final active = _therapists.where((t) => t['is_active'] == true).length;

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
                  Text('Equipo', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w300,
                  )),
                  Text('Terapeutas del spa', style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText,
                  )),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$active activos', style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  )),
                  Text('${_therapists.length} total', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.grayText,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 0.5,
              color: SaharaColors.gold.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  // ── Therapist card ────────────────────────────────────────────────────────

  Widget _buildCard(Map<String, dynamic> t) {
    final name     = t['full_name']     as String? ?? 'Terapeuta';
    final specialty = t['specialty']   as String?;
    final commPct  = (t['commission_pct'] as num?)?.toDouble() ?? 20.0;
    final active   = t['is_active']    as bool?   ?? true;

    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final specialtyLabel =
        _kSpecialties.where((s) => s.key == specialty).firstOrNull?.label;

    return GestureDetector(
      onTap: () => _openSheet(t),
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
                  ? SaharaColors.gold.withValues(alpha: 0.15)
                  : const Color(0xFF1E1E1E),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: SaharaColors.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: SaharaColors.gold.withValues(alpha: 0.3)),
                ),
                child: Center(child: Text(initials, style: GoogleFonts.inter(
                  fontSize: 15, color: SaharaColors.gold,
                  fontWeight: FontWeight.w700,
                ))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(
                      fontSize: 14, color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (specialtyLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SaharaColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(specialtyLabel, style: GoogleFonts.inter(
                              fontSize: 9, color: SaharaColors.gold,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5,
                            )),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text('${commPct.toStringAsFixed(0)}% comisión',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: SaharaColors.grayText,
                          )),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(active ? 'Activo' : 'Inactivo',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: active
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350),
                    )),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: SaharaColors.grayText, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

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
              border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.self_improvement_rounded,
                color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sin terapeutas registrados',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w300,
            )),
          const SizedBox(height: 8),
          Text(
            'Los terapeutas aparecerán aquí\nuna vez que se registren en la app.',
            style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.grayText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Terapeuta Sheet ───────────────────────────────────────────────────────────

class _TerapeutaSheet extends StatefulWidget {
  final SaharaAdminRepository repo;
  final Map<String, dynamic> therapist;
  const _TerapeutaSheet({required this.repo, required this.therapist});

  @override
  State<_TerapeutaSheet> createState() => _TerapeutaSheetState();
}

class _TerapeutaSheetState extends State<_TerapeutaSheet> {
  final _bioCtr  = TextEditingController();
  final _commCtr = TextEditingController();

  String? _specialty;
  bool    _isActive = true;
  bool    _saving   = false;

  @override
  void initState() {
    super.initState();
    final t = widget.therapist;
    _specialty = t['specialty'] as String?;
    _isActive  = t['is_active'] as bool? ?? true;
    _bioCtr.text  = t['bio'] as String? ?? '';
    _commCtr.text =
        ((t['commission_pct'] as num?)?.toInt() ?? 20).toString();
  }

  @override
  void dispose() {
    _bioCtr.dispose();
    _commCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateTherapist(
        widget.therapist['id'] as String,
        {
          'specialty':     _specialty,
          'commission_pct': double.tryParse(_commCtr.text) ?? 20.0,
          'bio':           _bioCtr.text.trim(),
          'is_active':     _isActive,
        },
      );
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
    final name = widget.therapist['full_name'] as String? ?? 'Terapeuta';
    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + nombre ───────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: SaharaColors.gold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  SaharaColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Center(child: Text(initials,
                          style: GoogleFonts.inter(
                            fontSize: 18, color: SaharaColors.gold,
                            fontWeight: FontWeight.w700,
                          ))),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.inter(
                            fontSize: 16, color: SaharaColors.whiteSoft,
                            fontWeight: FontWeight.w600,
                          )),
                          Text('Terapeuta', style: GoogleFonts.inter(
                            fontSize: 12, color: SaharaColors.grayText,
                          )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Especialidad ──────────────────────────────────────
                  _label('ESPECIALIDAD'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _kSpecialties.map((s) {
                      final sel = _specialty == s.key;
                      return GestureDetector(
                        onTap: () => setState(() => _specialty = s.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? SaharaColors.gold.withValues(alpha: 0.12)
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? SaharaColors.gold.withValues(alpha: 0.4)
                                  : const Color(0xFF2A2A2A),
                            ),
                          ),
                          child: Text(s.label, style: GoogleFonts.inter(
                            fontSize: 12,
                            color: sel
                                ? SaharaColors.gold
                                : SaharaColors.grayText,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // ── Comisión ──────────────────────────────────────────
                  _label('COMISIÓN (%)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commCtr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: GoogleFonts.inter(
                        fontSize: 14, color: SaharaColors.whiteSoft),
                    decoration: InputDecoration(
                      hintText: '20',
                      hintStyle: GoogleFonts.inter(
                          color:
                              SaharaColors.grayText.withValues(alpha: 0.5)),
                      suffixText: '%',
                      suffixStyle: GoogleFonts.inter(
                          color: SaharaColors.grayText),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: SaharaColors.gold
                                  .withValues(alpha: 0.5))),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Bio ───────────────────────────────────────────────
                  _label('BIO (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtr,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: SaharaColors.whiteSoft),
                    decoration: InputDecoration(
                      hintText:
                          'Breve presentación del terapeuta...',
                      hintStyle: GoogleFonts.inter(
                          color:
                              SaharaColors.grayText.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: SaharaColors.gold
                                  .withValues(alpha: 0.5))),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Activo toggle ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isActive
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          color: _isActive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Terapeuta activo',
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

                  // ── Save ──────────────────────────────────────────────
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                                    color: Colors.black,
                                    strokeWidth: 2))
                            : Text('Guardar cambios',
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
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, color: SaharaColors.grayText,
    fontWeight: FontWeight.w700, letterSpacing: 1.2,
  ));
}
