import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

class AdminTerapeutasPage extends StatefulWidget {
  const AdminTerapeutasPage({super.key});

  @override
  State<AdminTerapeutasPage> createState() => _AdminTerapeutasPageState();
}

class _AdminTerapeutasPageState extends State<AdminTerapeutasPage> {
  final _repo = SaharaAdminRepository();
  DateTime _month   = DateTime(DateTime.now().year, DateTime.now().month);
  bool     _loading = true;
  List<Map<String, dynamic>> _terapeutas = [];

  static final _monthFmt = DateFormat("MMMM yyyy", 'es');
  static final _currFmt  = NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _terapeutas = await _repo.getTerapeutasDetalle(_month);
    if (mounted) setState(() => _loading = false);
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year < now.year || (_month.year == now.year && _month.month < now.month)) {
      setState(() => _month = DateTime(_month.year, _month.month + 1));
      _load();
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  // Aggregates
  int    get _totalServices  => _terapeutas.fold(0, (s, t) => s + (t['services_count'] as int));
  double get _totalRevenue   => _terapeutas.fold(0.0, (s, t) => s + (t['revenue'] as double));
  double get _totalComission => _terapeutas.fold(0.0, (s, t) => s + (t['commission'] as double));

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
                : RefreshIndicator(
                    onRefresh: _load,
                    color: SaharaColors.gold,
                    child: _terapeutas.isEmpty
                        ? _buildEmpty()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                            children: [
                              _buildSummary(),
                              const SizedBox(height: 28),
                              _sectionLabel('TERAPEUTAS'),
                              const SizedBox(height: 14),
                              ..._terapeutas.map(_buildCard),
                            ],
                          ),
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
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
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
              Text('Terapeutas', style: GoogleFonts.playfairDisplay(
                fontSize: 22, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
              )),
              const Spacer(),
              _MonthBtn(icon: Icons.chevron_left,  onTap: _prevMonth),
              const SizedBox(width: 6),
              Text(
                _monthFmt.format(_month).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11, color: SaharaColors.gold,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              _MonthBtn(icon: Icons.chevron_right, onTap: _isCurrentMonth ? null : _nextMonth),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────────────────────

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(child: _SummaryCard(
          label: 'Servicios',
          value: '$_totalServices',
          icon: Icons.spa_rounded,
          color: SaharaColors.gold,
        )),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(
          label: 'Ingresos',
          value: _currFmt.format(_totalRevenue),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
        )),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(
          label: 'Comisiones',
          value: _currFmt.format(_totalComission),
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFFFFB74D),
        )),
      ],
    );
  }

  // ── Therapist card ────────────────────────────────────────────────────────

  Widget _buildCard(Map<String, dynamic> t) {
    final name        = t['name'] as String;
    final specialty   = t['specialty'] as String?;
    final count       = t['services_count'] as int;
    final revenue     = t['revenue'] as double;
    final commission  = t['commission'] as double;
    final commPct     = t['commission_pct'] as double;
    final occupancy   = (t['occupancy'] as double) / 100;
    final topSvcs     = (t['top_services'] as List).cast<Map<String, dynamic>>();
    final initials    = name.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return GestureDetector(
      onTap: () => _showDetail(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + services badge
            Row(
              children: [
                _Avatar(initials: initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(
                        fontSize: 15, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600,
                      )),
                      if (specialty != null)
                        Text(specialty, style: GoogleFonts.inter(
                          fontSize: 11, color: SaharaColors.grayText,
                        )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SaharaColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text('$count servicios', style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Occupancy bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ocupación del mes', style: GoogleFonts.inter(
                            fontSize: 10, color: SaharaColors.grayText,
                          )),
                          Text('${(occupancy * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 10, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                            )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: occupancy.clamp(0.0, 1.0),
                          backgroundColor: SaharaColors.gold.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(SaharaColors.gold),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Revenue + commission
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Ingresos',
                    value: _currFmt.format(revenue),
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    label: 'Comisión (${commPct.toStringAsFixed(0)}%)',
                    value: _currFmt.format(commission),
                    color: const Color(0xFFFFB74D),
                  ),
                ),
              ],
            ),

            // Top services chips
            if (topSvcs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: topSvcs.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${s['name']}  ×${s['count']}',
                      style: GoogleFonts.inter(
                        fontSize: 10, color: SaharaColors.grayText,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Detail bottom sheet ───────────────────────────────────────────────────

  void _showDetail(Map<String, dynamic> t) {
    final name       = t['name'] as String;
    final specialty  = t['specialty'] as String?;
    final count      = t['services_count'] as int;
    final revenue    = t['revenue'] as double;
    final commission = t['commission'] as double;
    final commPct    = t['commission_pct'] as double;
    final topSvcs    = (t['top_services'] as List).cast<Map<String, dynamic>>();
    final initials   = name.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile
            Row(
              children: [
                _Avatar(initials: initials, size: 52),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.playfairDisplay(
                      fontSize: 20, color: SaharaColors.whiteSoft,
                    )),
                    if (specialty != null)
                      Text(specialty, style: GoogleFonts.inter(
                        fontSize: 12, color: SaharaColors.grayText,
                      )),
                    Text(_monthFmt.format(_month), style: GoogleFonts.inter(
                      fontSize: 11, color: SaharaColors.gold.withValues(alpha: 0.7),
                    )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(child: _DetailStat(
                  label: 'Servicios', value: '$count',
                  color: SaharaColors.gold,
                )),
                const SizedBox(width: 10),
                Expanded(child: _DetailStat(
                  label: 'Ingresos', value: _currFmt.format(revenue),
                  color: const Color(0xFF10B981),
                )),
              ],
            ),
            const SizedBox(height: 10),

            // Commission breakdown card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CÁLCULO DE COMISIÓN', style: GoogleFonts.inter(
                    fontSize: 9, color: const Color(0xFFFFB74D),
                    fontWeight: FontWeight.w700, letterSpacing: 2,
                  )),
                  const SizedBox(height: 12),
                  _CommRow(
                    label: 'Ingresos generados',
                    value: _currFmt.format(revenue),
                  ),
                  const SizedBox(height: 6),
                  _CommRow(
                    label: '× Porcentaje (${commPct.toStringAsFixed(0)}%)',
                    value: '${commPct.toStringAsFixed(0)}%',
                    dimValue: true,
                  ),
                  const SizedBox(height: 10),
                  Container(height: 0.5, color: const Color(0xFFFFB74D).withValues(alpha: 0.2)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('COMISIÓN TOTAL', style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFFFFB74D),
                        fontWeight: FontWeight.w700,
                      )),
                      Text(_currFmt.format(commission), style: GoogleFonts.inter(
                        fontSize: 18, color: const Color(0xFFFFB74D),
                        fontWeight: FontWeight.w800,
                      )),
                    ],
                  ),
                ],
              ),
            ),

            // Top services
            if (topSvcs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('SERVICIOS MÁS REALIZADOS', style: GoogleFonts.inter(
                fontSize: 9, color: SaharaColors.grayText,
                fontWeight: FontWeight.w700, letterSpacing: 2,
              )),
              const SizedBox(height: 12),
              ...topSvcs.asMap().entries.map((entry) {
                final i   = entry.key;
                final s   = entry.value;
                final max = (topSvcs.first['count'] as int).toDouble();
                final pct = max > 0 ? (s['count'] as int) / max : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text('${i + 1}', style: GoogleFonts.inter(
                          fontSize: 11, color: SaharaColors.gold.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        )),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s['name'] as String, style: GoogleFonts.inter(
                                  fontSize: 13, color: SaharaColors.whiteSoft,
                                  fontWeight: FontWeight.w500,
                                )),
                                Text('${s['count']}×', style: GoogleFonts.inter(
                                  fontSize: 12, color: SaharaColors.grayText,
                                )),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor:
                                    SaharaColors.gold.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  SaharaColors.gold.withValues(alpha: 0.6)),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, color: SaharaColors.grayText,
    fontWeight: FontWeight.w700, letterSpacing: 2,
  ));

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
            child: const Icon(Icons.self_improvement_rounded,
                color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sin terapeutas activos', style: GoogleFonts.playfairDisplay(
            fontSize: 20, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
          )),
          const SizedBox(height: 8),
          Text('Agrega terapeutas desde Configuración.',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText)),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(initials, style: GoogleFonts.inter(
          fontSize: size * 0.32, color: SaharaColors.gold, fontWeight: FontWeight.w700,
        )),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _SummaryCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(
            fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w800,
          )),
          Text(label, style: GoogleFonts.inter(
            fontSize: 9, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(
            fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w700,
          )),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: color.withValues(alpha: 0.8),
          )),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _DetailStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(
            fontSize: 20, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w800,
          )),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: SaharaColors.grayText,
          )),
        ],
      ),
    );
  }
}

class _CommRow extends StatelessWidget {
  final String label;
  final String value;
  final bool dimValue;
  const _CommRow({required this.label, required this.value, this.dimValue = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, color: SaharaColors.grayText,
        )),
        Text(value, style: GoogleFonts.inter(
          fontSize: 13,
          color: dimValue ? SaharaColors.grayText : SaharaColors.whiteSoft,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MonthBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Icon(icon,
          color: onTap != null
              ? SaharaColors.grayText
              : SaharaColors.grayText.withValues(alpha: 0.25),
          size: 15),
      ),
    );
  }
}
