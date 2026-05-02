import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaharaColors {
  // Fondos
  static const Color black = Color(0xFF0B0B0B);
  static const Color wineDark = Color(0xFF2B0A0E);
  static const Color wineMid = Color(0xFF1A0D0F);
  static const Color wineAccent = Color(0xFF3A0F14);

  // Dorados
  static const Color gold = Color(0xFFC6A76A);
  static const Color goldLight = Color(0xFFE5C98B);
  static const Color goldDim = Color(0xFF9A7D4A);

  // Texto
  static const Color whiteSoft = Color(0xFFEDEDED);
  static const Color grayText = Color(0xFFA8A8A8);
  static const Color grayDark = Color(0xFF2A2A2A);

  // Legacy aliases (mantener compatibilidad)
  static const Color primary = wineDark;
  static const Color sand = gold;
  static const Color cream = whiteSoft;
  static const Color textBrown = whiteSoft;
  static const Color white = Color(0xFFFFFFFF);
  static const Color sandLight = grayDark;
  static const Color primaryLight = wineAccent;
}

class SaharaGradients {
  static const LinearGradient backgroundMain = LinearGradient(
    colors: [SaharaColors.black, SaharaColors.wineMid, SaharaColors.wineDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundCard = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF140A0C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldShimmer = LinearGradient(
    colors: [SaharaColors.goldDim, SaharaColors.gold, SaharaColors.goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient goldGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Color(0x1AC6A76A), Colors.transparent],
  );
}

class SaharaTheme {
  static TextStyle _playfair({
    double fontSize = 16,
    FontWeight weight = FontWeight.w400,
    Color color = SaharaColors.whiteSoft,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle _inter({
    double fontSize = 14,
    FontWeight weight = FontWeight.w400,
    Color color = SaharaColors.whiteSoft,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SaharaColors.black,
        colorScheme: const ColorScheme.dark(
          primary: SaharaColors.gold,
          secondary: SaharaColors.wineAccent,
          surface: Color(0xFF151515),
          onPrimary: SaharaColors.black,
          onSecondary: SaharaColors.whiteSoft,
          onSurface: SaharaColors.whiteSoft,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: _playfair(
            fontSize: 16,
            letterSpacing: 4,
            color: SaharaColors.gold,
          ),
          iconTheme: const IconThemeData(color: SaharaColors.gold),
        ),
        textTheme: TextTheme(
          displayLarge: _playfair(fontSize: 32, letterSpacing: 1, color: SaharaColors.gold),
          displayMedium: _playfair(fontSize: 26, color: SaharaColors.gold),
          headlineLarge: _playfair(fontSize: 22, color: SaharaColors.gold),
          headlineMedium: _playfair(fontSize: 18, color: SaharaColors.gold),
          titleLarge: _inter(fontSize: 16, weight: FontWeight.w600, color: SaharaColors.whiteSoft),
          bodyLarge: _inter(fontSize: 15, color: SaharaColors.whiteSoft),
          bodyMedium: _inter(fontSize: 13, color: SaharaColors.grayText),
          labelLarge: _inter(fontSize: 14, weight: FontWeight.w600, letterSpacing: 1, color: SaharaColors.black),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: _inter(color: SaharaColors.grayText),
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SaharaColors.gold,
            foregroundColor: SaharaColors.black,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: SaharaColors.grayDark,
          selectedColor: SaharaColors.gold.withValues(alpha: 0.2),
          labelStyle: _inter(fontSize: 12, color: SaharaColors.grayText),
          secondaryLabelStyle: _inter(fontSize: 12, color: SaharaColors.gold),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: SaharaColors.grayDark),
          ),
          side: const BorderSide(color: SaharaColors.grayDark),
        ),
        dividerTheme: const DividerThemeData(
          color: SaharaColors.grayDark,
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: SaharaColors.gold),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SaharaColors.grayDark,
          contentTextStyle: _inter(color: SaharaColors.whiteSoft),
        ),
      );
}

// Widget helper para el fondo degradado premium
class SaharaBackground extends StatelessWidget {
  final Widget child;
  const SaharaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
      child: child,
    );
  }
}

// Texto dorado con Playfair
class GoldTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final TextAlign textAlign;

  const GoldTitle(
    this.text, {
    super.key,
    this.fontSize = 22,
    this.letterSpacing = 0,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: SaharaColors.gold,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

// Divisor con diamante dorado
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: SaharaColors.grayDark)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.diamond_outlined, size: 12, color: SaharaColors.gold.withValues(alpha: 0.6)),
        ),
        Expanded(child: Container(height: 1, color: SaharaColors.grayDark)),
      ],
    );
  }
}
