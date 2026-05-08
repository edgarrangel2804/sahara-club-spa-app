import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

// Permiso key → etiqueta, descripción, ícono
const _kPerms = [
  (key: 'ver_caja',       label: 'Ver Caja',        desc: 'Acceso a cobros del día',     icon: Icons.point_of_sale_outlined),
  (key: 'ver_gastos',     label: 'Registrar Gastos', desc: 'Puede registrar gastos',      icon: Icons.receipt_long_outlined),
  (key: 'ver_clientes',   label: 'Ver Clientes',     desc: 'Acceso al directorio',        icon: Icons.people_outline),
  (key: 'cancelar_citas', label: 'Cancelar Citas',   desc: 'Puede cancelar reservas',     icon: Icons.cancel_outlined),
];

class AdminPermisosPage extends StatefulWidget {
  const AdminPermisosPage({super.key});

  @override
  State<AdminPermisosPage> createState() => _AdminPermisosPageState();
}

class _AdminPermisosPageState extends State<AdminPermisosPage> {
  final _repo = SaharaAdminRepository();
  bool _loading = true;
  List<_ReceptionistPerms> _receptionists = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await _repo.getReceptionists();
    if (!mounted) return;
    setState(() {
      _receptionists = raw.map(_ReceptionistPerms.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _save(_ReceptionistPerms r) async {
    try {
      await _repo.updatePermissions(r.id, r.permissions.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Permisos de ${r.name.split(' ').first} guardados',
          style: GoogleFonts.inter(color: Colors.black)),
        backgroundColor: SaharaColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFF2A1010),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5))
                : _receptionists.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                        children: [
                          _buildInfo(),
                          const SizedBox(height: 20),
                          ..._receptionists.map(_buildCard),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SaharaColors.grayDark),
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: SaharaColors.grayText, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Permisos', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
                  )),
                  Text('Control de acceso por recepcionista', style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: SaharaColors.gold, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los cambios se aplican al próximo inicio de sesión del recepcionista.',
              style: GoogleFonts.inter(
                fontSize: 12, color: SaharaColors.grayText, height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Receptionist card ─────────────────────────────────────────────────────

  Widget _buildCard(_ReceptionistPerms r) {
    final initials = r.name.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: SaharaColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Center(child: Text(initials, style: GoogleFonts.inter(
                    fontSize: 14, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                  ))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: GoogleFonts.inter(
                        fontSize: 14, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w600,
                      )),
                      Text('Recepcionista', style: GoogleFonts.inter(
                        fontSize: 11, color: SaharaColors.grayText,
                      )),
                    ],
                  ),
                ),
                // Active permissions count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.permissions.length == _kPerms.length
                        ? SaharaColors.gold.withValues(alpha: 0.1)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${r.permissions.length}/${_kPerms.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: r.permissions.length == _kPerms.length
                          ? SaharaColors.gold
                          : SaharaColors.grayText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 4),

          // Permission toggles
          ..._kPerms.map((p) => _buildToggle(r, p)),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: GestureDetector(
              onTap: () => _save(r),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: SaharaColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('Guardar cambios', style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold,
                ))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    _ReceptionistPerms r,
    ({String key, String label, String desc, IconData icon}) p,
  ) {
    final hasPermission = r.permissions.contains(p.key);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: hasPermission
                  ? SaharaColors.gold.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(p.icon, size: 15,
              color: hasPermission
                  ? SaharaColors.gold
                  : SaharaColors.grayText.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.label, style: GoogleFonts.inter(
                  fontSize: 13,
                  color: hasPermission
                      ? SaharaColors.whiteSoft
                      : SaharaColors.grayText.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                )),
                Text(p.desc, style: GoogleFonts.inter(
                  fontSize: 10,
                  color: SaharaColors.grayText.withValues(alpha: 0.5),
                )),
              ],
            ),
          ),
          Switch(
            value: hasPermission,
            onChanged: (v) {
              setState(() {
                if (v) {
                  r.permissions.add(p.key);
                } else {
                  r.permissions.remove(p.key);
                }
              });
            },
            activeThumbColor: SaharaColors.gold,
            activeTrackColor: SaharaColors.gold.withValues(alpha: 0.25),
            inactiveThumbColor: SaharaColors.grayText.withValues(alpha: 0.4),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

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
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.manage_accounts_outlined,
                color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sin recepcionistas registrados', style: GoogleFonts.playfairDisplay(
            fontSize: 18, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
          )),
          const SizedBox(height: 8),
          Text('Agrega recepcionistas para gestionar sus permisos.',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _ReceptionistPerms {
  final String id;
  final String name;
  final Set<String> permissions;

  _ReceptionistPerms({required this.id, required this.name, required this.permissions});

  static final _defaultPerms = {
    'ver_caja', 'ver_gastos', 'ver_clientes', 'cancelar_citas',
  };

  factory _ReceptionistPerms.fromMap(Map<String, dynamic> m) {
    final rawPerms = m['permissions'];
    Set<String> perms;
    if (rawPerms is List) {
      perms = rawPerms.cast<String>().toSet();
    } else {
      perms = Set.from(_defaultPerms);
    }
    return _ReceptionistPerms(
      id:          m['id'] as String,
      name:        m['full_name'] as String? ?? 'Recepcionista',
      permissions: perms,
    );
  }
}
