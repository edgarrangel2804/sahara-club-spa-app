import 'package:flutter/material.dart';
import 'package:sahara_club_spa_app/features/splash/splash_screen.dart';
import 'package:sahara_club_spa_app/features/auth/auth_gate.dart';
import 'package:sahara_club_spa_app/features/auth/screens/login_screen.dart';
import 'package:sahara_club_spa_app/features/auth/screens/register_screen.dart';
import 'package:sahara_club_spa_app/features/client/client_shell.dart';
import 'package:sahara_club_spa_app/features/services/screens/service_detail_screen.dart';
import 'package:sahara_club_spa_app/features/bookings/screens/booking_request_screen.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';
import 'package:sahara_club_spa_app/features/admin/admin_dashboard_page.dart';
import 'package:sahara_club_spa_app/features/reception/reception_shell.dart';
import 'package:sahara_club_spa_app/features/therapist/therapist_shell.dart';

class AppRoutes {
  static const String splash          = '/';
  static const String authGate        = '/auth-gate';
  static const String login           = '/login';
  static const String register        = '/register';
  static const String services        = '/services';
  static const String serviceDetail    = '/service-detail';
  static const String bookingRequest   = '/booking-request';
  static const String adminDashboard   = '/admin';
  static const String therapistDashboard   = '/terapeuta';
  static const String receptionDashboard   = '/recepcion';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _fade(const SplashScreen());

    case AppRoutes.authGate:
      return _fade(const AuthGate());

    case AppRoutes.login:
      return _fade(const LoginScreen());

    case AppRoutes.register:
      return _fade(const RegisterScreen());

    case AppRoutes.services:
      return _fade(const ClientShell());

    case AppRoutes.serviceDetail:
      final service = settings.arguments as SpaService;
      return MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service));

    case AppRoutes.bookingRequest:
      final service = settings.arguments as SpaService;
      return MaterialPageRoute(builder: (_) => BookingRequestScreen(service: service));

    case AppRoutes.adminDashboard:
      return _fade(const AdminDashboardPage());

    case AppRoutes.therapistDashboard:
      return _fade(const TherapistShell());

    case AppRoutes.receptionDashboard:
      return _fade(const ReceptionShell());

    default:
      return _fade(const SplashScreen());
  }
}

PageRouteBuilder<dynamic> _fade(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 900),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
