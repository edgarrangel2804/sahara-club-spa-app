import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/features/services/bloc/services_bloc.dart';
import 'package:sahara_club_spa_app/features/services/bloc/services_event.dart';
import 'package:sahara_club_spa_app/features/services/bloc/services_state.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicesBloc()..add(const ServicesLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  ServiceCategory? _selected;
  Map<String, dynamic>? _nextBooking;
  bool _loadingBooking = true;
  String? _avatarUrl;

  String get _firstName {
    final meta = AuthService().currentUser?.userMetadata;
    final full  = meta?['full_name'] as String? ?? '';
    return full.isNotEmpty ? full.split(' ').first : '';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingBooking = false);
      return;
    }
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        Supabase.instance.client
            .from('bookings')
            .select('''
              id, booking_date, booking_time, status, service_name,
              services(name),
              therapists:profiles!bookings_therapist_id_fkey(full_name)
            ''')
            .eq('client_id', user.id)
            .inFilter('status', ['scheduled', 'confirmed'])
            .gte('booking_date', today)
            .order('booking_date')
            .order('booking_time')
            .limit(1),
        Supabase.instance.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle(),
      ]);

      if (mounted) {
        final bookingList = results[0] as List;
        final profile = results[1] as Map<String, dynamic>?;
        setState(() {
          _nextBooking = bookingList.isNotEmpty ? bookingList.first as Map<String, dynamic> : null;
          _avatarUrl   = profile?['avatar_url'] as String?;
          _loadingBooking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is! ServicesLoaded) {
            return const Center(child: CircularProgressIndicator(
                color: SaharaColors.gold, strokeWidth: 1.5));
          }
          final all = state.all;
          final filtered = _selected == null
              ? all
              : all.where((s) => s.category == _selected).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero ────────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHero(context, all)),

              // ── Próxima cita ─────────────────────────────────────────────
              if (!_loadingBooking && _nextBooking != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: _NextBookingCard(booking: _nextBooking!),
                  ),
                ),

              // ── Categorías ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXPLORA', style: GoogleFonts.inter(
                        fontSize: 10, color: SaharaColors.gold,
                        fontWeight: FontWeight.w700, letterSpacing: 2.5,
                      )),
                      const SizedBox(height: 14),
                      _buildCategoryRow(),
                    ],
                  ),
                ),
              ),

              // ── Grid de servicios ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final s = filtered[i];
                      return _ServiceGridCard(
                        service: s,
                        onTap: () => Navigator.pushNamed(
                          ctx, AppRoutes.serviceDetail, arguments: s),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, List<SpaService> all) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset('assets/images/08.png', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
            ),
          ),
          // Gradiente oscuro
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC0B0B0B), Color(0x550B0B0B), Color(0xDD0B0B0B)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Contenido
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SAHARA', style: GoogleFonts.playfairDisplay(
                            fontSize: 18, color: SaharaColors.gold,
                            letterSpacing: 5, fontWeight: FontWeight.w400,
                          )),
                          Text('CLUB', style: GoogleFonts.inter(
                            fontSize: 9, color: SaharaColors.gold.withValues(alpha: 0.7),
                            letterSpacing: 4,
                          )),
                        ],
                      ),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: SaharaColors.gold.withValues(alpha: 0.5), width: 1.2),
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: ClipOval(
                          child: _avatarUrl != null
                              ? Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_outline,
                                      color: SaharaColors.gold, size: 20),
                                )
                              : const Icon(Icons.person_outline,
                                  color: SaharaColors.gold, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Texto principal
                  Text('BIENVENIDA DE NUEVO', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.gold,
                    letterSpacing: 3, fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: _firstName.isNotEmpty
                            ? 'Tu cuerpo recuerda\n'
                            : 'Tu cuerpo recuerda\n',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32, color: SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w300, height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'cómo descansar',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32, color: SaharaColors.gold,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic, height: 1.3,
                        ),
                      ),
                      if (_firstName.isNotEmpty)
                        TextSpan(
                          text: ', $_firstName.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32, color: SaharaColors.whiteSoft,
                            fontWeight: FontWeight.w300, height: 1.3,
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  // CTA
                  GestureDetector(
                    onTap: () {
                      if (all.isNotEmpty) {
                        Navigator.pushNamed(context, AppRoutes.serviceDetail,
                            arguments: all.first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      decoration: BoxDecoration(
                        color: SaharaColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: SaharaColors.gold.withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('RESERVA TU RITUAL', style: GoogleFonts.inter(
                            fontSize: 11, color: SaharaColors.gold,
                            fontWeight: FontWeight.w600, letterSpacing: 1.5,
                          )),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded,
                              color: SaharaColors.gold, size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtro de categorías ──────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _CategoryChip(
            label: 'Todos',
            isSelected: _selected == null,
            onTap: () => setState(() => _selected = null),
          ),
          ...ServiceCategory.values.map((cat) => _CategoryChip(
                label: cat.label,
                isSelected: _selected == cat,
                onTap: () => setState(
                    () => _selected = _selected == cat ? null : cat),
              )),
        ],
      ),
    );
  }
}

// ── Tarjeta próxima cita ──────────────────────────────────────────────────────

class _NextBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _NextBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status      = booking['status'] as String? ?? 'scheduled';
    final dateStr     = booking['booking_date'] as String? ?? '';
    final timeStr     = booking['booking_time'] as String? ?? '';
    final serviceName = (booking['services'] as Map?)?['name'] as String?
        ?? booking['service_name'] as String? ?? '—';
    final therapist   = (booking['therapists'] as Map?)?['full_name'] as String?;

    DateTime? date;
    try { date = DateTime.parse(dateStr); } catch (_) {}
    final dateLabel = date != null
        ? DateFormat("EEE d 'de' MMMM", 'es').format(date)
        : dateStr;
    final timeLabel = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
    final isConfirmed = status == 'confirmed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TU PRÓXIMA CITA', style: GoogleFonts.inter(
          fontSize: 10, color: SaharaColors.gold,
          fontWeight: FontWeight.w700, letterSpacing: 2.5,
        )),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConfirmed
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : SaharaColors.gold.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Imagen de fondo
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.asset('assets/images/07.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF111111)),
                  ),
                ),
                // Gradiente
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SaharaColors.black.withValues(alpha: 0.85),
                        SaharaColors.black.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                // Contenido
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                      : SaharaColors.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isConfirmed
                                        ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                                        : SaharaColors.gold.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  isConfirmed ? 'Confirmada' : 'Pendiente',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isConfirmed
                                        ? const Color(0xFF4CAF50)
                                        : SaharaColors.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(serviceName, style: GoogleFonts.playfairDisplay(
                                fontSize: 18, color: SaharaColors.whiteSoft,
                                fontWeight: FontWeight.w400,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 12, color: SaharaColors.grayText),
                                const SizedBox(width: 5),
                                Text('$dateLabel  ·  $timeLabel',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: SaharaColors.grayText)),
                              ]),
                              if (therapist != null) ...[
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.person_outline,
                                      size: 12, color: SaharaColors.grayText),
                                  const SizedBox(width: 5),
                                  Text(therapist, style: GoogleFonts.inter(
                                      fontSize: 12, color: SaharaColors.grayText)),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: SaharaColors.gold, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de servicio en grid ───────────────────────────────────────────────

class _ServiceGridCard extends StatelessWidget {
  final SpaService service;
  final VoidCallback onTap;
  const _ServiceGridCard({required this.service, required this.onTap});

  static String _imageFor(ServiceCategory cat) => switch (cat) {
    ServiceCategory.masajes              => 'assets/images/07.png',
    ServiceCategory.faciales            => 'assets/images/01.png',
    ServiceCategory.experienciasCorporales => 'assets/images/06.png',
    ServiceCategory.tecnologiaFacial    => 'assets/images/02.png',
    ServiceCategory.moldeoConsciente    => 'assets/images/04.png',
    ServiceCategory.tecnologiaCorporal  => 'assets/images/03.png',
    ServiceCategory.experienciasFusionadas => 'assets/images/05.png',
    ServiceCategory.saharaHouse         => 'assets/images/08.png',
  };

  static Color _accentFor(ServiceCategory cat) => switch (cat) {
    ServiceCategory.masajes              => const Color(0xFF8B5E3C),
    ServiceCategory.faciales            => const Color(0xFF7C4D6B),
    ServiceCategory.experienciasCorporales => const Color(0xFF3B6B5E),
    ServiceCategory.tecnologiaFacial    => const Color(0xFF4A5B8C),
    ServiceCategory.moldeoConsciente    => const Color(0xFF6B4A7C),
    ServiceCategory.tecnologiaCorporal  => const Color(0xFF2D6B7A),
    ServiceCategory.experienciasFusionadas => const Color(0xFF7A5C2D),
    ServiceCategory.saharaHouse         => const Color(0xFF5C2D2D),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(service.category);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            Image.asset(_imageFor(service.category), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.9), SaharaColors.black],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Overlay tint de categoría
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.2),
                    SaharaColors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono de categoría
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Icon(service.category.icon,
                        color: SaharaColors.whiteSoft, size: 16),
                  ),
                  const Spacer(),
                  // Nombre
                  Text(service.name, style: GoogleFonts.playfairDisplay(
                    fontSize: 15, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w500, height: 1.2,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  // Tagline
                  Text(service.tagline, style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.grayText,
                    height: 1.3,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (!service.priceOnQuote && service.durations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(service.durations.first.formattedPrice,
                      style: GoogleFonts.inter(
                        fontSize: 12, color: SaharaColors.gold,
                        fontWeight: FontWeight.w600,
                      )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de categoría ─────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? SaharaColors.gold.withValues(alpha: 0.7)
                : SaharaColors.grayDark,
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 11,
          color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 0.3,
        )),
      ),
    );
  }
}
