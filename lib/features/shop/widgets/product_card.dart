import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String price;
  final String? imagePath;
  final String? imageUrl;
  final IconData? icon;
  final Color? accentColor;
  final bool priceOnQuote;
  final String? tag;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.price,
    this.imagePath,
    this.imageUrl,
    this.icon,
    this.accentColor,
    this.priceOnQuote = false,
    this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? SaharaColors.gold;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Imagen (60 % del espacio) ─────────────────────────
              Expanded(
                flex: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(accent),
                    // Gradiente inferior sobre la imagen
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0D0D0D).withValues(alpha: 0.9),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Tag (tipo / categoría) en esquina superior izquierda
                    if (tag != null)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            tag!.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: accent.withValues(alpha: 0.9),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Divisor dorado (light-catcher) ────────────────────
              Container(height: 0.6, color: accent.withValues(alpha: 0.2)),

              // ── Sección de info (40 % del espacio) ───────────────
              Expanded(
                flex: 40,
                child: Container(
                  color: const Color(0xFF0D0D0D),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          color: SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Subtítulo
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: SaharaColors.grayText.withValues(alpha: 0.55),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Precio — sin badge, solo texto con línea decorativa
                      Row(
                        children: [
                          Container(
                            width: 16, height: 0.6,
                            color: accent.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            priceOnQuote ? 'Cotización' : '\$$price',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Color accent) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _colorBg(accent),
      );
    }
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _colorBg(accent),
      );
    }
    return _colorBg(accent);
  }

  Widget _colorBg(Color accent) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.35),
              const Color(0xFF0A0A0A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            icon ?? Icons.spa_outlined,
            size: 32,
            color: accent.withValues(alpha: 0.3),
          ),
        ),
      );
}
