import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class MembershipPassScreen extends StatelessWidget {
  final Map<String, dynamic> item;   // order_item row
  final Map<String, dynamic> order;  // parent order row

  const MembershipPassScreen({
    super.key,
    required this.item,
    required this.order,
  });

  String get _itemId    => item['id'] as String? ?? '';
  String get _tierName  => item['product_name'] as String? ?? 'Membresía';
  String get _member    => order['customer_name'] as String? ?? '';
  bool   get _redeemed  => item['redeemed_at'] != null;

  String get _shortId {
    final id = _itemId;
    return id.length >= 8 ? '#${id.substring(0, 8).toUpperCase()}' : '#$id';
  }

  String _fmt(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return '${_month(dt.month)} ${dt.year}';
  }

  String _fmtExpiry(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final exp = DateTime(dt.year + 1, dt.month, dt.day);
    return '${_month(exp.month)} ${exp.year}';
  }

  String _month(int m) => const [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ][m];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  _buildPass(),
                  const SizedBox(height: 24),
                  _buildNote(),
                ],
              ),
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
                  color: SaharaColors.grayDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
            const SizedBox(width: 16),
            Text('MEMBRESÍA DIGITAL', style: GoogleFonts.inter(
              fontSize: 13, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w600, letterSpacing: 3,
            )),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _itemId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('ID copiado'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ));
              },
              child: Icon(Icons.share_outlined,
                  color: SaharaColors.gold.withValues(alpha: 0.7), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPass() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _redeemed
              ? Colors.red.withValues(alpha: 0.25)
              : SaharaColors.gold.withValues(alpha: 0.3),
          width: 0.8,
        ),
        boxShadow: _redeemed ? null : [
          BoxShadow(
            color: SaharaColors.gold.withValues(alpha: 0.07),
            blurRadius: 40, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera del pase ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            decoration: BoxDecoration(
              color: _redeemed
                  ? Colors.red.withValues(alpha: 0.04)
                  : SaharaColors.gold.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(
                  color: _redeemed
                      ? Colors.red.withValues(alpha: 0.12)
                      : SaharaColors.gold.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SAHARA CLUB SPA', style: GoogleFonts.inter(
                      fontSize: 9,
                      color: SaharaColors.gold.withValues(alpha: 0.7),
                      letterSpacing: 3, fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: 6),
                    Text(_tierName, style: GoogleFonts.playfairDisplay(
                      fontSize: 22, color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w400,
                    )),
                    if (_member.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(_member, style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.grayText,
                        fontWeight: FontWeight.w300,
                      )),
                    ],
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _redeemed
                        ? Colors.red.withValues(alpha: 0.12)
                        : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _redeemed
                          ? Colors.red.withValues(alpha: 0.35)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _redeemed ? 'CANJEADO' : 'VÁLIDO',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: _redeemed ? Colors.red : const Color(0xFF4CAF50),
                      letterSpacing: 1.5, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── QR ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                if (!_redeemed && _itemId.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: SaharaColors.gold.withValues(alpha: 0.18),
                          blurRadius: 32, spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _itemId,
                      version: QrVersions.auto,
                      size: 200,
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
                  const SizedBox(height: 18),
                  Text('PRESENTA AL INGRESAR', style: GoogleFonts.inter(
                    fontSize: 10,
                    color: SaharaColors.gold.withValues(alpha: 0.8),
                    letterSpacing: 3, fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 6),
                  Text('Muestra este código en recepción',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: SaharaColors.grayText,
                        fontWeight: FontWeight.w300,
                      )),
                ] else ...[
                  Container(
                    width: 236, height: 236,
                    decoration: BoxDecoration(
                      color: const Color(0xFF140808),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 52, color: Colors.red.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('Membresía canjeada', style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.red.withValues(alpha: 0.6),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Línea de corte ─────────────────────────────────────────────
          _TicketDivider(
            color: _redeemed
                ? Colors.red.withValues(alpha: 0.15)
                : SaharaColors.gold.withValues(alpha: 0.15),
          ),

          // ── Pie ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoCol(label: 'MIEMBRO DESDE',
                        value: _fmt(order['created_at'] as String?)),
                    Container(width: 0.5, height: 32, color: SaharaColors.grayDark),
                    _InfoCol(label: 'VÁLIDA HASTA',
                        value: _fmtExpiry(order['created_at'] as String?)),
                    Container(width: 0.5, height: 32, color: SaharaColors.grayDark),
                    _InfoCol(label: 'CÓDIGO', value: _shortId),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14,
              color: SaharaColors.gold.withValues(alpha: 0.45)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este pase es personal e intransferible. Válido por 12 meses desde la fecha de compra.',
              style: GoogleFonts.inter(
                fontSize: 12, color: SaharaColors.grayText.withValues(alpha: 0.5),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _InfoCol extends StatelessWidget {
  final String label, value;
  const _InfoCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 8, color: SaharaColors.grayText.withValues(alpha: 0.5),
          letterSpacing: 1.5, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 5),
        Text(value, style: GoogleFonts.inter(
          fontSize: 12, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w400,
        )),
      ],
    );
  }
}

class _TicketDivider extends StatelessWidget {
  final Color color;
  const _TicketDivider({required this.color});

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
            builder: (_, c) => Row(
              children: List.generate(
                (c.maxWidth / 10).floor(),
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
