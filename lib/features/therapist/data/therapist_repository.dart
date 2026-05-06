import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';

class TherapistRepository {
  final _db = Supabase.instance.client;
  String get _myId => _db.auth.currentUser!.id;

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final data = await _db
          .from('profiles')
          .select('full_name, specialty, avatar_url')
          .eq('id', _myId)
          .single();
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return {'full_name': 'Terapeuta', 'specialty': null, 'avatar_url': null};
    }
  }

  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    try {
      final raw = await _db
          .from('bookings')
          .select('''
            *,
            clients:profiles!bookings_client_id_fkey(full_name),
            therapists:profiles!bookings_therapist_id_fkey(full_name),
            services(name)
          ''')
          .eq('therapist_id', _myId)
          .eq('booking_date', _dateStr(date))
          .neq('status', 'cancelled')
          .order('booking_time');
      return (raw as List).map((m) => Booking.fromMap(m)).toList();
    } catch (e) {
      debugPrint('TherapistRepository.getBookingsForDate error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final raw = await _db
          .from('bookings')
          .select('status')
          .eq('therapist_id', _myId)
          .eq('booking_date', _dateStr(DateTime.now()))
          .neq('status', 'cancelled');
      final list = raw as List;
      return {
        'total':     list.length,
        'completed': list.where((b) => b['status'] == 'completed').length,
        'upcoming':  list.where((b) => b['status'] != 'completed').length,
      };
    } catch (_) {
      return {'total': 0, 'completed': 0, 'upcoming': 0};
    }
  }

  Future<void> markCompleted(String bookingId) async {
    await _db.from('bookings').update({
      'status':     'completed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
