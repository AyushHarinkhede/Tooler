import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StationeryThemeMode {
  classicDoodle, // Minimal Light Mode
  blueprintChalkboard, // Midnight Dark Mode
  neonHighlighter, // Soft Pastel Mode
}

enum ToolerAccent {
  lilac, // Classic Purple (#A855F7, #EDE9FE)
  rose, // Soft Blush (#FB7185, #FFE4E6)
  mint, // Sage Mint (#10B981, #D1FAE5)
  sky, // Ocean Sky (#0EA5E9, #E0F2FE)
  amber, // Warm Amber (#F59E0B, #FEF3C7)
}

class StationeryTheme {
  final bool isDark;
  final ToolerAccent accentPalette;
  final StationeryThemeMode mode;

  StationeryTheme(
    this.mode, {
    bool? isDark,
    ToolerAccent? accentPalette,
  })  : isDark = isDark ?? (mode == StationeryThemeMode.blueprintChalkboard),
        accentPalette = accentPalette ??
            (mode == StationeryThemeMode.neonHighlighter
                ? ToolerAccent.rose
                : ToolerAccent.lilac);

  StationeryTheme.custom({
    required this.isDark,
    ToolerAccent? accentPalette,
    ToolerAccent? accent,
  })  : accentPalette = accentPalette ?? accent ?? ToolerAccent.lilac,
        mode = isDark
            ? StationeryThemeMode.blueprintChalkboard
            : ((accentPalette ?? accent) == ToolerAccent.rose
                ? StationeryThemeMode.neonHighlighter
                : StationeryThemeMode.classicDoodle);

  // Surface & Canvas Backgrounds
  Color get bg => isDark ? const Color(0xFF09090B) : const Color(0xFFFAFAFC);
  Color get cardBg => isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
  Color get border => isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
  Color get text => isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
  Color get textSecondary => isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

  // Dynamic Primary Accent
  Color get primary {
    if (isDark) {
      switch (accentPalette) {
        case ToolerAccent.lilac:
          return const Color(0xFFC084FC);
        case ToolerAccent.rose:
          return const Color(0xFFFB7185);
        case ToolerAccent.mint:
          return const Color(0xFF34D399);
        case ToolerAccent.sky:
          return const Color(0xFF38BDF8);
        case ToolerAccent.amber:
          return const Color(0xFFFBBF24);
      }
    } else {
      switch (accentPalette) {
        case ToolerAccent.lilac:
          return const Color(0xFFA855F7);
        case ToolerAccent.rose:
          return const Color(0xFFF43F5E);
        case ToolerAccent.mint:
          return const Color(0xFF10B981);
        case ToolerAccent.sky:
          return const Color(0xFF0284C7);
        case ToolerAccent.amber:
          return const Color(0xFFF59E0B);
      }
    }
  }

  Color get primaryDark {
    switch (accentPalette) {
      case ToolerAccent.lilac:
        return const Color(0xFF7C3AED);
      case ToolerAccent.rose:
        return const Color(0xFFE11D48);
      case ToolerAccent.mint:
        return const Color(0xFF059669);
      case ToolerAccent.sky:
        return const Color(0xFF0369A1);
      case ToolerAccent.amber:
        return const Color(0xFFD97706);
    }
  }

  Color get secondary {
    switch (accentPalette) {
      case ToolerAccent.lilac:
        return const Color(0xFFB388FF);
      case ToolerAccent.rose:
        return const Color(0xFFFDA4AF);
      case ToolerAccent.mint:
        return const Color(0xFF6EE7B7);
      case ToolerAccent.sky:
        return const Color(0xFF7DD3FC);
      case ToolerAccent.amber:
        return const Color(0xFFFDE68A);
    }
  }

  Color get accent {
    if (isDark) {
      switch (accentPalette) {
        case ToolerAccent.lilac:
          return const Color(0xFFDDD6FE);
        case ToolerAccent.rose:
          return const Color(0xFFFECDD3);
        case ToolerAccent.mint:
          return const Color(0xFFA7F3D0);
        case ToolerAccent.sky:
          return const Color(0xFFBAE6FD);
        case ToolerAccent.amber:
          return const Color(0xFFFDE68A);
      }
    } else {
      switch (accentPalette) {
        case ToolerAccent.lilac:
          return const Color(0xFFC084FC);
        case ToolerAccent.rose:
          return const Color(0xFFFB7185);
        case ToolerAccent.mint:
          return const Color(0xFF34D399);
        case ToolerAccent.sky:
          return const Color(0xFF38BDF8);
        case ToolerAccent.amber:
          return const Color(0xFFFBBF24);
      }
    }
  }

  Color get accentColorDot {
    switch (accentPalette) {
      case ToolerAccent.lilac:
        return const Color(0xFFA855F7);
      case ToolerAccent.rose:
        return const Color(0xFFFB7185);
      case ToolerAccent.mint:
        return const Color(0xFF10B981);
      case ToolerAccent.sky:
        return const Color(0xFF0EA5E9);
      case ToolerAccent.amber:
        return const Color(0xFFF59E0B);
    }
  }

  // Soft Tinted Hero & Card Background
  Color get lavenderCard {
    if (isDark) return const Color(0xFF27272A);
    switch (accentPalette) {
      case ToolerAccent.lilac:
        return const Color(0xFFF5F3FF);
      case ToolerAccent.rose:
        return const Color(0xFFFFF1F2);
      case ToolerAccent.mint:
        return const Color(0xFFF0FDF4);
      case ToolerAccent.sky:
        return const Color(0xFFF0F9FF);
      case ToolerAccent.amber:
        return const Color(0xFFFFFBEB);
    }
  }

  // 2D Backdrop Bubble Accent
  Color get lavenderBubble {
    if (isDark) return const Color(0xFF3F3F46);
    switch (accentPalette) {
      case ToolerAccent.lilac:
        return const Color(0xFFEDE9FE);
      case ToolerAccent.rose:
        return const Color(0xFFFFE4E6);
      case ToolerAccent.mint:
        return const Color(0xFFD1FAE5);
      case ToolerAccent.sky:
        return const Color(0xFFE0F2FE);
      case ToolerAccent.amber:
        return const Color(0xFFFEF3C7);
    }
  }

  Color get tape => primary.withValues(alpha: 0.2);

  // Modern Clean Typography
  TextStyle fontDoodle({double fontSize = 15, FontWeight fontWeight = FontWeight.w500, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
    );
  }

  TextStyle fontHandwritten({double fontSize = 16, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
    );
  }

  TextStyle fontDisplay({double fontSize = 22, FontWeight fontWeight = FontWeight.w700, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
      letterSpacing: -0.3,
    );
  }

  TextStyle fontMono({double fontSize = 15, FontWeight fontWeight = FontWeight.w600, Color? color}) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? text,
    );
  }

  // Clean Modern Card Decoration
  BoxDecoration doodleCard({
    Color? color,
    Color? borderColor,
    double borderWidth = 1.2,
    double borderRadius = 20.0,
    bool hasShadow = false,
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
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ]
          : null,
    );
  }
}
