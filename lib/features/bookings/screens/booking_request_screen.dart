import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

// URL del Payment Element del web. Cuando el anticipo está habilitado, la app
// crea la cita con status='pending_payment' y abre esta URL en el navegador.
// El web carga el Payment Element de Stripe con el client_secret devuelto por
// la edge function create_appointment_deposit_payment_intent. El webhook de
// Stripe actualiza la cita a 'payment_received' y luego 'confirmed' una vez
// recepción/admin valida.
const _kDepositPaymentUrlPrefix = 'https://saharaclubspa.com/pagar-anticipo/';

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
  Set<String> _occupiedSlots = {};

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
      final rows = await _db
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'therapist')
          .not('is_active', 'eq', false)
          .order('full_name');
      if (mounted) setState(() => _therapists = (rows as List).cast());
    } catch (e) {
      debugPrint('BookingRequest._loadTherapists: $e');
    }
  }

  Future<void> _loadOccupiedSlots() async {
    if (_selectedTherapistId == null) {
      setState(() => _occupiedSlots = {});
      return;
    }
    try {
      final rows = await _db
          .from('bookings')
          .select('booking_time')
          .eq('therapist_id', _selectedTherapistId!)
          .eq('booking_date', DateFormat('yyyy-MM-dd').format(_selectedDate))
          .neq('status', 'cancelled')
          .neq('status', 'no_show');
      final occupied = <String>{};
      for (final r in rows as List) {
        final t = (r['booking_time'] as String?)?.substring(0, 5);
        if (t != null) occupied.add(t);
      }
      if (mounted) {
        setState(() {
          _occupiedSlots = occupied;
          if (_selectedTime != null && occupied.contains(_selectedTime)) {
            _selectedTime = null;
          }
        });
      }
    } catch (e) {
      debugPrint('BookingRequest._loadOccupiedSlots: $e');
    }
  }

  /// Lee `ai_settings.appointment_deposit_*` para saber si el negocio exige
  /// anticipo y cuál es el monto. Si la lectura falla, devolvemos null y la
  /// cita se crea sin anticipo (failsafe — preferimos crear la cita a fallar
  /// el flujo completo).
  Future<Map<String, dynamic>?> _loadDepositConfig() async {
    try {
      final row = await _db
          .from('ai_settings')
          .select('appointment_deposit_enabled, appointment_deposit_amount')
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return null;
      return {
        'enabled': row['appointment_deposit_enabled'] == true,
        'amount': row['appointment_deposit_amount'],
      };
    } catch (e) {
      debugPrint('BookingRequest._loadDepositConfig: $e');
      return null;
    }
  }

  /// Muestra un diálogo explicando el anticipo y al confirmar abre el
  /// Payment Element del web en navegador externo. Si el cliente cancela, la
  /// cita ya quedó en pending_payment y puede pagar después desde Mis Citas.
  Future<void> _promptDepositPayment({
    required String bookingId,
    required int amount,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        backgroundColor: SaharaColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: SaharaColors.gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Anticipo para reservar',
                style: GoogleFonts.inter(
                  color: SaharaColors.whiteSoft,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Para asegurar tu espacio, Sahara Club Spa requiere un anticipo de '
          '\$$amount MXN. Te abriremos la página segura de pago. '
          'Después de pagar, recepción confirmará tu cita.',
          style: GoogleFonts.inter(
            color: SaharaColors.grayText,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(
              'Pagar más tarde',
              style: GoogleFonts.inter(color: SaharaColors.grayText),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: SaharaColors.gold,
              foregroundColor: SaharaColors.black,
            ),
            child: Text(
              'Pagar \$$amount ahora',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (accepted == true) {
      final url = Uri.parse('$_kDepositPaymentUrlPrefix$bookingId');
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnack('Te abrimos la página de pago. Vuelve a la app cuando termines.');
        }
      } catch (e) {
        debugPrint('BookingRequest launchUrl: $e');
        if (mounted) {
          _showSnack(
            'No pudimos abrir la página de pago. Puedes pagar después desde Mis Citas.',
            isError: true,
          );
        }
      }
    } else if (mounted) {
      _showSnack(
        '¡Cita reservada! Recuerda pagar el anticipo desde Mis Citas para que recepción la confirme.',
      );
    }
  }

  /// Llama al RPC `check_availability_for_booking_from_ai` para validar
  /// horario, terapeuta, horario laboral, comida, bloqueos y colisiones.
  /// Devuelve el JSON crudo del RPC o null si hay error de red.
  Future<Map<String, dynamic>?> _validateAvailability() async {
    try {
      final res = await _db.rpc(
        'check_availability_for_booking_from_ai',
        params: {
          'p_service_id': _selectedDuration?.serviceId ?? widget.service.id,
          'p_requested_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'p_requested_time': '${_selectedTime!}:00',
          'p_duration_min': _selectedDuration?.minutes ?? 60,
          if (_selectedTherapistId != null) 'p_staff_id': _selectedTherapistId,
        },
      );
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      debugPrint('BookingRequest._validateAvailability: $e');
      return null;
    }
  }

  Future<void> _sendRequest() async {
    if (_selectedTime == null) {
      _showSnack('Elige un horario para continuar', isError: true);
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _sending = true);

    // 1. Validar disponibilidad real contra business_hours, schedule_blocks,
    // staff_working_hours, staff_time_off y bookings activos.
    final check = await _validateAvailability();
    if (check != null && check['available'] != true) {
      if (mounted) {
        setState(() => _sending = false);
        await _showSuggestionsSheet(
          reasonLabel: (check['details'] ?? 'Ese horario no está disponible.').toString(),
          suggestions: (check['suggested_slots'] as List?) ?? const [],
        );
      }
      return;
    }

    // 2. Leer si el negocio requiere anticipo. Si está habilitado, la cita
    // se crea como 'pending_payment' y abrimos el navegador al Payment Element
    // del web. Si no, va directo a 'scheduled' como antes.
    final depositConfig = await _loadDepositConfig();
    final requiresDeposit = depositConfig != null && depositConfig['enabled'] == true;
    final depositAmount = (depositConfig?['amount'] as num?)?.toInt() ?? 0;

    // 3. Insertar booking. Si el cliente no pidió terapeuta específico, el RPC
    // sugirió una pero NO la asignamos automáticamente — la cita queda
    // "sin asignar" (therapist_id NULL) y recepción decide quién atiende.
    try {
      final inserted = await _db
          .from('bookings')
          .insert({
            'client_id':    user.id,
            'therapist_id': _selectedTherapistId,
            'service_id':   _selectedDuration?.serviceId ?? widget.service.id,
            'service_name': widget.service.name,
            'booking_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
            'booking_time': '${_selectedTime!}:00',
            'duration_min': _selectedDuration?.minutes ?? 60,
            'price':        _selectedDuration?.price ?? 0,
            'status':       requiresDeposit ? 'pending_payment' : 'scheduled',
            'payment_requirement': requiresDeposit ? 'deposit_required' : null,
            'deposit_amount': requiresDeposit ? depositAmount : null,
            'deposit_required_cents': requiresDeposit ? depositAmount * 100 : null,
            'client_notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            'created_by':   user.id,
          })
          .select('id')
          .single();

      final newBookingId = inserted['id']?.toString();

      if (!mounted) return;

      if (requiresDeposit && newBookingId != null) {
        // Mostrar diálogo y abrir Payment Element en navegador externo.
        await _promptDepositPayment(
          bookingId: newBookingId,
          amount: depositAmount,
        );
      } else {
        _showSnack('¡Solicitud enviada! La recepcionista confirmará tu cita pronto.');
      }

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.services));
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

  /// Bottom sheet con horarios alternativos cuando el RPC devuelve
  /// available=false. El cliente puede tocar una sugerencia y el form se
  /// actualiza con esa fecha/hora/terapeuta; al hacer "Continuar" se reintenta
  /// el envío. Si decide cerrar el sheet manualmente, el form queda intacto.
  Future<void> _showSuggestionsSheet({
    required String reasonLabel,
    required List<dynamic> suggestions,
  }) async {
    final list = suggestions.cast<Map<String, dynamic>>();
    final pick = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: SaharaColors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: SaharaColors.grayText.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Horario no disponible',
                  style: GoogleFonts.inter(
                    color: SaharaColors.whiteSoft,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reasonLabel,
                  style: GoogleFonts.inter(
                    color: SaharaColors.grayText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No tenemos alternativas cercanas. Prueba otro día.',
                      style: GoogleFonts.inter(
                        color: SaharaColors.grayText,
                        fontSize: 13,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Te ofrecemos estas opciones:',
                    style: GoogleFonts.inter(
                      color: SaharaColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = list[i];
                        final dateStr = s['date']?.toString() ?? '';
                        final timeStr = (s['time']?.toString() ?? '').substring(
                          0,
                          (s['time']?.toString().length ?? 0).clamp(0, 5),
                        );
                        final staffName = s['staff_name']?.toString() ?? 'Equipo Sahara';
                        DateTime? parsedDate;
                        try {
                          parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
                        } catch (_) {
                          parsedDate = null;
                        }
                        final niceDate = parsedDate == null
                            ? dateStr
                            : DateFormat("EEEE d 'de' MMMM", 'es').format(parsedDate);
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(sheetCtx, {
                            'date': dateStr,
                            'time': timeStr,
                            'staff_id': s['staff_id']?.toString(),
                            'staff_name': staffName,
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: SaharaColors.gold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: SaharaColors.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: SaharaColors.gold.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.schedule_rounded,
                                    color: SaharaColors.gold,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$niceDate · $timeStr',
                                        style: GoogleFonts.inter(
                                          color: SaharaColors.whiteSoft,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Con $staffName',
                                        style: GoogleFonts.inter(
                                          color: SaharaColors.grayText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: SaharaColors.grayText,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (pick == null) return;
    final dateStr = pick['date']?.toString();
    final timeStr = pick['time']?.toString();
    if (dateStr == null || timeStr == null) return;
    try {
      final d = DateFormat('yyyy-MM-dd').parse(dateStr);
      if (!mounted) return;
      setState(() {
        _selectedDate = d;
        _selectedTime = timeStr;
        // Si la sugerencia trae staff_id y el cliente no había elegido
        // terapeuta, no la fijamos — la cita queda sin asignar y recepción
        // decide. Si el cliente SÍ pidió terapeuta específica, respetamos
        // su elección original.
      });
      _loadOccupiedSlots();
      _showSnack('Horario actualizado. Toca "Solicitar cita" para confirmar.');
    } catch (e) {
      debugPrint('BookingRequest pick parse error: $e');
    }
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
              _loadOccupiedSlots();
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
        final isOccupied = _occupiedSlots.contains(t);
        return GestureDetector(
          onTap: isOccupied ? null : () {
            HapticFeedback.selectionClick();
            setState(() => _selectedTime = isSelected ? null : t);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOccupied
                  ? const Color(0xFF0A0A0A)
                  : isSelected
                      ? SaharaColors.gold.withValues(alpha: 0.15)
                      : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOccupied
                    ? const Color(0xFF1A1A1A)
                    : isSelected
                        ? SaharaColors.gold.withValues(alpha: 0.7)
                        : const Color(0xFF222222),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(t, style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isOccupied
                      ? SaharaColors.grayText.withValues(alpha: 0.25)
                      : isSelected
                          ? SaharaColors.gold
                          : SaharaColors.grayText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  decoration: isOccupied ? TextDecoration.lineThrough : null,
                  decorationColor: SaharaColors.grayText.withValues(alpha: 0.25),
                )),
              ],
            ),
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
              onTap: () { setState(() => _selectedTherapistId = null); _loadOccupiedSlots(); },
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
              _loadOccupiedSlots();
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
