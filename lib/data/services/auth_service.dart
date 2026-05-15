import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:sahara_club_spa_app/data/models/user_profile.dart';

// Excepción propia de la app — nombre sin conflicto con supabase_flutter
class AppAuthException implements Exception {
  final String message;
  const AppAuthException(this.message);
  @override
  String toString() => message;
}

// Alias para no romper código que ya usa AuthException
typedef AuthException = AppAuthException;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _client = sb.Supabase.instance.client;

  Stream<sb.AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
  sb.User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // ── Sign In ──────────────────────────────────────────────────────────────

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        throw const AppAuthException('No se pudo iniciar sesión.');
      }
      return await _fetchProfile(response.user!.id);
    } on AppAuthException {
      rethrow;
    } on sb.AuthApiException catch (e) {
      throw AppAuthException(_mapError(e.message));
    } on sb.AuthException catch (e) {
      throw AppAuthException(_mapError(e.message));
    } catch (e) {
      debugPrint('AuthService.signIn error: $e');
      throw AppAuthException('Error inesperado. Intenta de nuevo.');
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────

  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      if (response.user == null) {
        throw const AppAuthException('No se pudo crear la cuenta.');
      }

      // Si no hay sesión, Supabase requiere confirmación de correo
      if (response.session == null) {
        throw const AppAuthException(
          'Cuenta creada. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.',
        );
      }

      await _createProfile(
        userId: response.user!.id,
        fullName: fullName.trim(),
      );
      return await _fetchProfile(response.user!.id);
    } on AppAuthException {
      rethrow;
    } on sb.AuthApiException catch (e) {
      throw AppAuthException(_mapError(e.message));
    } on sb.AuthException catch (e) {
      throw AppAuthException(_mapError(e.message));
    } catch (e) {
      debugPrint('AuthService.signUp error: $e');
      throw AppAuthException('Error inesperado al crear cuenta: $e');
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Fetch profile ────────────────────────────────────────────────────────

  Future<UserProfile> _fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromMap(data);
    } catch (e) {
      debugPrint('AuthService._fetchProfile fallback: $e');
      return UserProfile(
        id: userId,
        fullName: currentUser?.userMetadata?['full_name'] as String? ?? '',
        role: UserRole.client,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> _createProfile({
    required String userId,
    required String fullName,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'role': 'client',
        'is_active': true,
      });
    } catch (e) {
      debugPrint('AuthService._createProfile error: $e');
    }
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  Future<void> updateLastSeen() async {
    if (currentUser == null) return;
    try {
      await _client
          .from('profiles')
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('id', currentUser!.id);
    } catch (e) {
      debugPrint('AuthService.updateLastSeen error: $e');
    }
  }

  // ── Reset password ──────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sb.AuthApiException catch (e) {
      throw AppAuthException(_mapError(e.message));
    } on sb.AuthException catch (e) {
      throw AppAuthException(_mapError(e.message));
    } catch (e) {
      debugPrint('AuthService.resetPassword error: $e');
      throw const AppAuthException('Error al enviar el correo. Intenta de nuevo.');
    }
  }

  Future<void> saveDeviceToken([String? token]) async {
    if (currentUser == null || token == null) return;
    try {
      await _client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', currentUser!.id);
    } catch (e) {
      debugPrint('AuthService.saveDeviceToken error: $e');
    }
  }

  String _mapError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('email already') || msg.contains('already registered') || msg.contains('already been registered')) {
      return 'Este correo ya está registrado.';
    }
    if (msg.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (msg.contains('network') || msg.contains('failed to fetch')) {
      return 'Sin conexión. Revisa tu internet.';
    }
    if (msg.contains('rate limit')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    return 'Error: $raw';
  }
}
