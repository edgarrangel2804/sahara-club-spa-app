import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/features/admin/pages/permisos_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/servicios_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/equipo_page.dart';

class AdminConfigScreen extends StatelessWidget {
  const AdminConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIGURACIÓN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SaharaColors.grayText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _section('CUENTA', [
            _tile(Icons.person_outline, 'Mi perfil', () {}),
            _tile(Icons.lock_outline, 'Cambiar contraseña', () {}),
            _tile(Icons.notifications_outlined, 'Notificaciones', () {}),
          ]),
          const SizedBox(height: 16),
          _section('NEGOCIO', [
            _tile(Icons.spa_outlined, 'Gestionar servicios', () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminServiciosPage()))),
            _tile(Icons.people_outline, 'Equipo de trabajo', () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminEquipoPage()))),
            _tile(Icons.schedule_outlined, 'Horarios', () {}),
            _tile(Icons.manage_accounts_outlined, 'Permisos', () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminPermisosPage()))),
            _tile(Icons.bar_chart_outlined, 'Reportes', () {}),
          ]),
          const SizedBox(height: 16),
          _section('SISTEMA', [
            _tile(Icons.info_outline, 'Acerca de Sahara Club', () {}),
            _tile(Icons.help_outline, 'Soporte', () {}),
          ]),
          const SizedBox(height: 24),
          _logoutButton(context),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SaharaColors.grayText, letterSpacing: 1.2),
            ),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: SaharaColors.gold, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(color: SaharaColors.whiteSoft, fontSize: 14))),
            const Icon(Icons.chevron_right, color: SaharaColors.grayText, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Text(
              'Cerrar sesión',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
