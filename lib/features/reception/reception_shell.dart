import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_home_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_agenda_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_clients_page.dart';

class ReceptionShell extends StatefulWidget {
  const ReceptionShell({super.key});

  @override
  State<ReceptionShell> createState() => _ReceptionShellState();
}

class _ReceptionShellState extends State<ReceptionShell> {
  int _index = 0;
  int _pendingCount = 0;
  final _repo = ReceptionRepository();

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,      label: 'Dashboard'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Agenda'),
    _NavItem(icon: Icons.people_outline,          activeIcon: Icons.people_rounded,         label: 'Clientes'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final list = await _repo.getPendingRequests();
    if (!mounted) return;
    setState(() => _pendingCount = list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          _Sidebar(
            currentIndex: _index,
            items: _navItems,
            pendingBadge: _pendingCount,
            onTap: (i) => setState(() => _index = i),
            onLogout: _logout,
          ),
          // ── Contenido ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B0B0B), Color(0xFF0F0B0D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: IndexedStack(
                index: _index,
                children: [
                  ReceptionHomePage(repo: _repo, onPendingChanged: _loadPendingCount),
                  ReceptionAgendaPage(repo: _repo),
                  ReceptionClientsPage(repo: _repo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final int pendingBadge;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.currentIndex,
    required this.items,
    required this.pendingBadge,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Recepcionista';
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          right: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // ── Logo ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAHARA', style: GoogleFonts.playfairDisplay(
                  fontSize: 20, color: SaharaColors.gold,
                  letterSpacing: 6, fontWeight: FontWeight.w400,
                )),
                Text('CLUB SPA', style: GoogleFonts.inter(
                  fontSize: 9, color: SaharaColors.grayText,
                  letterSpacing: 4, fontWeight: FontWeight.w400,
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(height: 1, color: SaharaColors.gold.withValues(alpha: 0.08)),
          ),
          const SizedBox(height: 8),

          // ── Badge de rol ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                  Text('Panel Recepción', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.gold, letterSpacing: 0.5,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Navegación ───────────────────────────────────────────────────
          ...List.generate(items.length, (i) => _SidebarItem(
                item: items[i],
                isSelected: i == currentIndex,
                badge: i == 0 ? pendingBadge : 0,
                onTap: () => onTap(i),
              )),

          const Spacer(),

          // ── Divisor ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(height: 1, color: SaharaColors.gold.withValues(alpha: 0.08)),
          ),
          const SizedBox(height: 16),

          // ── Usuario + logout ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: SaharaColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
                  ),
                  child: Center(child: Text(initials, style: GoogleFonts.inter(
                    fontSize: 12, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                  ))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.split(' ').first, style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500,
                      )),
                      Text('Recepcionista', style: GoogleFonts.inter(
                        fontSize: 10, color: SaharaColors.grayText,
                      )),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onLogout,
                  child: Icon(Icons.logout_rounded,
                    color: SaharaColors.grayText.withValues(alpha: 0.5), size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item de sidebar ───────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SaharaColors.gold.withValues(alpha: 0.2) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 18,
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Text(item.label, style: GoogleFonts.inter(
              fontSize: 13,
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
            const Spacer(),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge', style: GoogleFonts.inter(
                  fontSize: 10, color: Colors.black, fontWeight: FontWeight.w700,
                )),
              )
            else if (isSelected)
              Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(
                  color: SaharaColors.gold, shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
