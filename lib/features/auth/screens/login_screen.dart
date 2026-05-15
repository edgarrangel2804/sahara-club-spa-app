import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/core/ui_kit.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/models/user_profile.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Respiración del emblema
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;

  // Pulso/glow de los anillos
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _glowCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService().signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      switch (profile.role) {
        case UserRole.admin:
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        case UserRole.therapist:
          Navigator.pushReplacementNamed(context, AppRoutes.therapistDashboard);
        case UserRole.receptionist:
          Navigator.pushReplacementNamed(context, AppRoutes.receptionDashboard);
        case UserRole.client:
          Navigator.pushReplacementNamed(context, AppRoutes.services);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message,
                style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
            backgroundColor: SaharaColors.grayDark,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Stack(
        children: [
          // Fondo degradado premium
          Container(
            decoration: const BoxDecoration(
              gradient: SaharaGradients.backgroundMain,
            ),
          ),
          // Glow radial arriba
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.75,
                    colors: [
                      SaharaColors.gold.withValues(
                        alpha: 0.08 + _glowAnim.value * 0.07,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Contenido
          SafeArea(
            child: FadeIn(
              duration: const Duration(milliseconds: 1000),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 72),
                    _buildEmblem(),
                    const SizedBox(height: 48),
                    _buildForm(),
                    const SizedBox(height: 24),
                    SaharaButton(
                      text: 'INGRESAR',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    _buildSocialDivider(),
                    const SizedBox(height: 16),
                    _buildSocialButtons(),
                    const SizedBox(height: 28),
                    _buildFooterLinks(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmblem() {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheAnim, _glowAnim]),
      builder: (_, __) {
        final breathe = _breatheAnim.value;
        final glow = _glowAnim.value;

        return Transform.scale(
          scale: breathe,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Anillo exterior con glow pulsante
                  Container(
                    width: 108 + glow * 6,
                    height: 108 + glow * 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SaharaColors.gold.withValues(
                            alpha: 0.08 + glow * 0.18,
                          ),
                          blurRadius: 20 + glow * 24,
                          spreadRadius: 2 + glow * 6,
                        ),
                      ],
                    ),
                  ),
                  // Anillo exterior borde
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SaharaColors.gold.withValues(
                          alpha: 0.30 + glow * 0.25,
                        ),
                        width: 1.2,
                      ),
                    ),
                  ),
                  // Anillo interior borde
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SaharaColors.gold.withValues(
                          alpha: 0.18 + glow * 0.20,
                        ),
                        width: 0.8,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          SaharaColors.gold.withValues(
                            alpha: 0.04 + glow * 0.08,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Logo
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Image.asset(
                      'assets/images/icono_02.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.spa_outlined,
                        size: 30,
                        color: SaharaColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'SAHARA CLUB',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: SaharaColors.gold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Wellness & Beauty',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: SaharaColors.gold.withValues(alpha: 0.6),
                  letterSpacing: 3,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              const GoldDivider(),
              const SizedBox(height: 12),
              Text('ACCESO EXCLUSIVO', style: SaharaTextStyles.label),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        SaharaInput(
          hint: 'correo@ejemplo.com',
          label: 'Correo electrónico',
          prefixIcon: Icons.mail_outline,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        SaharaInput(
          hint: '••••••••',
          label: 'Contraseña',
          prefixIcon: Icons.lock_outline,
          obscure: _obscurePassword,
          controller: _passwordCtrl,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: SaharaColors.grayText,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForgotPasswordSheet(
        initialEmail: _emailCtrl.text.trim(),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showForgotPassword,
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SaharaColors.gold.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
              decorationColor: SaharaColors.gold.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Eres nueva clienta? ',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: SaharaColors.grayText,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.register),
              child: Text(
                'Regístrate',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.services),
          child: Text(
            'Explorar sin cuenta →',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: SaharaColors.grayText.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 0.5, color: SaharaColors.grayDark),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: SaharaColors.grayText,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: SaharaColors.grayDark),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: _GoogleIcon(),
            onTap: () {}, // TODO: Google Sign-In
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Facebook',
            icon: const _FacebookIcon(),
            onTap: () {}, // TODO: Facebook Sign-In
          ),
        ),
      ],
    );
  }
}

// ── Botón social genérico ───────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SaharaColors.gold.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: SaharaColors.whiteSoft.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Íconos vectoriales (sin dependencias externas) ──────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: SaharaColors.gold, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: SaharaColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

// ── Forgot password bottom sheet ─────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({this.initialEmail = ''});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final _ctrl = TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService().resetPassword(email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message,
              style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
          backgroundColor: SaharaColors.grayDark,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: SaharaColors.grayDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recuperar contraseña',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w400,
            )),
          const SizedBox(height: 8),
          if (!_sent) ...[
            Text(
              'Te enviaremos un enlace para restablecer tu contraseña.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.grayText, height: 1.5),
            ),
            const SizedBox(height: 24),
            SaharaInput(
              label: 'Correo electrónico',
              hint: 'correo@ejemplo.com',
              prefixIcon: Icons.mail_outline,
              controller: _ctrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SaharaButton(
              text: 'ENVIAR ENLACE',
              onPressed: _send,
              isLoading: _loading,
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SaharaColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: SaharaColors.gold.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: SaharaColors.gold, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Revisa tu correo. Si la cuenta existe, recibirás el enlace en unos minutos.',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: SaharaColors.whiteSoft,
                        height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar',
                    style: GoogleFonts.inter(
                        color: SaharaColors.grayText, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Facebook icon ─────────────────────────────────────────────────────────────

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SaharaColors.gold, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: SaharaColors.gold,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
