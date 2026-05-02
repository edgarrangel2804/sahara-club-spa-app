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
      final total = list.length;
      final confirmed = list.where((b) => b['status'] == 'confirmed').length;
      final completed = list.where((b) => b['status'] == 'completed').length;
      final pending   = list.where((b) => b['status'] == 'scheduled').length;
      final cancelled = list.where((b) => b['status'] == 'cancelled').length;
      final revenue   = list
          .where((b) => b['status'] == 'completed')
          .fold<double>(0, (s, b) => s + ((b['price'] as num?)?.toDouble() ?? 0));

      return {
        'total': total,
        'confirmed': confirmed,
        'completed': completed,
        'pending': pending,
        'cancelled': cancelled,
        'revenue': revenue,
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
    } catch (_) {
      return [];
    }
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _db.from('bookings').update({
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
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
  }

  // ── Solicitudes pendientes ────────────────────────────────────────────────

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
          .eq('is_active', true)
          .order('full_name');

      final raw = await query;
      final list = raw as List<dynamic>;

      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        return list
            .cast<Map<String, dynamic>>()
            .where((c) =>
                (c['full_name'] as String? ?? '').toLowerCase().contains(q) ||
                (c['phone'] as String? ?? '').contains(q))
            .toList();
      }
      return list.cast<Map<String, dynamic>>();
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

  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final raw = await _db
          .from('services')
          .select('id, name, category, duration_min, price')
          .eq('is_active', true)
          .order('display_order');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _today() => _dateStr(DateTime.now());
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
