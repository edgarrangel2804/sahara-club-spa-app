import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sahara_club_spa_app/core/app.dart';
import 'package:sahara_club_spa_app/core/locale_cubit.dart';
import 'package:sahara_club_spa_app/core/injection.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

const String _supabaseUrl = 'https://fkbyxhwdcsgrrixalzwf.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NzE3MjYsImV4cCI6MjA5MzE0NzcyNn0.IJ2nDtgBPkbY8CRDmGGJTvE6kELrY0sp3_F9yseZP9Q';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
