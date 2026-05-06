import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const StatusBadge({super.key, required this.status});

  static Color colorFor(BookingStatus s) => switch (s) {
    BookingStatus.confirmed => const Color(0xFF4CAF50),
    BookingStatus.completed => const Color(0xFF64B5F6),
    BookingStatus.cancelled => const Color(0xFFEF5350),
    BookingStatus.noShow    => const Color(0xFFFF7043),
    BookingStatus.scheduled => const Color(0xFFFFB74D),
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status.label, style: GoogleFonts.inter(
        fontSize: 11, color: color, fontWeight: FontWeight.w600,
      )),
    );
  }
}
