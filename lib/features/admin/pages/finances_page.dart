import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

class AdminFinancesPage extends StatefulWidget {
  const AdminFinancesPage({super.key});

  @override
  State<AdminFinancesPage> createState() => _AdminFinancesPageState();
}

class _AdminFinancesPageState extends State<AdminFinancesPage> {
  final _repo = SaharaAdminRepository();
  bool _loading = true;
  Map<String, double> _financials = {};
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.getFinancialStats(),
      _repo.getAllPayments(),
    ]);
    _financials = results[0] as Map<String, double>;
    _payments = results[1] as List<Map<String, dynamic>>;
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: 0);

    return _loading
        ? const Center(child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5))
        : RefreshIndicator(
            onRefresh: _load,
            color: SaharaColors.gold,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESUMEN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SaharaColors.grayText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _summaryRow('Ingresos Hoy', fmt.format(_financials['revenue_today'] ?? 0), const Color(0xFF10B981)),
                  _summaryRow('Ingresos Semana', fmt.format(_financials['revenue_week'] ?? 0), SaharaColors.gold),
                  _summaryRow('Ingresos Mes', fmt.format(_financials['revenue_month'] ?? 0), const Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  Container(height: 1, color: SaharaColors.grayDark),
                  const SizedBox(height: 8),
                  _summaryRow('Gastos Mes', fmt.format(_financials['expenses_month'] ?? 0), const Color(0xFFEF4444)),
                  _summaryRow(
                    'Utilidad Mes',
                    fmt.format(_financials['profit_month'] ?? 0),
                    (_financials['profit_month'] ?? 0) >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ÚLTIMOS PAGOS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SaharaColors.grayText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._payments.take(20).map((p) => _paymentRow(p, fmt)),
                ],
              ),
            ),
          );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SaharaColors.grayText, fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _paymentRow(Map<String, dynamic> p, NumberFormat fmt) {
    final amount = double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
    final method = p['method'] as String? ?? '';
    final createdAt = p['created_at'] as String? ?? '';
    final dateStr = createdAt.isNotEmpty ? createdAt.substring(0, 10) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: const TextStyle(color: SaharaColors.grayText, fontSize: 12)),
              if (method.isNotEmpty)
                Text(method, style: const TextStyle(color: SaharaColors.whiteSoft, fontSize: 13)),
            ],
          ),
          Text(
            fmt.format(amount),
            style: const TextStyle(color: SaharaColors.gold, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
