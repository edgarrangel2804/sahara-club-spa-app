import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

enum _View { ingresos, gastos }

class ReceptionCajaPage extends StatefulWidget {
  final ReceptionRepository repo;
  const ReceptionCajaPage({super.key, required this.repo});

  @override
  State<ReceptionCajaPage> createState() => _ReceptionCajaPageState();
}

class _ReceptionCajaPageState extends State<ReceptionCajaPage> {
  DateTime       _date    = DateTime.now();
  bool           _loading = true;
  _View          _view    = _View.ingresos;
  List<_Tx>      _txs     = [];
  List<_Expense> _gastos  = [];

  // ── Ingresos ──────────────────────────────────────────────────────────────
  double get _total   => _txs.fold(0, (s, t) => s + t.amount);
  double get _cash    => _txs.where((t) => t.method == 'cash').fold(0, (s, t) => s + t.amount);
  double get _debit   => _txs.where((t) => t.method == 'debit').fold(0, (s, t) => s + t.amount);
  double get _credit  => _txs.where((t) => t.method == 'credit').fold(0, (s, t) => s + t.amount);
  double get _unknown => _txs.where((t) => t.method == null).fold(0, (s, t) => s + t.amount);

  // ── Gastos ────────────────────────────────────────────────────────────────
  double get _totalGastos => _gastos.fold(0, (s, g) => s + g.amount);
  double get _pettyCash   => _gastos.where((g) => g.category == 'petty_cash').fold(0, (s, g) => s + g.amount);
  double get _fixed       => _gastos.where((g) => g.category == 'fixed').fold(0, (s, g) => s + g.amount);
  double get _otherExp    => _gastos.where((g) => g.category == 'other').fold(0, (s, g) => s + g.amount);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.repo.getCajaData(_date),
        widget.repo.getExpenses(_date),
      ]);
      if (!mounted) return;
      setState(() {
        _txs    = (results[0] as List<Map<String, dynamic>>).map(_Tx.fromMap).toList();
        _gastos = (results[1] as List<Map<String, dynamic>>).map(_Expense.fromMap).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevDay() {
    setState(() => _date = _date.subtract(const Duration(days: 1)));
    _load();
  }

  void _nextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_date.isBefore(DateTime(tomorrow.year, tomorrow.month, tomorrow.day))) {
      setState(() => _date = _date.add(const Duration(days: 1)));
      _load();
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year && _date.month == now.month && _date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5))
              : _view == _View.ingresos
                  ? _buildIngresos()
                  : _buildGastosBody(),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final dayLabel = _isToday
        ? 'Hoy'
        : DateFormat("EEE d 'de' MMM", 'es').format(_date);

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Caja', style: GoogleFonts.playfairDisplay(
                fontSize: 22, color: SaharaColors.whiteSoft,
                fontWeight: FontWeight.w300,
              )),
              Row(
                children: [
                  _NavBtn(icon: Icons.chevron_left,  onTap: _prevDay),
                  const SizedBox(width: 8),
                  _NavBtn(icon: Icons.chevron_right, onTap: _isToday ? null : _nextDay),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(dayLabel, style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.grayText,
              )),
              if (!_isToday) ...[
                const SizedBox(width: 6),
                Text('· ${DateFormat('yyyy', 'es').format(_date)}',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.grayText.withValues(alpha: 0.5),
                  )),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Tab switcher
          Row(
            children: [
              _TabPill(
                label: 'Ingresos',
                icon: Icons.trending_up_rounded,
                active: _view == _View.ingresos,
                onTap: () => setState(() => _view = _View.ingresos),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: 'Gastos',
                icon: Icons.trending_down_rounded,
                active: _view == _View.gastos,
                onTap: () => setState(() => _view = _View.gastos),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  // ── Ingresos ──────────────────────────────────────────────────────────────

  Widget _buildIngresos() {
    if (_txs.isEmpty) return _EmptyState(date: _date, isGastos: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        const SizedBox(height: 20),
        _buildTotalCard(),
        const SizedBox(height: 16),
        _buildMethodRow(),
        const SizedBox(height: 28),
        _buildListHeader(),
        const SizedBox(height: 12),
        ..._txs.map(_buildTxCard),
      ],
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL INGRESADO', style: GoogleFonts.inter(
            fontSize: 10, color: SaharaColors.gold,
            fontWeight: FontWeight.w700, letterSpacing: 2,
          )),
          const SizedBox(height: 12),
          Text(
            '\$${NumberFormat('#,###').format(_total)}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 42, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_txs.length} ${_txs.length == 1 ? 'servicio cobrado' : 'servicios cobrados'}',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodRow() {
    return Row(
      children: [
        Expanded(child: _MethodCard(
          label: 'Efectivo', icon: Icons.payments_outlined,
          amount: _cash, color: const Color(0xFF4CAF50),
        )),
        const SizedBox(width: 10),
        Expanded(child: _MethodCard(
          label: 'Débito', icon: Icons.credit_card_rounded,
          amount: _debit, color: const Color(0xFF64B5F6),
        )),
        const SizedBox(width: 10),
        Expanded(child: _MethodCard(
          label: 'Crédito', icon: Icons.contactless_rounded,
          amount: _credit, color: SaharaColors.gold,
        )),
        if (_unknown > 0) ...[
          const SizedBox(width: 10),
          Expanded(child: _MethodCard(
            label: 'Otro', icon: Icons.help_outline_rounded,
            amount: _unknown, color: SaharaColors.grayText,
          )),
        ],
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      children: [
        Text('TRANSACCIONES', style: GoogleFonts.inter(
          fontSize: 10, color: SaharaColors.grayText,
          fontWeight: FontWeight.w700, letterSpacing: 2,
        )),
        const Spacer(),
        if (_total > 0)
          Text(
            'Promedio \$${NumberFormat('#,###').format(_total / _txs.length)}',
            style: GoogleFonts.inter(
              fontSize: 11, color: SaharaColors.grayText.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildTxCard(_Tx tx) {
    final methodColor = _methodColor(tx.method);
    final methodLabel = _methodLabel(tx.method);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              tx.time.substring(0, 5),
              style: GoogleFonts.inter(
                fontSize: 12, color: SaharaColors.gold, fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.serviceName, style: GoogleFonts.inter(
                  fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600,
                ), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.person_rounded, size: 11, color: SaharaColors.grayText),
                  const SizedBox(width: 4),
                  Expanded(child: Text(tx.clientName, style: GoogleFonts.inter(
                    fontSize: 12, color: SaharaColors.grayText,
                  ), overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,###').format(tx.amount)}',
                style: GoogleFonts.inter(
                  fontSize: 15, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: methodColor.withValues(alpha: 0.3)),
                ),
                child: Text(methodLabel, style: GoogleFonts.inter(
                  fontSize: 10, color: methodColor, fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color  _methodColor(String? m) => switch (m) {
    'cash'   => const Color(0xFF4CAF50),
    'debit'  => const Color(0xFF64B5F6),
    'credit' => SaharaColors.gold,
    _        => SaharaColors.grayText,
  };
  String _methodLabel(String? m) => switch (m) {
    'cash'   => 'Efectivo',
    'debit'  => 'Débito',
    'credit' => 'Crédito',
    _        => 'Otro',
  };

  // ── Gastos ────────────────────────────────────────────────────────────────

  Widget _buildGastosBody() {
    return Stack(
      children: [
        _gastos.isEmpty
            ? _EmptyState(date: _date, isGastos: true)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  const SizedBox(height: 20),
                  _buildTotalGastosCard(),
                  const SizedBox(height: 16),
                  _buildCategoriesRow(),
                  const SizedBox(height: 28),
                  Text('GASTOS DEL DÍA', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.grayText,
                    fontWeight: FontWeight.w700, letterSpacing: 2,
                  )),
                  const SizedBox(height: 12),
                  ..._gastos.map(_buildExpenseCard),
                ],
              ),
        Positioned(
          bottom: 28, right: 20,
          child: GestureDetector(
            onTap: _showAddExpenseDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: SaharaColors.gold,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SaharaColors.gold.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 6),
                  Text('Registrar Gasto', style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold,
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalGastosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL GASTOS', style: GoogleFonts.inter(
            fontSize: 10, color: const Color(0xFFEF5350),
            fontWeight: FontWeight.w700, letterSpacing: 2,
          )),
          const SizedBox(height: 12),
          Text(
            '\$${NumberFormat('#,###').format(_totalGastos)}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 42, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_gastos.length} ${_gastos.length == 1 ? 'gasto registrado' : 'gastos registrados'}',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Row(
      children: [
        Expanded(child: _MethodCard(
          label: 'Caja Chica', icon: Icons.wallet_rounded,
          amount: _pettyCash, color: const Color(0xFFFFB74D),
        )),
        const SizedBox(width: 10),
        Expanded(child: _MethodCard(
          label: 'Gasto Fijo', icon: Icons.receipt_long_rounded,
          amount: _fixed, color: const Color(0xFF64B5F6),
        )),
        if (_otherExp > 0) ...[
          const SizedBox(width: 10),
          Expanded(child: _MethodCard(
            label: 'Otro', icon: Icons.more_horiz_rounded,
            amount: _otherExp, color: SaharaColors.grayText,
          )),
        ],
      ],
    );
  }

  Widget _buildExpenseCard(_Expense exp) {
    final catColor = _categoryColor(exp.category);
    final catLabel = _categoryLabel(exp.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon(exp.category), size: 16, color: catColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.description, style: GoogleFonts.inter(
                  fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500,
                ), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(catLabel, style: GoogleFonts.inter(
                    fontSize: 10, color: catColor, fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '-\$${NumberFormat('#,###').format(exp.amount)}',
            style: GoogleFonts.inter(
              fontSize: 15, color: const Color(0xFFEF5350), fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color    _categoryColor(String c) => switch (c) {
    'petty_cash' => const Color(0xFFFFB74D),
    'fixed'      => const Color(0xFF64B5F6),
    _            => SaharaColors.grayText,
  };
  String   _categoryLabel(String c) => switch (c) {
    'petty_cash' => 'Caja Chica',
    'fixed'      => 'Gasto Fijo',
    _            => 'Otro',
  };
  IconData _categoryIcon(String c) => switch (c) {
    'petty_cash' => Icons.wallet_rounded,
    'fixed'      => Icons.receipt_long_rounded,
    _            => Icons.more_horiz_rounded,
  };

  // ── Add expense dialog ────────────────────────────────────────────────────

  void _showAddExpenseDialog() {
    String category = 'petty_cash';
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (_, setM) {
        return Dialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar Gasto', style: GoogleFonts.playfairDisplay(
                  fontSize: 22, color: SaharaColors.whiteSoft)),
                const SizedBox(height: 4),
                Text(DateFormat("d 'de' MMMM", 'es').format(_date),
                  style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText)),
                const SizedBox(height: 24),

                // Monto
                Text('MONTO', style: GoogleFonts.inter(
                  fontSize: 10, color: SaharaColors.grayText, letterSpacing: 2)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: GoogleFonts.inter(
                    fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.inter(fontSize: 20, color: Colors.white24),
                    prefixText: '\$  ',
                    prefixStyle: GoogleFonts.inter(fontSize: 16, color: SaharaColors.grayText),
                    filled: true, fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Categoría
                Text('CATEGORÍA', style: GoogleFonts.inter(
                  fontSize: 10, color: SaharaColors.grayText, letterSpacing: 2)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _CatBtn(label: 'Caja Chica', value: 'petty_cash',
                      selected: category, onTap: () => setM(() => category = 'petty_cash')),
                    const SizedBox(width: 8),
                    _CatBtn(label: 'Gasto Fijo', value: 'fixed',
                      selected: category, onTap: () => setM(() => category = 'fixed')),
                    const SizedBox(width: 8),
                    _CatBtn(label: 'Otro', value: 'other',
                      selected: category, onTap: () => setM(() => category = 'other')),
                  ],
                ),
                const SizedBox(height: 20),

                // Descripción
                Text('DESCRIPCIÓN', style: GoogleFonts.inter(
                  fontSize: 10, color: SaharaColors.grayText, letterSpacing: 2)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ej: material de limpieza, aceite de masaje…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white24),
                    filled: true, fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 28),

                GestureDetector(
                  onTap: saving ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    final desc   = descCtrl.text.trim();
                    if (amount == null || amount <= 0 || desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Completa el monto y la descripción',
                          style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor: const Color(0xFF2A1010),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    setM(() => saving = true);
                    try {
                      await widget.repo.addExpense(
                        amount: amount,
                        category: category,
                        description: desc,
                        date: _date,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (mounted) await _load();
                    } catch (e) {
                      setM(() => saving = false);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: $e',
                          style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor: const Color(0xFF2A1010),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: saving
                          ? SaharaColors.gold.withValues(alpha: 0.5)
                          : SaharaColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                          : Text('Guardar Gasto', style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Modelos ───────────────────────────────────────────────────────────────────

class _Tx {
  final String  serviceName;
  final String  clientName;
  final String  time;
  final double  amount;
  final String? method;

  const _Tx({
    required this.serviceName, required this.clientName,
    required this.time, required this.amount, required this.method,
  });

  factory _Tx.fromMap(Map<String, dynamic> m) {
    final payments     = m['payments'] as List?;
    final firstPayment = (payments != null && payments.isNotEmpty)
        ? payments.first as Map?
        : null;
    final serviceMap = m['services'] as Map?;
    final clientMap  = m['clients']  as Map?;

    return _Tx(
      serviceName: serviceMap?['name'] as String? ?? m['service_name'] as String? ?? '—',
      clientName:  clientMap?['full_name'] as String? ?? '—',
      time:        m['booking_time'] as String? ?? '00:00',
      amount:      (m['price'] as num?)?.toDouble() ?? 0,
      method:      firstPayment?['payment_method'] as String?,
    );
  }
}

class _Expense {
  final String   id;
  final double   amount;
  final String   category;
  final String   description;
  final DateTime createdAt;

  const _Expense({
    required this.id, required this.amount,
    required this.category, required this.description, required this.createdAt,
  });

  factory _Expense.fromMap(Map<String, dynamic> m) => _Expense(
    id:          m['id'] as String,
    amount:      (m['amount'] as num).toDouble(),
    category:    m['category'] as String,
    description: m['description'] as String,
    createdAt:   DateTime.parse(m['created_at'] as String),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({
    required this.label, required this.icon,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SaharaColors.gold.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? SaharaColors.gold.withValues(alpha: 0.4) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
              color: active ? SaharaColors.gold : SaharaColors.grayText.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
              fontSize: 12,
              color: active ? SaharaColors.gold : SaharaColors.grayText.withValues(alpha: 0.5),
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }
}

class _CatBtn extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _CatBtn({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: isSelected ? SaharaColors.gold : Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12,
          color: isSelected ? SaharaColors.gold : Colors.white54,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String   label;
  final IconData icon;
  final double   amount;
  final Color    color;

  const _MethodCard({
    required this.label, required this.icon,
    required this.amount, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            '\$${NumberFormat('#,###').format(amount)}',
            style: GoogleFonts.inter(
              fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, required this.onTap});

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

class _EmptyState extends StatelessWidget {
  final DateTime date;
  final bool     isGastos;
  const _EmptyState({required this.date, required this.isGastos});

  @override
  Widget build(BuildContext context) {
    final isToday = () {
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
            ),
            child: Icon(
              isGastos ? Icons.receipt_long_outlined : Icons.point_of_sale_outlined,
              color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            isGastos
                ? (isToday ? 'Sin gastos hoy' : 'Sin gastos este día')
                : (isToday ? 'Sin cobros hoy' : 'Sin cobros este día'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 20, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGastos
                ? (isToday
                    ? 'Usa el botón + para registrar un gasto.'
                    : 'No se registraron gastos en esta fecha.')
                : (isToday
                    ? 'Los servicios cobrados aparecerán aquí.'
                    : 'No se registraron cobros en esta fecha.'),
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
