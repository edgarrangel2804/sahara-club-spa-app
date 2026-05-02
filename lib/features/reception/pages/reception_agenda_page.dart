import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

class ReceptionAgendaPage extends StatefulWidget {
  final ReceptionRepository repo;
  const ReceptionAgendaPage({super.key, required this.repo});

  @override
  State<ReceptionAgendaPage> createState() => _ReceptionAgendaPageState();
}

class _ReceptionAgendaPageState extends State<ReceptionAgendaPage> {
  DateTime _selectedDate = DateTime.now();
  List<Booking> _bookings = [];
  BookingStatus? _filterStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await widget.repo.getBookingsByDate(_selectedDate);
    if (!mounted) return;
    setState(() {
      _bookings = data;
      _loading = false;
    });
  }

  List<Booking> get _filtered => _filterStatus == null
      ? _bookings
      : _bookings.where((b) => b.status == _filterStatus).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título + selector de fecha ──────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Agenda', style: GoogleFonts.playfairDisplay(
                    fontSize: 26, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
                  )),
                  Text(
                    DateFormat("EEEE d 'de' MMMM", 'es').format(_selectedDate),
                    style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
                  ),
                ],
              ),
              const Spacer(),
              // Navegación de fecha
              _DateNav(
                date: _selectedDate,
                onChanged: (d) {
                  setState(() => _selectedDate = d);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Filtros de estado ────────────────────────────────────────────
          _StatusFilterRow(
            selected: _filterStatus,
            onChanged: (s) => setState(() => _filterStatus = s),
          ),
          const SizedBox(height: 20),

          // ── Tabla ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5))
                : _filtered.isEmpty
                    ? _empty()
                    : _AgendaTable(
                        bookings: _filtered,
                        onStatusChange: (b, s) async {
                          await widget.repo.updateBookingStatus(b.id, s);
                          _load();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined,
              color: SaharaColors.grayText.withValues(alpha: 0.25), size: 48),
          const SizedBox(height: 14),
          Text('Sin citas para este día', style: GoogleFonts.inter(
            fontSize: 15, color: SaharaColors.grayText.withValues(alpha: 0.5),
          )),
        ],
      ),
    );
  }
}

// ── Selector de fecha ─────────────────────────────────────────────────────────

class _DateNav extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateNav({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _navBtn(Icons.chevron_left, () => onChanged(date.subtract(const Duration(days: 1)))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: SaharaColors.gold,
                    surface: Color(0xFF1A1A1A),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SaharaColors.grayDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: SaharaColors.gold, size: 14),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy').format(date),
                  style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _navBtn(Icons.chevron_right, () => onChanged(date.add(const Duration(days: 1)))),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Icon(icon, color: SaharaColors.grayText, size: 18),
      ),
    );
  }
}

// ── Filtros ───────────────────────────────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  final BookingStatus? selected;
  final ValueChanged<BookingStatus?> onChanged;
  const _StatusFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(label: 'Todas', isSelected: selected == null, onTap: () => onChanged(null)),
          ...BookingStatus.values.map((s) => _FilterChip(
                label: s.label,
                isSelected: selected == s,
                onTap: () => onChanged(selected == s ? null : s),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? SaharaColors.gold.withValues(alpha: 0.6) : SaharaColors.grayDark,
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12,
          color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

// ── Tabla completa ────────────────────────────────────────────────────────────

class _AgendaTable extends StatelessWidget {
  final List<Booking> bookings;
  final void Function(Booking, BookingStatus) onStatusChange;
  const _AgendaTable({required this.bookings, required this.onStatusChange});

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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
            ),
            child: Row(children: const [
              _TH('HORA',      flex: 1),
              _TH('CLIENTE',   flex: 2),
              _TH('SERVICIO',  flex: 3),
              _TH('TERAPEUTA', flex: 2),
              _TH('DUR.',      flex: 1),
              _TH('CABINA',    flex: 1),
              _TH('PRECIO',    flex: 1),
              _TH('ESTADO',    flex: 2),
              _TH('',          flex: 1),
            ]),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (_, i) => _AgendaRow(
                booking: bookings[i],
                onStatusChange: onStatusChange,
              ),
            ),
          ),
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

class _AgendaRow extends StatelessWidget {
  final Booking booking;
  final void Function(Booking, BookingStatus) onStatusChange;
  const _AgendaRow({required this.booking, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed  => const Color(0xFF4CAF50),
      BookingStatus.completed  => const Color(0xFF64B5F6),
      BookingStatus.cancelled  => const Color(0xFFEF5350),
      BookingStatus.noShow     => const Color(0xFFFF7043),
      BookingStatus.scheduled  => const Color(0xFFFFB74D),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: Color(0xFF161616))),
        color: booking.status == BookingStatus.cancelled
            ? Colors.red.withValues(alpha: 0.03)
            : null,
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(
            booking.time.substring(0, 5),
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600),
          )),
          Expanded(flex: 2, child: Text(booking.clientName,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft))),
          Expanded(flex: 3, child: Text(booking.serviceName,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
            overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(booking.therapistName ?? '—',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText))),
          Expanded(flex: 1, child: Text('${booking.durationMin} min',
            style: GoogleFonts.inter(fontSize: 12, color: SaharaColors.grayText))),
          Expanded(flex: 1, child: Text(booking.cabin ?? '—',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText))),
          Expanded(flex: 1, child: Text(
            '\$${NumberFormat('#,###').format(booking.price)}',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.gold, fontWeight: FontWeight.w600),
          )),
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Text(booking.status.label, style: GoogleFonts.inter(
              fontSize: 11, color: statusColor, fontWeight: FontWeight.w600,
            )),
          )),
          Expanded(flex: 1, child: PopupMenuButton<BookingStatus>(
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
          )),
        ],
      ),
    );
  }
}
