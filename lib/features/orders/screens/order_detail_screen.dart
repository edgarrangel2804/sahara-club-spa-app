import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  List<Map<String, dynamic>> get _items =>
      (order['order_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
              children: [
                if (_items.isEmpty)
                  _buildNoItems()
                else
                  ..._items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _QrTicket(item: item, order: order),
                  )),
              ],
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
            Text('Mis Tickets', style: GoogleFonts.playfairDisplay(
              fontSize: 22, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNoItems() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Text('Los tickets aparecerán\ntras confirmar el pago.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14, color: SaharaColors.grayText,
              height: 1.6, fontStyle: FontStyle.italic,
            )),
      ),
    );
  }
}

// ── QR Ticket ─────────────────────────────────────────────────────────────────

class _QrTicket extends StatelessWidget {
  const _QrTicket({required this.item, required this.order});
  final Map<String, dynamic> item;
  final Map<String, dynamic> order;

  bool get _isRedeemed => item['redeemed_at'] != null;

  String get _shortId {
    final id = item['id'] as String? ?? '';
    return id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name        = item['product_name'] as String? ?? '';
    final price       = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final customerName = order['customer_name'] as String? ?? '';
    final date        = DateTime.tryParse(order['created_at'] as String? ?? '');
    final dateStr     = date != null
        ? '${date.day.toString().padLeft(2,'0')} ${_month(date.month)} ${date.year}'
        : '';
    final itemId      = item['id'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRedeemed
              ? Colors.red.withValues(alpha: 0.25)
              : SaharaColors.gold.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: _isRedeemed ? null : [
          BoxShadow(
            color: SaharaColors.gold.withValues(alpha: 0.05),
            blurRadius: 20, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera del ticket ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: _isRedeemed
                  ? Colors.red.withValues(alpha: 0.05)
                  : SaharaColors.gold.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SAHARA CLUB SPA', style: GoogleFonts.inter(
                        fontSize: 9, color: SaharaColors.gold.withValues(alpha: 0.7),
                        letterSpacing: 2.5, fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 6),
                      Text(name, style: GoogleFonts.playfairDisplay(
                        fontSize: 18, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w400, height: 1.2,
                      )),
                      const SizedBox(height: 4),
                      if (customerName.isNotEmpty)
                        Text(customerName, style: GoogleFonts.inter(
                          fontSize: 12, color: SaharaColors.grayText,
                          fontWeight: FontWeight.w300,
                        )),
                    ],
                  ),
                ),
                if (_isRedeemed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text('CANJEADO', style: GoogleFonts.inter(
                      fontSize: 9, color: Colors.red,
                      letterSpacing: 1.5, fontWeight: FontWeight.w700,
                    )),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                    ),
                    child: Text('VÁLIDO', style: GoogleFonts.inter(
                      fontSize: 9, color: const Color(0xFF4CAF50),
                      letterSpacing: 1.5, fontWeight: FontWeight.w700,
                    )),
                  ),
              ],
            ),
          ),

          // ── Línea de corte ─────────────────────────────────────────
          _TicketDivider(color: _isRedeemed
              ? Colors.red.withValues(alpha: 0.15)
              : SaharaColors.gold.withValues(alpha: 0.15)),

          // ── QR Code ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                if (!_isRedeemed && itemId.isNotEmpty)
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: itemId));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('ID copiado'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: itemId,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                else if (_isRedeemed)
                  Container(
                    width: 212, height: 212,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A0A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 48, color: Colors.red.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('Código canjeado', style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.red.withValues(alpha: 0.6),
                        )),
                        const SizedBox(height: 4),
                        Text(_formatRedeemedAt(), style: GoogleFonts.inter(
                          fontSize: 11, color: SaharaColors.grayText.withValues(alpha: 0.4),
                        )),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text('#$_shortId', style: GoogleFonts.inter(
                  fontSize: 11,
                  color: SaharaColors.grayText.withValues(alpha: 0.4),
                  letterSpacing: 2,
                )),
              ],
            ),
          ),

          // ── Línea de corte ─────────────────────────────────────────
          _TicketDivider(color: _isRedeemed
              ? Colors.red.withValues(alpha: 0.15)
              : SaharaColors.gold.withValues(alpha: 0.15)),

          // ── Pie del ticket ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(label: 'FECHA', value: dateStr),
                Container(width: 0.5, height: 28,
                    color: SaharaColors.grayDark),
                _InfoChip(label: 'MONTO',
                    value: price == 0 ? 'Incluido' : '\$${price.toStringAsFixed(0)}'),
                Container(width: 0.5, height: 28,
                    color: SaharaColors.grayDark),
                _InfoChip(label: 'VALIDEZ', value: '12 meses'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRedeemedAt() {
    final dt = DateTime.tryParse(item['redeemed_at'] as String? ?? '');
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  String _month(int m) => const ['','Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic'][m];
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 8, color: SaharaColors.grayText.withValues(alpha: 0.5),
          letterSpacing: 1.5, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(
          fontSize: 12, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w400,
        )),
      ],
    );
  }
}

class _TicketDivider extends StatelessWidget {
  const _TicketDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: SaharaColors.black,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            border: Border(
              right: BorderSide(color: color),
              top: BorderSide(color: color),
              bottom: BorderSide(color: color),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) => Row(
              children: List.generate(
                (constraints.maxWidth / 10).floor(),
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: i.isEven ? color : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: SaharaColors.black,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            border: Border(
              left: BorderSide(color: color),
              top: BorderSide(color: color),
              bottom: BorderSide(color: color),
            ),
          ),
        ),
      ],
    );
  }
}
