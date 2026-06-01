import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sahara_club_spa_app/core/app.dart';
import 'package:sahara_club_spa_app/core/locale_cubit.dart';
import 'package:sahara_club_spa_app/core/injection.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

// Credenciales Supabase para el cliente móvil.
//
// La anon_key NO es secreta: Supabase la diseñó para vivir en clientes
// públicos (web, móvil, navegador). Su único rol es identificar el proyecto.
// La seguridad real la enforza RLS sobre cada tabla. La clave que JAMÁS debe
// salir del servidor es service_role_key — esa no aparece en esta app.
//
// Si en el futuro queremos múltiples builds (staging vs prod), entonces sí
// vale la pena moverlas a --dart-define. Hoy con un solo entorno está bien
// hardcoded.
const String _supabaseUrl = 'https://fkbyxhwdcsgrrixalzwf.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NzE3MjYsImV4cCI6MjA5MzE0NzcyNn0.IJ2nDtgBPkbY8CRDmGGJTvE6kELrY0sp3_F9yseZP9Q';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Tap en notificación cuando la app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Tap en notificación cuando la app estaba cerrada (terminated)
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      // Esperar a que el navigator esté listo antes de navegar
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onNotificationTap(initialMsg),
      );
    }
  } catch (e) {
    debugPrint('Firebase no inicializado (falta google-services.json): $e');
  }

  tz.initializeTimeZones();

  await setupInjection();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  final notificationService = NotificationService.instance;
  await notificationService.init();
  notificationService.startInAppNotificationListener();
  notificationService.startBookingNotificationListener();
  notificationService.startCustomNotificationListener();

  // Cada vez que el usuario inicia sesión, guardar su token FCM
  AuthService().onAuthStateChange.listen((data) {
    if (data.session != null) {
      NotificationService.instance.saveTokenForCurrentUser();
    }
  });

  runApp(
    BlocProvider(
      create: (context) => LocaleCubit(),
      child: const SaharaApp(),
    ),
  );
}

// Navega al section adecuado cuando el usuario toca una push notification.
// AuthGate re-evalúa el rol y redirige al shell correcto.
void _onNotificationTap(RemoteMessage message) {
  saharaNavigatorKey.currentState
      ?.pushNamedAndRemoveUntil(AppRoutes.authGate, (_) => false);
}
