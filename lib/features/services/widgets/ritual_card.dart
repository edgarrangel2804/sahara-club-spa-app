import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';

class RitualCard extends StatelessWidget {
  final SpaService service;
  final bool isHero;
  final VoidCallback? onTap;

  const RitualCard({
    super.key,
    required this.service,
    this.isHero = false,
    this.onTap,
  });

  static Color _accentFor(ServiceCategory cat) {
    return switch (cat) {
      ServiceCategory.masajes              => const Color(0xFF8B5E3C),
      ServiceCategory.faciales            => const Color(0xFF7C4D6B),
      ServiceCategory.experienciasCorporales => const Color(0xFF3B6B5E),
      ServiceCategory.tecnologiaFacial    => const Color(0xFF4A5B8C),
      ServiceCategory.moldeoConsciente    => const Color(0xFF6B4A7C),
      ServiceCategory.tecnologiaCorporal  => const Color(0xFF2D6B7A),
      ServiceCategory.experienciasFusionadas => const Color(0xFF7A5C2D),
      ServiceCategory.saharaHouse         => const Color(0xFF5C2D2D),
      ServiceCategory.facialesPremium     => const Color(0xFF9B4D6B),
      ServiceCategory.colaboraciones      => const Color(0xFF4A7A5C),
    };
  }

  static String _imageFor(ServiceCategory cat) {
    return switch (cat) {
      ServiceCategory.masajes              => 'assets/images/07.png',
      ServiceCategory.faciales            => 'assets/images/01.png',
      ServiceCategory.experienciasCorporales => 'assets/images/06.png',
      ServiceCategory.tecnologiaFacial    => 'assets/images/02.png',
      ServiceCategory.moldeoConsciente    => 'assets/images/04.png',
      ServiceCategory.tecnologiaCorporal  => 'assets/images/03.png',
      ServiceCategory.experienciasFusionadas => 'assets/images/05.png',
      ServiceCategory.saharaHouse         => 'assets/images/08.png',
      ServiceCategory.facialesPremium     => 'assets/images/01.png',
      ServiceCategory.colaboraciones      => 'assets/images/05.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(service.category);
    final height = isHero ? 280.0 : 190.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: EdgeInsets.symmetric(horizontal: isHero ? 0 : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isHero ? 24 : 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen de fondo o gradiente placeholder
              Image.asset(
                _imageFor(service.category),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.9),
                        SaharaColors.black,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Capa de color de marca (tint)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.25),
                      SaharaColors.black.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Gradiente oscuro abajo para legibilidad
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: height * 0.6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        SaharaColors.black.withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Chip de categoría arriba izquierda
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.category.label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Precio arriba derecha
              if (!service.priceOnQuote && service.durations.isNotEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Text(
                    service.durations.first.formattedPrice,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: SaharaColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // Texto inferior
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.name,
                      style: GoogleFonts.playfairDisplay(
                        color: SaharaColors.whiteSoft,
                        fontSize: isHero ? 22 : 18,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.tagline,
                      style: GoogleFonts.inter(
                        color: SaharaColors.grayText,
                        fontSize: isHero ? 13 : 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isHero) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: SaharaColors.gold.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Ver experiencia',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: SaharaColors.gold,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (service.durations.isNotEmpty)
                            Text(
                              service.durations.first.formattedDuration,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: SaharaColors.grayText,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
