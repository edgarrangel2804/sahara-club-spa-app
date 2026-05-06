import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/models/booking.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

class AssignBookingDialog extends StatefulWidget {
  final Booking booking;
  final ReceptionRepository repo;
  final VoidCallback onAssigned;

  const AssignBookingDialog({
    super.key,
    required this.booking,
    required this.repo,
    required this.onAssigned,
  });

  @override
  State<AssignBookingDialog> createState() => _AssignBookingDialogState();
}

class _AssignBookingDialogState extends State<AssignBookingDialog> {
  bool _loading    = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _therapists = [];
  String? _selectedTherapist;
  late DateTime _date;
  late String   _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.booking.date;
    _time = widget.booking.time.substring(0, 5);
    _loadTherapists();
  }

  Future<void> _loadTherapists() async {
    try {
      final therapists = await widget.repo.getTherapists();
      if (!mounted) return;
      setState(() {
        _therapists = therapists;
        _loading    = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = 'Error al cargar terapeutas: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedTherapist == null) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final therapistName = _therapists
          .firstWhere((t) => t['id'] == _selectedTherapist, orElse: () => {})
          ['full_name'] as String? ?? 'La terapeuta';

      final available = await widget.repo.isTherapistAvailable(
        _selectedTherapist!, _date, _time,
        excludeBookingId: widget.booking.id,
      );
      if (!available) {
        if (!mounted) return;
        final msg = '$therapistName ya tiene una cita a las $_time. '
            'Selecciona otro horario o terapeuta.';
        setState(() { _submitting = false; _error = msg; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF2A1010),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
        return;
      }

      await widget.repo.assignBooking(
        bookingId:   widget.booking.id,
        therapistId: _selectedTherapist!,
        date:        _date,
        time:        _time,
      );
      widget.onAssigned();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Error al asignar la cita:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b          = widget.booking;
    final dateLabel  = DateFormat("EEE d 'de' MMM", 'es').format(_date);
    final canSubmit  = !_submitting && _selectedTherapist != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding:   const EdgeInsets.fromLTRB(28, 28, 28, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignar Cita', style: GoogleFonts.playfairDisplay(
              fontSize: 22, color: SaharaColors.gold)),
          const SizedBox(height: 4),
          Text(b.clientName, style: GoogleFonts.inter(
              fontSize: 14, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w600)),
        ],
      ),
      content: _loading
          ? const SizedBox(
              width: double.maxFinite, height: 120,
              child: Center(child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5)))
          : SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Error (al tope para que siempre sea visible) ──────────
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Info de la solicitud (read-only) ─────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: SaharaColors.gold.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.serviceName, style: GoogleFonts.inter(
                            fontSize: 14, color: SaharaColors.gold,
                            fontWeight: FontWeight.w600,
                          )),
                          const SizedBox(height: 8),
                          Wrap(spacing: 16, runSpacing: 6, children: [
                            _infoChip(Icons.calendar_today_rounded, dateLabel),
                            _infoChip(Icons.schedule_rounded, _time),
                            if (b.durationMin > 0)
                              _infoChip(Icons.timer_outlined, '${b.durationMin} min'),
                            if (b.price > 0)
                              _infoChip(Icons.attach_money_rounded,
                                  '\$${NumberFormat('#,###').format(b.price)}'),
                          ]),
                          if (b.clientNotes?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notes_rounded,
                                    size: 12, color: SaharaColors.grayText),
                                const SizedBox(width: 6),
                                Expanded(child: Text(b.clientNotes!,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: SaharaColors.grayText,
                                        fontStyle: FontStyle.italic))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Ajustar fecha y hora ──────────────────────────────────
                    Text('HORARIO DE LA CITA', style: GoogleFonts.inter(
                      fontSize: 10, color: SaharaColors.grayText,
                      fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    Column(children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: _date.isBefore(DateTime.now())
                                ? _date
                                : DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime(2030),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(colorScheme:
                                const ColorScheme.dark(primary: SaharaColors.gold,
                                    surface: Color(0xFF1A1A1A))),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: _pickerField(Icons.calendar_today_rounded,
                            DateFormat('dd/MM/yyyy').format(_date)),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final parts  = _time.split(':');
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour:   int.parse(parts[0]),
                              minute: int.parse(parts[1]),
                            ),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(colorScheme:
                                const ColorScheme.dark(primary: SaharaColors.gold,
                                    surface: Color(0xFF1A1A1A))),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setState(() => _time =
                              '${picked.hour.toString().padLeft(2, '0')}:'
                              '${picked.minute.toString().padLeft(2, '0')}');
                          }
                        },
                        child: _pickerField(Icons.schedule_rounded, _time),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Terapeuta (obligatorio) ───────────────────────────────
                    Text('TERAPEUTA', style: GoogleFonts.inter(
                      fontSize: 10, color: SaharaColors.grayText,
                      fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 10),
                    if (_therapists.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SaharaColors.grayDark),
                        ),
                        child: Text('Sin terapeutas activos', style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white38,
                        )),
                      )
                    else
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _therapists.map((t) {
                          final id         = t['id'] as String;
                          final name       = t['full_name'] as String? ?? '';
                          final specialty  = t['specialty'] as String?;
                          final isSelected = _selectedTherapist == id;
                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _selectedTherapist = id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? SaharaColors.gold.withValues(alpha: 0.15)
                                      : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? SaharaColors.gold
                                        : SaharaColors.grayDark,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check_circle_rounded,
                                          color: SaharaColors.gold, size: 14),
                                      const SizedBox(width: 6),
                                    ],
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: isSelected
                                              ? SaharaColors.gold
                                              : SaharaColors.whiteSoft,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        )),
                                        if (specialty != null)
                                          Text(specialty, style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: SaharaColors.grayText,
                                          )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SaharaColors.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: SaharaColors.gold.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: canSubmit ? _submit : null,
          child: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Asignar Cita',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: SaharaColors.gold),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(
            fontSize: 12, color: SaharaColors.grayText)),
      ],
    );
  }

  Widget _pickerField(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Row(children: [
        Icon(icon, color: SaharaColors.gold, size: 15),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(
            color: Colors.white, fontSize: 13)),
      ]),
    );
  }
}
