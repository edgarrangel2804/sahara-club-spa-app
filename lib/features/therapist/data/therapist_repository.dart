import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';

class TherapistRepository {
  final _db = Supabase.instance.client;
  String get _myId => _db.auth.currentUser!.id;
  String get myId  => _myId;

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

  // ── Clientes ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyClients() async {
    try {
      final raw = await _db
          .from('bookings')
          .select('client_id, booking_date, services(name), clients:profiles!bookings_client_id_fkey(full_name)')
          .eq('therapist_id', _myId)
          .neq('status', 'cancelled')
          .order('booking_date', ascending: false);

      final map = <String, Map<String, dynamic>>{};
      for (final b in (raw as List)) {
        final cid  = b['client_id'] as String?;
        if (cid == null) continue;
        final name = (b['clients'] as Map?)?['full_name'] as String? ?? 'Cliente';
        final date = b['booking_date'] as String? ?? '';
        final svc  = (b['services'] as Map?)?['name'] as String?;

        final entry = map.putIfAbsent(cid, () => {
          'id': cid, 'name': name, 'sessions': 0,
          'last_visit': date, 'services': <String>[],
        });
        entry['sessions'] = (entry['sessions'] as int) + 1;
        if (svc != null) (entry['services'] as List<String>).add(svc);
        if (date.compareTo(entry['last_visit'] as String) > 0) {
          entry['last_visit'] = date;
        }
      }
      return map.values.toList()
        ..sort((a, b) => (b['last_visit'] as String).compareTo(a['last_visit'] as String));
    } catch (e) {
      debugPrint('TherapistRepository.getMyClients: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClientHistory(String clientId) async {
    try {
      final raw = await _db
          .from('bookings')
          .select('id, booking_date, booking_time, status, price, services(name), session_notes')
          .eq('therapist_id', _myId)
          .eq('client_id', clientId)
          .order('booking_date', ascending: false);
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('TherapistRepository.getClientHistory: $e');
      return [];
    }
  }

  // ── Mensajes ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStaffContacts() async {
    try {
      final raw = await _db
          .from('profiles')
          .select('id, full_name, role, specialty, avatar_url')
          .inFilter('role', ['admin', 'receptionist'])
          .eq('is_active', true)
          .order('full_name');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('TherapistRepository.getStaffContacts: $e');
      return [];
    }
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    final existing = await _db
        .from('chats')
        .select('id')
        .or('and(participant_1.eq.$_myId,participant_2.eq.$otherUserId),'
            'and(participant_1.eq.$otherUserId,participant_2.eq.$_myId)')
        .maybeSingle();
    if (existing != null) return existing['id'] as String;
    final created = await _db
        .from('chats')
        .insert({'participant_1': _myId, 'participant_2': otherUserId})
        .select('id')
        .single();
    return created['id'] as String;
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String chatId, {int limit = 10}) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((list) => list.cast<Map<String, dynamic>>());
  }

  Future<void> sendMessage(String chatId, String content) async {
    await _db.from('messages').insert({
      'chat_id':   chatId,
      'sender_id': _myId,
      'content':   content,
    });
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
