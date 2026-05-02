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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? SaharaColors.gold;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fondo ───────────────────────────────────────────────────
            _buildBackground(accent),

            // ── Overlay degradado ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── Contenido ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Icon(icon ?? Icons.spa_outlined,
                        color: SaharaColors.whiteSoft, size: 16),
                  ),

                  const Spacer(),

                  // Nombre
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Subtítulo
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: SaharaColors.grayText,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Precio
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      priceOnQuote ? 'Cotización' : 'desde \$$price',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Color accent) {
    if (imageUrl != null) {
      return Image.network(imageUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _colorBg(accent));
    }
    if (imagePath != null) {
      return Image.asset(imagePath!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _colorBg(accent));
    }
    return _colorBg(accent);
  }

  Widget _colorBg(Color accent) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.4), SaharaColors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}
