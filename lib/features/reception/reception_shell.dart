import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_home_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_agenda_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_clients_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_caja_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_messages_page.dart';
import 'package:sahara_club_spa_app/features/reception/pages/reception_qr_scanner_page.dart';

class ReceptionShell extends StatefulWidget {
  const ReceptionShell({super.key});

  @override
  State<ReceptionShell> createState() => _ReceptionShellState();
}

class _ReceptionShellState extends State<ReceptionShell> {
  int _index = 0;
  int _pendingCount = 0;
  String _userName  = 'Recepcionista';
  String? _avatarUrl;
  Set<String> _permissions = {'ver_caja', 'ver_gastos', 'ver_clientes', 'cancelar_citas'};
  final _repo = ReceptionRepository();
  final _homeRefresh = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _homeRefresh.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    final list = await _repo.getPendingRequests();
    if (!mounted) return;
    setState(() => _pendingCount = list.length);
    _homeRefresh.value++;
  }

  Future<void> _loadUserProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url, permissions')
          .eq('id', user.id)
          .single();
      if (!mounted) return;
      setState(() {
        _userName  = data['full_name'] as String? ?? 'Recepcionista';
        _avatarUrl = data['avatar_url'] as String?;
        final rawPerms = data['permissions'];
        if (rawPerms is List) {
          _permissions = rawPerms.cast<String>().toSet();
        }
      });
    } catch (_) {
      final metaName = user.userMetadata?['full_name'] as String?;
      if (metaName != null && mounted) setState(() => _userName = metaName);
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  String _initials(String name) => name
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  List<_NavItem> _buildNavItems() => [
    const _NavItem(icon: Icons.home_outlined,           activeIcon: Icons.home_rounded,           label: 'Inicio'),
    const _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Agenda'),
    if (_permissions.contains('ver_clientes'))
      const _NavItem(icon: Icons.people_outline,        activeIcon: Icons.people_rounded,         label: 'Clientes'),
    const _NavItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble_rounded,    label: 'Mensajes'),
    if (_permissions.contains('ver_caja'))
      const _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale,         label: 'Caja'),
    const _NavItem(icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner_rounded, label: 'Escanear'),
  ];

  List<Widget> _buildPages() => [
    ReceptionHomePage(repo: _repo, onPendingChanged: _loadPendingCount, refreshNotifier: _homeRefresh),
    ReceptionAgendaPage(repo: _repo),
    if (_permissions.contains('ver_clientes'))
      ReceptionClientsPage(repo: _repo),
    ReceptionMessagesPage(repo: _repo),
    if (_permissions.contains('ver_caja'))
      ReceptionCajaPage(repo: _repo),
    const ReceptionQrScannerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final navItems = _buildNavItems();
    final pages    = _buildPages();
    final safeIndex = _index.clamp(0, pages.length - 1);

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          centerTitle: true,
          title: Text('SAHARA CLUB SPA', style: GoogleFonts.playfairDisplay(
            fontSize: 13, color: SaharaColors.gold,
            letterSpacing: 4, fontWeight: FontWeight.w400,
          )),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1,
                color: SaharaColors.gold.withValues(alpha: 0.1)),
          ),
          actions: [
            PopupMenuButton<String>(
              color: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              offset: const Offset(0, 48),
              onSelected: (v) { if (v == 'logout') _logout(); },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      _AvatarWidget(
                        avatarUrl: _avatarUrl,
                        initials:  _initials(_userName),
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName.split(' ').first, style: GoogleFonts.inter(
                            fontSize: 13, color: SaharaColors.whiteSoft,
                            fontWeight: FontWeight.w600,
                          )),
                          Text('Recepcionista', style: GoogleFonts.inter(
                            fontSize: 11, color: SaharaColors.grayText,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF5350), size: 18),
                    const SizedBox(width: 10),
                    Text('Cerrar Sesión', style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFEF5350),
                    )),
                  ]),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _AvatarWidget(
                  avatarUrl: _avatarUrl,
                  initials:  _initials(_userName),
                  size: 32,
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: safeIndex, children: pages),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: NotificationService.instance.unreadChatNotifier,
          builder: (context, hasUnreadChat, child) {
            return _BottomNav(
              currentIndex: safeIndex,
              items: navItems,
              pendingBadge: _pendingCount,
              hasUnreadChat: hasUnreadChat,
              onTap: (i) {
                if (i == 0 && _index != 0) _homeRefresh.value++;
                if (navItems[i].label == 'Mensajes') NotificationService.instance.markChatAsRead();
                setState(() => _index = i);
              },
            );
          },
        ),
      );
    }

    // ── Desktop / Tablet ────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: ValueListenableBuilder<bool>(
              valueListenable: NotificationService.instance.unreadChatNotifier,
              builder: (context, hasUnreadChat, child) {
                return _Sidebar(
                  currentIndex: safeIndex,
                  items:        navItems,
                  pendingBadge: _pendingCount,
                  hasUnreadChat: hasUnreadChat,
                  userName:     _userName,
                  avatarUrl:    _avatarUrl,
                  onTap:        (i) {
                    if (navItems[i].label == 'Mensajes') NotificationService.instance.markChatAsRead();
                    setState(() => _index = i);
                  },
                  onLogout:     _logout,
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B0B0B), Color(0xFF0F0B0D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: IndexedStack(index: safeIndex, children: pages),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar Widget ─────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String  initials;
  final double  size;

  const _AvatarWidget({
    required this.avatarUrl,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: SaharaColors.gold.withValues(alpha: 0.12),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(initials, style: GoogleFonts.inter(
          fontSize: size * 0.34,
          color: SaharaColors.gold,
          fontWeight: FontWeight.w700,
        )),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final int pendingBadge;
  final bool hasUnreadChat;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.pendingBadge,
    this.hasUnreadChat = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item       = items[i];
              final isSelected = i == currentIndex;
              final hasBadge   = i == 0 && pendingBadge > 0;
              final isChatAlert = item.label == 'Mensajes' && hasUnreadChat;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? SaharaColors.gold
                                : SaharaColors.grayText.withValues(alpha: 0.5),
                          ),
                          if (hasBadge || isChatAlert)
                            Positioned(
                              top: -4, right: -6,
                              child: Container(
                                padding: isChatAlert ? const EdgeInsets.all(4) : const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isChatAlert ? Colors.redAccent : const Color(0xFFFFB74D),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(isChatAlert ? '!' : '$pendingBadge',
                                  style: GoogleFonts.inter(
                                    fontSize: 8, color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  )),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected
                              ? SaharaColors.gold
                              : SaharaColors.grayText.withValues(alpha: 0.5),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Sidebar (Desktop) ─────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final int pendingBadge;
  final bool hasUnreadChat;
  final String userName;
  final String? avatarUrl;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.currentIndex,
    required this.items,
    required this.pendingBadge,
    this.hasUnreadChat = false,
    required this.userName,
    required this.avatarUrl,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          right: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
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
            child: Container(
                height: 1, color: SaharaColors.gold.withValues(alpha: 0.08)),
          ),
          const SizedBox(height: 8),

          // ── Badge de rol ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: SaharaColors.gold.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                  Text('Panel Recepción', style: GoogleFonts.inter(
                    fontSize: 10, color: SaharaColors.gold, letterSpacing: 0.5,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Navegación ────────────────────────────────────────────────────
          ...List.generate(items.length, (i) => _SidebarItem(
            item: items[i],
            isSelected: i == currentIndex,
            badge: i == 0 ? pendingBadge : 0,
            hasUnreadChat: items[i].label == 'Mensajes' && hasUnreadChat,
            onTap: () => onTap(i),
          )),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
                height: 1, color: SaharaColors.gold.withValues(alpha: 0.08)),
          ),
          const SizedBox(height: 16),

          // ── Usuario ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                _AvatarWidget(
                  avatarUrl: avatarUrl,
                  initials:  initials,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName.split(' ').first, style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w500,
                      )),
                      Text('Recepcionista', style: GoogleFonts.inter(
                        fontSize: 10, color: SaharaColors.grayText,
                      )),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Cerrar Sesión',
                  child: GestureDetector(
                    onTap: onLogout,
                    child: Icon(Icons.logout_rounded,
                      color: SaharaColors.grayText.withValues(alpha: 0.5),
                      size: 18),
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

// ── Sidebar item ──────────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final int badge;
  final bool hasUnreadChat;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.badge = 0,
    this.hasUnreadChat = false,
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
          color: isSelected
              ? SaharaColors.gold.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SaharaColors.gold.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 18,
              color: isSelected
                  ? SaharaColors.gold
                  : SaharaColors.grayText.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Text(item.label, style: GoogleFonts.inter(
              fontSize: 13,
              color: isSelected
                  ? SaharaColors.gold
                  : SaharaColors.grayText.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
            const Spacer(),
            if (badge > 0 || hasUnreadChat)
              Container(
                padding: hasUnreadChat ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasUnreadChat ? Colors.redAccent : const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(hasUnreadChat ? '!' : '$badge', style: GoogleFonts.inter(
                  fontSize: 10, color: Colors.black, fontWeight: FontWeight.w700,
                )),
              )
            else if (isSelected)
              Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(
                  color: SaharaColors.gold, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Modelo ────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
