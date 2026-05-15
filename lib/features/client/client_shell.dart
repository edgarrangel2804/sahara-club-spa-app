import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/services/screens/services_screen.dart';
import 'package:sahara_club_spa_app/features/bookings/screens/my_bookings_screen.dart';
import 'package:sahara_club_spa_app/features/profile/profile_screen.dart';
import 'package:sahara_club_spa_app/features/shop/screens/shop_screen.dart';
import 'package:sahara_club_spa_app/features/shop/controllers/shop_cart_controller.dart';
import 'package:sahara_club_spa_app/features/client/pages/client_messages_page.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,           label: 'Inicio'),
    _TabItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Reservas'),
    _TabItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded,   label: 'Tienda'),
    _TabItem(icon: Icons.chat_bubble_outline,  activeIcon: Icons.chat_bubble_rounded,    label: 'Mensajes'),
    _TabItem(icon: Icons.person_outline,       activeIcon: Icons.person_rounded,         label: 'Perfil'),
  ];

  static const _screens = [
    ServicesScreen(),
    MyBookingsScreen(),
    ShopScreen(),
    ClientMessagesPage(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _SaharaNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

// ── Barra personalizada ───────────────────────────────────────────────────────

class _SaharaNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _SaharaNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border(
          top: BorderSide(
            color: SaharaColors.gold.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == 2)
                          ValueListenableBuilder<List>(
                            valueListenable: ShopCartController.instance,
                            builder: (context, items, _) {
                              final count = ShopCartController.instance.itemCount;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isSelected ? tabs[i].activeIcon : tabs[i].icon,
                                      key: ValueKey(isSelected),
                                      size: 22,
                                      color: isSelected
                                          ? SaharaColors.gold
                                          : SaharaColors.grayText.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: -7,
                                      top: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: SaharaColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          count > 9 ? '9+' : '$count',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: SaharaColors.black,
                                            height: 1,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          )
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? tabs[i].activeIcon : tabs[i].icon,
                              key: ValueKey(isSelected),
                              size: 22,
                              color: isSelected
                                  ? SaharaColors.gold
                                  : SaharaColors.grayText.withValues(alpha: 0.6),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          tabs[i].label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? SaharaColors.gold
                                : SaharaColors.grayText.withValues(alpha: 0.6),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 2,
                          width: isSelected ? 18 : 0,
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

// ── Modelo de tab ─────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

