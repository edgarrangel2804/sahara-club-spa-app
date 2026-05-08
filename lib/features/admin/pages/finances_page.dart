import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

enum _Tab { dashboard, balance }

class AdminFinancesPage extends StatefulWidget {
  const AdminFinancesPage({super.key});

  @override
  State<AdminFinancesPage> createState() => _AdminFinancesPageState();
}

class _AdminFinancesPageState extends State<AdminFinancesPage> {
  final _repo = SaharaAdminRepository();
  DateTime _month   = DateTime(DateTime.now().year, DateTime.now().month);
  bool     _loading = true;
  _Tab     _tab     = _Tab.dashboard;
  Map<String, dynamic> _data    = {};
  Map<String, dynamic> _balance = {};

  static final _monthFmt = DateFormat("MMMM yyyy", 'es');
  static final _currFmt  = NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.getExecutiveDashboard(_month),
      _repo.getBalanceData(_month),
    ]);
    if (mounted) {
      setState(() {
        _data    = results[0];
        _balance = results[1];
        _loading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonthHeader(),
        _buildTabPills(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: SaharaColors.gold,
                  child: _tab == _Tab.dashboard
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                          children: [
                            _buildMainKpis(),
                            const SizedBox(height: 14),
                            _buildSecondaryKpis(),
                            const SizedBox(height: 28),
                            _sectionLabel('HORAS PICO'),
                            const SizedBox(height: 14),
                            _buildPeakHoursChart(),
                            const SizedBox(height: 28),
                            _sectionLabel('INGRESOS POR MÉTODO'),
                            const SizedBox(height: 14),
                            _buildMethodBreakdown(),
                            const SizedBox(height: 28),
                            _sectionLabel('EVOLUCIÓN DEL MES'),
                            const SizedBox(height: 14),
                            _buildDailySparkline(),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                          children: _buildBalanceTab(),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildTabPills() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          _TabPill(label: 'Dashboard', active: _tab == _Tab.dashboard,
              onTap: () => setState(() => _tab = _Tab.dashboard)),
          const SizedBox(width: 8),
          _TabPill(label: 'Balance General', active: _tab == _Tab.balance,
              onTap: () => setState(() => _tab = _Tab.balance)),
        ],
      ),
    );
  }

  List<Widget> _buildBalanceTab() {
    final revenue       = (_balance['revenue']        as double?) ?? 0;
    final pettyCash     = (_balance['petty_cash']     as double?) ?? 0;
    final fixed         = (_balance['fixed']          as double?) ?? 0;
    final other         = (_balance['other']          as double?) ?? 0;
    final totalExpenses = (_balance['total_expenses'] as double?) ?? 0;
    final commissions   = (_balance['commissions']    as double?) ?? 0;
    final profit        = (_balance['profit']         as double?) ?? 0;
    final netToOwner    = (_balance['net_to_owner']   as double?) ?? 0;
    final cashPosition  = (_balance['cash_position']  as double?) ?? 0;
    final cashIn        = (_balance['cash_in']        as double?) ?? 0;

    final profitColor     = profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF5350);
    final netColor        = netToOwner >= 0 ? SaharaColors.gold : const Color(0xFFEF5350);

    return [
      _balanceCard(
        label: 'INGRESOS BRUTOS',
        color: const Color(0xFF10B981),
        icon: Icons.trending_up_rounded,
        rows: [_balanceRow('Cobros del período', revenue, const Color(0xFF10B981))],
        total: null,
      ),
      const SizedBox(height: 12),
      _balanceCard(
        label: 'GASTOS OPERATIVOS',
        color: const Color(0xFFEF5350),
        icon: Icons.trending_down_rounded,
        rows: [
          _balanceRow('Caja Chica', -pettyCash, const Color(0xFFEF5350)),
          _balanceRow('Gastos Fijos', -fixed, const Color(0xFFFF8A65)),
          _balanceRow('Otros', -other, SaharaColors.grayText),
        ],
        total: _balanceTotalRow('Total Gastos', -totalExpenses, const Color(0xFFEF5350)),
      ),
      const SizedBox(height: 12),
      _resultCard('UTILIDAD BRUTA', profit, profitColor,
          Icons.account_balance_outlined,
          subtitle: 'Ingresos − Gastos operativos'),
      const SizedBox(height: 12),
      _balanceCard(
        label: 'COMISIONES',
        color: const Color(0xFF8B5CF6),
        icon: Icons.group_outlined,
        rows: [_balanceRow('A terapeutas', -commissions, const Color(0xFF8B5CF6))],
        total: null,
      ),
      const SizedBox(height: 12),
      _resultCard('RESULTADO NETO', netToOwner, netColor,
          Icons.emoji_events_rounded,
          subtitle: 'Para el negocio',
          highlight: true),
      const SizedBox(height: 20),
      _sectionLabel('POSICIÓN DE CAJA'),
      const SizedBox(height: 12),
      _balanceCard(
        label: 'EFECTIVO',
        color: const Color(0xFF64B5F6),
        icon: Icons.payments_outlined,
        rows: [
          _balanceRow('Efectivo recibido', cashIn, const Color(0xFF64B5F6)),
          _balanceRow('Caja chica', -pettyCash, const Color(0xFFEF5350)),
        ],
        total: _balanceTotalRow('Saldo en caja', cashPosition,
            cashPosition >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
      ),
    ];
  }

  Widget _balanceCard({
    required String label,
    required Color color,
    required IconData icon,
    required List<Widget> rows,
    required Widget? total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.inter(
                  fontSize: 10, color: color,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5,
                )),
              ],
            ),
          ),
          Container(height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white.withValues(alpha: 0.05)),
          ...rows,
          if (total != null) ...[
            Container(height: 0.5,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                color: Colors.white.withValues(alpha: 0.08)),
            total,
          ],
        ],
      ),
    );
  }

  Widget _balanceRow(String label, double value, Color color) {
    final isNeg = value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 13, color: SaharaColors.grayText,
          ))),
          Text(
            '${isNeg ? '−' : '+'} ${_currFmt.format(value.abs())}',
            style: GoogleFonts.inter(
              fontSize: 13, color: color, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceTotalRow(String label, double value, Color color) {
    final isNeg = value < 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w700,
          ))),
          Text(
            '${isNeg ? '−' : '+'} ${_currFmt.format(value.abs())}',
            style: GoogleFonts.inter(
              fontSize: 15, color: color, fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(String label, double value, Color color, IconData icon,
      {String? subtitle, bool highlight = false}) {
    final isNeg = value < 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.07)
            : const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: highlight ? 0.35 : 0.2)),
        boxShadow: highlight
            ? [BoxShadow(color: color.withValues(alpha: 0.1),
                blurRadius: 16, offset: const Offset(0, 4))]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(
                  fontSize: 10, color: color,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5,
                )),
                if (subtitle != null)
                  Text(subtitle, style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText,
                  )),
              ],
            ),
          ),
          Text(
            '${isNeg ? '−' : '+'} ${_currFmt.format(value.abs())}',
            style: GoogleFonts.inter(
              fontSize: highlight ? 20 : 16,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Month header ──────────────────────────────────────────────────────────

  Widget _buildMonthHeader() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthBtn(icon: Icons.chevron_left, onTap: _prevMonth),
              Text(
                _monthFmt.format(_month).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.gold,
                  fontWeight: FontWeight.w700, letterSpacing: 2,
                ),
              ),
              _MonthBtn(
                icon: Icons.chevron_right,
                onTap: _isCurrentMonth ? null : _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  // ── Main KPIs: Ingresos / Gastos / Utilidad ───────────────────────────────

  Widget _buildMainKpis() {
    final revenue  = (_data['revenue']  as double?) ?? 0;
    final expenses = (_data['expenses'] as double?) ?? 0;
    final profit   = (_data['profit']   as double?) ?? 0;
    final profitColor = profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF5350);

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'Ingresos',
          value: _currFmt.format(revenue),
          color: const Color(0xFF10B981),
          icon: Icons.trending_up_rounded,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          label: 'Gastos',
          value: _currFmt.format(expenses),
          color: const Color(0xFFEF5350),
          icon: Icons.trending_down_rounded,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          label: 'Utilidad',
          value: _currFmt.format(profit),
          color: profitColor,
          icon: profit >= 0 ? Icons.emoji_events_rounded : Icons.warning_amber_rounded,
        )),
      ],
    );
  }

  // ── Secondary KPIs: Ticket promedio / Cancelaciones ───────────────────────

  Widget _buildSecondaryKpis() {
    final avgTicket  = (_data['avg_ticket']  as double?) ?? 0;
    final cancelRate = (_data['cancel_rate'] as double?) ?? 0;
    final bookings   = (_data['bookings_count'] as int?) ?? 0;
    final cancelled  = (_data['cancelled_count'] as int?) ?? 0;

    return Row(
      children: [
        Expanded(child: _SecondaryCard(
          label: 'Ticket Promedio',
          value: _currFmt.format(avgTicket),
          sub: '${(_data['payments_count'] as int?) ?? 0} cobros',
          color: SaharaColors.gold,
          icon: Icons.receipt_rounded,
        )),
        const SizedBox(width: 10),
        Expanded(child: _SecondaryCard(
          label: 'Cancelaciones',
          value: '${cancelRate.toStringAsFixed(1)}%',
          sub: '$cancelled de $bookings citas',
          color: cancelRate > 20
              ? const Color(0xFFEF5350)
              : cancelRate > 10
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFF4CAF50),
          icon: Icons.cancel_outlined,
        )),
      ],
    );
  }

  // ── Peak hours chart ──────────────────────────────────────────────────────

  Widget _buildPeakHoursChart() {
    final peakHours = (_data['peak_hours'] as Map<int, int>?) ?? {};
    if (peakHours.isEmpty) {
      return _emptySection('Sin citas este mes');
    }

    const startH = 9;
    const endH   = 20;
    final maxCount = peakHours.values.fold(0, (m, v) => v > m ? v : m);
    if (maxCount == 0) return _emptySection('Sin citas este mes');

    final peakHour = peakHours.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: SaharaColors.gold),
              const SizedBox(width: 6),
              Text(
                'Hora pico: ${peakHour.toString().padLeft(2, '0')}:00',
                style: GoogleFonts.inter(
                  fontSize: 12, color: SaharaColors.gold, fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${peakHours[peakHour]} citas',
                style: GoogleFonts.inter(
                  fontSize: 11, color: SaharaColors.grayText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(endH - startH + 1, (i) {
                final hour  = startH + i;
                final count = peakHours[hour] ?? 0;
                final ratio = count / maxCount;
                final isPeak = hour == peakHour;
                final barColor = isPeak
                    ? SaharaColors.gold
                    : count > 0
                        ? SaharaColors.gold.withValues(alpha: 0.25)
                        : const Color(0xFF1E1E1E);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPeak)
                          Text('$count', style: GoogleFonts.inter(
                            fontSize: 8, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                          )),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: ratio > 0 ? (ratio * 56).clamp(4.0, 56.0) : 4,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$hour',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: isPeak
                                ? SaharaColors.gold
                                : SaharaColors.grayText.withValues(alpha: 0.5),
                            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Revenue by method ─────────────────────────────────────────────────────

  Widget _buildMethodBreakdown() {
    final byMethod = (_data['revenue_by_method'] as Map<String, double>?) ?? {};
    final revenue  = (_data['revenue'] as double?) ?? 0;

    if (byMethod.isEmpty || revenue == 0) {
      return _emptySection('Sin cobros este mes');
    }

    final methods = [
      ('cash',   'Efectivo',  Icons.payments_outlined,   const Color(0xFF4CAF50)),
      ('debit',  'Débito',    Icons.credit_card_rounded, const Color(0xFF64B5F6)),
      ('credit', 'Crédito',   Icons.contactless_rounded, SaharaColors.gold),
    ];

    return Column(
      children: methods.map((entry) {
        final (key, label, icon, color) = entry;
        final amount = byMethod[key] ?? 0;
        final pct    = revenue > 0 ? amount / revenue : 0.0;
        if (amount == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E1E1E)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 10),
                  Text(label, style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500,
                  )),
                  const Spacer(),
                  Text(_currFmt.format(amount), style: GoogleFonts.inter(
                    fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(width: 10),
                  Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Daily sparkline ───────────────────────────────────────────────────────

  Widget _buildDailySparkline() {
    final daily = (_data['daily_revenue'] as List<double>?) ?? [];
    if (daily.isEmpty || daily.every((v) => v == 0)) {
      return _emptySection('Sin ingresos registrados');
    }

    final maxVal = daily.fold(0.0, (m, v) => v > m ? v : m);
    final today  = DateTime.now().day - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Total: ', style: GoogleFonts.inter(
                fontSize: 12, color: SaharaColors.grayText,
              )),
              Text(
                _currFmt.format(daily.fold(0.0, (s, v) => s + v)),
                style: GoogleFonts.inter(
                  fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(daily.length, (i) {
                final v     = daily[i];
                final ratio = maxVal > 0 ? v / maxVal : 0.0;
                final isToday = _isCurrentMonth && i == today;
                final color = isToday
                    ? SaharaColors.gold
                    : v > 0
                        ? SaharaColors.gold.withValues(alpha: 0.3)
                        : const Color(0xFF1A1A1A);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: ratio > 0 ? (ratio * 52).clamp(3.0, 52.0) : 3,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: GoogleFonts.inter(
                fontSize: 9, color: SaharaColors.grayText.withValues(alpha: 0.5))),
              Text('${daily.length}', style: GoogleFonts.inter(
                fontSize: 9, color: SaharaColors.grayText.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(
      fontSize: 10, color: SaharaColors.grayText,
      fontWeight: FontWeight.w700, letterSpacing: 2,
    ));
  }

  Widget _emptySection(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Text(msg, textAlign: TextAlign.center, style: GoogleFonts.inter(
        fontSize: 13, color: SaharaColors.grayText,
      )),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? SaharaColors.gold.withValues(alpha: 0.12)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? SaharaColors.gold.withValues(alpha: 0.4)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12,
          color: active ? SaharaColors.gold : SaharaColors.grayText,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        )),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final IconData icon;

  const _KpiCard({
    required this.label, required this.value,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(
            fontSize: 16, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          )),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: SaharaColors.grayText, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color  color;
  final IconData icon;

  const _SecondaryCard({
    required this.label, required this.value, required this.sub,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(
                  fontSize: 18, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w800,
                )),
                Text(label, style: GoogleFonts.inter(
                  fontSize: 10, color: SaharaColors.grayText,
                )),
                Text(sub, style: GoogleFonts.inter(
                  fontSize: 10, color: SaharaColors.grayText.withValues(alpha: 0.6),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MonthBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Icon(icon,
          color: enabled
              ? SaharaColors.grayText
              : SaharaColors.grayText.withValues(alpha: 0.25),
          size: 18),
      ),
    );
  }
}
