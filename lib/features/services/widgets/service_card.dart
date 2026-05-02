import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';

class ServiceCard extends StatelessWidget {
  final SpaService service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: service),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: SaharaGradients.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaharaColors.grayDark, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Subtle radial glow on icon side
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        SaharaColors.gold.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    service.category.icon,
                                    size: 11,
                                    color: SaharaColors.gold.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    service.category.label.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: SaharaColors.gold.withValues(alpha: 0.7),
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                service.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  color: SaharaColors.whiteSoft,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                service.tagline,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: SaharaColors.gold.withValues(alpha: 0.85),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SaharaColors.gold.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SaharaColors.gold.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            service.category.icon,
                            color: SaharaColors.gold.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: SaharaColors.grayText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildPriceRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    if (service.priceOnQuote) {
      return _PriceChip(label: 'Por cotización', outlined: true);
    }

    if (service.hasPackages) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _PriceChip(
            label: '${service.packages.first.sessions} ses. · ${service.packages.first.formattedPrice}',
          ),
          if (service.packages.length > 1)
            _PriceChip(
              label: '+${service.packages.length - 1} paquetes',
              outlined: true,
            ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: service.durations.map((d) {
        final label = d.minutes > 0
            ? '${d.formattedDuration} · ${d.formattedPrice}'
            : d.formattedPrice;
        return _PriceChip(label: label);
      }).toList(),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final bool outlined;

  const _PriceChip({required this.label, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : SaharaColors.gold.withValues(alpha: 0.12),
        border: Border.all(
          color: outlined
              ? SaharaColors.gold.withValues(alpha: 0.35)
              : SaharaColors.gold.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: SaharaColors.gold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
