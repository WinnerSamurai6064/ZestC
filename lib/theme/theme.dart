import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZestTheme {
  // Lime-green palette
  static const Color limeGreen = Color(0xFFB5E853);
  static const Color limeGreenDark = Color(0xFF8BC34A);
  static const Color limeGreenDeep = Color(0xFF6AB04C);
  static const Color limeAccent = Color(0xFFCCFF66);
  static const Color limeSoft = Color(0xFFE8F5C8);

  // Dark base
  static const Color darkBase = Color(0xFF0A0F0A);
  static const Color darkSurface = Color(0xFF111811);
  static const Color darkCard = Color(0xFF1A231A);
  static const Color darkBorder = Color(0xFF2A3A2A);

  // Text
  static const Color textPrimary = Color(0xFFF0F8E8);
  static const Color textSecondary = Color(0xFFA0B890);
  static const Color textMuted = Color(0xFF607060);

  // Status
  static const Color online = Color(0xFF4CAF50);
  static const Color sent = Color(0xFF9E9E9E);
  static const Color delivered = Color(0xFF90A4AE);
  static const Color read = limeGreenDark;

  // Glass card styling
  static BoxDecoration glassCard({
    double opacity = 0.08,
    double borderOpacity = 0.15,
    double radius = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white.withOpacity(opacity),
      border: Border.all(
        color: limeGreen.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: limeGreen.withOpacity(0.04),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ],
    );
  }

  static BoxDecoration sentBubble() => BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        gradient: LinearGradient(
          colors: [limeGreen, limeGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: limeGreen.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration receivedBubble() => BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        color: darkCard,
        border: Border.all(color: darkBorder),
      );

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBase,
      colorScheme: ColorScheme.dark(
        primary: limeGreen,
        secondary: limeGreenDark,
        surface: darkSurface,
        background: darkBase,
        onPrimary: darkBase,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
            color: textPrimary, fontWeight: FontWeight.w700),
        bodyMedium: GoogleFonts.spaceGrotesk(color: textPrimary),
        bodySmall: GoogleFonts.spaceGrotesk(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: limeGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
