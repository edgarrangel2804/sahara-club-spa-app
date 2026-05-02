import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

class BookingRequestScreen extends StatefulWidget {
  final SpaService service;
  const BookingRequestScreen({super.key, required this.service});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _db = Supabase.instance.client;
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  String? _selectedTherapistId;
  ServiceDuration? _selectedDuration;
  bool _sending = false;
  List<Map<String, dynamic>> _therapists = [];
  String? _serviceDbId;

  static final _timeSlots = List.generate(21, (i) {
    final totalMin = 540 + i * 30; // 9:00 → 19:30
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  });

  @override
  void initState() {
    super.initState();
    if (widget.service.durations.isNotEmpty) {
      _selectedDuration = widget.service.durations.first;
    }
    _loadTherapists();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTherapists() async {
    try {
      final results = await Future.wait([
        _db.from('profiles').select('id, full_name, specialty')
            .eq('role', 'therapist').eq('is_active', true).order('full_name'),
        _db.from('services').select('id').eq('name', widget.service.name).limit(1),
      ]);
      if (mounted) {
        _therapists = (results[0] as List).cast();
        final serviceRows = results[1] as List;
        _serviceDbId = serviceRows.isNotEmpty ? serviceRows.first['id'] as String? : null;
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _sendRequest() async {
    if (_selectedTime == null) {
      _showSnack('Elige un horario para continuar', isError: true);
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      await _db.from('bookings').insert({
        'client_id':    user.id,
        'therapist_id': _selectedTherapistId,
        'service_id':   _serviceDbId,
        'service_name': widget.service.name,
        'booking_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'booking_time': '${_selectedTime!}:00',
        'duration_min': _selectedDuration?.minutes ?? 60,
        'price':        _selectedDuration?.price ?? 0,
        'status':       'scheduled',
        'client_notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'created_by':   user.id,
      });

      if (mounted) {
        _showSnack('¡Solicitud enviada! La recepcionista confirmará tu cita pronto.');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.services));
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Error al enviar: $e', isError: true);
    }
    if (mounted) setState(() => _sending = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(
          color: isError ? SaharaColors.whiteSoft : SaharaColors.black)),
      backgroundColor: isError ? Colors.redAccent : SaharaColors.gold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain)),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
                    children: [
                      _buildServiceCard(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('¿QUÉ DÍA?'),
                      const SizedBox(height: 14),
                      _buildDateStrip(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('¿A QUÉ HORA?'),
                      const SizedBox(height: 14),
                      _buildTimeGrid(),
                      if (widget.service.durations.length > 1) ...[
                        const SizedBox(height: 28),
                        _buildSectionLabel('DURACIÓN'),
                        const SizedBox(height: 14),
                        _buildDurationSelector(),
                      ],
                      if (_therapists.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildSectionLabel('TERAPEUTA PREFERIDA (OPCIONAL)'),
                        const SizedBox(height: 6),
                        Text(
                          'Si no está disponible, se asignará otra terapeuta',
                          style: GoogleFonts.inter(fontSize: 12, color: SaharaColors.grayText),
                        ),
                        const SizedBox(height: 14),
                        _buildTherapistList(),
                      ],
                      const SizedBox(height: 28),
                      _buildSectionLabel('NOTAS (OPCIONAL)'),
                      const SizedBox(height: 14),
                      _buildNotesField(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // CTA fijo abajo
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(22, 16, 22,
                  MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: SaharaColors.black.withValues(alpha: 0.95),
                border: Border(top: BorderSide(
                    color: SaharaColors.gold.withValues(alpha: 0.1))),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _sendRequest,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 1.5))
                      : const Icon(Icons.send_rounded, size: 17),
                  label: Text(_sending ? 'Agendando…' : 'Agendar cita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SaharaColors.gold,
                    foregroundColor: SaharaColors.black,
                    disabledBackgroundColor: SaharaColors.gold.withValues(alpha: 0.4),
                    elevation: 0,
                    textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 22, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: SaharaColors.gold, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(child: Text('Solicitar reserva',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
            ))),
        ],
      ),
    );
  }

  // ── Tarjeta del servicio ──────────────────────────────────────────────────

  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.service.category.icon,
                color: SaharaColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.service.name, style: GoogleFonts.playfairDisplay(
                  fontSize: 16, color: SaharaColors.whiteSoft,
                )),
                const SizedBox(height: 3),
                Text(widget.service.category.label, style: GoogleFonts.inter(
                  fontSize: 12, color: SaharaColors.grayText,
                )),
              ],
            ),
          ),
          if (_selectedDuration != null)
            Text(_selectedDuration!.formattedPrice, style: GoogleFonts.inter(
              fontSize: 15, color: SaharaColors.gold, fontWeight: FontWeight.w600,
            )),
        ],
      ),
    );
  }

  // ── Strip de fechas ───────────────────────────────────────────────────────

  Widget _buildDateStrip() {
    final days = List.generate(45, (i) =>
        DateTime.now().add(Duration(days: i + 1)));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected = DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isWeekend = d.weekday == 6 || d.weekday == 7;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? SaharaColors.gold.withValues(alpha: 0.15)
                    : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? SaharaColors.gold.withValues(alpha: 0.7)
                      : const Color(0xFF222222),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'es').format(d).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      color: isSelected
                          ? SaharaColors.gold
                          : isWeekend
                              ? SaharaColors.grayText.withValues(alpha: 0.4)
                              : SaharaColors.whiteSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM', 'es').format(d),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isSelected
                          ? SaharaColors.gold.withValues(alpha: 0.7)
                          : SaharaColors.grayText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Grid de horarios ──────────────────────────────────────────────────────

  Widget _buildTimeGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _timeSlots.map((t) {
        final isSelected = t == _selectedTime;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedTime = isSelected ? null : t);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? SaharaColors.gold.withValues(alpha: 0.15)
                  : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? SaharaColors.gold.withValues(alpha: 0.7)
                    : const Color(0xFF222222),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(t, style: GoogleFonts.inter(
              fontSize: 13,
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
          ),
        );
      }).toList(),
    );
  }

  // ── Duración ──────────────────────────────────────────────────────────────

  Widget _buildDurationSelector() {
    return Row(
      children: widget.service.durations.map((d) {
        final isSelected = _selectedDuration?.minutes == d.minutes;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDuration = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? SaharaColors.gold.withValues(alpha: 0.12)
                    : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? SaharaColors.gold.withValues(alpha: 0.6)
                      : const Color(0xFF222222),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(d.formattedDuration, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isSelected ? SaharaColors.gold : SaharaColors.whiteSoft,
                  )),
                  const SizedBox(height: 4),
                  Text(d.formattedPrice, style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected
                        ? SaharaColors.gold.withValues(alpha: 0.7)
                        : SaharaColors.grayText,
                  )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Lista de terapeutas ───────────────────────────────────────────────────

  Widget _buildTherapistList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _therapists.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            final isSelected = _selectedTherapistId == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedTherapistId = null),
              child: _TherapistChip(
                initials: '✦',
                name: 'Sin preferencia',
                isSelected: isSelected,
              ),
            );
          }
          final t = _therapists[i - 1];
          final id = t['id'] as String;
          final name = t['full_name'] as String? ?? '?';
          final isSelected = _selectedTherapistId == id;
          final initials = name.split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedTherapistId = isSelected ? null : id);
            },
            child: _TherapistChip(
              initials: initials,
              name: name.split(' ').first,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  // ── Notas ─────────────────────────────────────────────────────────────────

  Widget _buildNotesField() {
    return TextField(
      controller: _notesCtrl,
      style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Alguna indicación especial, condición o preferencia…',
        hintStyle: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF222222)),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: SaharaColors.gold, width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(
      fontSize: 10, color: SaharaColors.gold,
      fontWeight: FontWeight.w700, letterSpacing: 2,
    ));
  }
}

// ── Chip de terapeuta ─────────────────────────────────────────────────────────

class _TherapistChip extends StatelessWidget {
  final String initials;
  final String name;
  final bool isSelected;
  const _TherapistChip({required this.initials, required this.name, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 76,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? SaharaColors.gold.withValues(alpha: 0.12) : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.6) : const Color(0xFF222222),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? SaharaColors.gold.withValues(alpha: 0.2)
                  : SaharaColors.grayDark,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initials, style: GoogleFonts.inter(
              fontSize: initials == '✦' ? 14 : 13,
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
              fontWeight: FontWeight.w700,
            ))),
          ),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(
            fontSize: 10,
            color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }
}
