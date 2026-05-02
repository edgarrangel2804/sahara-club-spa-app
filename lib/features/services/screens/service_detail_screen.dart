import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';

class ServiceDetailScreen extends StatelessWidget {
  final SpaService service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
          ),
          CustomScrollView(
            slivers: [
              _DetailAppBar(service: service),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(service: service),
                      const SizedBox(height: 14),
                      Text(
                        service.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          color: SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.tagline,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: SaharaColors.gold,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const GoldDivider(),
                      const SizedBox(height: 20),
                      Text(
                        service.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: SaharaColors.grayText,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (service.priceOnQuote) ...[
                        _buildQuoteSection(context),
                      ] else if (service.hasPackages) ...[
                        _PackagesSection(service: service),
                      ] else if (service.hasDurations) ...[
                        _DurationsSection(service: service),
                      ],
                      const SizedBox(height: 32),
                      _BookButton(service: service),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: SaharaColors.gold.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La inversión se define de manera personalizada. Contáctanos para más información.',
              style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final SpaService service;
  const _DetailAppBar({required this.service});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: SaharaColors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: SaharaColors.gold, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SaharaColors.gold.withValues(alpha: 0.08),
                    border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    service.category.icon,
                    size: 36,
                    color: SaharaColors.gold.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final SpaService service;
  const _CategoryBadge({required this.service});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(service.category.icon, size: 12, color: SaharaColors.gold.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          service.category.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 2,
            color: SaharaColors.gold.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DurationsSection extends StatelessWidget {
  final SpaService service;
  const _DurationsSection({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones de tiempo e inversión',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            color: SaharaColors.gold,
          ),
        ),
        const SizedBox(height: 14),
        ...service.durations.map((d) => _DurationRow(duration: d)),
      ],
    );
  }
}

class _DurationRow extends StatelessWidget {
  final ServiceDuration duration;
  const _DurationRow({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SaharaColors.grayDark, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: SaharaColors.gold.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          if (duration.minutes > 0) ...[
            Text(
              duration.formattedDuration,
              style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
            ),
            const Spacer(),
          ] else
            const Spacer(),
          Text(
            duration.formattedPrice,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              color: SaharaColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackagesSection extends StatelessWidget {
  final SpaService service;
  const _PackagesSection({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paquetes disponibles',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            color: SaharaColors.gold,
          ),
        ),
        const SizedBox(height: 14),
        ...service.packages.map((p) => _PackageRow(package: p)),
      ],
    );
  }
}

class _PackageRow extends StatelessWidget {
  final SessionPackage package;
  const _PackageRow({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SaharaColors.grayDark, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(
                '${package.sessions}',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w700,
                  color: SaharaColors.gold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            package.sessions == 1 ? '1 sesión' : '${package.sessions} sesiones',
            style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
          ),
          const Spacer(),
          Text(
            package.formattedPrice,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              color: SaharaColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final SpaService service;
  const _BookButton({required this.service});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: SaharaGradients.goldShimmer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: SaharaColors.gold.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.bookingRequest,
            arguments: service,
          ),
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: Text(service.priceOnQuote ? 'Solicitar cotización' : 'Reservar experiencia'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: SaharaColors.black,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 17),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
