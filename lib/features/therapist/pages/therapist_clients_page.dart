import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/therapist/data/therapist_repository.dart';

class TherapistClientsPage extends StatefulWidget {
  final TherapistRepository repo;
  const TherapistClientsPage({super.key, required this.repo});

  @override
  State<TherapistClientsPage> createState() => _TherapistClientsPageState();
}

class _TherapistClientsPageState extends State<TherapistClientsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await widget.repo.getMyClients();
    if (!mounted) return;
    setState(() {
      _clients = raw;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: SaharaColors.gold, strokeWidth: 1.5));
    }
    if (_clients.isEmpty) return _buildEmpty();

    final totalSessions =
        _clients.fold<int>(0, (s, c) => s + (c['sessions'] as int));

    return RefreshIndicator(
      onRefresh: _load,
      color: SaharaColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: _clients.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _buildBanner(totalSessions);
          return _buildCard(_clients[i - 1]);
        },
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────

  Widget _buildBanner(int totalSessions) {
    final lastVisit = _clients.isEmpty ? '' : _clients.first['last_visit'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _Stat(value: '${_clients.length}', label: 'Clientes'),
          _vDivider(),
          _Stat(value: '$totalSessions', label: 'Sesiones'),
          _vDivider(),
          _Stat(value: _fmtShort(lastVisit), label: 'Últ. visita'),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 8),
      color: SaharaColors.gold.withValues(alpha: 0.2));

  // ── Client card ───────────────────────────────────────────────────────────

  Widget _buildCard(Map<String, dynamic> c) {
    final name      = c['name']       as String;
    final sessions  = c['sessions']   as int;
    final lastVisit = c['last_visit'] as String;
    final svcs      = (c['services']  as List).cast<String>();

    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final topSvcs = svcs.toSet().take(2).toList();

    return GestureDetector(
      onTap: () => _showHistory(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: SaharaColors.gold.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(initials, style: GoogleFonts.inter(
                fontSize: 14, color: SaharaColors.gold,
                fontWeight: FontWeight.w700,
              ))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(
                    fontSize: 14, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, size: 11,
                          color: SaharaColors.grayText.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(_fmtDate(lastVisit), style: GoogleFonts.inter(
                        fontSize: 11, color: SaharaColors.grayText,
                      )),
                      const SizedBox(width: 8),
                      ...topSvcs.map((s) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.length > 10 ? '${s.substring(0, 10)}…' : s,
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: SaharaColors.grayText),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$sessions\nses.', style: GoogleFonts.inter(
                fontSize: 11, color: SaharaColors.gold,
                fontWeight: FontWeight.w800, height: 1.2,
              ), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  // ── History sheet ─────────────────────────────────────────────────────────

  Future<void> _showHistory(Map<String, dynamic> c) async {
    final history = await widget.repo.getClientHistory(c['id'] as String);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientHistorySheet(client: c, history: history),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sin clientes aún', style: GoogleFonts.playfairDisplay(
            fontSize: 18, color: SaharaColors.whiteSoft,
            fontWeight: FontWeight.w300,
          )),
          const SizedBox(height: 8),
          Text(
            'Aquí verás el historial de clientes\nque hayas atendido.',
            style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.grayText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('d MMM yyyy', 'es').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _fmtShort(String d) {
    try {
      return DateFormat('d MMM', 'es').format(DateTime.parse(d));
    } catch (_) {
      return '—';
    }
  }
}

// ── Banner stat ───────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(
            fontSize: 18, color: SaharaColors.gold,
            fontWeight: FontWeight.w800,
          )),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: SaharaColors.grayText,
          )),
        ],
      ),
    );
  }
}

// ── Client history bottom sheet ───────────────────────────────────────────────

class _ClientHistorySheet extends StatelessWidget {
  final Map<String, dynamic> client;
  final List<Map<String, dynamic>> history;
  const _ClientHistorySheet({required this.client, required this.history});

  static final _currFmt =
      NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final name     = client['name']     as String;
    final sessions = client['sessions'] as int;
    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: SaharaColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: SaharaColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Center(child: Text(initials, style: GoogleFonts.inter(
                    fontSize: 16, color: SaharaColors.gold,
                    fontWeight: FontWeight.w700,
                  ))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(
                      fontSize: 16, color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w600,
                    )),
                    Text('$sessions sesiones contigo',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: SaharaColors.grayText)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: history.isEmpty
                ? Center(child: Text('Sin historial registrado',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.grayText)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    itemCount: history.length,
                    itemBuilder: (_, i) => _buildRow(history[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> b) {
    final date      = b['booking_date'] as String? ?? '';
    final time      = (b['booking_time'] as String? ?? '').substring(0, 5);
    final svc       = (b['services'] as Map?)?['name'] as String? ?? 'Servicio';
    final status    = b['status'] as String? ?? '';
    final notes     = b['session_notes'] as String?;
    final price     = (b['price'] as num?)?.toDouble();
    final completed = status == 'completed';
    final sColor    = completed ? const Color(0xFF4CAF50) : const Color(0xFFFFB74D);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_fmtDate(date), style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.whiteSoft,
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(width: 8),
              Text(time, style: GoogleFonts.inter(
                  fontSize: 11, color: SaharaColors.grayText)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(completed ? 'Completada' : 'Pendiente',
                  style: GoogleFonts.inter(
                    fontSize: 10, color: sColor,
                    fontWeight: FontWeight.w600,
                  )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(svc, style: GoogleFonts.inter(
              fontSize: 12, color: SaharaColors.grayText)),
          if (price != null) ...[
            const SizedBox(height: 3),
            Text(_currFmt.format(price), style: GoogleFonts.inter(
              fontSize: 12, color: SaharaColors.gold,
              fontWeight: FontWeight.w600,
            )),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: SaharaColors.gold.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined, size: 12,
                      color: SaharaColors.gold.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(notes, style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText, height: 1.4,
                  ))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('d MMM yyyy', 'es').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }
}
