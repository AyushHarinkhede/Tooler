import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StationeryThemeMode {
  classicDoodle, // Notebook paper, pastel stationery, pencil graphite
  blueprintChalkboard, // Deep navy/blackboard, cyan chalk, neon accents
  neonHighlighter, // Dark desk, fluorescent highlighter yellow/pink/cyan
}

class StationeryTheme {
  // Classic School Kit Palette
  static const Color classicBg = Color(0xFFFDF5E6); // Warm parchment notebook paper
  static const Color classicNoteBg = Color(0xFFFFFBE8); // Sticky note yellow
  static const Color classicText = Color(0xFF2C3E50); // Deep graphite pencil
  static const Color classicPrimary = Color(0xFFFF6B6B); // Coral red pen
  static const Color classicSecondary = Color(0xFF4ECDC4); // Mint ruler teal
  static const Color classicAccent = Color(0xFFF9D423); // Yellow highlighter
  static const Color classicTape = Color(0x99FFE853); // Translucent tape
  static const Color classicBorder = Color(0xFF3A3A3A); // Hand-drawn pen border
  static const Color classicBlueLine = Color(0x4093B8D4); // Notebook blue rule
  static const Color classicRedMargin = Color(0x60FF6B6B); // Notebook red margin
  static const Color classicWood = Color(0xFFD2A679); // Wooden ruler

  // Blueprint / Chalkboard Palette
  static const Color blueprintBg = Color(0xFF1A1A2E); // Deep blackboard navy
  static const Color blueprintNoteBg = Color(0xFF16213E);
  static const Color blueprintText = Color(0xFFF0F4F8); // White chalk
  static const Color blueprintPrimary = Color(0xFF4A9EFF); // Cyan chalk
  static const Color blueprintSecondary = Color(0xFF00D4FF);
  static const Color blueprintAccent = Color(0xFFFF6B6B);
  static const Color blueprintTape = Color(0x664A9EFF);
  static const Color blueprintBorder = Color(0xFF4A9EFF);
  static const Color blueprintGrid = Color(0x334A9EFF);

  // Neon Highlighter Palette
  static const Color neonBg = Color(0xFF121212); // Carbon desk
  static const Color neonNoteBg = Color(0xFF1E1E1E);
  static const Color neonText = Color(0xFFFFFFFF);
  static const Color neonPrimary = Color(0xFFFFE600); // Electric highlighter yellow
  static const Color neonSecondary = Color(0xFF00FFF0); // Highlighter cyan
  static const Color neonAccent = Color(0xFFFF007F); // Highlighter pink
  static const Color neonTape = Color(0x88FFE600);
  static const Color neonBorder = Color(0xFFFFE600);

  // Active theme colors
  final StationeryThemeMode mode;

  StationeryTheme(this.mode);

  Color get bg {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintBg;
      case StationeryThemeMode.neonHighlighter:
        return neonBg;
      case StationeryThemeMode.classicDoodle:
        return classicBg;
    }
  }

  Color get cardBg {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintNoteBg;
      case StationeryThemeMode.neonHighlighter:
        return neonNoteBg;
      case StationeryThemeMode.classicDoodle:
        return classicNoteBg;
    }
  }

  Color get text {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintText;
      case StationeryThemeMode.neonHighlighter:
        return neonText;
      case StationeryThemeMode.classicDoodle:
        return classicText;
    }
  }

  Color get primary {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintPrimary;
      case StationeryThemeMode.neonHighlighter:
        return neonPrimary;
      case StationeryThemeMode.classicDoodle:
        return classicPrimary;
    }
  }

  Color get secondary {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintSecondary;
      case StationeryThemeMode.neonHighlighter:
        return neonSecondary;
      case StationeryThemeMode.classicDoodle:
        return classicSecondary;
    }
  }

  Color get accent {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintAccent;
      case StationeryThemeMode.neonHighlighter:
        return neonAccent;
      case StationeryThemeMode.classicDoodle:
        return classicAccent;
    }
  }

  Color get border {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintBorder;
      case StationeryThemeMode.neonHighlighter:
        return neonBorder;
      case StationeryThemeMode.classicDoodle:
        return classicBorder;
    }
  }

  Color get tape {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return blueprintTape;
      case StationeryThemeMode.neonHighlighter:
        return neonTape;
      case StationeryThemeMode.classicDoodle:
        return classicTape;
    }
  }

  // School Stationary Fonts
  TextStyle fontDoodle({double fontSize = 16, FontWeight fontWeight = FontWeight.normal, Color? color}) {
    return GoogleFonts.kalam(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
    );
  }

  TextStyle fontHandwritten({double fontSize = 18, FontWeight fontWeight = FontWeight.bold, Color? color}) {
    return GoogleFonts.patrickHand(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
    );
  }

  TextStyle fontDisplay({double fontSize = 24, FontWeight fontWeight = FontWeight.bold, Color? color}) {
    return GoogleFonts.architectsDaughter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
      letterSpacing: 1.1,
    );
  }

  TextStyle fontMono({double fontSize = 16, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
    );
  }

  // Doodle Card Decoration
  BoxDecoration doodleCard({
    Color? color,
    Color? borderColor,
    double borderWidth = 2.5,
    double borderRadius = 16.0,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? border,
        width: borderWidth,
      ),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: (borderColor ?? border).withOpacity(0.35),
                offset: const Offset(4, 5),
                blurRadius: 0, // Sharp tactile comic shadow
              ),
            ]
          : null,
    );
  }
}
