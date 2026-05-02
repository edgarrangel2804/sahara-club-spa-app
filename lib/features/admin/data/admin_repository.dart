import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SaharaAdminRepository {
  final _db = Supabase.instance.client;

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  double _sumAmount(List<dynamic> list) =>
      list.fold(0.0, (s, e) => s + _toDouble(e['amount']));

  // ── Financial Stats ───────────────────────────────────────────────────────

  Future<Map<String, double>> getFinancialStats() async {
    try {
      final now = DateTime.now();
      final todayUtc = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final weekUtc = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(weekUtc.year, weekUtc.month, weekUtc.day).toUtc().toIso8601String();
      final monthUtc = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

      final results = await Future.wait([
        _db.from('payments').select('amount').gte('created_at', todayUtc),
        _db.from('payments').select('amount').gte('created_at', weekStart),
        _db.from('payments').select('amount').gte('created_at', monthUtc),
        _db.from('expenses').select('amount').gte('date', DateFormat('yyyy-MM-dd').format(now)),
        _db.from('expenses').select('amount').gte('date', DateFormat('yyyy-MM-dd').format(weekUtc)),
        _db.from('expenses').select('amount').gte('date', DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1))),
      ]);

      final rt = _sumAmount(results[0] as List);
      final rw = _sumAmount(results[1] as List);
      final rm = _sumAmount(results[2] as List);
      final et = _sumAmount(results[3] as List);
      final ew = _sumAmount(results[4] as List);
      final em = _sumAmount(results[5] as List);

      return {
        'revenue_today': rt,
        'revenue_week': rw,
        'revenue_month': rm,
        'expenses_today': et,
        'expenses_week': ew,
        'expenses_month': em,
        'profit_today': rt - et,
        'profit_week': rw - ew,
        'profit_month': rm - em,
      };
    } catch (e) {
      debugPrint('AdminRepo.getFinancialStats: $e');
      return {
        'revenue_today': 0, 'revenue_week': 0, 'revenue_month': 0,
        'expenses_today': 0, 'expenses_week': 0, 'expenses_month': 0,
        'profit_today': 0, 'profit_week': 0, 'profit_month': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getRevenueChartData() async {
    try {
      final now = DateTime.now();
      const dayLabels = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
      final values = <double>[];
      final labels = <String>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final start = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
        final end = DateTime(date.year, date.month, date.day).add(const Duration(days: 1)).toUtc().toIso8601String();

        labels.add(dayLabels[DateTime(date.year, date.month, date.day).weekday % 7]);

        final res = await _db.from('payments').select('amount').gte('created_at', start).lt('created_at', end);
        values.add(_sumAmount(res as List));
      }

      return {'values': values, 'labels': labels};
    } catch (_) {
      return {
        'values': List.filled(7, 0.0),
        'labels': ['D', 'L', 'M', 'X', 'J', 'V', 'S'],
      };
    }
  }

  // ── Operational Stats ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOperationalStats() async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final firstOfMonth = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _db.from('appointments').select('id').eq('appointment_date', todayStr),
        _db.from('profiles').select('id').eq('role', 'therapist'),
        _db.from('profiles').select('id, created_at').eq('role', 'client'),
        _db.from('appointments').select('id').eq('appointment_date', todayStr).eq('status', 'cancelled'),
        _db.from('appointments').select('client_profile_id'),
      ]);

      final clients = results[2] as List;
      int newClients = 0;
      for (final c in clients) {
        try {
          if (DateTime.parse(c['created_at'] as String).isAfter(firstOfMonth)) newClients++;
        } catch (_) {}
      }

      final allAppts = results[4] as List;
      final apptCounts = <String, int>{};
      for (final a in allAppts) {
        final pid = a['client_profile_id'] as String?;
        if (pid != null) apptCounts[pid] = (apptCounts[pid] ?? 0) + 1;
      }

      int returning = 0, inactive = 0;
      for (final c in clients) {
        final count = apptCounts[c['id'] as String] ?? 0;
        if (count > 1) { returning++; }
        else if (count == 0) { inactive++; }
      }

      return {
        'appointments_today': (results[0] as List).length,
        'therapists_count': (results[1] as List).length,
        'clients_count': clients.length,
        'new_clients_month': newClients,
        'returning_clients': returning,
        'inactive_clients': inactive,
        'cancelled_today': (results[3] as List).length,
      };
    } catch (e) {
      debugPrint('AdminRepo.getOperationalStats: $e');
      return {
        'appointments_today': 0,
        'therapists_count': 0,
        'clients_count': 0,
        'new_clients_month': 0,
        'returning_clients': 0,
        'inactive_clients': 0,
        'cancelled_today': 0,
      };
    }
  }

  // ── Today Agenda ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTodayAgenda() async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final res = await _db
          .from('appointments')
          .select('*, therapist:therapist_profile_id(full_name), client:client_profile_id(full_name, avatar_url)')
          .eq('appointment_date', todayStr)
          .order('appointment_time');

      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  // ── Service Summary ───────────────────────────────────────────────────────

  Future<Map<String, int>> getServiceSummary() async {
    try {
      final res = await _db.from('appointments').select('status');
      final stats = {'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};
      for (final item in res as List) {
        final s = (item['status'] as String? ?? '').toLowerCase();
        if (stats.containsKey(s)) stats[s] = stats[s]! + 1;
      }
      return stats;
    } catch (_) {
      return {'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  // ── Terapeutas Performance ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTerapeutasPerformance() async {
    try {
      final now = DateTime.now();
      final monthStr = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));

      final res = await _db
          .from('profiles')
          .select('id, full_name, appointments:appointments!therapist_profile_id(id, appointment_date, status)')
          .eq('role', 'therapist');

      return (res as List).map((t) {
        final appts = (t['appointments'] as List? ?? []);
        final thisMonth = appts.where((a) {
          try {
            return (a['appointment_date'] as String).compareTo(monthStr) >= 0;
          } catch (_) {
            return false;
          }
        }).length;
        final completed = appts.where((a) => a['status'] == 'completed').length;

        return {
          'name': t['full_name'] ?? 'Terapeuta',
          'appointments_month': thisMonth,
          'completed': completed,
          'occupancy': thisMonth > 0 ? (thisMonth / 160.0 * 100).clamp(0.0, 100.0) : 0.0,
        };
      }).toList();
    } catch (e) {
      debugPrint('AdminRepo.getTerapeutasPerformance: $e');
      return [];
    }
  }

  // ── All Profiles ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllClients() async {
    try {
      final res = await _db.from('profiles').select().eq('role', 'client').order('full_name');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final res = await _db.from('profiles').select().order('full_name');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _db.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    try {
      final res = await _db
          .from('appointments')
          .select('*, client:client_profile_id(full_name), therapist:therapist_profile_id(full_name)')
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllPayments({DateTime? from, DateTime? to}) async {
    try {
      var q = _db.from('payments').select('*, client:client_id(full_name)');
      if (from != null) q = q.gte('created_at', from.toUtc().toIso8601String());
      if (to != null) q = q.lte('created_at', to.toUtc().toIso8601String());
      final res = await q.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _db.from('appointments').update({'status': status}).eq('id', id);
  }
}
