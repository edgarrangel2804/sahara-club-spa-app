import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/user_profile.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 800), _navigate);
      }
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // Supabase v2 restaura la sesión de forma asíncrona.
    // Si currentUser es null al arrancar, esperamos el primer evento de auth.
    var user = AuthService().currentUser;
    if (user == null) {
      try {
        final event = await Supabase.instance.client.auth.onAuthStateChange
            .first
            .timeout(const Duration(seconds: 4));
        user = event.session?.user;
      } catch (_) {}
    }

    if (!mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    // Hay sesión: buscamos el rol en profiles.
    // Si falla (sin internet, RLS, etc.) mandamos a servicios de cliente
    // en lugar de lanzar al login — el usuario ya está autenticado.
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      final role = UserRoleX.fromString(data['role'] as String?);
      switch (role) {
        case UserRole.admin:
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
        case UserRole.therapist:
          Navigator.of(context).pushReplacementNamed(AppRoutes.therapistDashboard);
        case UserRole.receptionist:
          Navigator.of(context).pushReplacementNamed(AppRoutes.receptionDashboard);
        case UserRole.client:
          Navigator.of(context).pushReplacementNamed(AppRoutes.services);
      }
    } catch (_) {
      // No se pudo leer el perfil pero el usuario SÍ está logueado.
      // Mostramos la pantalla de cliente como fallback seguro.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.services);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/flasch_screen_02.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: SaharaColors.black),
          ),
        ),
      ),
    );
  }
}
