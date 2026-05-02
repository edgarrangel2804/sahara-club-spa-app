import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
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

  // Datos por tab — se cargan una sola vez
  List<Map<String, dynamic>> _services  = [];
  List<Map<String, dynamic>> _physical  = [];
  List<Map<String, dynamic>> _digital   = [];
  bool _loading = true;

  static const _tabs = ['Rituales', 'Tienda', 'Digital'];
  static const _types = ['service', 'physical', 'digital'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
                          ),
                          _ProductGrid(
                            items: _physical,
                            emptyLabel: 'Productos físicos próximamente',
                            comingSoon: true,
                          ),
                          _ProductGrid(
                            items: _digital,
                            emptyLabel: 'Contenido digital próximamente',
                            comingSoon: true,
                          ),
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
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
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
    );
  }
}

// ── Grid de productos ─────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyLabel;
  final bool comingSoon;

  const _ProductGrid({
    required this.items,
    required this.emptyLabel,
    this.comingSoon = false,
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

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !comingSoon) {
      return Center(
        child: Text(emptyLabel, style: GoogleFonts.inter(
          fontSize: 14, color: SaharaColors.grayText.withValues(alpha: 0.5),
        )),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: items.isEmpty ? 6 : items.length,
          itemBuilder: (ctx, i) {
            if (items.isEmpty) {
              // Placeholder skeleton cuando no hay datos
              return _SkeletonCard();
            }

            final p = items[i];
            final price = (p['price'] as num?)?.toDouble() ?? 0;
            final category = p['category'] as String?;
            final imageUrl = p['image'] as String?;
            final duration = p['duration'] as int?;
            final subtitle = duration != null ? '$duration min' : (p['description'] as String? ?? '');

            return ProductCard(
              name: p['name'] as String? ?? '',
              subtitle: subtitle,
              price: price.toStringAsFixed(0),
              imageUrl: imageUrl,
              imagePath: imageUrl == null ? _imageFor(category) : null,
              icon: _iconFor(category),
              accentColor: _accentFor(category),
              priceOnQuote: price == 0,
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p),
                ),
              ),
            );
          },
        ),

        // Badge "Próximamente" para tabs sin datos reales aún
        if (comingSoon && items.isEmpty)
          Positioned(
            bottom: 110, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: SaharaColors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: SaharaColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 13,
                        color: SaharaColors.gold.withValues(alpha: 0.7)),
                    const SizedBox(width: 7),
                    Text('Disponible próximamente', style: GoogleFonts.inter(
                      fontSize: 12,
                      color: SaharaColors.gold.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    )),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

}

// ── Skeleton card de carga ────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SaharaColors.grayDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
