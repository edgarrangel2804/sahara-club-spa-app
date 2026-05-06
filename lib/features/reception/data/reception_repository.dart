import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';

class ReceptionRepository {
  final _db = Supabase.instance.client;

  // ── Estadísticas del día ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTodayStats() async {
    final today = _today();
    try {
      final bookings = await _db
          .from('bookings')
          .select('status, price')
          .eq('booking_date', today);

      final list = bookings as List;
      final total     = list.length;
      final confirmed = list.where((b) => b['status'] == 'confirmed').length;
      final completed = list.where((b) => b['status'] == 'completed').length;
      final pending   = list.where((b) => b['status'] == 'scheduled').length;
      final cancelled = list.where((b) => b['status'] == 'cancelled').length;
      final revenue   = list
          .where((b) => b['status'] == 'completed')
          .fold<double>(0, (s, b) => s + ((b['price'] as num?)?.toDouble() ?? 0));

      return {
        'total': total, 'confirmed': confirmed, 'completed': completed,
        'pending': pending, 'cancelled': cancelled, 'revenue': revenue,
      };
    } catch (_) {
      return {'total': 0, 'confirmed': 0, 'completed': 0, 'pending': 0, 'cancelled': 0, 'revenue': 0.0};
    }
  }

  // ── Citas ─────────────────────────────────────────────────────────────────

  Future<List<Booking>> getBookingsByDate(DateTime date) async {
    try {
      final raw = await _db
          .from('bookings')
          .select('''
            *,
            clients:profiles!bookings_client_id_fkey(full_name),
            therapists:profiles!bookings_therapist_id_fkey(full_name),
            services(name)
          ''')
          .eq('booking_date', _dateStr(date))
          .order('booking_time');
      return (raw as List).map((m) => Booking.fromMap(m)).toList();
    } catch (e) {
      debugPrint('ReceptionRepository.getBookingsByDate error: $e');
      return [];
    }
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _db.from('bookings').update({
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    if (status == BookingStatus.confirmed) {
      await notifyBookingConfirmed(id);
    }
  }

  Future<void> assignBooking({
    required String bookingId,
    required String therapistId,
    required DateTime date,
    required String time,
  }) async {
    try {
      await _db.from('bookings').update({
        'therapist_id': therapistId,
        'booking_date': _dateStr(date),
        'booking_time': time,
        'status':       'confirmed',
        'updated_at':   DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      await notifyBookingConfirmed(bookingId);
    } catch (e) {
      debugPrint('ReceptionRepository.assignBooking error: $e');
      rethrow;
    }
  }

  // Llama a la edge function que envía push al cliente confirmando su cita
  Future<void> notifyBookingConfirmed(String bookingId) async {
    try {
      await _db.functions.invoke(
        'notify-booking-event',
        body: {'type': 'booking_confirmed', 'booking_id': bookingId},
      );
    } catch (e) {
      debugPrint('ReceptionRepository.notifyBookingConfirmed error: $e');
      // No-fatal: no relanzar, la cita ya fue confirmada
    }
  }

  Future<void> rescheduleBooking(String id, DateTime newDate, String newTime) async {
    try {
      await _db.from('bookings').update({
        'booking_date': _dateStr(newDate),
        'booking_time': newTime,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('ReceptionRepository.rescheduleBooking error: $e');
      rethrow;
    }
  }

  Future<void> chargeBooking(Booking b, String paymentMethod) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _db.from('payments').insert({
        'booking_id':     b.id,
        'client_id':      b.clientId,
        'amount':         b.price,
        'payment_method': paymentMethod,
        'status':         'completed',
        'created_by':     userId,
      });
    } catch (e) {
      debugPrint('chargeBooking: payments insert error (non-fatal): $e');
    }

    await updateBookingStatus(b.id, BookingStatus.completed);
  }

  Future<void> createBooking({
    required String clientId,
    required String? therapistId,
    required String serviceId,
    required DateTime date,
    required String time,
    required int durationMin,
    required double price,
    String? cabin,
    String? clientNotes,
    required String createdBy,
  }) async {
    try {
      await _db.from('bookings').insert({
        'client_id':    clientId,
        'therapist_id': therapistId,
        'service_id':   serviceId,
        'booking_date': _dateStr(date),
        'booking_time': time,
        'duration_min': durationMin,
        'price':        price,
        'status':       'scheduled',
        'cabin':        cabin,
        'client_notes': clientNotes,
        'created_by':   createdBy,
      });
    } catch (e) {
      debugPrint('ReceptionRepository.createBooking error: $e');
      rethrow;
    }
  }

  // ── Solicitudes pendientes ────────────────────────────────────────────────

  // Busca cualquier cita existente del cliente en esa fecha (no cancelada, sin
  // importar status). La comparación de hora se hace en Dart para evitar
  // problemas de casting con columnas time en PostgREST.
  Future<bool> isTherapistAvailable(
      String therapistId, DateTime date, String time,
      {String? excludeBookingId}) async {
    try {
      final rows = await _db
          .from('bookings')
          .select('id, booking_time')
          .eq('therapist_id', therapistId)
          .eq('booking_date', _dateStr(date))
          .neq('status', 'cancelled')
          .neq('status', 'completed');
      final prefix = time.substring(0, 5);
      final conflicts = (rows as List).where((r) {
        if (excludeBookingId != null && r['id'] == excludeBookingId) return false;
        return (r['booking_time'] as String?)?.startsWith(prefix) == true;
      }).toList();
      return conflicts.isEmpty;
    } catch (_) {
      return true;
    }
  }

  Future<String?> findExistingBookingId(
      String clientId, DateTime date, String time) async {
    try {
      final rows = await _db
          .from('bookings')
          .select('id, booking_time')
          .eq('client_id', clientId)
          .eq('booking_date', _dateStr(date))
          .neq('status', 'cancelled');
      final list = rows as List;
      final prefix = time.substring(0, 5);
      final match = list.where((r) =>
          (r['booking_time'] as String?)?.startsWith(prefix) == true).toList();
      if (match.isEmpty) return null;
      return match.first['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Booking>> getPendingRequests() async {
    try {
      final raw = await _db
          .from('bookings')
          .select('''
            *,
            clients:profiles!bookings_client_id_fkey(full_name),
            therapists:profiles!bookings_therapist_id_fkey(full_name),
            services(name)
          ''')
          .eq('status', 'scheduled')
          .order('booking_date')
          .order('booking_time');
      return (raw as List).map((m) => Booking.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Clientes ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getClients({String? search}) async {
    try {
      var query = _db
          .from('profiles')
          .select('id, full_name, phone, created_at, is_active')
          .eq('role', 'client')
          .eq('is_active', true);

      if (search != null && search.isNotEmpty) {
        query = query.ilike('full_name', '%$search%');
      }

      final raw = await query.order('full_name');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Terapeutas ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTherapists() async {
    try {
      final raw = await _db
          .from('profiles')
          .select('id, full_name, specialty')
          .eq('role', 'therapist')
          .eq('is_active', true)
          .order('full_name');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Servicios ─────────────────────────────────────────────────────────────
  // Intenta primero la tabla `services` (referenciada por bookings.service_id FK).
  // Si falla, cae a `products` con type='service' como fallback.

  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final raw = await _db
          .from('services')
          .select('id, name, category, duration_min, price')
          .eq('is_active', true)
          .order('category')
          .order('name');
      return (raw as List).map((s) {
        final m = Map<String, dynamic>.from(s as Map);
        // Normaliza: el resto del código espera la clave 'duration'
        m['duration'] = (m['duration_min'] as int?) ?? 60;
        return m;
      }).toList();
    } catch (e) {
      debugPrint('ReceptionRepository.getServices (services) error: $e');
      // Fallback: tabla products con type='service'
      try {
        final raw = await _db
            .from('products')
            .select('id, name, category, duration, price')
            .eq('type', 'service')
            .eq('active', true)
            .order('display_order');
        return (raw as List).cast<Map<String, dynamic>>();
      } catch (e2) {
        debugPrint('ReceptionRepository.getServices (products fallback) error: $e2');
        return [];
      }
    }
  }

  // ── Historial de cliente ──────────────────────────────────────────────────

  Future<List<Booking>> getClientBookingHistory(String clientId) async {
    try {
      final raw = await _db
          .from('bookings')
          .select('''
            *,
            clients:profiles!bookings_client_id_fkey(full_name),
            therapists:profiles!bookings_therapist_id_fkey(full_name),
            services(name)
          ''')
          .eq('client_id', clientId)
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false)
          .limit(20);
      return (raw as List).map((m) => Booking.fromMap(m)).toList();
    } catch (e) {
      debugPrint('ReceptionRepository.getClientBookingHistory error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createClient({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final result = await _db.functions.invoke(
      'create-reception-client',
      body: {
        'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
    if (result.data == null) throw Exception('No se pudo crear el cliente');
    final data = result.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error']);
    return data['client'] as Map<String, dynamic>;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _today() => _dateStr(DateTime.now());
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
