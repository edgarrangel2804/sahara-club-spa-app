import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/features/memberships/memberships_screen.dart';
import 'package:sahara_club_spa_app/features/orders/screens/my_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _db = Supabase.instance.client;
  bool _loading = true;
  bool _saving = false;

  // ── Avatar ─────────────────────────────────────────────────────────────────
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  // ── Sección 1: Básico ──────────────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _email = '';

  // ── Sección 2: Bienestar ───────────────────────────────────────────────────
  String _mood = '';
  final Set<String> _tensionAreas = {};

  // ── Sección 3: Facial ──────────────────────────────────────────────────────
  String _skinType = '';
  final _allergiesCtrl   = TextEditingController();
  final _conditionsCtrl  = TextEditingController();
  bool _isPregnant = false;

  // ── Sección 4: Preferencias ────────────────────────────────────────────────
  String _pressure = '';
  String _schedule = '';
  final _notesCtrl = TextEditingController();

  static const _sections = ['Perfil', 'Bienestar', 'Facial', 'Preferencias'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _sections.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) return;

    _email = user.email ?? '';

    try {
      final profile = await _db
          .from('profiles')
          .select('full_name, phone, avatar_url')
          .eq('id', user.id)
          .single();
      _nameCtrl.text  = profile['full_name'] as String? ?? '';
      _phoneCtrl.text = profile['phone'] as String? ?? '';
      _avatarUrl      = profile['avatar_url'] as String?;
    } catch (e) {
      debugPrint('ProfileScreen._loadData profiles: $e');
    }

    try {
      final cp = await _db
          .from('client_profiles')
          .select()
          .eq('client_id', user.id)
          .single();

      _skinType = cp['skin_type'] as String? ?? '';
      _allergiesCtrl.text  = cp['known_allergies']   as String? ?? '';
      _conditionsCtrl.text = cp['medical_conditions'] as String? ?? '';
      _isPregnant = cp['is_pregnant'] as bool? ?? false;
      _pressure   = cp['preferred_pressure']  as String? ?? '';
      _schedule   = cp['preferred_schedule']  as String? ?? '';
      _notesCtrl.text = cp['notes'] as String? ?? '';
    } catch (e) {
      debugPrint('ProfileScreen._loadData client_profiles: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _db.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      await _db.from('client_profiles').upsert({
        'client_id':          user.id,
        'skin_type':          _skinType,
        'known_allergies':    _allergiesCtrl.text.trim(),
        'medical_conditions': _conditionsCtrl.text.trim(),
        'is_pregnant':        _isPregnant,
        'preferred_pressure': _pressure,
        'preferred_schedule': _schedule,
        'notes':              _notesCtrl.text.trim(),
      }, onConflict: 'client_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Perfil actualizado', style: GoogleFonts.inter(color: SaharaColors.black)),
          backgroundColor: SaharaColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e',
              style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: SaharaColors.grayDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: SaharaColors.gold),
              title: Text('Tomar foto', style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: SaharaColors.gold),
              title: Text('Elegir de galería', style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 512);
    if (picked == null) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final path  = '${user.id}/avatar.jpg';

      await _db.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      final publicUrl = _db.storage.from('avatars').getPublicUrl(path);
      // Forzamos cache-bust para que la imagen se refresque
      final urlWithBust = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _db.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);

      if (mounted) {
        setState(() => _avatarUrl = urlWithBust);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Foto actualizada', style: GoogleFonts.inter(color: SaharaColors.black)),
          backgroundColor: SaharaColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir foto: $e',
              style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _uploadingAvatar = false);
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
          ),
          // Glow dorado
          Positioned(
            top: -60, left: 0, right: 0,
            child: Container(height: 260, decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter, radius: 0.75,
                colors: [Color(0x12C6A76A), Colors.transparent],
              ),
            )),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SaharaColors.gold, strokeWidth: 1.5))
                : Column(
                    children: [
                      _buildHeader(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _buildBasicTab(),
                            _buildWellnessTab(),
                            _buildFacialTab(),
                            _buildPrefsTab(),
                          ],
                        ),
                      ),
                      _buildSaveCta(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final name = _nameCtrl.text.trim();
    final initials = name.isNotEmpty
        ? name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Row(
        children: [
          // ── Avatar con botón de cámara ──────────────────────────────────
          GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SaharaColors.gold.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: _avatarUrl != null
                        ? Image.network(
                            _avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(initials),
                          )
                        : _avatarFallback(initials),
                  ),
                ),
                // Indicador de carga
                if (_uploadingAvatar)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: SaharaColors.gold, strokeWidth: 1.5)),
                        ),
                      ),
                    ),
                  ),
                // Icono cámara
                if (!_uploadingAvatar)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: SaharaColors.gold,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SaharaColors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: SaharaColors.black, size: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name.split(' ').first : 'Mi perfil',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SaharaColors.grayDark),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: SaharaColors.grayText, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A1F0E), Color(0xFF1A1408)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(initials, style: GoogleFonts.playfairDisplay(
          fontSize: 22, color: SaharaColors.gold, fontWeight: FontWeight.w500,
        )),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: SaharaColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.zero,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
        labelColor: SaharaColors.gold,
        unselectedLabelColor: SaharaColors.grayText,
        tabs: _sections.map((s) => Tab(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(s),
          ),
        )).toList(),
      ),
    );
  }

  // ── Sección 1: Perfil básico ───────────────────────────────────────────────

  Widget _buildBasicTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      children: [
        _sectionLabel('TU INFORMACIÓN'),
        const SizedBox(height: 16),
        _textField(label: 'Nombre completo', ctrl: _nameCtrl, icon: Icons.person_outline),
        const SizedBox(height: 14),
        _textField(label: 'Teléfono', ctrl: _phoneCtrl, icon: Icons.phone_outlined,
            inputType: TextInputType.phone),
        const SizedBox(height: 14),
        _readonlyField(label: 'Correo electrónico', value: _email, icon: Icons.mail_outline),
        const SizedBox(height: 32),
        _buildMyOrdersBanner(),
        const SizedBox(height: 12),
        _buildMembershipBanner(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMyOrdersBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: SaharaColors.grayDark.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: SaharaColors.grayDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: SaharaColors.grayText, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Mis Órdenes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w400,
                  )),
            ),
            Icon(Icons.chevron_right_rounded,
                color: SaharaColors.grayText.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MembershipsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1200), Color(0xFF0E0C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: SaharaColors.gold.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: SaharaColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Membresía Elite',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w400,
                      )),
                  const SizedBox(height: 2),
                  Text('Oasis Plata · Duna Dorada · Sahara Black',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: SaharaColors.gold.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: SaharaColors.gold.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Sección 2: Bienestar ───────────────────────────────────────────────────

  Widget _buildWellnessTab() {
    const moods = ['Saturada', 'Cansada', 'Desconectada', 'Ansiosa', 'En paz', 'Equilibrada'];
    const areas = ['Cuello', 'Espalda', 'Hombros', 'Pies', 'Piernas', 'Cabeza', 'Brazos', 'Lumbares'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      children: [
        _sectionLabel('¿CÓMO TE SIENTES HOY?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: moods.map((m) => _SelectChip(
            label: m,
            isSelected: _mood == m,
            onTap: () => setState(() => _mood = _mood == m ? '' : m),
          )).toList(),
        ),
        const SizedBox(height: 28),
        _sectionLabel('¿DÓNDE SIENTES TENSIÓN?'),
        const SizedBox(height: 6),
        Text('Puedes seleccionar varias zonas', style: GoogleFonts.inter(
          fontSize: 12, color: SaharaColors.grayText,
        )),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: areas.map((a) => _SelectChip(
            label: a,
            isSelected: _tensionAreas.contains(a),
            onTap: () => setState(() {
              _tensionAreas.contains(a) ? _tensionAreas.remove(a) : _tensionAreas.add(a);
            }),
          )).toList(),
        ),
      ],
    );
  }

  // ── Sección 3: Facial ──────────────────────────────────────────────────────

  Widget _buildFacialTab() {
    const skins = ['Normal', 'Seca', 'Grasa', 'Mixta', 'Sensible'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      children: [
        _sectionLabel('TIPO DE PIEL'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skins.map((s) => _SelectChip(
            label: s,
            isSelected: _skinType == s,
            onTap: () => setState(() => _skinType = _skinType == s ? '' : s),
          )).toList(),
        ),
        const SizedBox(height: 28),
        _sectionLabel('ALERGIAS CONOCIDAS'),
        const SizedBox(height: 14),
        _textField(
          label: 'Ej. látex, fragrancias, frutos secos…',
          ctrl: _allergiesCtrl,
          icon: Icons.warning_amber_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 22),
        _sectionLabel('CONDICIONES MÉDICAS'),
        const SizedBox(height: 14),
        _textField(
          label: 'Ej. hipertensión, diabetes…',
          ctrl: _conditionsCtrl,
          icon: Icons.medical_information_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 22),
        _ToggleRow(
          label: '¿Estás embarazada?',
          value: _isPregnant,
          onChanged: (v) => setState(() => _isPregnant = v),
        ),
      ],
    );
  }

  // ── Sección 4: Preferencias ────────────────────────────────────────────────

  Widget _buildPrefsTab() {
    const pressures = ['Suave', 'Media', 'Profunda'];
    const schedules = ['Mañana', 'Tarde', 'Noche'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      children: [
        _sectionLabel('INTENSIDAD DEL MASAJE'),
        const SizedBox(height: 14),
        Row(
          children: pressures.map((p) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PressureCard(
                label: p,
                isSelected: _pressure == p,
                onTap: () => setState(() => _pressure = _pressure == p ? '' : p),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 28),
        _sectionLabel('HORARIO PREFERIDO'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: schedules.map((s) => _SelectChip(
            label: s,
            isSelected: _schedule == s,
            onTap: () => setState(() => _schedule = _schedule == s ? '' : s),
          )).toList(),
        ),
        const SizedBox(height: 28),
        _sectionLabel('NOTAS ADICIONALES'),
        const SizedBox(height: 14),
        _textField(
          label: 'Algo que debamos saber antes de tu ritual…',
          ctrl: _notesCtrl,
          icon: Icons.notes_outlined,
          maxLines: 4,
        ),
      ],
    );
  }

  // ── Botón guardar ──────────────────────────────────────────────────────────

  Widget _buildSaveCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      decoration: BoxDecoration(
        color: SaharaColors.black.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.1))),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: SaharaColors.gold,
            foregroundColor: SaharaColors.black,
            disabledBackgroundColor: SaharaColors.gold.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5))
              : Text('Guardar perfil', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
                )),
        ),
      ),
    );
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(
      fontSize: 10, color: SaharaColors.gold,
      fontWeight: FontWeight.w700, letterSpacing: 2,
    ));
  }

  Widget _textField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText),
        prefixIcon: Icon(icon, color: SaharaColors.grayText.withValues(alpha: 0.6), size: 18),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _readonlyField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C1C1C)),
      ),
      child: Row(
        children: [
          Icon(icon, color: SaharaColors.grayText.withValues(alpha: 0.4), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(value.isNotEmpty ? value : label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: value.isNotEmpty ? SaharaColors.grayText : SaharaColors.grayText.withValues(alpha: 0.4),
            ),
          )),
          Icon(Icons.lock_outline_rounded, color: SaharaColors.grayText.withValues(alpha: 0.25), size: 14),
        ],
      ),
    );
  }
}

// ── Chips de selección ────────────────────────────────────────────────────────

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.15) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? SaharaColors.gold.withValues(alpha: 0.6) : const Color(0xFF222222),
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 13,
          color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

// ── Tarjeta de presión de masaje ──────────────────────────────────────────────

class _PressureCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PressureCard({required this.label, required this.isSelected, required this.onTap});

  static IconData _iconFor(String label) {
    return switch (label) {
      'Suave'    => Icons.air_rounded,
      'Profunda' => Icons.fitness_center_rounded,
      _          => Icons.spa_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? SaharaColors.gold.withValues(alpha: 0.12) : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SaharaColors.gold.withValues(alpha: 0.55) : const Color(0xFF222222),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(_iconFor(label),
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(
              fontSize: 12,
              color: isSelected ? SaharaColors.gold : SaharaColors.grayText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? SaharaColors.gold.withValues(alpha: 0.3) : const Color(0xFF222222),
        ),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 14, color: SaharaColors.whiteSoft,
          )),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SaharaColors.gold,
            activeTrackColor: SaharaColors.gold.withValues(alpha: 0.25),
            inactiveThumbColor: SaharaColors.grayDark,
            inactiveTrackColor: const Color(0xFF1C1C1C),
          ),
        ],
      ),
    );
  }
}
