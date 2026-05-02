import 'package:flutter/material.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class TerapeutasWidget extends StatelessWidget {
  final List<Map<String, dynamic>> terapeutas;

  const TerapeutasWidget({super.key, required this.terapeutas});

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
          const Text(
            'TERAPEUTAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SaharaColors.grayText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (terapeutas.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Sin terapeutas registrados', style: TextStyle(color: SaharaColors.grayText, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: terapeutas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _buildRow(terapeutas[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> t) {
    final name = t['name'] as String? ?? 'Terapeuta';
    final appts = (t['appointments_month'] as int? ?? 0);
    final occupancy = (t['occupancy'] as double? ?? 0.0);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: SaharaGradients.backgroundCard,
            shape: BoxShape.circle,
            border: Border.all(color: SaharaColors.goldDim.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'T',
              style: const TextStyle(color: SaharaColors.gold, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: SaharaColors.whiteSoft, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (occupancy / 100).clamp(0.0, 1.0),
                  backgroundColor: SaharaColors.grayDark,
                  valueColor: const AlwaysStoppedAnimation(SaharaColors.gold),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$appts', style: const TextStyle(color: SaharaColors.gold, fontSize: 16, fontWeight: FontWeight.w800)),
            const Text('citas', style: TextStyle(color: SaharaColors.grayText, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
