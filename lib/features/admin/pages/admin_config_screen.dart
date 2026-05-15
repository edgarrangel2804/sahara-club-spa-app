import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/features/admin/pages/permisos_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/servicios_page.dart';
import 'package:sahara_club_spa_app/features/admin/pages/equipo_page.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await _db
          .from('profiles')
          .select('full_name, phone, avatar_url')
          .eq('id', uid)
          .single();
      if (mounted) setState(() => _profile = Map<String, dynamic>.from(data as Map));
    } catch (_) {}
  }

  // ── Perfil ────────────────────────────────────────────────────────────────

  void _openPerfil() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PerfilSheet(
        profile: _profile,
        onSaved: (updated) {
          setState(() => _profile = updated);
        },
      ),
    );
  }

  // ── Contraseña ────────────────────────────────────────────────────────────

  void _openCambiarPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PasswordSheet(),
    );
  }

  // ── Notificaciones ────────────────────────────────────────────────────────

  void _openNotificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NotificacionesSheet(),
    );
  }

  // ── Horarios ──────────────────────────────────────────────────────────────

  void _openHorarios() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HorariosSheet(),
    );
  }

  // ── Reportes ──────────────────────────────────────────────────────────────

  void _openReportes() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _ReportesPage()));
  }

  // ── Acerca de ─────────────────────────────────────────────────────────────

  void _openAcercaDe() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AcercaDeSheet(),
    );
  }

  // ── Soporte ───────────────────────────────────────────────────────────────

  void _openSoporte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SoporteSheet(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name  = _profile?['full_name'] as String? ?? 'Admin';
    final email = _db.auth.currentUser?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONFIGURACIÓN', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: SaharaColors.grayText, letterSpacing: 1.5,
          )),
          const SizedBox(height: 16),

          // ── Admin card ──────────────────────────────────────────────────
          GestureDetector(
            onTap: _openPerfil,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: SaharaGradients.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: SaharaColors.gold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Center(child: Text(
                      name.trim().split(' ').where((w) => w.isNotEmpty).take(2)
                          .map((w) => w[0].toUpperCase()).join(),
                      style: GoogleFonts.inter(
                        fontSize: 16, color: SaharaColors.gold, fontWeight: FontWeight.w700,
                      ),
                    )),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.inter(
                          fontSize: 15, color: SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w600,
                        )),
                        Text(email, style: GoogleFonts.inter(
                          fontSize: 12, color: SaharaColors.grayText,
                        )),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SaharaColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Administrador', style: GoogleFonts.inter(
                            fontSize: 10, color: SaharaColors.gold, fontWeight: FontWeight.w600,
                          )),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, color: SaharaColors.grayText, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Cuenta ──────────────────────────────────────────────────────
          _section('CUENTA', [
            _tile(Icons.lock_outline,           'Cambiar contraseña',  _openCambiarPassword),
            _tile(Icons.notifications_outlined,  'Notificaciones',      _openNotificaciones),
          ]),
          const SizedBox(height: 16),

          // ── Negocio ─────────────────────────────────────────────────────
          _section('NEGOCIO', [
            _tile(Icons.spa_outlined,            'Gestionar servicios', () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminServiciosPage()))),
            _tile(Icons.people_outline,          'Equipo de trabajo',   () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminEquipoPage()))),
            _tile(Icons.schedule_outlined,       'Horarios',            _openHorarios),
            _tile(Icons.manage_accounts_outlined,'Permisos',            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminPermisosPage()))),
            _tile(Icons.bar_chart_outlined,      'Reportes',            _openReportes),
          ]),
          const SizedBox(height: 16),

          // ── Sistema ─────────────────────────────────────────────────────
          _section('SISTEMA', [
            _tile(Icons.info_outline,  'Acerca de Sahara Club', _openAcercaDe),
            _tile(Icons.help_outline,  'Soporte',               _openSoporte),
          ]),
          const SizedBox(height: 24),
          _logoutButton(context),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaharaColors.grayDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: SaharaColors.grayText, letterSpacing: 1.2,
            )),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: SaharaColors.gold, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(
              color: SaharaColors.whiteSoft, fontSize: 14,
            ))),
            const Icon(Icons.chevron_right, color: SaharaColors.grayText, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Text('Cerrar sesión', style: GoogleFonts.inter(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.w600, fontSize: 15,
            )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PERFIL SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _PerfilSheet extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final void Function(Map<String, dynamic>) onSaved;
  const _PerfilSheet({required this.profile, required this.onSaved});

  @override
  State<_PerfilSheet> createState() => _PerfilSheetState();
}

class _PerfilSheetState extends State<_PerfilSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _avatarUrl;
  File?   _localImage;
  bool    _saving       = false;
  bool    _uploadingImg = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.profile?['full_name'] as String? ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile?['phone']     as String? ?? '');
    _avatarUrl = widget.profile?['avatar_url'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Foto ──────────────────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final xfile  = await picker.pickImage(
      source:     ImageSource.gallery,
      maxWidth:   512,
      maxHeight:  512,
      imageQuality: 85,
    );
    if (xfile == null) return;

    setState(() => _uploadingImg = true);
    try {
      final uid    = Supabase.instance.client.auth.currentUser!.id;
      final bytes  = await xfile.readAsBytes();
      final ext    = xfile.path.split('.').last.toLowerCase();
      final path   = 'admin/$uid.$ext';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(path, bytes,
              fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      // Añade timestamp para forzar recarga y evitar caché
      final freshUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client.from('profiles').update({
        'avatar_url': freshUrl,
      }).eq('id', uid);

      if (mounted) {
        setState(() {
          _avatarUrl   = freshUrl;
          _localImage  = File(xfile.path);
          _uploadingImg = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImg = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo subir la foto: $e'),
          backgroundColor: const Color(0xFF2A1010),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Guardar texto ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').update({
        'full_name':  name,
        'phone':      _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);
      widget.onSaved({
        'full_name':  name,
        'phone':      _phoneCtrl.text.trim(),
        'avatar_url': _avatarUrl,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFF2A1010),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final email   = Supabase.instance.client.auth.currentUser?.email ?? '';
    final initials = _nameCtrl.text.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    // viewInsets: espacio ocupado por el teclado
    // viewPadding.bottom: barra de navegación de Android
    final bottomPad = MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).viewPadding.bottom
        + 24;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Mi perfil', Icons.person_outline),
          const SizedBox(height: 24),

          // ── Avatar ──────────────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _uploadingImg ? null : _pickAndUpload,
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: SaharaColors.gold.withValues(alpha: 0.5), width: 2),
                    ),
                    child: ClipOval(
                      child: _uploadingImg
                          ? Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Center(child: CircularProgressIndicator(
                                  color: SaharaColors.gold, strokeWidth: 1.5)),
                            )
                          : _localImage != null
                              ? Image.file(_localImage!, fit: BoxFit.cover)
                              : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                  ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _avatarPlaceholder(initials))
                                  : _avatarPlaceholder(initials),
                    ),
                  ),
                  // Badge editar
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SaharaColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0E0E0E), width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.black, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Toca para cambiar foto',
              style: GoogleFonts.inter(fontSize: 11, color: SaharaColors.grayText)),
          ),

          const SizedBox(height: 24),
          _field('Nombre completo', _nameCtrl, TextInputType.name),
          const SizedBox(height: 14),
          _readonlyField('Correo electrónico', email),
          const SizedBox(height: 14),
          _field('Teléfono', _phoneCtrl, TextInputType.phone),
          const SizedBox(height: 24),
          _saveButton(_saving ? null : _save, 'Guardar cambios', _saving),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(String initials) => Container(
    color: SaharaColors.gold.withValues(alpha: 0.12),
    child: Center(child: Text(
      initials.isEmpty ? 'A' : initials,
      style: GoogleFonts.inter(
        fontSize: 28, color: SaharaColors.gold, fontWeight: FontWeight.w700),
    )),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// CAMBIAR CONTRASEÑA SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _newCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving      = false;
  bool _showNew     = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newPass = _newCtrl.text.trim();
    if (newPass.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (newPass != _confirmCtrl.text.trim()) {
      _snack('Las contraseñas no coinciden');
      return;
    }
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Contraseña actualizada',
            style: GoogleFonts.inter(color: Colors.black)),
          backgroundColor: SaharaColors.gold,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF2A1010),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).viewPadding.bottom + 24;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Cambiar contraseña', Icons.lock_outline),
          const SizedBox(height: 20),
          _passwordField('Nueva contraseña', _newCtrl, _showNew,
              () => setState(() => _showNew = !_showNew)),
          const SizedBox(height: 14),
          _passwordField('Confirmar contraseña', _confirmCtrl, _showConfirm,
              () => setState(() => _showConfirm = !_showConfirm)),
          const SizedBox(height: 8),
          Text('Mínimo 6 caracteres', style: GoogleFonts.inter(
            fontSize: 11, color: SaharaColors.grayText,
          )),
          const SizedBox(height: 24),
          _saveButton(_saving ? null : _save, 'Actualizar contraseña', _saving),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICACIONES SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _NotificacionesSheet extends StatefulWidget {
  const _NotificacionesSheet();

  @override
  State<_NotificacionesSheet> createState() => _NotificacionesSheetState();
}

class _NotificacionesSheetState extends State<_NotificacionesSheet> {
  bool _registering = false;
  bool _registered  = false;

  Future<void> _reregister() async {
    setState(() => _registering = true);
    try {
      await NotificationService.instance.saveTokenForCurrentUser();
      if (mounted) setState(() => _registered = true);
    } catch (_) {} finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Notificaciones', Icons.notifications_outlined),
          const SizedBox(height: 20),
          _infoCard(Icons.check_circle_outline, 'Estado', 'Push notifications activas',
              const Color(0xFF22C55E)),
          const SizedBox(height: 12),
          _infoCard(Icons.campaign_outlined, 'Tipos', 'Nuevas reservas · Confirmaciones · Asignaciones',
              SaharaColors.gold),
          const SizedBox(height: 20),
          if (_registered)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 8),
                  Text('Token registrado correctamente', style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF22C55E),
                  )),
                ],
              ),
            )
          else
            _saveButton(
              _registering ? null : _reregister,
              'Registrar dispositivo',
              _registering,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HORARIOS SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _HorariosSheet extends StatefulWidget {
  const _HorariosSheet();

  @override
  State<_HorariosSheet> createState() => _HorariosSheetState();
}

class _HorariosSheetState extends State<_HorariosSheet> {
  static const _days = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo',
  ];

  final _open  = List<String>.filled(7, '09:00');
  final _close = List<String>.filled(7, '20:00');
  final _closed = List<bool>.filled(7, false);

  @override
  void initState() {
    super.initState();
    _closed[6] = true; // Domingo cerrado por defecto
    _close[5]  = '18:00'; // Sábado cierra más temprano
  }

  Future<void> _pickTime(int dayIndex, bool isOpen) async {
    final parts = (isOpen ? _open[dayIndex] : _close[dayIndex]).split(':');
    final init  = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Color(0xFF1A1A1A),
          ),
          colorScheme: const ColorScheme.dark(primary: SaharaColors.gold),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final str = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isOpen) { _open[dayIndex]  = str; }
      else        { _close[dayIndex] = str; }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _sheetTitle('Horarios del spa', Icons.schedule_outlined),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _dayRow(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayRow(int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _closed[i]
            ? Colors.white.withValues(alpha: 0.06)
            : SaharaColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(_days[i], style: GoogleFonts.inter(
              fontSize: 13,
              color: _closed[i] ? SaharaColors.grayText : SaharaColors.whiteSoft,
              fontWeight: FontWeight.w500,
            )),
          ),
          if (_closed[i])
            Expanded(child: Text('Cerrado', style: GoogleFonts.inter(
              fontSize: 13, color: SaharaColors.grayText,
            )))
          else ...[
            GestureDetector(
              onTap: () => _pickTime(i, true),
              child: _timePill(_open[i]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.grayText,
              )),
            ),
            GestureDetector(
              onTap: () => _pickTime(i, false),
              child: _timePill(_close[i]),
            ),
          ],
          const Spacer(),
          Switch(
            value: !_closed[i],
            onChanged: (v) => setState(() => _closed[i] = !v),
            activeThumbColor: SaharaColors.gold,
            activeTrackColor: SaharaColors.gold.withValues(alpha: 0.25),
            inactiveThumbColor: SaharaColors.grayText.withValues(alpha: 0.4),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _timePill(String time) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: SaharaColors.gold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
    ),
    child: Text(time, style: GoogleFonts.inter(
      fontSize: 13, color: SaharaColors.gold, fontWeight: FontWeight.w600,
    )),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTES PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportesPage extends StatefulWidget {
  const _ReportesPage();

  @override
  State<_ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<_ReportesPage> {
  final _db    = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  DateTime _from = DateTime.now().subtract(const Duration(days: 29));
  DateTime _to   = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fromStr = _dateStr(_from);
      final toStr   = _dateStr(_to.add(const Duration(days: 1)));

      final bookingsRaw = await _db
          .from('bookings')
          .select('status, price, booking_date, services(name)')
          .gte('booking_date', fromStr)
          .lt('booking_date', toStr);

      final list  = bookingsRaw as List;
      final total = list.length;
      final done  = list.where((b) => b['status'] == 'completed').length;
      final canc  = list.where((b) => b['status'] == 'cancelled').length;
      final pend  = list.where((b) => b['status'] == 'scheduled').length;
      final rev   = list
          .where((b) => b['status'] == 'completed')
          .fold<double>(0, (s, b) => s + ((b['price'] as num?)?.toDouble() ?? 0));

      // Top services
      final svcCount = <String, int>{};
      for (final b in list) {
        final name = (b['services'] as Map?)?['name'] as String? ?? 'Otro';
        svcCount[name] = (svcCount[name] ?? 0) + 1;
      }
      final topSvcs = svcCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _stats = {
            'total': total, 'completed': done,
            'cancelled': canc, 'pending': pend,
            'revenue': rev, 'top_services': topSvcs.take(5).toList(),
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SaharaColors.grayDark),
                        ),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: SaharaColors.grayText, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reportes', style: GoogleFonts.playfairDisplay(
                          fontSize: 22, color: SaharaColors.whiteSoft,
                          fontWeight: FontWeight.w300,
                        )),
                        Text('${_fmtDate(_from)} – ${_fmtDate(_to)}',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: SaharaColors.grayText,
                          )),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: SaharaColors.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Text('Período', style: GoogleFonts.inter(
                          fontSize: 12, color: SaharaColors.gold,
                        )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 0.5, color: SaharaColors.gold.withValues(alpha: 0.1)),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    children: [
                      // KPIs
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _kpi('Total citas',   '${_stats['total']}',       Icons.calendar_today_outlined, SaharaColors.gold),
                          _kpi('Completadas',   '${_stats['completed']}',   Icons.check_circle_outline,    const Color(0xFF22C55E)),
                          _kpi('Canceladas',    '${_stats['cancelled']}',   Icons.cancel_outlined,         const Color(0xFFEF4444)),
                          _kpi('Ingresos',      '\$${(_stats['revenue'] as double).toStringAsFixed(0)}', Icons.attach_money, const Color(0xFF3B82F6)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Top servicios
                      Text('Servicios más solicitados', style: GoogleFonts.inter(
                        fontSize: 12, color: SaharaColors.grayText,
                        fontWeight: FontWeight.w600, letterSpacing: 0.8,
                      )),
                      const SizedBox(height: 12),
                      ...(_stats['top_services'] as List? ?? []).map((e) {
                        final entry = e as MapEntry<String, int>;
                        final max   = ((_stats['top_services'] as List).first as MapEntry<String, int>).value;
                        final pct   = max > 0 ? entry.value / max : 0.0;
                        return _svcBar(entry.key, entry.value, pct);
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: SaharaColors.gold),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() { _from = picked.start; _to = picked.end; });
    _load();
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(
                fontSize: 22, color: SaharaColors.whiteSoft,
                fontWeight: FontWeight.w700,
              )),
              Text(label, style: GoogleFonts.inter(
                fontSize: 11, color: SaharaColors.grayText,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _svcBar(String name, int count, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.whiteSoft,
              ))),
              Text('$count', style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.gold, fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation(SaharaColors.gold),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACERCA DE SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _AcercaDeSheet extends StatelessWidget {
  const _AcercaDeSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.spa_outlined, color: SaharaColors.gold, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Sahara Club Spa', style: GoogleFonts.playfairDisplay(
            fontSize: 24, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
          )),
          const SizedBox(height: 6),
          Text('App de gestión interna', style: GoogleFonts.inter(
            fontSize: 13, color: SaharaColors.grayText,
          )),
          const SizedBox(height: 24),
          _infoRow('Versión', '1.0.0'),
          _divider(),
          _infoRow('Desarrollado para', 'Sahara Club Spa'),
          _divider(),
          _infoRow('Plataforma', 'Flutter · Supabase'),
          _divider(),
          _infoRow('Soporte', 'soporte@saharaclubspa.com'),
          const SizedBox(height: 20),
          Text('© 2025 Sahara Club Spa. Todos los derechos reservados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: SaharaColors.grayText)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 13, color: SaharaColors.grayText,
        )),
        Text(value, style: GoogleFonts.inter(
          fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500,
        )),
      ],
    ),
  );

  Widget _divider() => Container(height: 0.5, color: Colors.white.withValues(alpha: 0.06));
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOPORTE SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SoporteSheet extends StatelessWidget {
  const _SoporteSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Soporte', Icons.help_outline),
          const SizedBox(height: 20),
          Text('¿Necesitas ayuda?', style: GoogleFonts.inter(
            fontSize: 14, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 6),
          Text('Contáctanos por cualquiera de estos medios y te atendemos a la brevedad.',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText, height: 1.5)),
          const SizedBox(height: 20),
          _contactCard(Icons.email_outlined,     'Correo',    'soporte@saharaclubspa.com', () {
            Clipboard.setData(const ClipboardData(text: 'soporte@saharaclubspa.com'));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Correo copiado',
                  style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: SaharaColors.gold,
              behavior: SnackBarBehavior.floating,
            ));
          }),
          const SizedBox(height: 10),
          _contactCard(Icons.chat_outlined,      'WhatsApp',  '+52 55 0000 0000', () {
            Clipboard.setData(const ClipboardData(text: '+525500000000'));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Número copiado',
                  style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: SaharaColors.gold,
              behavior: SnackBarBehavior.floating,
            ));
          }),
          const SizedBox(height: 10),
          _contactCard(Icons.schedule_outlined,  'Horario',   'Lun – Vie  9:00 – 18:00', null),
        ],
      ),
    );
  }

  Widget _contactCard(IconData icon, String label, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: SaharaColors.gold, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(
                    fontSize: 11, color: SaharaColors.grayText,
                  )),
                  Text(value, style: GoogleFonts.inter(
                    fontSize: 13, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w500,
                  )),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.copy_rounded, color: SaharaColors.grayText, size: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Widget _sheetTitle(String title, IconData icon) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: SaharaColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: SaharaColors.gold, size: 18),
      ),
      const SizedBox(width: 12),
      Text(title, style: GoogleFonts.playfairDisplay(
        fontSize: 20, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
      )),
    ],
  );
}

Widget _field(String label, TextEditingController ctrl, TextInputType type) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, color: SaharaColors.grayText, fontWeight: FontWeight.w500,
      )),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF141414),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SaharaColors.grayDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SaharaColors.grayDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SaharaColors.gold),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}

Widget _readonlyField(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, color: SaharaColors.grayText, fontWeight: FontWeight.w500,
      )),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SaharaColors.grayDark),
        ),
        child: Text(value, style: GoogleFonts.inter(
          fontSize: 14, color: SaharaColors.grayText,
        )),
      ),
    ],
  );
}

Widget _passwordField(String label, TextEditingController ctrl,
    bool visible, VoidCallback toggle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, color: SaharaColors.grayText, fontWeight: FontWeight.w500,
      )),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: !visible,
        style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF141414),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SaharaColors.grayDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SaharaColors.grayDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SaharaColors.gold),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: SaharaColors.grayText, size: 18,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    ],
  );
}

Widget _saveButton(VoidCallback? onTap, String label, bool loading) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: onTap == null ? SaharaColors.gold.withValues(alpha: 0.4) : SaharaColors.gold,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.black))
            : Text(label, style: GoogleFonts.inter(
                fontSize: 14, color: Colors.black, fontWeight: FontWeight.w700,
              )),
      ),
    ),
  );
}

Widget _infoCard(IconData icon, String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(
              fontSize: 10, color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            )),
            Text(value, style: GoogleFonts.inter(
              fontSize: 13, color: SaharaColors.whiteSoft,
            )),
          ],
        ),
      ],
    ),
  );
}
