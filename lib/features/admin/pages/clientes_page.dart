import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  final _repo = SaharaAdminRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  String _search = '';
  String _filterRole = 'todos';

  static const _roles = ['todos', 'client', 'therapist', 'receptionist', 'admin'];

  static const _roleLabels = {
    'client': 'Cliente',
    'therapist': 'Terapeuta',
    'receptionist': 'Recepción',
    'admin': 'Admin',
  };

  static const _roleColors = {
    'client': SaharaColors.grayText,
    'therapist': Color(0xFF10B981),
    'receptionist': Color(0xFF8B5CF6),
    'admin': SaharaColors.gold,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _users = await _repo.getAllUsers();
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    return _users.where((u) {
      final name = (u['full_name'] as String? ?? '').toLowerCase();
      final role = u['role'] as String? ?? 'client';
      final matchSearch = name.contains(_search.toLowerCase());
      final matchRole = _filterRole == 'todos' || role == _filterRole;
      return matchSearch && matchRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildRoleFilter(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: SaharaColors.gold,
                  child: _filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: SaharaColors.whiteSoft),
        decoration: InputDecoration(
          hintText: 'Buscar usuario...',
          hintStyle: const TextStyle(color: SaharaColors.grayText),
          prefixIcon: const Icon(Icons.search, color: SaharaColors.grayText, size: 20),
          filled: true,
          fillColor: SaharaColors.grayDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _roles.map((r) {
          final selected = _filterRole == r;
          final label = r == 'todos' ? 'Todos' : (_roleLabels[r] ?? r);
          final color = r == 'todos' ? SaharaColors.whiteSoft : (_roleColors[r] ?? SaharaColors.grayText);
          return GestureDetector(
            onTap: () => setState(() => _filterRole = r),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color.withValues(alpha: 0.6) : SaharaColors.grayDark,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : SaharaColors.grayText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> u) {
    final name = u['full_name'] as String? ?? 'Usuario';
    final phone = u['phone'] as String? ?? '';
    final role = u['role'] as String? ?? 'client';
    final isActive = u['is_active'] as bool? ?? true;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final roleColor = _roleColors[role] ?? SaharaColors.grayText;
    final roleLabel = _roleLabels[role] ?? role;

    return GestureDetector(
      onTap: () => _showRoleDialog(u),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: SaharaGradients.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Text(phone, style: const TextStyle(color: SaharaColors.grayText, fontSize: 12)),
                ],
              ),
            ),
            // Role badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: isActive ? SaharaColors.grayText : const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleDialog(Map<String, dynamic> u) {
    final name = u['full_name'] as String? ?? 'Usuario';
    final currentRole = u['role'] as String? ?? 'client';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: SaharaColors.grayDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                color: SaharaColors.whiteSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Asignar rol',
              style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
            ),
            const SizedBox(height: 20),
            ..._roleLabels.entries.map((e) {
              final isSelected = e.key == currentRole;
              final color = _roleColors[e.key] ?? SaharaColors.grayText;
              return GestureDetector(
                onTap: () => _assignRole(u, e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color.withValues(alpha: 0.5) : SaharaColors.grayDark,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _roleIcon(e.key),
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        e.value,
                        style: TextStyle(
                          color: isSelected ? color : SaharaColors.whiteSoft,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: color, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _assignRole(Map<String, dynamic> u, String newRole) async {
    Navigator.pop(context);
    final userId = u['id'] as String;
    try {
      await _repo.updateUserRole(userId, newRole);
      // Actualizar localmente
      setState(() {
        final idx = _users.indexWhere((x) => x['id'] == userId);
        if (idx != -1) _users[idx] = {..._users[idx], 'role': newRole};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rol actualizado a ${_roleLabels[newRole]}',
              style: GoogleFonts.inter(color: SaharaColors.whiteSoft),
            ),
            backgroundColor: SaharaColors.grayDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar rol: $e',
                style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
            backgroundColor: SaharaColors.grayDark,
          ),
        );
      }
    }
  }

  IconData _roleIcon(String role) {
    return switch (role) {
      'admin' => Icons.admin_panel_settings_outlined,
      'therapist' => Icons.spa_outlined,
      'receptionist' => Icons.support_agent_outlined,
      _ => Icons.person_outline,
    };
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, color: SaharaColors.grayDark, size: 48),
          const SizedBox(height: 12),
          Text(
            'No se encontraron usuarios',
            style: GoogleFonts.inter(color: SaharaColors.grayText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
