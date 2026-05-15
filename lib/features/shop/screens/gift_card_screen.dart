import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:sahara_club_spa_app/features/shop/screens/cart_screen.dart';

class GiftCardScreen extends StatefulWidget {
  final int amount;
  final String label;

  const GiftCardScreen({
    super.key,
    required this.amount,
    required this.label,
  });

  @override
  State<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends State<GiftCardScreen> {
  final _recipientCtrl = TextEditingController();
  final _senderCtrl    = TextEditingController();
  final _messageCtrl   = TextEditingController();

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _senderCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  bool get _canAdd => _recipientCtrl.text.trim().isNotEmpty &&
      _senderCtrl.text.trim().isNotEmpty;

  void _addToCart() {
    HapticFeedback.mediumImpact();
    ShopCartController.instance.add({
      'id': 'gift-card-${widget.amount}',
      'name': 'Gift Card ${widget.label}',
      'description':
          'Para: ${_recipientCtrl.text.trim()}. De: ${_senderCtrl.text.trim()}.'
          '${_messageCtrl.text.trim().isNotEmpty ? ' "${_messageCtrl.text.trim()}"' : ''}',
      'price': widget.amount.toDouble(),
      'type': 'gift_card',
      'category': 'gift_card',
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardVisual(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('PARA QUIÉN ES'),
                  const SizedBox(height: 14),
                  _buildField(_recipientCtrl, 'Nombre del destinatario',
                      Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _buildField(_senderCtrl, 'Tu nombre (remitente)',
                      Icons.favorite_border_rounded),
                  const SizedBox(height: 28),
                  _buildSectionLabel('MENSAJE PERSONAL (OPCIONAL)'),
                  const SizedBox(height: 14),
                  _buildField(_messageCtrl, 'Escribe un mensaje especial…',
                      Icons.edit_outlined,
                      maxLines: 4),
                  const SizedBox(height: 32),
                  _buildNote(),
                ],
              ),
            ),
          ),
          _buildFooter(),
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
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
            const SizedBox(width: 16),
            Text('Gift Card',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w300,
                )),
            const Spacer(),
            Text(widget.label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCardVisual() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1300), Color(0xFF0A0900), Color(0xFF1A1000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SaharaColors.gold.withValues(alpha: 0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: SaharaColors.gold.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración top-right
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SaharaColors.gold.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('SAHARA CLUB', style: GoogleFonts.inter(
                      fontSize: 10,
                      color: SaharaColors.gold.withValues(alpha: 0.7),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    )),
                    const Spacer(),
                    Icon(Icons.card_giftcard_rounded,
                        color: SaharaColors.gold.withValues(alpha: 0.5),
                        size: 18),
                  ],
                ),
                const Spacer(),
                Text('GIFT CARD', style: GoogleFonts.inter(
                  fontSize: 9,
                  color: SaharaColors.grayText.withValues(alpha: 0.5),
                  letterSpacing: 2,
                )),
                const SizedBox(height: 4),
                Text(widget.label, style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w400,
                )),
                const SizedBox(height: 2),
                Text('MXN · Válida 12 meses', style: GoogleFonts.inter(
                  fontSize: 11,
                  color: SaharaColors.grayText.withValues(alpha: 0.4),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(
      fontSize: 10,
      color: SaharaColors.gold,
      letterSpacing: 2.5,
      fontWeight: FontWeight.w600,
    ));
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(
        fontSize: 14, color: SaharaColors.whiteSoft),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: SaharaColors.grayText.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(icon, size: 18,
            color: SaharaColors.grayText.withValues(alpha: 0.45)),
        filled: true,
        fillColor: const Color(0xFF0E0E0E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: SaharaColors.grayDark.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: SaharaColors.grayDark.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: SaharaColors.gold.withValues(alpha: 0.45)),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15,
              color: SaharaColors.gold.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'El destinatario recibirá un código de canje exclusivo por correo electrónico. Válido para cualquier ritual o producto del spa.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: SaharaColors.grayText.withValues(alpha: 0.55),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border(
          top: BorderSide(
            color: SaharaColors.gold.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AnimatedOpacity(
                opacity: _canAdd ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _canAdd ? SaharaGradients.goldShimmer : null,
                    color: _canAdd ? null : SaharaColors.grayDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canAdd
                        ? [BoxShadow(
                            color: SaharaColors.gold.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          )]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _canAdd ? _addToCart : null,
                    icon: const Icon(Icons.card_giftcard_rounded, size: 17),
                    label: const Text('Agregar al carrito'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: SaharaColors.black,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: SaharaColors.grayText,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
