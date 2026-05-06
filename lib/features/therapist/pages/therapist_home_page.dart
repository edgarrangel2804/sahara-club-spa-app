import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';
import 'package:sahara_club_spa_app/features/reception/widgets/status_badge.dart';
import 'package:sahara_club_spa_app/features/therapist/data/therapist_repository.dart';

class TherapistHomePage extends StatefulWidget {
  final TherapistRepository repo;
  final String name;
  final String? specialty;
  final String? avatarUrl;

  const TherapistHomePage({
    super.key,
    required this.repo,
    required this.name,
    required this.specialty,
    required this.avatarUrl,
  });

  @override
  State<TherapistHomePage> createState() => _TherapistHomePageState();
}

class _TherapistHomePageState extends State<TherapistHomePage> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _weekStart;
  List<Booking> _bookings = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _load();
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final bookingsFuture = widget.repo.getBookingsForDate(_selectedDate);
      final statsFuture = _isToday(_selectedDate)
          ? widget.repo.getTodayStats()
          : Future.value(<String, dynamic>{});
      final results = await Future.wait([bookingsFuture, statsFuture]);
      if (!mounted) return;
      setState(() {
        _bookings = results[0] as List<Booking>;
        _stats    = results[1] as Map<String, dynamic>;
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBookingDetail(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking:     booking,
        repo:        widget.repo,
        onCompleted: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Column(
      children: [
        _GreetingHeader(
          greeting:  _greeting(),
          name:      widget.name,
          specialty: widget.specialty,
          initials:  initials,
          avatarUrl: widget.avatarUrl,
          stats:     _isToday(_selectedDate) ? _stats : null,
        ),
        _WeekStrip(
          weekDays:     _weekDays,
          selectedDate: _selectedDate,
          onDayTap: (d) { setState(() => _selectedDate = d); _load(); },
          onPrev: () {
            setState(() {
              _weekStart    = _weekStart.subtract(const Duration(days: 7));
              _selectedDate = _weekStart;
            });
            _load();
          },
          onNext: () {
            setState(() {
              _weekStart    = _weekStart.add(const Duration(days: 7));
              _selectedDate = _weekStart;
            });
            _load();
          },
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5))
              : _bookings.isEmpty
                  ? _EmptyDay(isToday: _isToday(_selectedDate))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      itemCount: _bookings.length,
                      itemBuilder: (_, i) => _TimelineCard(
                        booking: _bookings[i],
                        isLast:  i == _bookings.length - 1,
                        isToday: _isToday(_selectedDate),
                        onTap:   () => _showBookingDetail(_bookings[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 13) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

// ── Greeting header ───────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String? specialty;
  final String initials;
  final String? avatarUrl;
  final Map<String, dynamic>? stats;

  const _GreetingHeader({
    required this.greeting,
    required this.name,
    required this.specialty,
    required this.initials,
    required this.avatarUrl,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    final total     = stats?['total'] as int? ?? 0;

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              _TherapistAvatar(avatarUrl: avatarUrl, initials: initials, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: GoogleFonts.inter(
                      fontSize: 11, color: SaharaColors.grayText,
                      letterSpacing: 0.5,
                    )),
                    Text(firstName, style: GoogleFonts.playfairDisplay(
                      fontSize: 26, color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w400,
                    )),
                    if (specialty != null)
                      Text(specialty!, style: GoogleFonts.inter(
                        fontSize: 11, color: SaharaColors.gold,
                        letterSpacing: 0.8, fontWeight: FontWeight.w500,
                      )),
                  ],
                ),
              ),
            ],
          ),

          // ── Stats del día (solo si es hoy y hay citas) ───────────────────
          if (stats != null && total > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _StatPill('$total',
                    total == 1 ? 'cita' : 'citas',
                    Icons.calendar_today_rounded,
                    SaharaColors.gold),
                const SizedBox(width: 10),
                _StatPill('${stats!['completed']}',
                    'hechas',
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF4CAF50)),
                const SizedBox(width: 10),
                _StatPill('${stats!['upcoming']}',
                    'pendientes',
                    Icons.schedule_rounded,
                    const Color(0xFFFFB74D)),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.12)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatPill(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text('$value $label', style: GoogleFonts.inter(
            fontSize: 11, color: color, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

// ── Week strip ────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  const _WeekStrip({
    required this.weekDays,
    required this.selectedDate,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day       = weekDays[i];
                final isSelected = day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;
                final isToday = day.year == now.year &&
                    day.month == now.month && day.day == now.day;

                return GestureDetector(
                  onTap: () => onDayTap(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? SaharaColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: SaharaColors.gold.withValues(alpha: 0.35))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(_letters[i], style: GoogleFonts.inter(
                          fontSize: 9,
                          color: isSelected ? Colors.black87 : SaharaColors.grayText,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5,
                        )),
                        const SizedBox(height: 4),
                        Text('${day.day}', style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isSelected ? Colors.black
                              : isToday ? SaharaColors.gold : SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 4),
          _NavBtn(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Icon(icon, color: SaharaColors.grayText, size: 16),
      ),
    );
  }
}

// ── Timeline card ─────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final Booking booking;
  final bool isLast;
  final bool isToday;
  final VoidCallback onTap;

  const _TimelineCard({
    required this.booking,
    required this.isLast,
    required this.isToday,
    required this.onTap,
  });

  Color get _accentColor => switch (booking.status) {
    BookingStatus.confirmed => const Color(0xFF4CAF50),
    BookingStatus.completed => const Color(0xFF64B5F6),
    BookingStatus.cancelled => const Color(0xFFEF5350),
    _                       => const Color(0xFFFFB74D),
  };

  bool get _canComplete =>
      isToday &&
      (booking.status == BookingStatus.confirmed ||
       booking.status == BookingStatus.scheduled);

  @override
  Widget build(BuildContext context) {
    final timeLabel = booking.time.substring(0, 5);
    final hasNotes  = booking.clientNotes?.isNotEmpty == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Columna de hora + punto ──────────────────────────────────────
        SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(timeLabel, style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.gold,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5,
                )),
              ),
              const SizedBox(height: 8),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor,
                  boxShadow: [BoxShadow(
                    color: _accentColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  )],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // ── Tarjeta de cita ──────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left:   BorderSide(color: _accentColor, width: 3),
                  top:    BorderSide(color: _accentColor.withValues(alpha: 0.12)),
                  right:  BorderSide(color: _accentColor.withValues(alpha: 0.12)),
                  bottom: BorderSide(color: _accentColor.withValues(alpha: 0.12)),
                ),
              ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Servicio + estado
                      Row(
                        children: [
                          Expanded(
                            child: Text(booking.serviceName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16, color: SaharaColors.whiteSoft,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusBadge(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Cliente + notas
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 12,
                              color: SaharaColors.grayText),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(booking.clientName,
                              style: GoogleFonts.inter(
                                fontSize: 13, color: SaharaColors.whiteSoft,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasNotes)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Tooltip(
                                message: 'Tiene notas',
                                child: Icon(Icons.sticky_note_2_outlined,
                                    size: 14,
                                    color: SaharaColors.gold.withValues(alpha: 0.7)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Duración + acción rápida
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 11,
                              color: SaharaColors.grayText.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text('${booking.durationMin} min',
                            style: GoogleFonts.inter(
                              fontSize: 11, color: SaharaColors.grayText,
                            )),
                          if (booking.price > 0) ...[
                            Text('  ·  ', style: GoogleFonts.inter(
                                fontSize: 11, color: SaharaColors.grayText)),
                            Text('\$${NumberFormat('#,###').format(booking.price)}',
                              style: GoogleFonts.inter(
                                fontSize: 11, color: SaharaColors.gold,
                              )),
                          ],
                          const Spacer(),
                          if (_canComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded,
                                      size: 11, color: Color(0xFF4CAF50)),
                                  const SizedBox(width: 4),
                                  Text('Completar', style: GoogleFonts.inter(
                                    fontSize: 10, color: const Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }
}

// ── Booking detail bottom sheet ───────────────────────────────────────────────

class _BookingDetailSheet extends StatefulWidget {
  final Booking booking;
  final TherapistRepository repo;
  final VoidCallback onCompleted;

  const _BookingDetailSheet({
    required this.booking,
    required this.repo,
    required this.onCompleted,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  bool _completing = false;

  bool get _canComplete =>
      widget.booking.status == BookingStatus.confirmed ||
      widget.booking.status == BookingStatus.scheduled;

  Future<void> _markCompleted() async {
    setState(() => _completing = true);
    try {
      await widget.repo.markCompleted(widget.booking.id);
      widget.onCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al marcar como completado: $e'),
        backgroundColor: const Color(0xFF2A1010),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b         = widget.booking;
    final dateLabel = DateFormat("EEEE d 'de' MMMM", 'es').format(b.date);
    final timeLabel = b.time.substring(0, 5);
    final hasNotes  = b.clientNotes?.isNotEmpty == true;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Servicio + estado ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(b.serviceName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24, color: SaharaColors.gold,
                          )),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: b.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Fecha y hora ───────────────────────────────────────────
                  _DetailRow(Icons.calendar_today_rounded,
                      '$dateLabel  ·  $timeLabel'),
                  const SizedBox(height: 8),
                  _DetailRow(Icons.timer_outlined, '${b.durationMin} min'),
                  if (b.price > 0) ...[
                    const SizedBox(height: 8),
                    _DetailRow(Icons.attach_money_rounded,
                        '\$${NumberFormat('#,###').format(b.price)}'),
                  ],
                  const SizedBox(height: 20),

                  // ── Cliente ────────────────────────────────────────────────
                  Text('CLIENTE', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.grayText,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5,
                  )),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SaharaColors.gold.withValues(alpha: 0.1),
                          border: Border.all(
                              color: SaharaColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            b.clientName.trim().split(' ')
                                .where((w) => w.isNotEmpty).take(2)
                                .map((w) => w[0].toUpperCase()).join(),
                            style: GoogleFonts.inter(
                              fontSize: 14, color: SaharaColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(b.clientName, style: GoogleFonts.inter(
                        fontSize: 16, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w500,
                      )),
                    ],
                  ),

                  // ── Notas del cliente (destacadas) ─────────────────────────
                  if (hasNotes) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SaharaColors.gold.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: SaharaColors.gold.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sticky_note_2_outlined,
                                  size: 14, color: SaharaColors.gold),
                              const SizedBox(width: 7),
                              Text('NOTAS DEL CLIENTE', style: GoogleFonts.inter(
                                fontSize: 10, color: SaharaColors.gold,
                                fontWeight: FontWeight.w700, letterSpacing: 1.5,
                              )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(b.clientNotes!, style: GoogleFonts.inter(
                            fontSize: 14, color: SaharaColors.whiteSoft,
                            height: 1.5,
                          )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Botón de completar ─────────────────────────────────────
                  if (_canComplete)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _completing ? null : _markCompleted,
                        icon: _completing
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline_rounded,
                                size: 20),
                        label: Text(
                          _completing ? 'Registrando...' : 'Marcar como Completado',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (b.status == BookingStatus.completed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50), size: 20),
                          const SizedBox(width: 8),
                          Text('Servicio Completado', style: GoogleFonts.inter(
                            fontSize: 15, color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cerrar', style: GoogleFonts.inter(
                        color: SaharaColors.grayText, fontSize: 14,
                      )),
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: SaharaColors.gold.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(
          fontSize: 13, color: SaharaColors.grayText,
        )),
      ],
    );
  }
}

// ── Avatar del terapeuta ──────────────────────────────────────────────────────

class _TherapistAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double size;
  const _TherapistAvatar({
    required this.avatarUrl, required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: SaharaColors.gold.withValues(alpha: 0.12),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SaharaColors.gold.withValues(alpha: 0.1),
        border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(initials, style: GoogleFonts.inter(
          fontSize: size * 0.34,
          color: SaharaColors.gold,
          fontWeight: FontWeight.w700,
        )),
      ),
    );
  }
}

// ── Día vacío ─────────────────────────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  final bool isToday;
  const _EmptyDay({required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_outlined,
              size: 48,
              color: SaharaColors.gold.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            isToday ? 'Sin citas para hoy' : 'Sin citas este día',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              color: SaharaColors.grayText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Disfruta el descanso',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SaharaColors.grayText.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
