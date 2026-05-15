import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:sahara_club_spa_app/features/shop/models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: ShopCartController.instance,
        builder: (context, items, _) {
          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: items.isEmpty
                    ? _buildEmpty()
                    : _buildList(items),
              ),
              if (items.isNotEmpty) _buildFooter(context, items),
            ],
          );
        },
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
            Expanded(
              child: Text(
                'Tus Rituales',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            ValueListenableBuilder<List<CartItem>>(
              valueListenable: ShopCartController.instance,
              builder: (context, items, _) {
                final count = ShopCartController.instance.itemCount;
                if (count == 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ShopCartController.instance.clear();
                  },
                  child: Text(
                    'Vaciar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: SaharaColors.grayText.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
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
          Icon(Icons.shopping_bag_outlined,
              size: 52, color: SaharaColors.grayText.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            'Tu carrito está vacío',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: SaharaColors.grayText.withValues(alpha: 0.5),
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega rituales o productos\npara continuar',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SaharaColors.grayText.withValues(alpha: 0.35),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<CartItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 16),
        color: SaharaColors.grayDark.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, i) => _CartItemTile(item: items[i]),
    );
  }

  Widget _buildFooter(BuildContext context, List<CartItem> items) {
    final subtotal = items.fold<double>(
      0,
      (sum, item) {
        final price = (item.product['price'] as num?)?.toDouble() ?? 0;
        return sum + price * item.quantity;
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border(
          top: BorderSide(
            color: SaharaColors.gold.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: SaharaColors.grayText,
                      fontWeight: FontWeight.w300,
                    )),
                Text(
                  subtotal == 0
                      ? 'Por cotización'
                      : '\$${subtotal.toStringAsFixed(0)} MXN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    color: SaharaColors.gold,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SaharaGradients.goldShimmer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: SaharaColors.gold.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _handleCheckout(context);
                  },
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: const Text('Proceder al pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: SaharaColors.black,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleCheckout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Checkout próximamente',
        style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Tile de producto en el carrito ────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  static const _categoryColors = {
    'masajes': Color(0xFF2A1F0F),
    'faciales': Color(0xFF1A1F2A),
    'corporales': Color(0xFF1A2A1F),
    'moldeo': Color(0xFF2A1A1F),
    'tecnologia_facial': Color(0xFF1F1A2A),
    'tecnologia_corporal': Color(0xFF2A2A1A),
    'fusionadas': Color(0xFF2A1A2A),
  };

  static const _categoryIcons = {
    'masajes': Icons.self_improvement_rounded,
    'faciales': Icons.face_retouching_natural_rounded,
    'corporales': Icons.spa_rounded,
    'moldeo': Icons.accessibility_new_rounded,
    'tecnologia_facial': Icons.star_rounded,
    'tecnologia_corporal': Icons.bolt_rounded,
    'fusionadas': Icons.auto_awesome_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final name = item.product['name'] as String? ?? '';
    final price = (item.product['price'] as num?)?.toDouble() ?? 0;
    final category = item.product['category'] as String? ?? '';
    final imgUrl = item.product['image'] as String?;
    final bgColor = _categoryColors[category] ?? const Color(0xFF1A1A1A);
    final iconData = _categoryIcons[category] ?? Icons.shopping_bag_outlined;
    final lineTotal = price * item.quantity;

    return Row(
      children: [
        // Imagen / placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 68, height: 68,
            child: imgUrl != null && imgUrl.isNotEmpty
                ? Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _placeholder(bgColor, iconData))
                : _placeholder(bgColor, iconData),
          ),
        ),
        const SizedBox(width: 14),

        // Nombre + precio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  )),
              const SizedBox(height: 6),
              Text(
                price == 0
                    ? 'Precio por cotización'
                    : '\$${lineTotal.toStringAsFixed(0)} MXN',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Controles +/-
        _QuantityControl(item: item),
      ],
    );
  }

  Widget _placeholder(Color bg, IconData icon) {
    return Container(
      color: bg,
      child: Center(
        child: Icon(icon, size: 26,
            color: SaharaColors.gold.withValues(alpha: 0.45)),
      ),
    );
  }
}

// ── Control de cantidad ───────────────────────────────────────────────────────

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SaharaColors.grayDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: item.quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              ShopCartController.instance.decrementOrRemove(item.id);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${item.quantity}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SaharaColors.whiteSoft,
              ),
            ),
          ),
          _btn(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              ShopCartController.instance.add(item.product);
            },
          ),
        ],
      ),
    );
  }

  Widget _btn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(icon, size: 16, color: SaharaColors.grayText),
      ),
    );
  }
}
