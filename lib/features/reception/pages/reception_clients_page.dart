import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

class ReceptionClientsPage extends StatefulWidget {
  final ReceptionRepository repo;
  const ReceptionClientsPage({super.key, required this.repo});

  @override
  State<ReceptionClientsPage> createState() => _ReceptionClientsPageState();
}

class _ReceptionClientsPageState extends State<ReceptionClientsPage> {
  List<Map<String, dynamic>> _clients = [];
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
    final data = await widget.repo.getClients(search: _search.isEmpty ? null : _search);
    if (!mounted) return;
    setState(() {
      _clients = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ──────────────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clientes', style: GoogleFonts.playfairDisplay(
                    fontSize: 26, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
                  )),
                  Text('${_clients.length} clientes registrados',
                    style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText)),
                ],
              ),
              const Spacer(),
              // Búsqueda
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.whiteSoft),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
                    prefixIcon: const Icon(Icons.search, color: SaharaColors.grayText, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                              _load();
                            },
                            child: const Icon(Icons.close, color: SaharaColors.grayText, size: 16),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: SaharaColors.gold, width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() => _search = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Tabla ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5))
                : _clients.isEmpty
                    ? _empty()
                    : _ClientsTable(clients: _clients),
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
            _search.isEmpty ? 'Sin clientes registrados' : 'Sin resultados para "$_search"',
            style: GoogleFonts.inter(fontSize: 15, color: SaharaColors.grayText.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ── Tabla de clientes ─────────────────────────────────────────────────────────

class _ClientsTable extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  const _ClientsTable({required this.clients});

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
              _TH('NOMBRE',        flex: 3),
              _TH('TELÉFONO',      flex: 2),
              _TH('MIEMBRO DESDE', flex: 2),
              _TH('ESTADO',        flex: 1),
            ]),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (_, i) => _ClientRow(client: clients[i]),
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

class _ClientRow extends StatelessWidget {
  final Map<String, dynamic> client;
  const _ClientRow({required this.client});

  @override
  Widget build(BuildContext context) {
    final name = client['full_name'] as String? ?? '—';
    final phone = client['phone'] as String? ?? '—';
    final createdAt = client['created_at'] as String?;
    final since = createdAt != null
        ? DateFormat("dd MMM yyyy", 'es').format(DateTime.parse(createdAt))
        : '—';
    final isActive = client['is_active'] as bool? ?? true;
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF161616))),
      ),
      child: Row(
        children: [
          // Avatar + nombre
          Expanded(flex: 3, child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: SaharaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
                ),
                child: Center(child: Text(initials, style: GoogleFonts.inter(
                  fontSize: 12, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                ))),
              ),
              const SizedBox(width: 12),
              Text(name, style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500,
              )),
            ],
          )),
          Expanded(flex: 2, child: Text(phone,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText))),
          Expanded(flex: 2, child: Text(since,
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText))),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350))
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              isActive ? 'Activo' : 'Inactivo',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
