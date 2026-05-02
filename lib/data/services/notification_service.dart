import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// Manejador de mensajes en background — debe ser top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? get _fcm {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseMessaging.instance;
  }

  // ── Canales Android ───────────────────────────────────────────────────────

  static const _channelReminders = AndroidNotificationChannel(
    'sahara_reminders',
    'Recordatorios de cita',
    description: 'Avisos de tu próxima cita en Sahara Club Spa',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('alerta_push'),
    enableVibration: true,
  );

  static const _channelChat = AndroidNotificationChannel(
    'sahara_chat',
    'Mensajes',
    description: 'Mensajes y avisos generales de Sahara',
    importance: Importance.defaultImportance,
    sound: RawResourceAndroidNotificationSound('chat_push'),
  );

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Permisos
    await _fcm?.requestPermission(alert: true, badge: true, sound: true);

    // Crear canales Android
    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channelReminders);
    await androidPlugin?.createNotificationChannel(_channelChat);

    // Init local notifications
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _local.initialize(settings);

    // Token inicial
    await _fetchAndSaveToken();

    // Refrescar token cuando cambie
    _fcm?.onTokenRefresh.listen(_saveToken);

    debugPrint('NotificationService: inicializado');
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<void> _fetchAndSaveToken() async {
    try {
      final token = await _fcm?.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('NotificationService: no se pudo obtener token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'user_id':  user.id,
          'token':    token,
          'platform': 'android',
        },
        onConflict: 'user_id, token',
      );
      debugPrint('NotificationService: token guardado');
    } catch (e) {
      debugPrint('NotificationService: error guardando token: $e');
    }
  }

  // Llamado desde AuthService cuando el usuario inicia sesión
  Future<void> saveTokenForCurrentUser() => _fetchAndSaveToken();

  // ── Listeners ─────────────────────────────────────────────────────────────

  // Mensajes cuando la app está en primer plano
  void startInAppNotificationListener() {
    if (Firebase.apps.isEmpty) return;
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('Notificación en foreground: ${msg.notification?.title}');
      _showLocalNotification(msg);
    });
  }

  // Tap en notificación de reserva (app en background o cerrada)
  void startBookingNotificationListener() {
    if (Firebase.apps.isEmpty) return;
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Notificación de reserva abierta: ${msg.data}');
      // La navegación se maneja desde main.dart con el navigatorKey
    });
  }

  // Mensajes personalizados (admin broadcast)
  void startCustomNotificationListener() {
    // Extendible para mensajes de tipo 'custom' del admin
  }

  // ── Mostrar notificación local ─────────────────────────────────────────────

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    final type = message.data['type'] as String? ?? 'reminder';
    final isChat = type == 'chat' || type == 'custom';

    final androidDetails = AndroidNotificationDetails(
      isChat ? 'sahara_chat' : 'sahara_reminders',
      isChat ? 'Mensajes' : 'Recordatorios de cita',
      importance: isChat ? Importance.defaultImportance : Importance.high,
      priority: Priority.high,
      sound: isChat
          ? const RawResourceAndroidNotificationSound('chat_push')
          : const RawResourceAndroidNotificationSound('alerta_push'),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data['booking_id'] as String?,
    );
  }
}
