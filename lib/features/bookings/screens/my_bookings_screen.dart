import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/features/client/pages/client_messages_page.dart';

// Misma URL que usa booking_request_screen al crear cita con anticipo.
// La tarjeta de cita ofrece este enlace para que el cliente pueda pagar más
// tarde cualquier cita en pending_payment.
const _kDepositPaymentUrlPrefix = 'https://saharaclubspa.com/pagar-anticipo/';

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
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _tab.dispose();
    if (_channel != null) _db.removeChannel(_channel!);
    super.dispose();
  }

  void _subscribeRealtime() {
    final user = AuthService().currentUser;
    if (user == null) return;
    _channel = _db
        .channel('my-bookings-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: user.id,
          ),
          callback: (_) { if (mounted) _load(); },
        )
        .subscribe();
  }

  Future<void> _load() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      // RLS hace el filtrado: el rol client solo ve bookings cuyo client_id es
      // su uid (cuenta) o cuyo client_record_id apunta a un clients ligado a
      // su profile (citas walk-in que recepción creó por teléfono y después
      // se vincularon al perfil cuando el cliente se registró). No metemos
      // .eq('client_id', user.id) para no excluir las walk-in vinculadas.
      final raw = await _db
          .from('bookings')
          .select('''
            id, booking_date, booking_time, duration_min, status, price, client_notes,
            payment_requirement, deposit_amount, deposit_paid_cents,
            services(name, category),
            therapists:staff!bookings_therapist_id_fkey(full_name)
          ''')
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);
      if (mounted) setState(() => _bookings = (raw as List).cast());
    } catch (e) {
      debugPrint('MyBookingsScreen._load: $e');
      if (mounted) setState(() => _error = 'No se pudieron cargar tus citas.');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _upcoming => _bookings
      .where((b) => !['completed', 'cancelled', 'no_show', 'paid'].contains(b['status']))
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
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wifi_off_rounded,
                                      color: SaharaColors.grayText
                                          .withValues(alpha: 0.25),
                                      size: 44),
                                  const SizedBox(height: 14),
                                  Text(_error!,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: SaharaColors.grayText
                                              .withValues(alpha: 0.5))),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _load,
                                    child: Text('Reintentar',
                                        style: GoogleFonts.inter(
                                            color: SaharaColors.gold)),
                                  ),
                                ],
                              ),
                            )
                          : TabBarView(
                          controller: _tab,
                          children: [
                            _BookingsList(
                              bookings: _upcoming,
                              emptyLabel: 'Sin citas próximas',
                              emptyIcon: Icons.calendar_today_outlined,
                              onRefresh: _load,
                              allowCancel: true,
                              onContactReception: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClientMessagesPage(),
                                ),
                              ),
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
  final VoidCallback? onContactReception;
  final bool allowCancel;

  const _BookingsList({
    required this.bookings,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.onRefresh,
    this.onContactReception,
    this.allowCancel = false,
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
        itemBuilder: (_, i) => _BookingCard(
          booking: bookings[i],
          onContactReception: onContactReception,
          onRefresh: allowCancel ? onRefresh : null,
        ),
      ),
    );
  }
}

// ── Tarjeta de cita ───────────────────────────────────────────────────────────

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onContactReception;
  final VoidCallback? onRefresh;
  const _BookingCard({required this.booking, this.onContactReception, this.onRefresh});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  // Paleta alineada con el web admin (paleta pastel premium adaptada al
  // theme oscuro de la app).
  static Color _statusColor(String status) => switch (status) {
    'confirmed'         => const Color(0xFF5DAA6E), // verde pistache
    'scheduled'         => const Color(0xFF5C8CC9), // azul pastel — Agendada
    'pending'           => const Color(0xFF5C8CC9),
    'pending_reception' => const Color(0xFF5C8CC9),
    'pending_payment'   => const Color(0xFFD9A23B), // ámbar — esperando anticipo
    'payment_received'  => const Color(0xFF5DAA6E), // verde — pagada por confirmar
    'checked_in'        => const Color(0xFFD9A23B), // ámbar — en servicio
    'in_progress'       => const Color(0xFFD9A23B),
    'completed'         => const Color(0xFF8C8478), // gris — finalizada
    'awaiting_payment'  => const Color(0xFFB06A1F),
    'paid'              => const Color(0xFF0E8F55),
    'cancelled'         => const Color(0xFFC77878), // coral
    'rescheduled'       => const Color(0xFF5C8CC9),
    'no_show'           => const Color(0xFFC77878),
    _                   => const Color(0xFF5C8CC9),
  };

  static String _statusLabel(String status) => switch (status) {
    'confirmed'         => 'Confirmada',
    'scheduled'         => 'Agendada',
    'pending'           => 'Agendada',
    'pending_reception' => 'Agendada · por revisar',
    'pending_payment'   => 'Esperando anticipo',
    'payment_received'  => 'Pago recibido · por confirmar',
    'checked_in'        => 'En servicio',
    'in_progress'       => 'En servicio',
    'completed'         => 'Finalizada',
    'awaiting_payment'  => 'Pendiente de cobro',
    'paid'              => 'Pagada',
    'cancelled'         => 'Cancelada',
    'rescheduled'       => 'Reagendada',
    'no_show'           => 'No asistí',
    _                   => 'Agendada',
  };

  static IconData _statusIcon(String status) => switch (status) {
    'confirmed'         => Icons.check_circle_outline,
    'scheduled'         => Icons.event_available_rounded,
    'pending'           => Icons.event_available_rounded,
    'pending_reception' => Icons.event_available_rounded,
    'pending_payment'   => Icons.payments_rounded,
    'payment_received'  => Icons.task_alt_rounded,
    'checked_in'        => Icons.login_rounded,
    'in_progress'       => Icons.spa_rounded,
    'completed'         => Icons.done_all_rounded,
    'awaiting_payment'  => Icons.payments_outlined,
    'paid'              => Icons.paid_outlined,
    'cancelled'         => Icons.cancel_outlined,
    'rescheduled'       => Icons.event_repeat_outlined,
    'no_show'           => Icons.event_busy_outlined,
    _                   => Icons.schedule_rounded,
  };

  /// Abre el Payment Element del web para que el cliente pague el anticipo
  /// pendiente de esta cita.
  Future<void> _openDepositPayment(String bookingId) async {
    final url = Uri.parse('$_kDepositPaymentUrlPrefix$bookingId');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('_openDepositPayment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No pudimos abrir la página de pago: $e',
              style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status      = widget.booking['status'] as String? ?? 'scheduled';
    final color       = _statusColor(status);
    final dateStr     = widget.booking['booking_date'] as String? ?? '';
    final timeStr     = widget.booking['booking_time'] as String? ?? '';
    final serviceName = (widget.booking['services'] as Map?)?['name'] as String? ?? '—';
    final therapist   = (widget.booking['therapists'] as Map?)?['full_name'] as String?;
    final price       = (widget.booking['price'] as num?)?.toDouble() ?? 0;
    final notes       = widget.booking['client_notes'] as String?;

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
                if (status == 'pending_payment') ...[
                  const SizedBox(height: 14),
                  _DepositCallToAction(
                    amount: (widget.booking['deposit_amount'] as num?)?.toInt() ?? 0,
                    onPay: () {
                      final id = widget.booking['id']?.toString();
                      if (id != null) _openDepositPayment(id);
                    },
                  ),
                ],
                if (widget.onContactReception != null) ...[
                  const SizedBox(height: 14),
                  Divider(color: SaharaColors.gold.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: widget.onContactReception,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: SaharaColors.gold.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('¿Necesitas cambiar esta cita? Contactar recepción',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: SaharaColors.gold.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

// ── CTA "Pagar anticipo" para citas en pending_payment ────────────────────────
class _DepositCallToAction extends StatelessWidget {
  final int amount;
  final VoidCallback onPay;
  const _DepositCallToAction({required this.amount, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD9A23B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD9A23B).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFFD9A23B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para confirmar tu cita necesitamos tu anticipo.',
                  style: GoogleFonts.inter(
                    color: SaharaColors.whiteSoft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPay,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD9A23B),
                foregroundColor: SaharaColors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: Text(
                amount > 0 ? 'Pagar anticipo · \$$amount MXN' : 'Pagar anticipo',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
