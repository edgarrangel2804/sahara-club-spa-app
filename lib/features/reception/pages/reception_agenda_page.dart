import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/features/reception/widgets/assign_booking_dialog.dart';
import 'package:sahara_club_spa_app/features/reception/widgets/status_badge.dart';

class ReceptionAgendaPage extends StatefulWidget {
  final ReceptionRepository repo;
  const ReceptionAgendaPage({super.key, required this.repo});

  @override
  State<ReceptionAgendaPage> createState() => _ReceptionAgendaPageState();
}

class _ReceptionAgendaPageState extends State<ReceptionAgendaPage> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _weekStart;
  List<Booking> _bookings = [];
  List<Map<String, dynamic>> _therapists = [];
  String? _selectedTherapistId;
  bool _loading = true;

  static const _startHour = 8;
  static const _endHour   = 20;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _load();
  }

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  // ── _load con try-catch: el loading SIEMPRE se resetea ──────────────────
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final bookings = await widget.repo.getBookingsByDate(_selectedDate);
      if (_therapists.isEmpty) {
        final therapists = await widget.repo.getTherapists();
        if (!mounted) return;
        setState(() => _therapists = therapists);
      }
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading  = false;
      });
    } catch (e) {
      debugPrint('ReceptionAgendaPage._load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Booking> get _filtered {
    if (_selectedTherapistId == null) return _bookings;
    return _bookings.where((b) => b.therapistId == _selectedTherapistId).toList();
  }

  int get _freeHours {
    final occupied = <int>{};
    for (final b in _filtered) {
      final h = int.tryParse(b.time.split(':')[0]) ?? -1;
      if (h >= _startHour && h < _endHour) occupied.add(h);
    }
    return (_endHour - _startHour) - occupied.length;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeekStrip(
          weekDays:     _weekDays,
          selectedDate: _selectedDate,
          onDayTap: (d) { setState(() => _selectedDate = d); _load(); },
          onPrevWeek: () {
            setState(() {
              _weekStart    = _weekStart.subtract(const Duration(days: 7));
              _selectedDate = _weekStart;
            });
            _load();
          },
          onNextWeek: () {
            setState(() {
              _weekStart    = _weekStart.add(const Duration(days: 7));
              _selectedDate = _weekStart;
            });
            _load();
          },
        ),
        _SummaryBar(
          date:         _selectedDate,
          bookingCount: _filtered.length,
          freeHours:    _freeHours,
        ),
        if (_therapists.isNotEmpty)
          _TherapistRow(
            therapists: _therapists,
            bookings:   _bookings,
            selectedId: _selectedTherapistId,
            onSelect:   (id) => setState(() => _selectedTherapistId = id),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  children: _buildTimeline(),
                ),
        ),
      ],
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  List<Widget> _buildTimeline() {
    final items    = <Widget>[];
    final filtered = _filtered;

    for (int h = _startHour; h < _endHour; h++) {
      final hourStr      = '${h.toString().padLeft(2, '0')}:00';
      final hourBookings = filtered
          .where((b) => int.tryParse(b.time.split(':')[0]) == h)
          .toList();
      final hasBookings  = hourBookings.isNotEmpty;

      items.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(hourStr, style: GoogleFonts.inter(
                  fontSize: 12,
                  color: SaharaColors.grayText.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ), textAlign: TextAlign.right),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                const SizedBox(height: 19),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasBookings ? SaharaColors.gold : const Color(0xFF242424),
                    border: Border.all(
                      color: hasBookings
                          ? SaharaColors.gold.withValues(alpha: 0.5)
                          : const Color(0xFF303030),
                      width: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(width: 1, color: const Color(0xFF1C1C1C)),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: hasBookings
                    ? Column(children: hourBookings.map(_appointmentCard).toList())
                    : _availableSlot(hourStr),
              ),
            ),
          ],
        ),
      ));
    }
    return items;
  }

  Widget _availableSlot(String timeStr) {
    return GestureDetector(
      onTap: () => _showQuickBookingModal(timeStr),
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('Disponible', style: GoogleFonts.inter(
            fontSize: 13,
            color: SaharaColors.grayText.withValues(alpha: 0.3),
          )),
        ),
      ),
    );
  }

  Widget _appointmentCard(Booking booking) {
    final isInactive   = booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.completed;
    final isPending    = booking.status == BookingStatus.scheduled ||
        booking.status == BookingStatus.pending;
    final isConfirmed  = booking.status == BookingStatus.confirmed;
    final accentColor  = isPending
        ? const Color(0xFFFFB74D)
        : isConfirmed
            ? const Color(0xFF4CAF50)
            : const Color(0xFF1E1E1E);

    return GestureDetector(
      onTap: () => _showAppointmentOptions(booking),
      child: Opacity(
        opacity: isInactive ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              // Franja lateral de color
              Container(
                width: 3,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isInactive ? 0.2 : 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft:    Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Servicio + badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(booking.serviceName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15, color: SaharaColors.gold,
                                decoration: booking.status == BookingStatus.cancelled
                                    ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Cliente
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 12,
                              color: SaharaColors.whiteSoft),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(booking.clientName,
                              style: GoogleFonts.inter(
                                fontSize: 13, color: SaharaColors.whiteSoft,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (booking.clientNotes?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.sticky_note_2_outlined,
                                  size: 13,
                                  color: SaharaColors.gold.withValues(alpha: 0.7)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Terapeuta + tiempo
                      Row(
                        children: [
                          Icon(
                            booking.therapistName != null
                                ? Icons.spa_rounded
                                : Icons.person_add_outlined,
                            size: 12,
                            color: booking.therapistName != null
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFFB74D),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              booking.therapistName ?? 'Sin asignar',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: booking.therapistName != null
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFB74D),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.schedule_rounded, size: 11,
                              color: SaharaColors.grayText.withValues(alpha: 0.6)),
                          const SizedBox(width: 3),
                          Text(booking.time.substring(0, 5),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: SaharaColors.grayText)),
                          if (booking.durationMin > 0) ...[
                            Text('  ·  ${booking.durationMin} min',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: SaharaColors.grayText.withValues(alpha: 0.5),
                              )),
                          ],
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

  // ── Appointment options bottom sheet ──────────────────────────────────────

  void _showAppointmentOptions(Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.serviceName, style: GoogleFonts.playfairDisplay(
                          fontSize: 22, color: SaharaColors.gold)),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.clientName} · \$${NumberFormat('#,###').format(booking.price)}',
                        style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 24),

            if (booking.clientNotes?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SaharaColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: SaharaColors.gold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notas del cliente', style: GoogleFonts.inter(
                            fontSize: 11, color: SaharaColors.gold,
                            fontWeight: FontWeight.w700,
                          )),
                          const SizedBox(height: 4),
                          Text(booking.clientNotes!, style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white70,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text('ACCIONES', style: GoogleFonts.inter(
              fontSize: 10, color: SaharaColors.grayText,
              fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
            const SizedBox(height: 12),

            if (booking.status == BookingStatus.scheduled ||
                booking.status == BookingStatus.pending)
              _bsAction(Icons.person_add_rounded, 'Asignar Terapeuta',
                  SaharaColors.gold, () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AssignBookingDialog(
                    booking: booking,
                    repo:    widget.repo,
                    onAssigned: () {
                      Navigator.pop(dCtx);
                      _load();
                    },
                  ),
                );
              }),

            if (booking.status == BookingStatus.scheduled ||
                booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed) ...[
              _bsAction(Icons.payment_rounded, 'Cobrar Servicio',
                  const Color(0xFF4CAF50), () {
                Navigator.pop(ctx);
                _showChargeModal(booking);
              }),
              _bsAction(Icons.edit_calendar_rounded, 'Reagendar',
                  Colors.white, () {
                Navigator.pop(ctx);
                _showRescheduleModal(booking);
              }),
              const Divider(color: Colors.white12, height: 24),
              _bsAction(Icons.cancel_outlined, 'Cancelar Cita',
                  const Color(0xFFEF5350), () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                await widget.repo.updateBookingStatus(
                    booking.id, BookingStatus.cancelled);
                _load();
              }),
            ],

            if (booking.status == BookingStatus.completed ||
                booking.status == BookingStatus.cancelled)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Sin acciones disponibles para este estado.',
                    style: GoogleFonts.inter(fontSize: 13,
                        color: SaharaColors.grayText, fontStyle: FontStyle.italic)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bsAction(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(title, style: GoogleFonts.inter(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  // ── Charge modal ──────────────────────────────────────────────────────────

  void _showChargeModal(Booking booking) {
    showDialog(context: context, builder: (ctx) {
      String selectedMethod = 'debit';
      return StatefulBuilder(builder: (_, setM) {
        return Dialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(booking.serviceName, style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.gold)),
                const SizedBox(height: 6),
                Text(booking.clientName, style: GoogleFonts.inter(
                    fontSize: 15, color: Colors.white70)),
                const SizedBox(height: 24),
                Text('\$${NumberFormat('#,###').format(booking.price)}',
                  style: GoogleFonts.inter(fontSize: 36, color: Colors.white,
                      fontWeight: FontWeight.bold)),
                const SizedBox(height: 28),
                Text('MÉTODO DE PAGO', style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.white54, letterSpacing: 2)),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10, runSpacing: 10,
                  children: [
                    _payBtn('Efectivo', 'cash',   selectedMethod, () => setM(() => selectedMethod = 'cash')),
                    _payBtn('Débito',   'debit',  selectedMethod, () => setM(() => selectedMethod = 'debit')),
                    _payBtn('Crédito',  'credit', selectedMethod, () => setM(() => selectedMethod = 'credit')),
                  ],
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await widget.repo.chargeBooking(booking, selectedMethod);
                      await _load();
                      if (!mounted) return;
                      _showReceiptModal(booking, selectedMethod);
                    } catch (e) {
                      await _load();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error al cobrar: $e'),
                        backgroundColor: const Color(0xFF2A1010),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: SaharaColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text('Confirmar Cobro', style: GoogleFonts.inter(
                      color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15,
                    ))),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _payBtn(String label, String value, String selected, VoidCallback onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: isSelected ? SaharaColors.gold : Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.inter(
          color: isSelected ? SaharaColors.gold : Colors.white54,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }

  // ── Receipt modal ─────────────────────────────────────────────────────────

  void _showReceiptModal(Booking booking, String method) {
    final methodLabel = _payLabel(method);
    showDialog(context: context, builder: (ctx) {
      return Dialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark circle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SaharaColors.gold.withValues(alpha: 0.1),
                  border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.check_rounded, color: SaharaColors.gold, size: 30),
              ),
              const SizedBox(height: 18),
              Text('Pago Exitoso', style: GoogleFonts.playfairDisplay(
                  fontSize: 26, color: Colors.white)),
              const SizedBox(height: 22),

              // Ticket body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _receiptRow(Icons.spa_rounded, booking.serviceName, SaharaColors.gold),
                    const SizedBox(height: 10),
                    _receiptRow(Icons.person_rounded, booking.clientName, Colors.white60),
                    if (booking.therapistName != null) ...[
                      const SizedBox(height: 10),
                      _receiptRow(Icons.self_improvement_rounded,
                          booking.therapistName!, Colors.white38),
                    ],
                    const SizedBox(height: 10),
                    _receiptRow(
                      Icons.access_time_rounded,
                      '${booking.time.substring(0, 5)}  ·  '
                          '${DateFormat("d 'de' MMM", 'es').format(booking.date)}',
                      Colors.white38,
                    ),
                    const SizedBox(height: 16),
                    Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL', style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.white38, letterSpacing: 2,
                        )),
                        Row(
                          children: [
                            Text(
                              '\$${NumberFormat('#,###').format(booking.price)}',
                              style: GoogleFonts.inter(
                                fontSize: 22, color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: SaharaColors.gold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: SaharaColors.gold.withValues(alpha: 0.3)),
                              ),
                              child: Text(methodLabel, style: GoogleFonts.inter(
                                fontSize: 10, color: SaharaColors.gold,
                                fontWeight: FontWeight.w600,
                              )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('"Tu cuerpo recuerda cómo descansar."',
                style: GoogleFonts.playfairDisplay(
                  fontStyle: FontStyle.italic,
                  color: SaharaColors.grayText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Center(child: Text('Cerrar', style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 14,
                  ))),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _receiptRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.inter(
          fontSize: 13, color: color, fontWeight: FontWeight.w400,
        ))),
      ],
    );
  }

  String _payLabel(String method) => switch (method) {
    'cash'   => 'Efectivo',
    'debit'  => 'Débito',
    'credit' => 'Crédito',
    _        => method,
  };

  // ── Reschedule modal ──────────────────────────────────────────────────────

  void _showRescheduleModal(Booking booking) {
    DateTime tempDate = booking.date;
    String   tempTime = booking.time.substring(0, 5);

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (_, setM) {
        return Dialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reagendar Cita', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.gold)),
                const SizedBox(height: 6),
                Text('${booking.clientName} — ${booking.serviceName}',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 24),

                Text('Nueva fecha', style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context, initialDate: tempDate,
                      firstDate: DateTime.now(), lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme:
                          const ColorScheme.dark(primary: SaharaColors.gold,
                              surface: Color(0xFF1A1A1A))),
                        child: child!,
                      ),
                    );
                    if (picked != null) setM(() => tempDate = picked);
                  },
                  child: _pickerField(Icons.calendar_today_rounded,
                      DateFormat('dd/MM/yyyy').format(tempDate)),
                ),
                const SizedBox(height: 14),

                Text('Nueva hora', style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final parts  = tempTime.split(':');
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour:   int.parse(parts[0]),
                        minute: int.parse(parts[1]),
                      ),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme:
                          const ColorScheme.dark(primary: SaharaColors.gold,
                              surface: Color(0xFF1A1A1A))),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setM(() => tempTime =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                    }
                  },
                  child: _pickerField(Icons.schedule_rounded, tempTime),
                ),

                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      const SizedBox(width: 12),
                      // ── BOTÓN REAGENDAR con loader ────────────────────────
                      _RescheduleConfirmButton(
                        onConfirm: () async {
                          Navigator.pop(ctx);
                          try {
                            await widget.repo.rescheduleBooking(
                                booking.id, tempDate, tempTime);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error al reagendar: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF2A1010),
                              ));
                            }
                          }
                          await _load();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _pickerField(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Row(children: [
        Icon(icon, color: SaharaColors.gold, size: 16),
        const SizedBox(width: 10),
        Text(text, style: GoogleFonts.inter(color: Colors.white)),
      ]),
    );
  }

  // ── Quick booking modal ───────────────────────────────────────────────────

  void _showQuickBookingModal(String timeStr) {
    showDialog(
      context: context,
      builder: (ctx) => _QuickBookingDialog(
        timeStr:              timeStr,
        date:                 _selectedDate,
        therapists:           _therapists,
        initialTherapistId:   _selectedTherapistId,
        repo:                 widget.repo,
        onCreated: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }
}

// ── Botón de confirmar reagendar con estado de carga interno ──────────────────

class _RescheduleConfirmButton extends StatefulWidget {
  final Future<void> Function() onConfirm;
  const _RescheduleConfirmButton({required this.onConfirm});

  @override
  State<_RescheduleConfirmButton> createState() => _RescheduleConfirmButtonState();
}

class _RescheduleConfirmButtonState extends State<_RescheduleConfirmButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: SaharaColors.gold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: SaharaColors.gold.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: _loading ? null : () async {
        setState(() => _loading = true);
        await widget.onConfirm();
        if (mounted) setState(() => _loading = false);
      },
      child: _loading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
          : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// ── Week Strip ────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const _WeekStrip({
    required this.weekDays,
    required this.selectedDate,
    required this.onDayTap,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  static const _letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat("MMMM yyyy", 'es').format(selectedDate),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20, color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Row(
                children: [
                  _NavBtn(icon: Icons.chevron_left,  onTap: onPrevWeek),
                  const SizedBox(width: 6),
                  _NavBtn(icon: Icons.chevron_right, onTap: onNextWeek),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day        = weekDays[i];
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month && day.day == selectedDate.day;
              final isToday    = day.year == now.year &&
                  day.month == now.month && day.day == now.day;

              return GestureDetector(
                onTap: () => onDayTap(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? SaharaColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: SaharaColors.gold.withValues(alpha: 0.35))
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(_letters[i], style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isSelected ? Colors.black87 : SaharaColors.grayText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      )),
                      const SizedBox(height: 6),
                      Text('${day.day}', style: GoogleFonts.inter(
                        fontSize: 17,
                        color: isSelected
                            ? Colors.black
                            : isToday ? SaharaColors.gold : SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Icon(icon, color: SaharaColors.grayText, size: 18),
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final DateTime date;
  final int bookingCount;
  final int freeHours;

  const _SummaryBar({
    required this.date,
    required this.bookingCount,
    required this.freeHours,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel  = DateFormat("EEEE d 'de' MMMM", 'es').format(date);
    final citasStr  = bookingCount == 1 ? '1 cita' : '$bookingCount citas';
    final libresStr = '$freeHours ${freeHours == 1 ? "hora libre" : "horas libres"}';

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(dayLabel, style: GoogleFonts.inter(
            fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 2),
          Text('$citasStr · $libresStr', style: GoogleFonts.inter(
            fontSize: 12, color: SaharaColors.grayText,
          )),
        ],
      ),
    );
  }
}

// ── Therapist chips ───────────────────────────────────────────────────────────

class _TherapistRow extends StatelessWidget {
  final List<Map<String, dynamic>> therapists;
  final List<Booking> bookings;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _TherapistRow({
    required this.therapists,
    required this.bookings,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(label: 'Todos', isSelected: selectedId == null,
                dotColor: null, onTap: () => onSelect(null)),
            ...therapists.map((t) {
              final busy = bookings.any((b) =>
                  b.therapistId == t['id'] &&
                  (b.status == BookingStatus.confirmed ||
                   b.status == BookingStatus.pending ||
                   b.status == BookingStatus.scheduled));
              return _Chip(
                label:      (t['full_name'] as String? ?? '').split(' ')[0],
                isSelected: selectedId == t['id'],
                dotColor:   busy ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
                onTap:      () => onSelect(t['id'] as String?),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? dotColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? SaharaColors.gold.withValues(alpha: 0.12)
              : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? SaharaColors.gold.withValues(alpha: 0.5)
                : SaharaColors.grayDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 6),
            ],
            Text(label, style: GoogleFonts.inter(
              fontSize: 12,
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Quick Booking Dialog ──────────────────────────────────────────────────────

class _QuickBookingDialog extends StatefulWidget {
  final String timeStr;
  final DateTime date;
  final List<Map<String, dynamic>> therapists;
  final String? initialTherapistId;
  final ReceptionRepository repo;
  final VoidCallback onCreated;

  const _QuickBookingDialog({
    required this.timeStr,
    required this.date,
    required this.therapists,
    this.initialTherapistId,
    required this.repo,
    required this.onCreated,
  });

  @override
  State<_QuickBookingDialog> createState() => _QuickBookingDialogState();
}

class _QuickBookingDialogState extends State<_QuickBookingDialog> {
  bool _loading    = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _clients  = [];
  List<Map<String, dynamic>> _services = [];
  String? _selectedClient;
  String? _selectedService;
  String? _selectedTherapist;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedTherapist = widget.initialTherapistId;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.repo.getClients(),
        widget.repo.getServices(),
      ]);
      if (!mounted) return;
      setState(() {
        _clients  = List<Map<String, dynamic>>.from(results[0] as List);
        _services = List<Map<String, dynamic>>.from(results[1] as List);
        _loading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = 'Error al cargar datos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedClient == null || _selectedService == null) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final srv    = _services.firstWhere((s) => s['id'] == _selectedService);
      final userId = AuthService().currentUser?.id ?? 'reception';

      if (_selectedTherapist != null) {
        final available = await widget.repo.isTherapistAvailable(
          _selectedTherapist!, widget.date, widget.timeStr);
        if (!available) {
          final therapistName = widget.therapists
              .firstWhere((t) => t['id'] == _selectedTherapist, orElse: () => {})
              ['full_name'] as String? ?? 'La terapeuta';
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _error = '$therapistName ya tiene una cita a las ${widget.timeStr}. '
                'Selecciona otra terapeuta.';
          });
          return;
        }
      }

      // Si ya existe cualquier cita del cliente a esa hora (scheduled o
      // confirmed sin terapeuta), se actualiza en lugar de crear un duplicado.
      final existingId = await widget.repo.findExistingBookingId(
        _selectedClient!, widget.date, widget.timeStr);

      if (existingId != null && _selectedTherapist != null) {
        await widget.repo.assignBooking(
          bookingId:   existingId,
          therapistId: _selectedTherapist!,
          date:        widget.date,
          time:        widget.timeStr,
        );
      } else {
        await widget.repo.createBooking(
          clientId:    _selectedClient!,
          therapistId: _selectedTherapist,
          serviceId:   _selectedService!,
          date:        widget.date,
          time:        widget.timeStr,
          durationMin: (srv['duration'] as int?) ?? (srv['duration_min'] as int?) ?? 60,
          price:       (srv['price'] as num?)?.toDouble() ?? 0,
          createdBy:   userId,
        );
      }
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Error al asignar la cita:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_submitting && _selectedClient != null && _selectedService != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignar Cita', style: GoogleFonts.playfairDisplay(
              fontSize: 22, color: SaharaColors.gold)),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd/MM/yyyy').format(widget.date)} · ${widget.timeStr}',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
      content: _loading
          ? const SizedBox(
              width: double.maxFinite,
              height: 120,
              child: Center(child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5)))
          : SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Text(_error!, style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _label('Cliente'),
                    _dropdown(
                      key: ValueKey('client_$_selectedClient'),
                      items: _clients.map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['full_name'] as String? ?? ''),
                      )).toList(),
                      value: _selectedClient,
                      hint: 'Seleccionar cliente',
                      onChanged: (v) => setState(() => _selectedClient = v),
                    ),
                    const SizedBox(height: 14),

                    _label('Terapeuta (opcional)'),
                    _dropdown(
                      key: ValueKey('therapist_$_selectedTherapist'),
                      items: widget.therapists.map((t) => DropdownMenuItem<String>(
                        value: t['id'] as String,
                        child: Text(t['full_name'] as String? ?? ''),
                      )).toList(),
                      value: _selectedTherapist,
                      hint: 'Sin asignar',
                      onChanged: (v) => setState(() => _selectedTherapist = v),
                    ),
                    const SizedBox(height: 14),

                    _label('Servicio'),
                    _ServiceCategoryPicker(
                      services:   _services,
                      selectedId: _selectedService,
                      onSelect:   (id) => setState(() => _selectedService = id),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SaharaColors.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: SaharaColors.gold.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: canSubmit ? _submit : null,
          child: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Asignar Cita',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
  );

  Widget _dropdown({
    Key? key,
    required List<DropdownMenuItem<String>> items,
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      isExpanded: true,
      dropdownColor: const Color(0xFF1A1A1A),
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true, fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SaharaColors.grayDark)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SaharaColors.grayDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SaharaColors.gold, width: 1.2)),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
      ),
      initialValue: value,
      items: items,
      onChanged: onChanged,
    );
  }
}

// ── Service Category Picker ───────────────────────────────────────────────────

class _ServiceCategoryPicker extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _ServiceCategoryPicker({
    required this.services,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_ServiceCategoryPicker> createState() => _ServiceCategoryPickerState();
}

class _ServiceCategoryPickerState extends State<_ServiceCategoryPicker> {
  String? _expandedCategory;

  Map<String, List<Map<String, dynamic>>> get _byCategory {
    final Map<String, List<Map<String, dynamic>>> result = {};
    for (final s in widget.services) {
      final cat = _normalizeCategory(s['category'] as String?);
      result.putIfAbsent(cat, () => []).add(s);
    }
    return result;
  }

  String _normalizeCategory(String? raw) {
    if (raw == null || raw.isEmpty) return 'General';
    return raw.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Text('Sin servicios disponibles', style: GoogleFonts.inter(
          fontSize: 13, color: Colors.white38,
        )),
      );
    }

    // Si hay un servicio seleccionado, mostrar chip de selección
    if (widget.selectedId != null) {
      final selected = widget.services.where((s) => s['id'] == widget.selectedId).toList();
      if (selected.isNotEmpty) {
        final s = selected.first;
        return GestureDetector(
          onTap: () {
            setState(() => _expandedCategory = null);
            widget.onSelect(null);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: SaharaColors.gold, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String? ?? '', style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w500,
                      )),
                      const SizedBox(height: 2),
                      Text(
                        '${_normalizeCategory(s['category'] as String?)} · \$${NumberFormat('#,###').format((s['price'] as num?) ?? 0)}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: SaharaColors.grayText),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.close_rounded,
                    color: SaharaColors.grayText.withValues(alpha: 0.6), size: 16),
              ],
            ),
          ),
        );
      }
    }

    // Mostrar acordeón de categorías
    final categories = _byCategory;
    final catKeys    = categories.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: List.generate(catKeys.length, (idx) {
            final cat        = catKeys[idx];
            final srvs       = categories[cat]!;
            final isExpanded = _expandedCategory == cat;
            final isLast     = idx == catKeys.length - 1;

            return Column(
              children: [
                // Cabecera de categoría
                GestureDetector(
                  onTap: () => setState(() {
                    _expandedCategory = isExpanded ? null : cat;
                  }),
                  child: Container(
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Text(cat, style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isExpanded
                              ? SaharaColors.gold
                              : SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w600,
                        )),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? SaharaColors.gold.withValues(alpha: 0.15)
                                : const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${srvs.length}', style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isExpanded
                                ? SaharaColors.gold
                                : SaharaColors.grayText,
                            fontWeight: FontWeight.w600,
                          )),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: isExpanded
                              ? SaharaColors.gold
                              : SaharaColors.grayText,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de servicios expandida
                if (isExpanded) ...[
                  Container(height: 1, color: const Color(0xFF222222)),
                  ...srvs.map((s) => GestureDetector(
                    onTap: () {
                      setState(() => _expandedCategory = null);
                      widget.onSelect(s['id'] as String);
                    },
                    child: Container(
                      color: const Color(0xFF111111),
                      padding: const EdgeInsets.fromLTRB(24, 11, 14, 11),
                      child: Row(
                        children: [
                          const Icon(Icons.spa_outlined,
                              size: 13,
                              color: Color(0xFF555555)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name'] as String? ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: Colors.white70)),
                                if ((s['duration'] ?? s['duration_min']) != null)
                                  Text(
                                    '${s['duration'] ?? s['duration_min']} min',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF555555)),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            (s['price'] as num? ?? 0) > 0
                                ? '\$${NumberFormat('#,###').format(s['price'] as num)}'
                                : 'Cotizar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: (s['price'] as num? ?? 0) > 0
                                  ? SaharaColors.gold
                                  : SaharaColors.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],

                if (!isLast)
                  Container(height: 1, color: const Color(0xFF1E1E1E)),
              ],
            );
          }),
        ),
      ),
    );
  }
}
