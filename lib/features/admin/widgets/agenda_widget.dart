import 'package:flutter/material.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class AdminAgendaWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;

  const AdminAgendaWidget({super.key, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AGENDA HOY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SaharaColors.grayText,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SaharaColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SaharaColors.goldDim.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${appointments.length} citas',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SaharaColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.spa_outlined, color: SaharaColors.grayDark, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Sin citas programadas hoy',
                      style: TextStyle(color: SaharaColors.grayText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildItem(appointments[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> appt) {
    final time = (appt['appointment_time'] as String? ?? '00:00').substring(0, 5);
    final clientName = appt['client']?['full_name'] as String? ?? 'Cliente';
    final therapistName = appt['therapist']?['full_name'] as String? ?? '';
    final status = appt['status'] as String? ?? 'pending';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: SaharaColors.grayDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SaharaColors.gold)),
              const Text('HRS', style: TextStyle(fontSize: 8, color: SaharaColors.grayText, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SaharaColors.whiteSoft,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (therapistName.isNotEmpty)
                Text(
                  therapistName,
                  style: const TextStyle(fontSize: 11, color: SaharaColors.grayText),
                ),
            ],
          ),
        ),
        _statusDot(status),
      ],
    );
  }

  Widget _statusDot(String status) {
    final color = switch (status) {
      'confirmed' => const Color(0xFF10B981),
      'completed' => SaharaColors.gold,
      'pending' => const Color(0xFFF59E0B),
      'cancelled' => const Color(0xFFEF4444),
      _ => SaharaColors.grayText,
    };
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
      ),
    );
  }
}
