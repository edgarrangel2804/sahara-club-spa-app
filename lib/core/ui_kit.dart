import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

// ─── Text Styles ─────────────────────────────────────────────────────────────

class SaharaTextStyles {
  static TextStyle get title => GoogleFonts.playfairDisplay(
        fontSize: 24,
        color: SaharaColors.whiteSoft,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 16,
        color: SaharaColors.grayText,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: SaharaColors.black,
        letterSpacing: 0.5,
      );

  static TextStyle get goldTitle => GoogleFonts.playfairDisplay(
        fontSize: 22,
        color: SaharaColors.gold,
        letterSpacing: 3,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        color: SaharaColors.grayText,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      );
}

// ─── SaharaButton ────────────────────────────────────────────────────────────

class SaharaButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const SaharaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isLoading ? null : SaharaGradients.goldShimmer,
          color: isLoading ? SaharaColors.grayDark : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: SaharaColors.gold.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: SaharaColors.gold,
                  strokeWidth: 1.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: SaharaColors.black),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: SaharaTextStyles.button),
                ],
              ),
      ),
    );
  }
}

// ─── SaharaInput ─────────────────────────────────────────────────────────────

class SaharaInput extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? label;

  const SaharaInput({
    super.key,
    required this.hint,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: SaharaColors.whiteSoft),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        hintStyle: GoogleFonts.inter(color: SaharaColors.grayText, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: SaharaColors.grayText, fontSize: 13),
        filled: true,
        fillColor: Colors.transparent,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: SaharaColors.grayText)
            : null,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: SaharaColors.grayDark),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: SaharaColors.gold, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}

// ─── SaharaCard ──────────────────────────────────────────────────────────────

class SaharaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool goldBorder;

  const SaharaCard({
    super.key,
    required this.child,
    this.padding,
    this.goldBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: SaharaGradients.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goldBorder
              ? SaharaColors.gold.withValues(alpha: 0.35)
              : SaharaColors.grayDark,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── FadeIn ──────────────────────────────────────────────────────────────────

class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

// ─── SaharaScaffold (fondo premium listo) ────────────────────────────────────

class SaharaScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showGoldGlow;

  const SaharaScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showGoldGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
          ),
          if (showGoldGlow)
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Container(
                height: 320,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.75,
                    colors: [Color(0x16C6A76A), Colors.transparent],
                  ),
                ),
              ),
            ),
          body,
        ],
      ),
    );
  }
}
