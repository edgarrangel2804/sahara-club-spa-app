import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final resp = await Supabase.instance.client
        .from('orders')
        .select('id, status, total, currency, created_at, customer_name, order_items(id, product_name, product_type, unit_price, quantity, redeemed_at)')
        .or('customer_id.eq.${user.id},customer_email.eq.${user.email}')
        .order('created_at', ascending: false);
    return (resp as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5));
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) return _buildEmpty();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    color: SaharaColors.grayDark.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (_, i) => _OrderTile(
                    order: orders[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: orders[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: SaharaColors.grayDark, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
            const SizedBox(width: 16),
            Text('Mis Órdenes', style: GoogleFonts.playfairDisplay(
              fontSize: 22, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48,
              color: SaharaColors.grayText.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Sin órdenes aún', style: GoogleFonts.playfairDisplay(
            fontSize: 18, color: SaharaColors.grayText.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          )),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  String get _statusLabel => switch (order['status'] as String? ?? '') {
    'paid'      => 'PAGADO',
    'pending'   => 'PENDIENTE',
    'cancelled' => 'CANCELADO',
    'refunded'  => 'REEMBOLSADO',
    _           => 'PENDIENTE',
  };

  Color get _statusColor => switch (order['status'] as String? ?? '') {
    'paid'    => const Color(0xFF4CAF50),
    'pending' => const Color(0xFFFFB74D),
    _         => SaharaColors.grayText,
  };

  @override
  Widget build(BuildContext context) {
    final items = (order['order_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final date  = DateTime.tryParse(order['created_at'] as String? ?? '');
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2,'0')} ${_month(date.month)} ${date.year}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaharaColors.grayDark.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.receipt_outlined, color: SaharaColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${items.length} ${items.length == 1 ? 'producto' : 'productos'}',
                      style: GoogleFonts.inter(fontSize: 13,
                          color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(dateStr, style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText, fontWeight: FontWeight.w300,
                  )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${total.toStringAsFixed(0)}', style: GoogleFonts.playfairDisplay(
                  fontSize: 16, color: SaharaColors.gold,
                )),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_statusLabel, style: GoogleFonts.inter(
                    fontSize: 9, color: _statusColor, letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: SaharaColors.grayText.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }

  String _month(int m) => const ['', 'Ene','Feb','Mar','Abr','May','Jun',
    'Jul','Ago','Sep','Oct','Nov','Dic'][m];
}
