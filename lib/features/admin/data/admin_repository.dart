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
        _db.from('expenses').select('amount').gte('expense_date', DateFormat('yyyy-MM-dd').format(now)),
        _db.from('expenses').select('amount').gte('expense_date', DateFormat('yyyy-MM-dd').format(weekUtc)),
        _db.from('expenses').select('amount').gte('expense_date', DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1))),
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

  // ── Services CRUD ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCatalogServices() async {
    try {
      final res = await _db.from('services').select().order('display_order').order('name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminRepo.getCatalogServices: $e');
      return [];
    }
  }

  Future<void> createService(Map<String, dynamic> data) async {
    await _db.from('services').insert(data);
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _db.from('services').update(data).eq('id', id);
  }

  // ── Therapists CRUD ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCatalogTherapists() async {
    try {
      final res = await _db
          .from('profiles')
          .select('id, full_name, specialty, commission_pct, bio, is_active, phone')
          .eq('role', 'therapist')
          .order('full_name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminRepo.getCatalogTherapists: $e');
      return [];
    }
  }

  Future<void> updateTherapist(String id, Map<String, dynamic> data) async {
    await _db.from('profiles').update(data).eq('id', id);
  }

  // ── Permisos ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReceptionists() async {
    try {
      final raw = await _db
          .from('profiles')
          .select('id, full_name, phone, permissions')
          .eq('role', 'receptionist')
          .eq('is_active', true)
          .order('full_name');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminRepo.getReceptionists: $e');
      return [];
    }
  }

  Future<void> updatePermissions(String userId, List<String> permissions) async {
    await _db.from('profiles').update({'permissions': permissions}).eq('id', userId);
  }

  // ── Balance General ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBalanceData(DateTime month) async {
    try {
      final start    = DateTime(month.year, month.month, 1);
      final end      = DateTime(month.year, month.month + 1, 1);
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr   = DateFormat('yyyy-MM-dd').format(end);
      final startUtc = start.toUtc().toIso8601String();
      final endUtc   = end.toUtc().toIso8601String();

      final results = await Future.wait([
        _db.from('payments')
            .select('amount, payment_method')
            .gte('created_at', startUtc)
            .lt('created_at', endUtc),
        _db.from('expenses')
            .select('amount, category')
            .gte('expense_date', startStr)
            .lt('expense_date', endStr),
        _db.from('bookings')
            .select('price, therapists:staff!bookings_therapist_id_fkey(full_name)')
            .gte('booking_date', startStr)
            .lt('booking_date', endStr)
            .eq('status', 'completed'),
      ]);

      final payments = (results[0] as List).cast<Map<String, dynamic>>();
      final expenses = (results[1] as List).cast<Map<String, dynamic>>();
      final bookings = (results[2] as List).cast<Map<String, dynamic>>();

      final revenue   = payments.fold<double>(0, (s, p) => s + _toDouble(p['amount']));
      final cashIn    = payments.where((p) => p['payment_method'] == 'cash')
          .fold<double>(0, (s, p) => s + _toDouble(p['amount']));
      final pettyCash = expenses.where((e) => e['category'] == 'petty_cash')
          .fold<double>(0, (s, e) => s + _toDouble(e['amount']));
      final fixed     = expenses.where((e) => e['category'] == 'fixed')
          .fold<double>(0, (s, e) => s + _toDouble(e['amount']));
      final other     = expenses.where((e) => e['category'] == 'other')
          .fold<double>(0, (s, e) => s + _toDouble(e['amount']));
      final totalExp  = pettyCash + fixed + other;

      double commissions = 0;
      for (final b in bookings) {
        final pct = _toDouble((b['therapists'] as Map?)?['commission_pct'] ?? 20.0);
        commissions += _toDouble(b['price']) * pct / 100;
      }

      return {
        'revenue':       revenue,
        'cash_in':       cashIn,
        'petty_cash':    pettyCash,
        'fixed':         fixed,
        'other':         other,
        'total_expenses': totalExp,
        'commissions':   commissions,
        'profit':        revenue - totalExp,
        'net_to_owner':  revenue - totalExp - commissions,
        'cash_position': cashIn - pettyCash,
      };
    } catch (e) {
      debugPrint('AdminRepo.getBalanceData: $e');
      return {
        'revenue': 0.0, 'cash_in': 0.0, 'petty_cash': 0.0, 'fixed': 0.0,
        'other': 0.0, 'total_expenses': 0.0, 'commissions': 0.0,
        'profit': 0.0, 'net_to_owner': 0.0, 'cash_position': 0.0,
      };
    }
  }

  // ── Executive Dashboard ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getExecutiveDashboard(DateTime month) async {
    try {
      final start    = DateTime(month.year, month.month, 1);
      final end      = DateTime(month.year, month.month + 1, 1);
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr   = DateFormat('yyyy-MM-dd').format(end);
      final startUtc = start.toUtc().toIso8601String();
      final endUtc   = end.toUtc().toIso8601String();

      final results = await Future.wait([
        _db.from('payments')
            .select('amount, payment_method')
            .gte('created_at', startUtc)
            .lt('created_at', endUtc),
        _db.from('expenses')
            .select('amount, category')
            .gte('expense_date', startStr)
            .lt('expense_date', endStr),
        _db.from('bookings')
            .select('booking_time, status')
            .gte('booking_date', startStr)
            .lt('booking_date', endStr),
        _db.from('payments')
            .select('amount, created_at')
            .gte('created_at', startUtc)
            .lt('created_at', endUtc),
      ]);

      final payments   = (results[0] as List).cast<Map<String, dynamic>>();
      final expenses   = (results[1] as List).cast<Map<String, dynamic>>();
      final bookings   = (results[2] as List).cast<Map<String, dynamic>>();
      final paymentsTs = (results[3] as List).cast<Map<String, dynamic>>();

      final revenue       = payments.fold<double>(0, (s, p) => s + _toDouble(p['amount']));
      final totalExpenses = expenses.fold<double>(0, (s, e) => s + _toDouble(e['amount']));
      final avgTicket     = payments.isEmpty ? 0.0 : revenue / payments.length;

      final revenueByMethod = <String, double>{};
      for (final p in payments) {
        final m = (p['payment_method'] as String?) ?? 'other';
        revenueByMethod[m] = (revenueByMethod[m] ?? 0) + _toDouble(p['amount']);
      }

      final totalBookings = bookings.length;
      final cancelled     = bookings.where((b) => b['status'] == 'cancelled').length;
      final cancelRate    = totalBookings > 0 ? cancelled / totalBookings * 100 : 0.0;

      final peakHours = <int, int>{};
      for (final b in bookings) {
        if (b['status'] == 'cancelled') continue;
        final t = b['booking_time'] as String? ?? '';
        if (t.length >= 2) {
          final h = int.tryParse(t.substring(0, 2));
          if (h != null) peakHours[h] = (peakHours[h] ?? 0) + 1;
        }
      }

      final daysInMonth  = end.difference(start).inDays;
      final dailyRevenue = List<double>.filled(daysInMonth, 0);
      for (final p in paymentsTs) {
        final raw = p['created_at'] as String?;
        if (raw == null) continue;
        try {
          final d = DateTime.parse(raw).toLocal();
          final idx = d.day - 1;
          if (idx >= 0 && idx < daysInMonth) dailyRevenue[idx] += _toDouble(p['amount']);
        } catch (_) {}
      }

      return {
        'revenue':           revenue,
        'expenses':          totalExpenses,
        'profit':            revenue - totalExpenses,
        'avg_ticket':        avgTicket,
        'cancel_rate':       cancelRate,
        'revenue_by_method': revenueByMethod,
        'peak_hours':        peakHours,
        'daily_revenue':     dailyRevenue,
        'payments_count':    payments.length,
        'bookings_count':    totalBookings,
        'cancelled_count':   cancelled,
      };
    } catch (e) {
      debugPrint('AdminRepo.getExecutiveDashboard: $e');
      return {
        'revenue': 0.0, 'expenses': 0.0, 'profit': 0.0,
        'avg_ticket': 0.0, 'cancel_rate': 0.0,
        'revenue_by_method': <String, double>{},
        'peak_hours': <int, int>{},
        'daily_revenue': <double>[],
        'payments_count': 0, 'bookings_count': 0, 'cancelled_count': 0,
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
        _db.from('bookings').select('id').eq('booking_date', todayStr),
        _db.from('profiles').select('id').eq('role', 'therapist').not('is_active', 'eq', false),
        _db.from('profiles').select('id, created_at').eq('role', 'client'),
        _db.from('bookings').select('id').eq('booking_date', todayStr).eq('status', 'cancelled'),
        _db.from('bookings').select('client_id'),
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
        final pid = a['client_id'] as String?;
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
          .from('bookings')
          .select('''
            *,
            therapists:staff!bookings_therapist_id_fkey(full_name),
            clients:profiles!bookings_client_id_fkey(full_name)
          ''')
          .eq('booking_date', todayStr)
          .order('booking_time');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  // ── Service Summary ───────────────────────────────────────────────────────

  Future<Map<String, int>> getServiceSummary() async {
    try {
      final res = await _db.from('bookings').select('status');
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

  // ── Terapeutas Detalle (Phase 4) ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTerapeutasDetalle(DateTime month) async {
    try {
      final start    = DateTime(month.year, month.month, 1);
      final end      = DateTime(month.year, month.month + 1, 1);
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr   = DateFormat('yyyy-MM-dd').format(end);

      final results = await Future.wait([
        _db.from('profiles')
            .select('id, full_name, specialty, commission_pct')
            .eq('role', 'therapist')
            .eq('is_active', true)
            .order('full_name'),
        _db.from('bookings')
            .select('therapist_id, price, services(name)')
            .gte('booking_date', startStr)
            .lt('booking_date', endStr)
            .eq('status', 'completed'),
      ]);

      final therapists = (results[0] as List).cast<Map<String, dynamic>>();
      final bookings   = (results[1] as List).cast<Map<String, dynamic>>();

      // Aggregate per therapist
      final byId = <String, Map<String, dynamic>>{};
      for (final b in bookings) {
        final tid = b['therapist_id'] as String?;
        if (tid == null) continue;
        final entry = byId.putIfAbsent(tid, () => {
          'count': 0, 'revenue': 0.0, 'services': <String>[],
        });
        entry['count']   = (entry['count'] as int) + 1;
        entry['revenue'] = (entry['revenue'] as double) + _toDouble(b['price']);
        final svc = (b['services'] as Map?)?['name'] as String?;
        if (svc != null) (entry['services'] as List<String>).add(svc);
      }

      return therapists.map((t) {
        final id      = t['id'] as String;
        final stats   = byId[id] ?? {'count': 0, 'revenue': 0.0, 'services': <String>[]};
        final commPct = _toDouble(t['commission_pct'] ?? 20.0);
        final revenue = stats['revenue'] as double;
        final count   = stats['count'] as int;

        final svcList  = stats['services'] as List<String>;
        final svcCount = <String, int>{};
        for (final s in svcList) { svcCount[s] = (svcCount[s] ?? 0) + 1; }
        final topSvcs = (svcCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .map((e) => {'name': e.key, 'count': e.value})
            .toList();

        return {
          'id':             id,
          'name':           t['full_name'] as String? ?? 'Terapeuta',
          'specialty':      t['specialty'] as String?,
          'services_count': count,
          'revenue':        revenue,
          'commission_pct': commPct,
          'commission':     revenue * commPct / 100,
          'occupancy':      (count / 30.0 * 100).clamp(0.0, 100.0),
          'top_services':   topSvcs,
        };
      }).toList();
    } catch (e) {
      debugPrint('AdminRepo.getTerapeutasDetalle: $e');
      return [];
    }
  }

  // ── Terapeutas Performance ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTerapeutasPerformance() async {
    try {
      final now = DateTime.now();
      final monthStr = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));

      final res = await _db
          .from('profiles')
          .select('id, full_name, bookings:bookings!bookings_therapist_id_fkey(id, booking_date, status)')
          .eq('role', 'therapist');

      return (res as List).map((t) {
        final appts = (t['bookings'] as List? ?? []);
        final thisMonth = appts.where((a) {
          try {
            return (a['booking_date'] as String).compareTo(monthStr) >= 0;
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
          .from('bookings')
          .select('''
            *,
            clients:profiles!bookings_client_id_fkey(full_name),
            therapists:staff!bookings_therapist_id_fkey(full_name)
          ''')
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);
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

  // ── Chat interno ──────────────────────────────────────────────────────────

  String get _myId => _db.auth.currentUser!.id;
  String get myId  => _myId;

  Future<List<Map<String, dynamic>>> getStaffContacts() async {
    try {
      final raw = await _db
          .from('profiles')
          .select('id, full_name, role, specialty, avatar_url')
          .inFilter('role', ['therapist', 'receptionist'])
          .eq('is_active', true)
          .order('role')
          .order('full_name');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminRepo.getStaffContacts: $e');
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

  Stream<List<Map<String, dynamic>>> streamMessages(String chatId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((list) => list.cast<Map<String, dynamic>>());
  }

  Future<void> sendMessage(String chatId, String content) async {
    await _db.from('messages').insert({
      'chat_id':   chatId,
      'sender_id': _myId,
      'content':   content,
    });
  }
}
