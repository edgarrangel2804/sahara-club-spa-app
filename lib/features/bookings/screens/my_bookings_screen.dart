import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final raw = await _db
          .from('bookings')
          .select('''
            id, booking_date, booking_time, duration_min, status, price, client_notes,
            services(name, category),
            therapists:profiles!bookings_therapist_id_fkey(full_name)
          ''')
          .eq('client_id', user.id)
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);
      if (mounted) setState(() => _bookings = (raw as List).cast());
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _upcoming => _bookings
      .where((b) => !['completed', 'cancelled', 'no_show'].contains(b['status']))
      .toList();

  List<Map<String, dynamic>> get _past => _bookings
      .where((b) => ['completed', 'cancelled', 'no_show'].contains(b['status']))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                  child: Text('Mis reservas',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
                    )),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: TabBar(
                    controller: _tab,
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: SaharaColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.5)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                    labelColor: SaharaColors.gold,
                    unselectedLabelColor: SaharaColors.grayText,
                    tabs: const [Tab(text: 'Próximas'), Tab(text: 'Historial')],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(
                          color: SaharaColors.gold, strokeWidth: 1.5))
                      : TabBarView(
                          controller: _tab,
                          children: [
                            _BookingsList(
                              bookings: _upcoming,
                              emptyLabel: 'Sin citas próximas',
                              emptyIcon: Icons.calendar_today_outlined,
                              onRefresh: _load,
                            ),
                            _BookingsList(
                              bookings: _past,
                              emptyLabel: 'Sin historial de citas',
                              emptyIcon: Icons.history_rounded,
                              onRefresh: _load,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lista de citas ────────────────────────────────────────────────────────────

class _BookingsList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final String emptyLabel;
  final IconData emptyIcon;
  final VoidCallback onRefresh;

  const _BookingsList({
    required this.bookings,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                color: SaharaColors.grayText.withValues(alpha: 0.25), size: 48),
            const SizedBox(height: 14),
            Text(emptyLabel, style: GoogleFonts.inter(
              fontSize: 15, color: SaharaColors.grayText.withValues(alpha: 0.5),
            )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: SaharaColors.gold,
      backgroundColor: const Color(0xFF111111),
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

// ── Tarjeta de cita ───────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  static Color _statusColor(String status) => switch (status) {
    'confirmed'  => const Color(0xFF4CAF50),
    'completed'  => const Color(0xFF64B5F6),
    'cancelled'  => const Color(0xFFEF5350),
    'no_show'    => const Color(0xFFFF7043),
    _            => const Color(0xFFFFB74D),
  };

  static String _statusLabel(String status) => switch (status) {
    'confirmed'  => 'Confirmada',
    'completed'  => 'Completada',
    'cancelled'  => 'Cancelada',
    'no_show'    => 'No asistí',
    _            => 'Pendiente',
  };

  static IconData _statusIcon(String status) => switch (status) {
    'confirmed'  => Icons.check_circle_outline,
    'completed'  => Icons.done_all_rounded,
    'cancelled'  => Icons.cancel_outlined,
    'no_show'    => Icons.event_busy_outlined,
    _            => Icons.schedule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final status     = booking['status'] as String? ?? 'scheduled';
    final color      = _statusColor(status);
    final dateStr    = booking['booking_date'] as String? ?? '';
    final timeStr    = booking['booking_time'] as String? ?? '';
    final serviceName = (booking['services'] as Map?)?['name'] as String? ?? '—';
    final therapist  = (booking['therapists'] as Map?)?['full_name'] as String?;
    final price      = (booking['price'] as num?)?.toDouble() ?? 0;
    final notes      = booking['client_notes'] as String?;

    DateTime? date;
    try { date = DateTime.parse(dateStr); } catch (_) {}

    final dateLabel = date != null
        ? DateFormat("EEE d 'de' MMM", 'es').format(date)
        : dateStr;
    final timeLabel = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.05),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        children: [
          // ── Franja de color con estado ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), color: color, size: 14),
                const SizedBox(width: 7),
                Text(_statusLabel(status), style: GoogleFonts.inter(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                Text('\$${NumberFormat('#,###').format(price)}',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.gold, fontWeight: FontWeight.w600,
                  )),
              ],
            ),
          ),
          // ── Contenido ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceName, style: GoogleFonts.playfairDisplay(
                  fontSize: 17, color: SaharaColors.whiteSoft,
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoPill(icon: Icons.calendar_today_rounded, label: dateLabel),
                    const SizedBox(width: 10),
                    _InfoPill(icon: Icons.schedule_rounded, label: timeLabel),
                  ],
                ),
                if (therapist != null) ...[
                  const SizedBox(height: 10),
                  _InfoPill(icon: Icons.person_outline_rounded, label: therapist),
                ] else ...[
                  const SizedBox(height: 10),
                  _InfoPill(
                    icon: Icons.person_search_outlined,
                    label: 'Terapeuta por asignar',
                    faded: true,
                  ),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(notes, style: GoogleFonts.inter(
                    fontSize: 12, color: SaharaColors.grayText.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool faded;
  const _InfoPill({required this.icon, required this.label, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final color = faded
        ? SaharaColors.grayText.withValues(alpha: 0.4)
        : SaharaColors.grayText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: color)),
      ],
    );
  }
}
