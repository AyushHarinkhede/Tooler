import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StationeryThemeMode {
  classicDoodle, // Minimal Aesthetic Lilac & Pure White (matching reference UI)
  blueprintChalkboard, // Modern Dark Slate & Lilac Accent
  neonHighlighter, // Soft Minimal Blush Rose
}

class StationeryTheme {
  // Minimal Aesthetic Lilac Palette (Image 1 & 2 Match)
  static const Color classicBg = Color(0xFFFAFAFC); // Clean crisp canvas
  static const Color classicCardBg = Color(0xFFFFFFFF); // Pure white card
  static const Color classicLavenderCard = Color(0xFFF5F3FF); // Soft lilac hero/banner
  static const Color classicLavenderBubble = Color(0xFFEDE9FE); // 2D backdrop accent
  static const Color classicText = Color(0xFF18181B); // Deep charcoal black
  static const Color classicTextSecondary = Color(0xFF71717A); // Neutral slate
  static const Color classicPrimary = Color(0xFFA855F7); // Vibrant lilac purple
  static const Color classicPrimaryDark = Color(0xFF7C3AED); // Deep violet
  static const Color classicSecondary = Color(0xFFB388FF); // Soft purple
  static const Color classicAccent = Color(0xFFC084FC); // Lilac highlight
  static const Color classicTape = Color(0x33A855F7); // Subtle translucent accent
  static const Color classicBorder = Color(0xFFE4E4E7); // Clean, thin outline (1.2px)
  static const Color classicBlueLine = Colors.transparent;
  static const Color classicRedMargin = Colors.transparent;
  static const Color classicWood = Color(0xFFEDE9FE);

  // Modern Dark Slate & Lilac
  static const Color darkBg = Color(0xFF09090B);
  static const Color darkCardBg = Color(0xFF18181B);
  static const Color darkLavenderCard = Color(0xFF27272A);
  static const Color darkLavenderBubble = Color(0xFF3F3F46);
  static const Color darkText = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkPrimary = Color(0xFFC084FC);
  static const Color darkPrimaryDark = Color(0xFFA855F7);
  static const Color darkSecondary = Color(0xFFE9D5FF);
  static const Color darkAccent = Color(0xFF9333EA);
  static const Color darkTape = Color(0x33C084FC);
  static const Color darkBorder = Color(0xFF27272A);

  // Soft Minimal Blush Rose
  static const Color blushBg = Color(0xFFFFF1F2);
  static const Color blushCardBg = Color(0xFFFFFFFF);
  static const Color blushLavenderCard = Color(0xFFFFE4E6);
  static const Color blushLavenderBubble = Color(0xFFFECDD3);
  static const Color blushText = Color(0xFF1F2937);
  static const Color blushTextSecondary = Color(0xFF6B7280);
  static const Color blushPrimary = Color(0xFFF43F5E);
  static const Color blushPrimaryDark = Color(0xFFE11D48);
  static const Color blushSecondary = Color(0xFFFB7185);
  static const Color blushAccent = Color(0xFFFDA4AF);
  static const Color blushTape = Color(0x33F43F5E);
  static const Color blushBorder = Color(0xFFFFE4E6);

  final StationeryThemeMode mode;

  StationeryTheme(this.mode);

  Color get bg {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkBg;
      case StationeryThemeMode.neonHighlighter:
        return blushBg;
      case StationeryThemeMode.classicDoodle:
        return classicBg;
    }
  }

  Color get cardBg {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkCardBg;
      case StationeryThemeMode.neonHighlighter:
        return blushCardBg;
      case StationeryThemeMode.classicDoodle:
        return classicCardBg;
    }
  }

  Color get lavenderCard {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkLavenderCard;
      case StationeryThemeMode.neonHighlighter:
        return blushLavenderCard;
      case StationeryThemeMode.classicDoodle:
        return classicLavenderCard;
    }
  }

  Color get lavenderBubble {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkLavenderBubble;
      case StationeryThemeMode.neonHighlighter:
        return blushLavenderBubble;
      case StationeryThemeMode.classicDoodle:
        return classicLavenderBubble;
    }
  }

  Color get text {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkText;
      case StationeryThemeMode.neonHighlighter:
        return blushText;
      case StationeryThemeMode.classicDoodle:
        return classicText;
    }
  }

  Color get textSecondary {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkTextSecondary;
      case StationeryThemeMode.neonHighlighter:
        return blushTextSecondary;
      case StationeryThemeMode.classicDoodle:
        return classicTextSecondary;
    }
  }

  Color get primary {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkPrimary;
      case StationeryThemeMode.neonHighlighter:
        return blushPrimary;
      case StationeryThemeMode.classicDoodle:
        return classicPrimary;
    }
  }

  Color get primaryDark {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkPrimaryDark;
      case StationeryThemeMode.neonHighlighter:
        return blushPrimaryDark;
      case StationeryThemeMode.classicDoodle:
        return classicPrimaryDark;
    }
  }

  Color get secondary {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkSecondary;
      case StationeryThemeMode.neonHighlighter:
        return blushSecondary;
      case StationeryThemeMode.classicDoodle:
        return classicSecondary;
    }
  }

  Color get accent {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkAccent;
      case StationeryThemeMode.neonHighlighter:
        return blushAccent;
      case StationeryThemeMode.classicDoodle:
        return classicAccent;
    }
  }

  Color get border {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkBorder;
      case StationeryThemeMode.neonHighlighter:
        return blushBorder;
      case StationeryThemeMode.classicDoodle:
        return classicBorder;
    }
  }

  Color get tape {
    switch (mode) {
      case StationeryThemeMode.blueprintChalkboard:
        return darkTape;
      case StationeryThemeMode.neonHighlighter:
        return blushTape;
      case StationeryThemeMode.classicDoodle:
        return classicTape;
    }
  }

  // Modern Clean Typography (GoogleFonts.plusJakartaSans)
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

  // Modern Clean Minimal Card Decoration
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
