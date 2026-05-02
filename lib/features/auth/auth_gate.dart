import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/data/models/user_profile.dart';

/// Se monta una sola vez al arrancar la app (después del splash).
/// Escucha el stream de auth y redirige según sesión + rol.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final auth = AuthService();

    if (!auth.isLoggedIn) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // Hay sesión activa: busca el perfil para leer el rol
    try {
      final profile = await _fetchProfile(auth.currentUser!.id);
      if (!mounted) return;
      _routeByRole(profile.role);
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromMap(data);
  }

  void _routeByRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      case UserRole.therapist:
        Navigator.pushReplacementNamed(context, AppRoutes.therapistDashboard);
      case UserRole.receptionist:
        Navigator.pushReplacementNamed(context, AppRoutes.receptionDashboard);
      case UserRole.client:
        Navigator.pushReplacementNamed(context, AppRoutes.services);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0B0B),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC6A76A),
          strokeWidth: 1.5,
        ),
      ),
    );
  }
}
