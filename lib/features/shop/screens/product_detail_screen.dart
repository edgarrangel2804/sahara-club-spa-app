import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/services/bloc/services_bloc.dart';
import 'package:sahara_club_spa_app/features/services/bloc/services_event.dart';
import 'package:sahara_club_spa_app/features/services/bloc/services_state.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  String get _type     => product['type'] as String? ?? 'service';
  String get _name     => product['name'] as String? ?? '';
  String get _desc     => product['description'] as String? ?? '';
  double get _price    => (product['price'] as num?)?.toDouble() ?? 0;
  int?   get _duration => product['duration'] as int?;
  String? get _imgUrl  => product['image'] as String?;
  String get _category => product['category'] as String? ?? '';
  bool   get _quote    => _price == 0;

  static String _assetFor(String cat) => switch (cat) {
    'masajes'             => 'assets/images/07.png',
    'faciales'            => 'assets/images/01.png',
    'faciales_combo'      => 'assets/images/01.png',
    'corporales'          => 'assets/images/06.png',
    'tecnologia_facial'   => 'assets/images/02.png',
    'moldeo'              => 'assets/images/04.png',
    'tecnologia_corporal' => 'assets/images/03.png',
    'fusionadas'          => 'assets/images/05.png',
    _                     => 'assets/images/08.png',
  };

  static List<String> _benefitsFor(String cat) => switch (cat) {
    'masajes' => ['Libera tensión muscular profunda', 'Mejora la calidad del sueño', 'Restaura el equilibrio energético'],
    'faciales' || 'faciales_combo' => ['Luminosidad y uniformidad del tono', 'Hidratación profunda', 'Efecto lifting visible'],
    'tecnologia_facial' => ['Resultados desde la primera sesión', 'No invasivo, sin tiempo de recuperación', 'Potencia tus tratamientos faciales'],
    'corporales' => ['Descanso profundo del sistema nervioso', 'Reconexión mente-cuerpo', 'Sensación de ligereza y calma'],
    'moldeo' => ['Redefine contornos corporales', 'Mejora circulación y drenaje', 'Resultados progresivos y duraderos'],
    'tecnologia_corporal' => ['Reducción localizada efectiva', 'Sin cirugía ni recuperación', 'Complementa tu rutina de bienestar'],
    'fusionadas' => ['Experiencia multisensorial completa', 'Rituales únicos e irrepetibles', 'Bienestar integral en una sesión'],
    _ => ['Experiencia personalizada', 'Atención premium', 'Resultados visibles'],
  };

  @override
  Widget build(BuildContext context) {
    final benefits = _benefitsFor(_category);
    final asset = _assetFor(_category);

    return BlocProvider(
      create: (_) => ServicesBloc()..add(const ServicesLoadRequested()),
      child: Scaffold(
        backgroundColor: SaharaColors.black,
        body: Stack(
          children: [
            // ── Imagen hero ──────────────────────────────────────────────
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.48,
              width: double.infinity,
              child: _imgUrl != null
                  ? Image.network(_imgUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset(asset, fit: BoxFit.cover))
                  : Image.asset(asset, fit: BoxFit.cover),
            ),

            // ── Gradiente sobre imagen ───────────────────────────────────
            Container(
              height: MediaQuery.of(context).size.height * 0.48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    SaharaColors.black.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // ── Botón back ───────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),

            // ── Sheet deslizable ─────────────────────────────────────────
            DraggableScrollableSheet(
              initialChildSize: 0.58,
              minChildSize: 0.55,
              maxChildSize: 0.92,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: SaharaColors.black,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(
                          color: SaharaColors.gold.withValues(alpha: 0.12)),
                    ),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 36, height: 3,
                          decoration: BoxDecoration(
                            color: SaharaColors.grayDark,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Categoría badge
                      _CategoryBadge(category: _category, type: _type),
                      const SizedBox(height: 14),

                      // Nombre
                      Text(_name, style: GoogleFonts.playfairDisplay(
                        fontSize: 28, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w300, height: 1.15,
                      )),
                      const SizedBox(height: 10),

                      // Precio + duración
                      Row(
                        children: [
                          Text(
                            _quote ? 'Precio por cotización' : '\$${_price.toStringAsFixed(0)}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22, color: SaharaColors.gold,
                              fontWeight: FontWeight.w400,
                              fontStyle: _quote ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                          if (_duration != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SaharaColors.grayDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 11, color: SaharaColors.grayText),
                                  const SizedBox(width: 4),
                                  Text('$_duration min',
                                    style: GoogleFonts.inter(
                                      fontSize: 11, color: SaharaColors.grayText,
                                    )),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Divisor
                      Container(height: 1,
                          color: SaharaColors.grayDark.withValues(alpha: 0.5)),
                      const SizedBox(height: 22),

                      // Descripción
                      if (_desc.isNotEmpty) ...[
                        Text(_desc, style: GoogleFonts.inter(
                          fontSize: 14, color: SaharaColors.grayText, height: 1.7,
                        )),
                        const SizedBox(height: 24),
                      ],

                      // Beneficios
                      Text('Beneficios', style: GoogleFonts.playfairDisplay(
                        fontSize: 16, color: SaharaColors.gold,
                        fontWeight: FontWeight.w400,
                      )),
                      const SizedBox(height: 14),
                      ...benefits.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.fromLTRB(0, 6, 12, 0),
                              decoration: const BoxDecoration(
                                color: SaharaColors.gold, shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(child: Text(b, style: GoogleFonts.inter(
                              fontSize: 13, color: SaharaColors.grayText, height: 1.5,
                            ))),
                          ],
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),

            // ── CTA flotante ─────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _CtaButton(product: product, type: _type, quote: _quote),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge de categoría ────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category, type;
  const _CategoryBadge({required this.category, required this.type});

  static String _label(String cat, String type) {
    if (type == 'physical') return 'PRODUCTO';
    if (type == 'digital')  return 'DIGITAL';
    return switch (cat) {
      'masajes'             => 'MASAJE',
      'faciales'            => 'FACIAL',
      'faciales_combo'      => 'FACIAL',
      'corporales'          => 'EXPERIENCIA',
      'tecnologia_facial'   => 'TECNOLOGÍA',
      'moldeo'              => 'MOLDEO',
      'tecnologia_corporal' => 'TECNOLOGÍA',
      'fusionadas'          => 'RITUAL FUSIONADO',
      'colaboraciones'      => 'COLABORACIÓN',
      'sahara_house'        => 'SAHARA HOUSE',
      _                     => 'RITUAL',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.spa_outlined, size: 11,
            color: SaharaColors.gold.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(_label(category, type), style: GoogleFonts.inter(
          fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.w600,
          color: SaharaColors.gold.withValues(alpha: 0.7),
        )),
      ],
    );
  }
}

// ── Botón CTA según tipo ──────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final Map<String, dynamic> product;
  final String type;
  final bool quote;
  const _CtaButton({
    required this.product, required this.type, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SaharaColors.black.withValues(alpha: 0.0),
            SaharaColors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: SaharaGradients.goldShimmer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: SaharaColors.gold.withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 6),
            )],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _handleTap(context);
            },
            icon: Icon(_ctaIcon, size: 17),
            label: Text(_ctaLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: SaharaColors.black,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }

  String get _ctaLabel => switch (type) {
    'physical' => 'Agregar al carrito',
    'digital'  => 'Obtener acceso',
    _          => quote ? 'Solicitar cotización' : 'Reservar este ritual',
  };

  IconData get _ctaIcon => switch (type) {
    'physical' => Icons.shopping_cart_outlined,
    'digital'  => Icons.download_outlined,
    _          => Icons.calendar_today_outlined,
  };

  void _handleTap(BuildContext context) {
    switch (type) {
      case 'service':
        // Busca el SpaService por nombre y navega al booking
        _navigateToBooking(context);
        break;
      case 'physical':
        ShopCartController.instance.add(product);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${product['name'] ?? 'Producto'} agregado al carrito',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        break;
      case 'digital':
        ShopCartController.instance.add(product);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${product['name'] ?? 'Producto'} agregado al carrito',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        break;
    }
  }

  void _navigateToBooking(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final state = context.read<ServicesBloc>().state;
    if (state is ServicesLoaded) {
      try {
        final service = state.all.firstWhere(
          (s) => s.name.toLowerCase().trim() == name.toLowerCase().trim(),
        );
        Navigator.pushNamed(context, AppRoutes.bookingRequest, arguments: service);
        return;
      } catch (_) {}
    }
    // Si no encontró match exacto, va al listado de servicios
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.services, (r) => false);
  }
}
