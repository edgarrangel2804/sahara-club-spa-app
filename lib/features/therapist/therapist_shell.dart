import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/features/therapist/data/therapist_repository.dart';
import 'package:sahara_club_spa_app/features/therapist/pages/therapist_home_page.dart';
import 'package:sahara_club_spa_app/features/therapist/pages/therapist_clients_page.dart';
import 'package:sahara_club_spa_app/features/therapist/pages/therapist_messages_page.dart';

class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key});

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _index = 0;
  String _name      = 'Terapeuta';
  String? _specialty;
  String? _avatarUrl;
  final _repo = TherapistRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _repo.getProfile();
    if (!mounted) return;
    setState(() {
      _name      = profile['full_name'] as String? ?? 'Terapeuta';
      _specialty = profile['specialty'] as String?;
      _avatarUrl = profile['avatar_url'] as String?;
    });
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      TherapistHomePage(
        repo:      _repo,
        name:      _name,
        specialty: _specialty,
        avatarUrl: _avatarUrl,
      ),
      TherapistClientsPage(repo: _repo),
      TherapistMessagesPage(repo: _repo),
      _ProfileTab(
        name:      _name,
        specialty: _specialty,
        avatarUrl: _avatarUrl,
        initials:  _initials(_name),
        onLogout:  _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: SaharaColors.black,
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0B0B), Color(0xFF0F0B0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: NotificationService.instance.unreadChatNotifier,
        builder: (context, hasUnreadChat, child) {
          return _TherapistBottomNav(
            currentIndex: _index,
            hasUnreadChat: hasUnreadChat,
            onTap: (i) {
              if (i == 2) NotificationService.instance.markChatAsRead(); // index 2 is Mensajes
              setState(() => _index = i);
            },
          );
        },
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _TherapistBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool hasUnreadChat;
  final ValueChanged<int> onTap;

  const _TherapistBottomNav({
    required this.currentIndex,
    this.hasUnreadChat = false,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.spa_outlined,       Icons.spa_rounded,           'Inicio'),
    _NavItem(Icons.people_outline,     Icons.people_rounded,        'Clientes'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble_rounded,  'Mensajes'),
    _NavItem(Icons.person_outline,     Icons.person_rounded,        'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
            top: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item       = _items[i];
              final isSelected = i == currentIndex;
              final isChatAlert = item.label == 'Mensajes' && hasUnreadChat;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: 1,
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
                            if (isChatAlert)
                              Positioned(
                                top: -2, right: -4,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(item.label, style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected
                              ? SaharaColors.gold
                              : SaharaColors.grayText.withValues(alpha: 0.5),
                          fontWeight: isSelected
                              ? FontWeight.w600 : FontWeight.w400,
                        )),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width:  isSelected ? 16 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: SaharaColors.gold,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ── Profile tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final String name;
  final String? specialty;
  final String? avatarUrl;
  final String initials;
  final VoidCallback onLogout;

  const _ProfileTab({
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.initials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar grande
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SaharaColors.gold.withValues(alpha: 0.1),
              border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.4), width: 2),
            ),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(child: Image.network(avatarUrl!, fit: BoxFit.cover))
                : Center(child: Text(initials, style: GoogleFonts.inter(
                    fontSize: 32, color: SaharaColors.gold,
                    fontWeight: FontWeight.w700,
                  ))),
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.playfairDisplay(
            fontSize: 26, color: SaharaColors.whiteSoft,
          )),
          if (specialty != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: SaharaColors.gold.withValues(alpha: 0.2)),
              ),
              child: Text(specialty!, style: GoogleFonts.inter(
                fontSize: 12, color: SaharaColors.gold,
                fontWeight: FontWeight.w500, letterSpacing: 0.5,
              )),
            ),
          ],
          const SizedBox(height: 6),
          Text('Terapeuta · Sahara Club Spa', style: GoogleFonts.inter(
            fontSize: 12, color: SaharaColors.grayText,
          )),
          const SizedBox(height: 40),
          Container(height: 1, color: SaharaColors.gold.withValues(alpha: 0.08)),
          const SizedBox(height: 32),
          // Cerrar sesión
          GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Color(0xFFEF5350), size: 18),
                  const SizedBox(width: 10),
                  Text('Cerrar Sesión', style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFFEF5350),
                    fontWeight: FontWeight.w500,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
