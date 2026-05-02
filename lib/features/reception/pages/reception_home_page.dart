import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

class ReceptionHomePage extends StatefulWidget {
  final ReceptionRepository repo;
  final VoidCallback? onPendingChanged;

  const ReceptionHomePage({super.key, required this.repo, this.onPendingChanged});

  @override
  State<ReceptionHomePage> createState() => _ReceptionHomePageState();
}

class _ReceptionHomePageState extends State<ReceptionHomePage> {
  Map<String, dynamic> _stats = {};
  List<Booking> _todayBookings = [];
  List<Booking> _pendingRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.repo.getTodayStats(),
      widget.repo.getBookingsByDate(DateTime.now()),
      widget.repo.getPendingRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats           = results[0] as Map<String, dynamic>;
      _todayBookings   = results[1] as List<Booking>;
      _pendingRequests = results[2] as List<Booking>;
      _loading = false;
    });
  }

  Future<void> _changeStatus(Booking b, BookingStatus s) async {
    await widget.repo.updateBookingStatus(b.id, s);
    widget.onPendingChanged?.call();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());
    final greeting  = _greeting();

    return _loading
        ? const Center(child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Encabezado ───────────────────────────────────────────────
                Text(greeting, style: GoogleFonts.playfairDisplay(
                  fontSize: 28, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
                )),
                const SizedBox(height: 4),
                Text(dateLabel, style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.grayText, letterSpacing: 0.5,
                )),
                const SizedBox(height: 32),

                // ── Solicitudes pendientes ────────────────────────────────────
                if (_pendingRequests.isNotEmpty) ...[
                  _PendingRequestsSection(
                    bookings: _pendingRequests,
                    onConfirm: (b) => _changeStatus(b, BookingStatus.confirmed),
                    onCancel:  (b) => _changeStatus(b, BookingStatus.cancelled),
                  ),
                  const SizedBox(height: 36),
                ],

                // ── KPIs ─────────────────────────────────────────────────────
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 5 : c.maxWidth > 600 ? 3 : 2;
                  return _KpiGrid(stats: _stats, cols: cols);
                }),
                const SizedBox(height: 36),

                // ── Agenda de hoy ─────────────────────────────────────────────
                Row(
                  children: [
                    Text('AGENDA DE HOY', style: GoogleFonts.inter(
                      fontSize: 11, color: SaharaColors.gold,
                      fontWeight: FontWeight.w700, letterSpacing: 2,
                    )),
                    const SizedBox(width: 12),
                    Container(height: 1, width: 40,
                        color: SaharaColors.gold.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(height: 16),

                if (_todayBookings.isEmpty)
                  _EmptyState(label: 'Sin citas para hoy')
                else
                  _TodayAgendaTable(bookings: _todayBookings, onStatusChange: _changeStatus),
              ],
            ),
          );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 13) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

// ── Sección solicitudes pendientes ────────────────────────────────────────────

class _PendingRequestsSection extends StatelessWidget {
  final List<Booking> bookings;
  final void Function(Booking) onConfirm;
  final void Function(Booking) onCancel;

  const _PendingRequestsSection({
    required this.bookings,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFFFFB74D)),
                  const SizedBox(width: 5),
                  Text('${bookings.length}', style: GoogleFonts.inter(
                    fontSize: 11, color: Color(0xFFFFB74D), fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('SOLICITUDES PENDIENTES', style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFFFFB74D),
              fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
            const SizedBox(width: 12),
            Container(height: 1, width: 40,
                color: const Color(0xFFFFB74D).withValues(alpha: 0.3)),
          ],
        ),
        const SizedBox(height: 14),
        ...bookings.map((b) => _PendingCard(
          booking: b,
          onConfirm: () => onConfirm(b),
          onCancel:  () => onCancel(b),
        )),
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PendingCard({
    required this.booking,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat("EEE d 'de' MMM", 'es').format(booking.date);
    final timeLabel = booking.time.substring(0, 5);
    final createdLabel = DateFormat("dd/MM · HH:mm").format(booking.createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.04),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(
        children: [
          // ── Franja lateral de color ───────────────────────────────────
          Container(
            width: 3, height: 48,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Info de la solicitud ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(booking.clientName, style: GoogleFonts.inter(
                      fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(width: 8),
                    Text('· solicitado $createdLabel', style: GoogleFonts.inter(
                      fontSize: 11, color: SaharaColors.grayText.withValues(alpha: 0.6),
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(booking.serviceName, style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.grayText,
                )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: SaharaColors.gold),
                    const SizedBox(width: 4),
                    Text(dateLabel, style: GoogleFonts.inter(fontSize: 12, color: SaharaColors.gold)),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule_rounded, size: 11, color: SaharaColors.gold),
                    const SizedBox(width: 4),
                    Text(timeLabel, style: GoogleFonts.inter(fontSize: 12, color: SaharaColors.gold)),
                    if (booking.therapistName != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.person_outline, size: 11, color: SaharaColors.grayText),
                      const SizedBox(width: 4),
                      Text(booking.therapistName!, style: GoogleFonts.inter(
                        fontSize: 12, color: SaharaColors.grayText,
                      )),
                    ],
                  ],
                ),
                if (booking.clientNotes != null && booking.clientNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 11, color: SaharaColors.grayText),
                      const SizedBox(width: 4),
                      Expanded(child: Text(booking.clientNotes!, style: GoogleFonts.inter(
                        fontSize: 11, color: SaharaColors.grayText.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Acciones ──────────────────────────────────────────────────
          const SizedBox(width: 16),
          Column(
            children: [
              _ActionBtn(
                label: 'Confirmar',
                icon: Icons.check_rounded,
                color: const Color(0xFF4CAF50),
                onTap: onConfirm,
              ),
              const SizedBox(height: 8),
              _ActionBtn(
                label: 'Cancelar',
                icon: Icons.close_rounded,
                color: const Color(0xFFEF5350),
                onTap: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.inter(
              fontSize: 12, color: color, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ── KPIs ──────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final int cols;
  const _KpiGrid({required this.stats, required this.cols});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData('Citas hoy',     '${stats['total'] ?? 0}',    Icons.calendar_today_rounded,    SaharaColors.gold),
      _KpiData('Confirmadas',   '${stats['confirmed'] ?? 0}', Icons.check_circle_outline,      const Color(0xFF4CAF50)),
      _KpiData('Pendientes',    '${stats['pending'] ?? 0}',   Icons.schedule_rounded,          const Color(0xFFFFB74D)),
      _KpiData('Completadas',   '${stats['completed'] ?? 0}', Icons.done_all_rounded,          const Color(0xFF64B5F6)),
      _KpiData('Ingresos',
        '\$${NumberFormat('#,###').format((stats['revenue'] as double?) ?? 0)}',
        Icons.attach_money_rounded, SaharaColors.goldLight),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((d) => SizedBox(
        width: (MediaQuery.of(context).size.width - 280 - 64 - (cols - 1) * 16) / cols,
        child: _KpiCard(data: d),
      )).toList(),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: data.color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(height: 14),
          Text(data.value, style: GoogleFonts.inter(
            fontSize: 26, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(data.label, style: GoogleFonts.inter(
            fontSize: 12, color: SaharaColors.grayText,
          )),
        ],
      ),
    );
  }
}

// ── Tabla de agenda ───────────────────────────────────────────────────────────

class _TodayAgendaTable extends StatelessWidget {
  final List<Booking> bookings;
  final void Function(Booking, BookingStatus) onStatusChange;
  const _TodayAgendaTable({required this.bookings, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
            ),
            child: Row(
              children: const [
                _TH('HORA',      flex: 1),
                _TH('CLIENTE',   flex: 2),
                _TH('SERVICIO',  flex: 3),
                _TH('TERAPEUTA', flex: 2),
                _TH('CABINA',    flex: 1),
                _TH('ESTADO',    flex: 2),
                _TH('',          flex: 1),
              ],
            ),
          ),
          ...bookings.map((b) => _BookingRow(booking: b, onStatusChange: onStatusChange)),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.inter(
        fontSize: 10, color: SaharaColors.grayText,
        fontWeight: FontWeight.w700, letterSpacing: 1.5,
      )),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Booking booking;
  final void Function(Booking, BookingStatus) onStatusChange;
  const _BookingRow({required this.booking, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF161616))),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(booking.time.substring(0, 5),
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(booking.clientName,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft))),
          Expanded(flex: 3, child: Text(booking.serviceName,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
            overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(booking.therapistName ?? '—',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText))),
          Expanded(flex: 1, child: Text(booking.cabin ?? '—',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText))),
          Expanded(flex: 2, child: _StatusBadge(status: booking.status)),
          Expanded(flex: 1, child: _QuickActions(booking: booking, onStatusChange: onStatusChange)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.confirmed  => const Color(0xFF4CAF50),
      BookingStatus.completed  => const Color(0xFF64B5F6),
      BookingStatus.cancelled  => const Color(0xFFEF5350),
      BookingStatus.noShow     => const Color(0xFFFF7043),
      BookingStatus.scheduled  => const Color(0xFFFFB74D),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status.label, style: GoogleFonts.inter(
        fontSize: 11, color: color, fontWeight: FontWeight.w600,
      )),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Booking booking;
  final void Function(Booking, BookingStatus) onStatusChange;
  const _QuickActions({required this.booking, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BookingStatus>(
      icon: const Icon(Icons.more_horiz, color: SaharaColors.grayText, size: 18),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => BookingStatus.values
          .where((s) => s != booking.status)
          .map((s) => PopupMenuItem(
                value: s,
                child: Text(s.label, style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.whiteSoft,
                )),
              ))
          .toList(),
      onSelected: (s) => onStatusChange(booking, s),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: SaharaColors.grayText.withValues(alpha: 0.3), size: 36),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.inter(
              fontSize: 14, color: SaharaColors.grayText.withValues(alpha: 0.5),
            )),
          ],
        ),
      ),
    );
  }
}
