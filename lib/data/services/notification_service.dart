import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// Manejador de mensajes en background — debe ser top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Evitar duplicados: Si trae bloque notification, Android lo muestra automáticamente.
  // Solo mostramos notificación local manual si es un mensaje de tipo 'data-only'.
  if (message.notification == null) {
    await NotificationService._showLocalNotification(message);
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? get _fcm {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseMessaging.instance;
  }

  // ── Notificaciones visuales (UI) ──────────────────────────────────────────
  final unreadChatNotifier = ValueNotifier<bool>(false);

  void markChatAsRead() {
    unreadChatNotifier.value = false;
  }

  // ID del chat que el usuario está viendo actualmente.
  // Se actualiza desde las páginas de chat al abrirse y cerrarse.
  String? _activeChatId;

  void enterChat(String chatId) => _activeChatId = chatId;
  void leaveChat() => _activeChatId = null;

  // ── Canales Android ───────────────────────────────────────────────────────

  static const _chReminders = AndroidNotificationChannel(
    'sahara_reminders_v3',
    'Recordatorios de cita',
    description: 'Avisos de tu próxima cita en Sahara Club Spa',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('alerta_push'),
    enableVibration: true,
  );

  static const _chChat = AndroidNotificationChannel(
    'sahara_chat_v3',
    'Mensajes internos',
    description: 'Mensajes del equipo Sahara Club Spa',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('chat_push'),
    enableVibration: true,
  );

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _fcm?.requestPermission(alert: true, badge: true, sound: true);

    // initialize() primero — necesario antes de crear canales
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _local.initialize(settings);

    // Limpiar canales viejos y crear v3 con los sonidos correctos.
    // Android cachea la configuración de canal; usar un ID nuevo garantiza
    // que el sonido se aplica sin importar el historial del dispositivo.
    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final id in [
      'sahara_reminders',
      'sahara_chat',
      'sahara_reminders_v2',
      'sahara_chat_v2',
    ]) {
      await androidPlugin?.deleteNotificationChannel(id);
    }
    await androidPlugin?.createNotificationChannel(_chReminders);
    await androidPlugin?.createNotificationChannel(_chChat);

    await _fetchAndSaveToken();
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
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      await Supabase.instance.client.from('device_tokens').upsert(
        {'user_id': user.id, 'token': token, 'platform': 'android'},
        onConflict: 'user_id, token',
      );
      debugPrint('NotificationService: token guardado');
    } catch (e) {
      debugPrint('NotificationService: error guardando token: $e');
    }
  }

  // Llamado desde AuthService cuando el usuario inicia sesión.
  Future<void> saveTokenForCurrentUser() async {
    // No llamamos deleteToken() — FCM invalida el token viejo automáticamente al reinstalar
    // y llamarlo solo alarga la ventana en que la DB tiene un token obsoleto.
    await _fetchAndSaveToken();
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void startInAppNotificationListener() {
    if (Firebase.apps.isEmpty) return;
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('Notificación en foreground: ${msg.notification?.title}');
      final type   = msg.data['type']    as String? ?? 'reminder';
      final chatId = msg.data['chat_id'] as String?;

      if (type == 'chat' || type == 'custom') {
        unreadChatNotifier.value = true;
      }

      // Si el usuario ya está viendo ese chat, usar sonido de chat; si no, alerta.
      final inActiveChat = type == 'chat' && chatId != null && chatId == _activeChatId;
      _showLocalNotification(msg, inActiveChat: inActiveChat);
    });
  }

  void startBookingNotificationListener() {
    if (Firebase.apps.isEmpty) return;
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Notificación de reserva abierta: ${msg.data}');
    });
  }

  void startCustomNotificationListener() {
    // Extendible para mensajes de tipo 'custom' del admin
  }

  // ── Mostrar notificación local ─────────────────────────────────────────────

  static Future<void> _showLocalNotification(
    RemoteMessage message, {
    bool inActiveChat = false,
  }) async {
    final n = message.notification;
    if (n == null) return;

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));

    // inActiveChat = true  → ambos en el chat, sonido sutil de chat
    // inActiveChat = false → mensaje nuevo, reserva, o cualquier alerta → alerta_push
    final androidDetails = AndroidNotificationDetails(
      inActiveChat ? 'sahara_chat_v3' : 'sahara_reminders_v3',
      inActiveChat ? 'Mensajes' : 'Recordatorios de cita',
      importance: Importance.high,
      priority: Priority.high,
      sound: inActiveChat
          ? const RawResourceAndroidNotificationSound('chat_push')
          : const RawResourceAndroidNotificationSound('alerta_push'),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await plugin.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data['booking_id'] as String?,
    );
  }
}
