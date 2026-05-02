import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/core/ui_kit.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty) {
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Las contraseñas no coinciden',
            style: GoogleFonts.inter(color: SaharaColors.whiteSoft),
          ),
          backgroundColor: SaharaColors.grayDark,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().signUp(
        fullName: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.services);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style: GoogleFonts.inter(color: SaharaColors.whiteSoft),
            ),
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
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.75,
                    colors: [
                      SaharaColors.gold.withValues(
                        alpha: 0.06 + _glowAnim.value * 0.06,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeIn(
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          _buildTitle(),
                          const SizedBox(height: 28),
                          _buildForm(),
                          const SizedBox(height: 28),
                          SaharaButton(
                            text: 'CREAR CUENTA',
                            onPressed: _handleRegister,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 20),
                          _buildFooter(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: SaharaColors.gold,
                size: 16,
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Image.asset(
                'assets/images/icono_02.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.spa_outlined,
                  size: 22,
                  color: SaharaColors.gold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SAHARA CLUB',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11,
                  color: SaharaColors.gold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comienza tu proceso',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            color: SaharaColors.whiteSoft,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crea tu cuenta y vive una experiencia hecha para ti.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: SaharaColors.grayText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        const GoldDivider(),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        SaharaInput(
          hint: 'Tu nombre completo',
          label: 'Nombre completo',
          prefixIcon: Icons.person_outline,
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 14),
        SaharaInput(
          hint: 'correo@ejemplo.com',
          label: 'Correo electrónico',
          prefixIcon: Icons.mail_outline,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        SaharaInput(
          hint: '••••••••',
          label: 'Confirmar contraseña',
          prefixIcon: Icons.lock_outline,
          obscure: _obscureConfirm,
          controller: _confirmCtrl,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: SaharaColors.grayText,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            text: '¿Ya tienes cuenta? ',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SaharaColors.grayText,
            ),
            children: [
              TextSpan(
                text: 'Inicia sesión',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SaharaColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
