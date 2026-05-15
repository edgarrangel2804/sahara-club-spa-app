import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:sahara_club_spa_app/features/shop/models/cart_item.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
      final meta = user.userMetadata;
      final name = meta?['full_name'] as String? ?? meta?['name'] as String? ?? '';
      if (name.isNotEmpty) _nameCtrl.text = name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<CartItem> get _items => ShopCartController.instance.value;

  double get _subtotal => _items.fold(
      0, (s, i) => s + ((i.product['price'] as num?)?.toDouble() ?? 0) * i.quantity);

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().contains('@') &&
      !_loading;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_canSubmit) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout-session',
        body: {
          'customer_name': _nameCtrl.text.trim(),
          'customer_email': _emailCtrl.text.trim(),
          'customer_phone': _phoneCtrl.text.trim(),
          'notes': _notesCtrl.text.trim(),
          'items': _items.map((item) => {
            'product_id': item.product['id']?.toString() ?? '',
            'name': item.product['name'] ?? '',
            'description': item.product['description'] ?? '',
            'unit_price': (item.product['price'] as num?)?.toDouble() ?? 0,
            'currency': 'mxn',
            'quantity': item.quantity,
            'image_url': item.product['image'] ?? '',
            'product_type': item.product['type'] ?? 'service',
            'category_key': item.product['category'] ?? '',
          }).toList(),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (response.status >= 400 || data == null) {
        _showError(data?['error']?.toString() ?? 'No se pudo iniciar el pago.');
        return;
      }

      final checkoutUrl = data['checkout_url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        _showError('No se recibió la URL de pago.');
        return;
      }

      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null) {
        _showError('URL de pago inválida.');
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // After returning from browser, show confirmation and clear cart
      if (mounted) {
        ShopCartController.instance.clear();
        _showSuccess();
      }
    } catch (e) {
      _showError('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(
          fontSize: 13, color: SaharaColors.whiteSoft)),
      backgroundColor: const Color(0xFF2A0A0A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess() {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: SaharaColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: SaharaColors.gold, size: 28),
              ),
              const SizedBox(height: 20),
              Text('¡Pago iniciado!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w300,
                  )),
              const SizedBox(height: 10),
              Text(
                'Completa el pago en el navegador.\nRecibirás confirmación por correo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SaharaColors.grayText,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);       // close dialog
                    Navigator.pop(context);       // close checkout
                    Navigator.pop(context);       // close cart
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SaharaColors.gold,
                    foregroundColor: SaharaColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  _buildOrderSummary(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Datos de contacto'),
                  const SizedBox(height: 16),
                  _buildField(_nameCtrl,  'Nombre completo', Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _buildField(_emailCtrl, 'Correo electrónico', Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _buildField(_phoneCtrl, 'Teléfono (opcional)', Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _buildField(_notesCtrl, 'Notas (opcional)', Icons.notes_rounded,
                      maxLines: 3),
                  const SizedBox(height: 32),
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
            Text('Finalizar compra',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w300,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del pedido',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: SaharaColors.gold,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 14),
          ..._items.map((item) {
            final name = item.product['name'] as String? ?? '';
            final price = (item.product['price'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text('$name × ${item.quantity}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: SaharaColors.whiteSoft,
                        )),
                  ),
                  Text(
                    price == 0
                        ? 'Cotización'
                        : '\$${(price * item.quantity).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: SaharaColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
              height: 0.5,
              color: SaharaColors.grayDark),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SaharaColors.grayText,
                    fontWeight: FontWeight.w300,
                  )),
              Text(
                _subtotal == 0
                    ? 'Por cotización'
                    : '\$${_subtotal.toStringAsFixed(0)} MXN',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: SaharaColors.gold,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ));
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, __, ___) => TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: SaharaColors.whiteSoft,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: SaharaColors.grayText.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(icon, size: 18,
              color: SaharaColors.grayText.withValues(alpha: 0.5)),
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
                color: SaharaColors.gold.withValues(alpha: 0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
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
                opacity: _canSubmit ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _canSubmit
                        ? SaharaGradients.goldShimmer
                        : null,
                    color: _canSubmit
                        ? null
                        : SaharaColors.grayDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canSubmit
                        ? [BoxShadow(
                            color: SaharaColors.gold.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: SaharaColors.black,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: SaharaColors.grayText,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      textStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SaharaColors.black,
                            ),
                          )
                        : const Text('Ir a pagar con Stripe'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 11,
                    color: SaharaColors.grayText.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text('Pago seguro con Stripe',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: SaharaColors.grayText.withValues(alpha: 0.4),
                    )),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
