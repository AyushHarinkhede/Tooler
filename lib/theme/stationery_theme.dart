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
  indigo, // Electric Indigo (#6366F1, #E0E7FF)
  emerald, // Deep Emerald (#059669, #D1FAE5)
  coral, // Sunset Coral (#FF6B6B, #FFEDD5)
  cyan, // Cyber Aqua (#06B6D4, #CFFAFE)
  crimson, // Velvet Crimson (#E11D48, #FFE4E6)
  berry, // Berry Orchid (#D946EF, #FAE8FF)
  lemon, // Neon Lime (#84CC16, #ECFCCB)
  slate, // Nordic Slate (#64748B, #F1F5F9)
}

extension ToolerAccentInfo on ToolerAccent {
  String get displayName {
    switch (this) {
      case ToolerAccent.lilac:
        return 'Lilac Violet';
      case ToolerAccent.rose:
        return 'Blush Rose';
      case ToolerAccent.mint:
        return 'Sage Mint';
      case ToolerAccent.sky:
        return 'Ocean Sky';
      case ToolerAccent.amber:
        return 'Sunset Amber';
      case ToolerAccent.indigo:
        return 'Electric Indigo';
      case ToolerAccent.emerald:
        return 'Deep Emerald';
      case ToolerAccent.coral:
        return 'Sunset Coral';
      case ToolerAccent.cyan:
        return 'Cyber Aqua';
      case ToolerAccent.crimson:
        return 'Velvet Crimson';
      case ToolerAccent.berry:
        return 'Berry Orchid';
      case ToolerAccent.lemon:
        return 'Neon Lime';
      case ToolerAccent.slate:
        return 'Nordic Slate';
    }
  }

  String get description {
    switch (this) {
      case ToolerAccent.lilac:
        return 'Creative, calm & royal purple';
      case ToolerAccent.rose:
        return 'Soft warm floral pink';
      case ToolerAccent.mint:
        return 'Fresh botanical sage mint';
      case ToolerAccent.sky:
        return 'Crisp azure ocean blue';
      case ToolerAccent.amber:
        return 'Warm golden radiant sunlight';
      case ToolerAccent.indigo:
        return 'Deep cyber ultramarine indigo';
      case ToolerAccent.emerald:
        return 'Rich jewel forest emerald';
      case ToolerAccent.coral:
        return 'Punchy warm sunset coral';
      case ToolerAccent.cyan:
        return 'Electric futuristic teal aqua';
      case ToolerAccent.crimson:
        return 'Sophisticated luxury velvet red';
      case ToolerAccent.berry:
        return 'Vivid high-energy magenta fuchsia';
      case ToolerAccent.lemon:
        return 'Zesty modern citrus lime';
      case ToolerAccent.slate:
        return 'Minimalist Scandinavian steel';
    }
  }

  Color get swatchColor {
    switch (this) {
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
      case ToolerAccent.indigo:
        return const Color(0xFF6366F1);
      case ToolerAccent.emerald:
        return const Color(0xFF059669);
      case ToolerAccent.coral:
        return const Color(0xFFFF6B6B);
      case ToolerAccent.cyan:
        return const Color(0xFF06B6D4);
      case ToolerAccent.crimson:
        return const Color(0xFFE11D48);
      case ToolerAccent.berry:
        return const Color(0xFFD946EF);
      case ToolerAccent.lemon:
        return const Color(0xFF84CC16);
      case ToolerAccent.slate:
        return const Color(0xFF64748B);
    }
  }

  String get tag {
    switch (this) {
      case ToolerAccent.lilac:
        return 'Classic';
      case ToolerAccent.rose:
        return 'Soft';
      case ToolerAccent.mint:
        return 'Fresh';
      case ToolerAccent.sky:
        return 'Popular';
      case ToolerAccent.amber:
        return 'Warm';
      case ToolerAccent.indigo:
        return 'Vibrant';
      case ToolerAccent.emerald:
        return 'Nature';
      case ToolerAccent.coral:
        return 'Sunset';
      case ToolerAccent.cyan:
        return 'Cyber';
      case ToolerAccent.crimson:
        return 'Luxury';
      case ToolerAccent.berry:
        return 'Vivid';
      case ToolerAccent.lemon:
        return 'Citrus';
      case ToolerAccent.slate:
        return 'Minimal';
    }
  }
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
        case ToolerAccent.indigo:
          return const Color(0xFF818CF8);
        case ToolerAccent.emerald:
          return const Color(0xFF34D399);
        case ToolerAccent.coral:
          return const Color(0xFFFB923C);
        case ToolerAccent.cyan:
          return const Color(0xFF22D3EE);
        case ToolerAccent.crimson:
          return const Color(0xFFFB7185);
        case ToolerAccent.berry:
          return const Color(0xFFE879F9);
        case ToolerAccent.lemon:
          return const Color(0xFFA3E635);
        case ToolerAccent.slate:
          return const Color(0xFF94A3B8);
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
        case ToolerAccent.indigo:
          return const Color(0xFF4F46E5);
        case ToolerAccent.emerald:
          return const Color(0xFF059669);
        case ToolerAccent.coral:
          return const Color(0xFFEA580C);
        case ToolerAccent.cyan:
          return const Color(0xFF0891B2);
        case ToolerAccent.crimson:
          return const Color(0xFFBE123C);
        case ToolerAccent.berry:
          return const Color(0xFFC026D3);
        case ToolerAccent.lemon:
          return const Color(0xFF65A30D);
        case ToolerAccent.slate:
          return const Color(0xFF475569);
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
      case ToolerAccent.indigo:
        return const Color(0xFF3730A3);
      case ToolerAccent.emerald:
        return const Color(0xFF047857);
      case ToolerAccent.coral:
        return const Color(0xFFC2410C);
      case ToolerAccent.cyan:
        return const Color(0xFF0E7490);
      case ToolerAccent.crimson:
        return const Color(0xFF9F1239);
      case ToolerAccent.berry:
        return const Color(0xFFA21CAF);
      case ToolerAccent.lemon:
        return const Color(0xFF4D7C0F);
      case ToolerAccent.slate:
        return const Color(0xFF334155);
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
      case ToolerAccent.indigo:
        return const Color(0xFFA5B4FC);
      case ToolerAccent.emerald:
        return const Color(0xFF6EE7B7);
      case ToolerAccent.coral:
        return const Color(0xFFFDBA74);
      case ToolerAccent.cyan:
        return const Color(0xFF67E8F9);
      case ToolerAccent.crimson:
        return const Color(0xFFFDA4AF);
      case ToolerAccent.berry:
        return const Color(0xFFF0ABFC);
      case ToolerAccent.lemon:
        return const Color(0xFFBEF264);
      case ToolerAccent.slate:
        return const Color(0xFFCBD5E1);
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
        case ToolerAccent.indigo:
          return const Color(0xFFC7D2FE);
        case ToolerAccent.emerald:
          return const Color(0xFFA7F3D0);
        case ToolerAccent.coral:
          return const Color(0xFFFED7AA);
        case ToolerAccent.cyan:
          return const Color(0xFFA5F3FC);
        case ToolerAccent.crimson:
          return const Color(0xFFFECDD3);
        case ToolerAccent.berry:
          return const Color(0xFFF5D0FE);
        case ToolerAccent.lemon:
          return const Color(0xFFD9F99D);
        case ToolerAccent.slate:
          return const Color(0xFFE2E8F0);
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
        case ToolerAccent.indigo:
          return const Color(0xFF818CF8);
        case ToolerAccent.emerald:
          return const Color(0xFF10B981);
        case ToolerAccent.coral:
          return const Color(0xFFFB923C);
        case ToolerAccent.cyan:
          return const Color(0xFF22D3EE);
        case ToolerAccent.crimson:
          return const Color(0xFFFB7185);
        case ToolerAccent.berry:
          return const Color(0xFFE879F9);
        case ToolerAccent.lemon:
          return const Color(0xFFA3E635);
        case ToolerAccent.slate:
          return const Color(0xFF94A3B8);
      }
    }
  }

  Color get accentColorDot {
    return accentPalette.swatchColor;
  }

  // Soft Tinted Hero & Card Background
  Color get lavenderCard {
    if (isDark) return const Color(0xFF1E1E24);
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
      case ToolerAccent.indigo:
        return const Color(0xFFEEF2FF);
      case ToolerAccent.emerald:
        return const Color(0xFFECFDF5);
      case ToolerAccent.coral:
        return const Color(0xFFFFF7ED);
      case ToolerAccent.cyan:
        return const Color(0xFFECFEFF);
      case ToolerAccent.crimson:
        return const Color(0xFFFFF1F2);
      case ToolerAccent.berry:
        return const Color(0xFFFDF4FF);
      case ToolerAccent.lemon:
        return const Color(0xFFF7FEE7);
      case ToolerAccent.slate:
        return const Color(0xFFF8FAFC);
    }
  }

  // 2D Backdrop Bubble Accent
  Color get lavenderBubble {
    if (isDark) return primary.withValues(alpha: 0.18);
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
      case ToolerAccent.indigo:
        return const Color(0xFFE0E7FF);
      case ToolerAccent.emerald:
        return const Color(0xFFD1FAE5);
      case ToolerAccent.coral:
        return const Color(0xFFFFEDD5);
      case ToolerAccent.cyan:
        return const Color(0xFFCFFAFE);
      case ToolerAccent.crimson:
        return const Color(0xFFFFE4E6);
      case ToolerAccent.berry:
        return const Color(0xFFFAE8FF);
      case ToolerAccent.lemon:
        return const Color(0xFFECFCCB);
      case ToolerAccent.slate:
        return const Color(0xFFF1F5F9);
    }
  }

  /// Pastel background tint for character backdrops across all themes (both Light & Dark)
  Color get characterBg {
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
      case ToolerAccent.indigo:
        return const Color(0xFFEEF2FF);
      case ToolerAccent.emerald:
        return const Color(0xFFECFDF5);
      case ToolerAccent.coral:
        return const Color(0xFFFFF7ED);
      case ToolerAccent.cyan:
        return const Color(0xFFECFEFF);
      case ToolerAccent.crimson:
        return const Color(0xFFFFF1F2);
      case ToolerAccent.berry:
        return const Color(0xFFFDF4FF);
      case ToolerAccent.lemon:
        return const Color(0xFFF7FEE7);
      case ToolerAccent.slate:
        return const Color(0xFFF8FAFC);
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
