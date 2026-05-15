import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:sahara_club_spa_app/features/shop/screens/cart_screen.dart';

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildHero()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TierCard(
                  tier: _TierData.silver,
                  onSelect: (tier) => _handleSelect(context, tier),
                ),
                const SizedBox(height: 16),
                _TierCard(
                  tier: _TierData.gold,
                  onSelect: (tier) => _handleSelect(context, tier),
                  featured: true,
                ),
                const SizedBox(height: 16),
                _TierCard(
                  tier: _TierData.black,
                  onSelect: (tier) => _handleSelect(context, tier),
                ),
                const SizedBox(height: 48),
                _buildStory(),
                const SizedBox(height: 60),
              ]),
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
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
            const SizedBox(width: 16),
            Text('SAHARA CLUB',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 4,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEMBRESÍA ELITE',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: SaharaColors.gold,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Acceso exclusivo\na un mundo de\nbienestar.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 38,
              color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w300,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nuestras membresías son llaves a un\nsantuario privado donde el tiempo\nse detiene.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: SaharaColors.grayText,
              height: 1.7,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Un refugio diseñado\npara tu espíritu.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w300,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Disfruta de acceso preferencial a terapeutas maestros, suites de tratamiento privadas y eventos exclusivos del club. Tu bienestar no es un lujo, es una necesidad.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SaharaColors.grayText,
              height: 1.75,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.star_rounded,
                  size: 14, color: SaharaColors.gold.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text('Terapeutas maestros',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SaharaColors.grayText,
                  )),
              const SizedBox(width: 20),
              Icon(Icons.lock_outline_rounded,
                  size: 14, color: SaharaColors.gold.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text('Acceso privado',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SaharaColors.grayText,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSelect(BuildContext context, _TierData tier) {
    HapticFeedback.mediumImpact();
    ShopCartController.instance.add({
      'id': tier.productId,
      'name': tier.title,
      'description': tier.subtitle,
      'price': tier.priceValue,
      'type': 'membership',
      'category': 'membership',
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }
}

// ── Tier data model ───────────────────────────────────────────────────────────

class _TierBenefit {
  const _TierBenefit({required this.label, required this.included});
  final String label;
  final bool included;
}

class _TierData {
  const _TierData({
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceValue,
    required this.period,
    required this.accentColor,
    required this.cta,
    required this.benefits,
  });

  final String productId;
  final String title;
  final String subtitle;
  final String price;
  final double priceValue;
  final String period;
  final Color accentColor;
  final String cta;
  final List<_TierBenefit> benefits;

  static const silver = _TierData(
    productId: 'mem-oasis-plata',
    title: 'Oasis Plata',
    subtitle: 'Lujo de entrada',
    price: '\$250',
    priceValue: 250,
    period: '/mes',
    accentColor: Color(0xFFB8B8C8),
    cta: 'SELECCIONAR',
    benefits: [
      _TierBenefit(label: 'Reserva prioritaria de rituales', included: true),
      _TierBenefit(label: 'Esenciales de ritual de cortesía', included: true),
      _TierBenefit(label: 'Concierge digital de bienestar', included: false),
      _TierBenefit(label: 'Acceso privado al santuario', included: false),
    ],
  );

  static const gold = _TierData(
    productId: 'mem-duna-dorada',
    title: 'Duna Dorada',
    subtitle: 'La experiencia de autor',
    price: '\$550',
    priceValue: 550,
    period: '/mes',
    accentColor: SaharaColors.gold,
    cta: 'SOLICITAR ACCESO',
    benefits: [
      _TierBenefit(label: 'Reserva prioritaria de rituales', included: true),
      _TierBenefit(label: 'Esenciales de ritual de cortesía', included: true),
      _TierBenefit(label: 'Concierge digital de bienestar', included: true),
      _TierBenefit(label: 'Acceso privado al santuario', included: false),
    ],
  );

  static const black = _TierData(
    productId: 'mem-sahara-black',
    title: 'Sahara Black',
    subtitle: 'El nivel más alto',
    price: '\$1,200',
    priceValue: 1200,
    period: '/mes',
    accentColor: Color(0xFF8A7560),
    cta: 'SELECCIONAR',
    benefits: [
      _TierBenefit(label: 'Reserva prioritaria de rituales', included: true),
      _TierBenefit(label: 'Esenciales de ritual de cortesía', included: true),
      _TierBenefit(label: 'Concierge digital de bienestar', included: true),
      _TierBenefit(label: 'Acceso privado al santuario', included: true),
    ],
  );
}

// ── Tier card ─────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.onSelect,
    this.featured = false,
  });

  final _TierData tier;
  final void Function(_TierData) onSelect;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: featured
            ? const Color(0xFF0F0E0A)
            : const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: featured
              ? tier.accentColor.withValues(alpha: 0.4)
              : tier.accentColor.withValues(alpha: 0.15),
          width: featured ? 1.2 : 0.8,
        ),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: tier.accentColor.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTop(),
          _buildBenefits(),
          _buildCta(context),
        ],
      ),
    );
  }

  Widget _buildTop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tier.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: tier.accentColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  tier.title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: tier.accentColor,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (featured) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tier.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'MÁS POPULAR',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: SaharaColors.black,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(tier.subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: tier.accentColor.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: tier.price,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  color: tier.accentColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: ' MXN${tier.period}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: SaharaColors.grayText.withValues(alpha: 0.6),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        children: [
          Container(
              height: 0.5,
              color: tier.accentColor.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          ...tier.benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: b.included
                            ? tier.accentColor.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: b.included
                              ? tier.accentColor.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        b.included
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 11,
                        color: b.included
                            ? tier.accentColor
                            : SaharaColors.grayText.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: b.included
                              ? SaharaColors.whiteSoft.withValues(alpha: 0.85)
                              : SaharaColors.grayText.withValues(alpha: 0.35),
                          fontWeight: b.included
                              ? FontWeight.w400
                              : FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: SizedBox(
        width: double.infinity,
        child: featured
            ? Container(
                decoration: BoxDecoration(
                  gradient: SaharaGradients.goldShimmer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: tier.accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => onSelect(tier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: SaharaColors.black,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(tier.cta),
                ),
              )
            : OutlinedButton(
                onPressed: () => onSelect(tier),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tier.accentColor,
                  side: BorderSide(
                      color: tier.accentColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(tier.cta),
              ),
      ),
    );
  }
}
