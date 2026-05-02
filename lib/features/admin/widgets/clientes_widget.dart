import 'package:flutter/material.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class ClientesWidget extends StatelessWidget {
  final Map<String, int> stats;

  const ClientesWidget({super.key, required this.stats});

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
            'CLIENTES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SaharaColors.grayText, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat('${stats['new'] ?? 0}', 'Nuevos', const Color(0xFF10B981)),
              _divider(),
              _stat('${stats['returning'] ?? 0}', 'Recurrentes', SaharaColors.gold),
              _divider(),
              _stat('${stats['inactive'] ?? 0}', 'Inactivos', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: SaharaColors.grayText)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: SaharaColors.grayDark);
  }
}
