import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:sahara_club_spa_app/features/shop/models/cart_item.dart';
import 'package:sahara_club_spa_app/features/shop/screens/cart_screen.dart';
import 'package:sahara_club_spa_app/features/shop/screens/gift_card_screen.dart';
import 'package:sahara_club_spa_app/features/shop/screens/product_detail_screen.dart';
import 'package:sahara_club_spa_app/features/shop/widgets/product_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _physical = [];
  List<Map<String, dynamic>> _digital  = [];
  bool _loading = true;

  static const _tabs  = ['Rituales', 'Tienda', 'Digital', 'Regalos', 'Membresías'];
  static const _types = ['service', 'physical', 'digital'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait(
        _types.map((t) => Supabase.instance.client
            .from('products')
            .select()
            .eq('type', t)
            .eq('active', true)
            .order('display_order')),
      );
      if (!mounted) return;
      setState(() {
        _services = (results[0] as List).cast<Map<String, dynamic>>();
        _physical = (results[1] as List).cast<Map<String, dynamic>>();
        _digital  = (results[2] as List).cast<Map<String, dynamic>>();
        _loading  = false;
      });
    } catch (e) {
      debugPrint('ShopScreen error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTabBar(),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(
                        color: SaharaColors.gold, strokeWidth: 1.5))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _ProductGrid(
                            items: _services,
                            emptyLabel: 'Sin rituales disponibles',
                            itemTag: 'Ritual',
                          ),
                          _ProductGrid(
                            items: _physical,
                            emptyLabel: 'Sin productos disponibles',
                            itemTag: 'Físico',
                          ),
                          _ProductGrid(
                            items: _digital,
                            emptyLabel: 'Sin contenido disponible',
                            itemTag: 'Digital',
                          ),
                          const _GiftCardTab(),
                          const _MembershipsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIENDA', style: GoogleFonts.inter(
                  fontSize: 10, color: SaharaColors.gold,
                  fontWeight: FontWeight.w700, letterSpacing: 3,
                )),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'Seleccionado\n',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w300, height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: 'para tu ritual',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28, color: SaharaColors.gold,
                        fontWeight: FontWeight.w400, fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: ShopCartController.instance,
            builder: (context, items, _) {
              final count = ShopCartController.instance.itemCount;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: SaharaColors.grayDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: count > 0
                              ? SaharaColors.gold.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 19,
                        color: count > 0
                            ? SaharaColors.gold
                            : SaharaColors.grayText.withValues(alpha: 0.6),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4, top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(
                              minWidth: 17, minHeight: 17),
                          decoration: const BoxDecoration(
                            color: SaharaColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: SaharaColors.black,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isSelected = _tabController.index == i;
            return GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SaharaColors.gold.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? SaharaColors.gold.withValues(alpha: 0.6)
                        : SaharaColors.grayDark,
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Grid de productos ─────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyLabel;
  final String itemTag;

  const _ProductGrid({
    required this.items,
    required this.emptyLabel,
    required this.itemTag,
  });

  static String _imageFor(String? category) => switch (category) {
    'masajes'             => 'assets/images/07.png',
    'faciales'            => 'assets/images/01.png',
    'faciales_combo'      => 'assets/images/01.png',
    'corporales'          => 'assets/images/06.png',
    'tecnologia_facial'   => 'assets/images/02.png',
    'moldeo'              => 'assets/images/04.png',
    'tecnologia_corporal' => 'assets/images/03.png',
    'fusionadas'          => 'assets/images/05.png',
    'colaboraciones'      => 'assets/images/08.png',
    'sahara_house'        => 'assets/images/08.png',
    _                     => 'assets/images/07.png',
  };

  static Color _accentFor(String? category) => switch (category) {
    'masajes'             => const Color(0xFF8B5E3C),
    'faciales'            => const Color(0xFF7C4D6B),
    'faciales_combo'      => const Color(0xFF7C4D6B),
    'corporales'          => const Color(0xFF3B6B5E),
    'tecnologia_facial'   => const Color(0xFF4A5B8C),
    'moldeo'              => const Color(0xFF6B4A7C),
    'tecnologia_corporal' => const Color(0xFF2D6B7A),
    'fusionadas'          => const Color(0xFF7A5C2D),
    _                     => SaharaColors.goldDim,
  };

  static IconData _iconFor(String? category) => switch (category) {
    'masajes'             => Icons.self_improvement_outlined,
    'faciales'            => Icons.face_outlined,
    'faciales_combo'      => Icons.face_outlined,
    'corporales'          => Icons.spa_outlined,
    'tecnologia_facial'   => Icons.biotech_outlined,
    'moldeo'              => Icons.accessibility_new_outlined,
    'tecnologia_corporal' => Icons.electrical_services_outlined,
    'fusionadas'          => Icons.auto_awesome_outlined,
    'colaboraciones'      => Icons.group_outlined,
    'sahara_house'        => Icons.villa_outlined,
    _                     => Icons.shopping_bag_outlined,
  };

  static String _categoryLabelFor(String? category) => switch (category) {
    'masajes'             => 'Masaje',
    'faciales'            => 'Facial',
    'faciales_combo'      => 'Facial',
    'corporales'          => 'Corporal',
    'tecnologia_facial'   => 'Tecnología',
    'moldeo'              => 'Moldeo',
    'tecnologia_corporal' => 'Tecnología',
    'fusionadas'          => 'Fusionado',
    'colaboraciones'      => 'Colaboración',
    'sahara_house'        => 'Sahara House',
    _                     => '',
  };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: GoogleFonts.inter(
          fontSize: 14,
          color: SaharaColors.grayText.withValues(alpha: 0.5),
        )),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final p = items[i];
        final price    = (p['price'] as num?)?.toDouble() ?? 0;
        final category = p['category'] as String?;
        final imageUrl = p['image'] as String?;
        final duration = p['duration'] as int?;
        final subtitle = duration != null
            ? '$duration min'
            : (p['description'] as String? ?? '');
        final catLabel = _categoryLabelFor(category);
        final tag      = catLabel.isNotEmpty ? catLabel : itemTag;

        return ProductCard(
          name: p['name'] as String? ?? '',
          subtitle: subtitle,
          price: price.toStringAsFixed(0),
          imageUrl: imageUrl,
          imagePath: (imageUrl == null || imageUrl.isEmpty)
              ? _imageFor(category)
              : null,
          icon: _iconFor(category),
          accentColor: _accentFor(category),
          priceOnQuote: price == 0,
          tag: tag,
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab de Gift Cards ─────────────────────────────────────────────────────────

class _GiftCardTab extends StatelessWidget {
  const _GiftCardTab();

  static const _presets = [
    _GiftPreset(amount: 1000,  label: '\$1,000', subtitle: 'Un ritual de entrada'),
    _GiftPreset(amount: 2500,  label: '\$2,500', subtitle: 'La experiencia completa'),
    _GiftPreset(amount: 5000,  label: '\$5,000', subtitle: 'Paquete premium'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Hero copy
        Text('REGALA BIENESTAR', style: GoogleFonts.inter(
          fontSize: 10, color: SaharaColors.gold,
          letterSpacing: 4, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 14),
        Text(
          'El regalo más\nprofundo que\npuedes dar.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32, color: SaharaColors.whiteSoft,
            fontWeight: FontWeight.w300, height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gift cards con validez de 12 meses\npara cualquier ritual del spa.',
          style: GoogleFonts.inter(
            fontSize: 13, color: SaharaColors.grayText,
            height: 1.65, fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 32),
        // Cards de montos
        ..._presets.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _GiftAmountCard(preset: p),
        )),
      ],
    );
  }
}

class _GiftPreset {
  const _GiftPreset({
    required this.amount,
    required this.label,
    required this.subtitle,
  });
  final int amount;
  final String label;
  final String subtitle;
}

class _GiftAmountCard extends StatelessWidget {
  const _GiftAmountCard({required this.preset});
  final _GiftPreset preset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GiftCardScreen(
            amount: preset.amount,
            label: preset.label,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SaharaColors.gold.withValues(alpha: 0.2),
                    SaharaColors.gold.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: SaharaColors.gold, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preset.subtitle, style: GoogleFonts.inter(
                    fontSize: 12, color: SaharaColors.grayText,
                    fontWeight: FontWeight.w300,
                  )),
                  const SizedBox(height: 4),
                  Text(preset.label, style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.gold,
                    fontWeight: FontWeight.w400,
                  )),
                  Text('MXN · Válida 12 meses', style: GoogleFonts.inter(
                    fontSize: 10,
                    color: SaharaColors.grayText.withValues(alpha: 0.45),
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: SaharaColors.gold.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Tab de Membresías ─────────────────────────────────────────────────────────

class _MembershipsTab extends StatelessWidget {
  const _MembershipsTab();

  static const _tiers = [
    _Tier(
      title: 'Oasis Plata',
      subtitle: 'Lujo de entrada',
      price: '\$250',
      period: '/mes',
      accent: Color(0xFFB8B8C8),
      benefits: ['Reserva prioritaria de rituales', 'Esenciales de ritual de cortesía'],
      excluded: ['Concierge digital de bienestar', 'Acceso privado al santuario'],
    ),
    _Tier(
      title: 'Duna Dorada',
      subtitle: 'La experiencia de autor',
      price: '\$550',
      period: '/mes',
      accent: SaharaColors.gold,
      featured: true,
      benefits: ['Reserva prioritaria de rituales', 'Esenciales de ritual de cortesía', 'Concierge digital de bienestar'],
      excluded: ['Acceso privado al santuario'],
    ),
    _Tier(
      title: 'Sahara Black',
      subtitle: 'El nivel más alto',
      price: '\$1,200',
      period: '/mes',
      accent: Color(0xFF8A7560),
      benefits: ['Reserva prioritaria de rituales', 'Esenciales de ritual de cortesía', 'Concierge digital de bienestar', 'Acceso privado al santuario'],
      excluded: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text('MEMBRESÍA ELITE', style: GoogleFonts.inter(
          fontSize: 10, color: SaharaColors.gold,
          letterSpacing: 4, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 14),
        Text(
          'Acceso exclusivo\na un mundo de\nbienestar.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 30, color: SaharaColors.whiteSoft,
            fontWeight: FontWeight.w300, height: 1.15,
          ),
        ),
        const SizedBox(height: 28),
        ..._tiers.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _TierCard(tier: t),
        )),
      ],
    );
  }
}

class _Tier {
  final String title, subtitle, price, period;
  final Color accent;
  final bool featured;
  final List<String> benefits;
  final List<String> excluded;
  const _Tier({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.accent,
    this.featured = false,
    required this.benefits,
    required this.excluded,
  });
}

class _TierCard extends StatelessWidget {
  final _Tier tier;
  const _TierCard({required this.tier});

  void _addToCart(BuildContext context) {
    ShopCartController.instance.add({
      'id': 'mem-${tier.title.toLowerCase().replaceAll(' ', '-')}',
      'name': tier.title,
      'description': tier.subtitle,
      'price': double.parse(tier.price.replaceAll(RegExp(r'[^\d.]'), '')),
      'type': 'membership',
      'category': 'membership',
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = tier.accent;
    return Container(
      decoration: BoxDecoration(
        color: tier.featured ? const Color(0xFF0F0E0A) : const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.featured
              ? accent.withValues(alpha: 0.4)
              : accent.withValues(alpha: 0.15),
          width: tier.featured ? 1.2 : 0.8,
        ),
        boxShadow: tier.featured
            ? [BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 24, offset: const Offset(0, 8))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(tier.title.toUpperCase(), style: GoogleFonts.inter(
                    fontSize: 9, color: accent,
                    letterSpacing: 2.5, fontWeight: FontWeight.w700,
                  )),
                ),
                if (tier.featured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('MÁS POPULAR', style: GoogleFonts.inter(
                      fontSize: 8, color: SaharaColors.black,
                      letterSpacing: 1.5, fontWeight: FontWeight.w800,
                    )),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(tier.subtitle, style: GoogleFonts.inter(
              fontSize: 12, color: accent.withValues(alpha: 0.7), letterSpacing: 0.5,
            )),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: tier.price,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34, color: accent, fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: ' MXN${tier.period}',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: SaharaColors.grayText.withValues(alpha: 0.6),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(height: 0.5, color: accent.withValues(alpha: 0.12)),
            const SizedBox(height: 14),
            // Beneficios incluidos
            ...tier.benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.15),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.check_rounded, size: 11, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(b, style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.whiteSoft.withValues(alpha: 0.85),
                  ))),
                ],
              ),
            )),
            // Beneficios excluidos
            ...tier.excluded.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Icon(Icons.close_rounded, size: 11,
                        color: SaharaColors.grayText.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(b, style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SaharaColors.grayText.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w300,
                  ))),
                ],
              ),
            )),
            const SizedBox(height: 6),
            // CTA
            SizedBox(
              width: double.infinity,
              child: tier.featured
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: SaharaGradients.goldShimmer,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _addToCart(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: SaharaColors.black,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('SOLICITAR ACCESO'),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => _addToCart(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SELECCIONAR'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
