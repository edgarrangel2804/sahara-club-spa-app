import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';
import 'package:sahara_club_spa_app/features/reception/widgets/add_client_dialog.dart';
import 'package:sahara_club_spa_app/features/reception/widgets/client_detail_sheet.dart';

class ReceptionClientsPage extends StatefulWidget {
  final ReceptionRepository repo;
  const ReceptionClientsPage({super.key, required this.repo});

  @override
  State<ReceptionClientsPage> createState() => _ReceptionClientsPageState();
}

class _ReceptionClientsPageState extends State<ReceptionClientsPage> {
  List<Map<String, dynamic>> _allClients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  String _search = '';
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await widget.repo.getClients();
    if (!mounted) return;
    setState(() {
      _allClients = data;
      _filterList();
      _loading = false;
    });
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddClientDialog(
        repo: widget.repo,
        onCreated: (newClient) {
          Navigator.pop(ctx);
          setState(() {
            _allClients = [newClient, ..._allClients];
            _filterList();
          });
        },
      ),
    );
  }

  void _showClientDetail(Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientDetailSheet(client: client, repo: widget.repo),
    );
  }

  void _filterList() {
    if (_search.isEmpty) {
      _filteredClients = List.from(_allClients);
    } else {
      final q = _search.toLowerCase();
      _filteredClients = _allClients.where((c) {
        final name = (c['full_name'] as String? ?? '').toLowerCase();
        final phone = (c['phone'] as String? ?? '');
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clientes', style: GoogleFonts.playfairDisplay(
                      fontSize: 26, color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w300,
                    )),
                    Text('${_allClients.length} registrados',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: SaharaColors.grayText)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showAddClientDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: SaharaColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: SaharaColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_rounded,
                          color: SaharaColors.gold, size: 16),
                      const SizedBox(width: 6),
                      Text('Agregar', style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.gold,
                        fontWeight: FontWeight.w500,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Búsqueda ──────────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o teléfono…',
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.grayText),
              prefixIcon: const Icon(Icons.search,
                  color: SaharaColors.grayText, size: 18),
              suffixIcon: _search.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() { _search = ''; _filterList(); });
                      },
                      child: const Icon(Icons.close,
                          color: SaharaColors.grayText, size: 16),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF111111),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: SaharaColors.gold, width: 1.2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (v) => setState(() { _search = v; _filterList(); }),
          ),
          const SizedBox(height: 16),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5))
                : _filteredClients.isEmpty
                    ? _empty()
                    : ListView.builder(
                        itemCount: _filteredClients.length,
                        itemBuilder: (_, i) => _ClientCard(
                          client: _filteredClients[i],
                          onTap: () => _showClientDetail(_filteredClients[i]),
                          onMessageTap: () => _showClientDetail(_filteredClients[i]),
                        ),
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
          Icon(Icons.person_search_outlined,
              color: SaharaColors.grayText.withValues(alpha: 0.25), size: 48),
          const SizedBox(height: 14),
          Text(
            _search.isEmpty
                ? 'Sin clientes registrados'
                : 'Sin resultados para "$_search"',
            style: GoogleFonts.inter(
                fontSize: 15,
                color: SaharaColors.grayText.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de cliente ────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onTap;
  final VoidCallback onMessageTap;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = client['full_name'] as String? ?? '—';
    final phone = client['phone'] as String? ?? '';
    final createdAt = client['created_at'] as String?;
    final since = createdAt != null
        ? DateFormat("MMM yyyy", 'es').format(DateTime.parse(createdAt))
        : null;
    final isActive = client['is_active'] as bool? ?? true;
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').where((w) => w.isNotEmpty).take(2)
            .map((w) => w[0].toUpperCase()).join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────────────────────────────────
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SaharaColors.gold.withValues(alpha: 0.12),
              border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Center(
              child: Text(initials, style: GoogleFonts.inter(
                fontSize: 17, color: SaharaColors.gold,
                fontWeight: FontWeight.w700,
              )),
            ),
          ),
          const SizedBox(width: 14),

          // ── Info ──────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(
                  fontSize: 15, color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w600,
                ), overflow: TextOverflow.ellipsis),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(phone, style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.grayText,
                  )),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (since != null) ...[
                      Text('Desde $since', style: GoogleFonts.inter(
                        fontSize: 11,
                        color: SaharaColors.grayText.withValues(alpha: 0.6),
                      )),
                      const SizedBox(width: 8),
                    ],
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
                    Text(isActive ? 'Activo' : 'Inactivo',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isActive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                      )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Botones de acción ─────────────────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionBtn(
                icon: Icons.phone_outlined,
                color: const Color(0xFF4CAF50),
                tooltip: 'Llamar',
                onTap: phone.isNotEmpty
                    ? () => launchUrl(Uri(scheme: 'tel', path: phone))
                    : null,
              ),
              const SizedBox(height: 8),
              _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                color: SaharaColors.gold,
                tooltip: 'Mensaje interno',
                onTap: onMessageTap,
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap != null ? 1.0 : 0.35,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
