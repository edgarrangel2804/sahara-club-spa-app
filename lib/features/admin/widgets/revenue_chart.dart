import 'package:flutter/material.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

class AdminRevenueChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;

  const AdminRevenueChart({super.key, required this.data, required this.labels});

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
                'INGRESOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SaharaColors.grayText,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  _chip('7D', true),
                  _chip('1M', false),
                  _chip('3M', false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _GoldChartPainter(data: data),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((l) => Text(
                      l,
                      style: const TextStyle(fontSize: 10, color: SaharaColors.grayText),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? SaharaColors.gold.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? SaharaColors.goldDim : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? SaharaColors.gold : SaharaColors.grayText,
        ),
      ),
    );
  }
}

class _GoldChartPainter extends CustomPainter {
  final List<double> data;
  _GoldChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final dx = size.width / (data.length - 1);
    final path = Path();
    final fill = Path();

    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
      if (i == data.length - 1) {
        fill.lineTo(x, size.height);
        fill.close();
      }
    }

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x30C6A76A), Color(0x00C6A76A)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = SaharaColors.gold
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] / maxVal) * size.height;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = SaharaColors.gold);
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = const Color(0xFF151515));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
