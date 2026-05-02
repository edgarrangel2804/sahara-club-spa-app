import 'package:flutter/material.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/admin/data/admin_repository.dart';

class AdminAgendaPage extends StatefulWidget {
  const AdminAgendaPage({super.key});

  @override
  State<AdminAgendaPage> createState() => _AdminAgendaPageState();
}

class _AdminAgendaPageState extends State<AdminAgendaPage> {
  final _repo = SaharaAdminRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _appointments = await _repo.getAllAppointments();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5))
        : RefreshIndicator(
            onRefresh: _load,
            color: SaharaColors.gold,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildCard(_appointments[i]),
            ),
          );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final date = a['appointment_date'] as String? ?? '';
    final time = (a['appointment_time'] as String? ?? '00:00').substring(0, 5);
    final client = a['client']?['full_name'] as String? ?? 'Cliente';
    final status = a['status'] as String? ?? 'pending';

    final statusColor = switch (status) {
      'confirmed' => const Color(0xFF10B981),
      'completed' => SaharaColors.gold,
      'cancelled' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(time, style: const TextStyle(color: SaharaColors.gold, fontWeight: FontWeight.w800, fontSize: 15)),
              Text(date, style: const TextStyle(color: SaharaColors.grayText, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(client, style: const TextStyle(color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
