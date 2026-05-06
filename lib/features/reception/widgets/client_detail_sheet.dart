import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';
import 'package:sahara_club_spa_app/features/reception/widgets/status_badge.dart';

class ClientDetailSheet extends StatefulWidget {
  final Map<String, dynamic> client;
  final ReceptionRepository repo;

  const ClientDetailSheet({
    super.key,
    required this.client,
    required this.repo,
  });

  @override
  State<ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends State<ClientDetailSheet> {
  List<Booking> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await widget.repo.getClientBookingHistory(
        widget.client['id'] as String);
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  // ── Estadísticas calculadas ───────────────────────────────────────────────

  int get _totalVisits =>
      _history.where((b) => b.status == BookingStatus.completed).length;

  double get _totalSpent => _history
      .where((b) => b.status == BookingStatus.completed)
      .fold(0, (sum, b) => sum + b.price);

  String get _favoriteService {
    final freq = <String, int>{};
    for (final b in _history.where((b) => b.status == BookingStatus.completed)) {
      freq[b.serviceName] = (freq[b.serviceName] ?? 0) + 1;
    }
    if (freq.isEmpty) return '—';
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    final name      = widget.client['full_name'] as String? ?? '—';
    final phone     = widget.client['phone'] as String? ?? '';
    final isActive  = widget.client['is_active'] as bool? ?? true;
    final createdAt = widget.client['created_at'] as String?;
    final since     = createdAt != null
        ? DateFormat("MMMM yyyy", 'es').format(DateTime.parse(createdAt))
        : null;
    final initials  = name.trim().isNotEmpty
        ? name.trim().split(' ').where((w) => w.isNotEmpty).take(2)
            .map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header del cliente ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SaharaColors.gold.withValues(alpha: 0.12),
                          border: Border.all(
                              color: SaharaColors.gold.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: Center(child: Text(initials,
                          style: GoogleFonts.inter(
                            fontSize: 22, color: SaharaColors.gold,
                            fontWeight: FontWeight.w700,
                          ))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.playfairDisplay(
                              fontSize: 22, color: SaharaColors.whiteSoft,
                            )),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 13, color: SaharaColors.gold),
                                    const SizedBox(width: 5),
                                    Text(phone, style: GoogleFonts.inter(
                                      fontSize: 13, color: SaharaColors.gold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: SaharaColors.gold,
                                    )),
                                  ],
                                ),
                              ),
                            ],
                            if (since != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Desde $since', style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: SaharaColors.grayText.withValues(alpha: 0.7),
                                  )),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFEF5350),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(isActive ? 'Activa' : 'Inactiva',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isActive
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFEF5350),
                                    )),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Stats row ──────────────────────────────────────────────
                  if (!_loading) ...[
                    Row(
                      children: [
                        _StatCard(
                          value: '$_totalVisits',
                          label: _totalVisits == 1 ? 'visita' : 'visitas',
                          icon: Icons.spa_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          value: '\$${NumberFormat('#,###').format(_totalSpent)}',
                          label: 'gastado',
                          icon: Icons.attach_money_rounded,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            value: _favoriteService,
                            label: 'más frecuente',
                            icon: Icons.favorite_outline_rounded,
                            valueMaxLines: 2,
                            flex: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Historial ──────────────────────────────────────────────
                  Text('HISTORIAL', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.grayText,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5,
                  )),
                  const SizedBox(height: 12),

                  if (_loading)
                    const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator(
                          color: SaharaColors.gold, strokeWidth: 1.5)),
                    )
                  else if (_history.isEmpty)
                    _EmptyHistory()
                  else
                    ...(_history.map(_historyRow).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(Booking b) {
    final dateLabel = DateFormat("d MMM yyyy", 'es').format(b.date);
    final timeLabel = b.time.substring(0, 5);
    final isCompleted = b.status == BookingStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
              : SaharaColors.gold.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.serviceName, style: GoogleFonts.inter(
                  fontSize: 14, color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w500,
                ), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 11, color: SaharaColors.grayText.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('$dateLabel · $timeLabel', style: GoogleFonts.inter(
                    fontSize: 12, color: SaharaColors.grayText,
                  )),
                  if (b.therapistName != null) ...[
                    Text('  ·  ', style: GoogleFonts.inter(
                        fontSize: 12, color: SaharaColors.grayText)),
                    Flexible(child: Text(b.therapistName!.split(' ').first,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: SaharaColors.grayText),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (b.price > 0)
                Text('\$${NumberFormat('#,###').format(b.price)}',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.gold,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              StatusBadge(status: b.status),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final int valueMaxLines;
  final bool flex;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.valueMaxLines = 1,
    this.flex = false,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: SaharaColors.gold.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(value,
            style: GoogleFonts.inter(
              fontSize: 15, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w600,
            ),
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: SaharaColors.grayText,
          )),
        ],
      ),
    );

    return flex ? inner : SizedBox(width: 100, child: inner);
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded,
                size: 36,
                color: SaharaColors.grayText.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Text('Sin citas registradas', style: GoogleFonts.inter(
              fontSize: 14,
              color: SaharaColors.grayText.withValues(alpha: 0.5),
            )),
          ],
        ),
      ),
    );
  }
}
