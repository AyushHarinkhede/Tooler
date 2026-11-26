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
  brown, // Mocha Brown (#8D5B4C, #F1E3DC)
  yellow, // Sunburst Yellow (#FACC15, #FEF9C3)
  maroon, // Royal Maroon (#9B1B30, #FCE2E7)
  darkBlue, // Midnight Blue (#1E40AF, #DBEAFE)
  terracotta, // Terracotta Rust (#C2593F, #FCE2DA)
  olive, // Olive Moss (#6B7E32, #ECF2D0)
}

class MaterialYouPalette {
  final Color bg;
  final Color cardBg;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color swatch;
  final Color lavenderCard;
  final Color lavenderBubble;
  final Color characterBg;
  final bool isNativeSupported;

  const MaterialYouPalette({
    required this.bg,
    required this.cardBg,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.swatch,
    required this.lavenderCard,
    required this.lavenderBubble,
    required this.characterBg,
    this.isNativeSupported = false,
  });

  factory MaterialYouPalette.fallback({required bool isDark}) {
    if (isDark) {
      return const MaterialYouPalette(
        bg: Color(0xFF0B0A0E),
        cardBg: Color(0xFF1C1B1F),
        border: Color(0xFF3B3845),
        text: Color(0xFFF4EFF4),
        textSecondary: Color(0xFFA8A2B4),
        primary: Color(0xFF9F86E5),
        primaryDark: Color(0xFFD0BCFF),
        secondary: Color(0xFFCCC2DC),
        accent: Color(0xFFEADDFF),
        swatch: Color(0xFF9F86E5),
        lavenderCard: Color(0xFF241F2E),
        lavenderBubble: Color(0xFF2E2C36),
        characterBg: Color(0xFF241F2E),
        isNativeSupported: false,
      );
    }
    return const MaterialYouPalette(
      bg: Color(0xFFFAF8FC),
      cardBg: Color(0xFFFFFFFF),
      border: Color(0xFFE3DCE8),
      text: Color(0xFF1C1B1F),
      textSecondary: Color(0xFF6B6478),
      primary: Color(0xFF6750A4),
      primaryDark: Color(0xFF4F378B),
      secondary: Color(0xFF7D5260),
      accent: Color(0xFF9A82DB),
      swatch: Color(0xFF6750A4),
      lavenderCard: Color(0xFFF5F0FF),
      lavenderBubble: Color(0xFFEDE7F6),
      characterBg: Color(0xFFF5F0FF),
      isNativeSupported: false,
    );
  }
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
      case ToolerAccent.brown:
        return 'Mocha Brown';
      case ToolerAccent.yellow:
        return 'Sunburst Yellow';
      case ToolerAccent.maroon:
        return 'Royal Maroon';
      case ToolerAccent.darkBlue:
        return 'Midnight Blue';
      case ToolerAccent.terracotta:
        return 'Terracotta Rust';
      case ToolerAccent.olive:
        return 'Olive Moss';
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
      case ToolerAccent.brown:
        return 'Rich warm roasted espresso';
      case ToolerAccent.yellow:
        return 'Radiant sunlit golden yellow';
      case ToolerAccent.maroon:
        return 'Deep royal burgundy wine';
      case ToolerAccent.darkBlue:
        return 'Classic deep midnight sapphire';
      case ToolerAccent.terracotta:
        return 'Warm earthy baked clay rust';
      case ToolerAccent.olive:
        return 'Organic muted botanical moss';
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
      case ToolerAccent.brown:
        return const Color(0xFF8D5B4C);
      case ToolerAccent.yellow:
        return const Color(0xFFFACC15);
      case ToolerAccent.maroon:
        return const Color(0xFF9B1B30);
      case ToolerAccent.darkBlue:
        return const Color(0xFF1E40AF);
      case ToolerAccent.terracotta:
        return const Color(0xFFC2593F);
      case ToolerAccent.olive:
        return const Color(0xFF6B7E32);
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
      case ToolerAccent.brown:
        return 'Earthy';
      case ToolerAccent.yellow:
        return 'Bright';
      case ToolerAccent.maroon:
        return 'Royal';
      case ToolerAccent.darkBlue:
        return 'Deep';
      case ToolerAccent.terracotta:
        return 'Clay';
      case ToolerAccent.olive:
        return 'Moss';
    }
  }
}

class StationeryTheme {
  final bool isDark;
  final ToolerAccent accentPalette;
  final StationeryThemeMode mode;
  final bool useMaterialYou;
  final MaterialYouPalette? materialYouPalette;

  StationeryTheme(
    this.mode, {
    bool? isDark,
    ToolerAccent? accentPalette,
    this.useMaterialYou = false,
    this.materialYouPalette,
  })  : isDark = isDark ?? (mode == StationeryThemeMode.blueprintChalkboard),
        accentPalette = accentPalette ??
            (mode == StationeryThemeMode.neonHighlighter
                ? ToolerAccent.rose
                : ToolerAccent.lilac);

  StationeryTheme.custom({
    required this.isDark,
    ToolerAccent? accentPalette,
    ToolerAccent? accent,
    this.useMaterialYou = false,
    this.materialYouPalette,
  })  : accentPalette = accentPalette ?? accent ?? ToolerAccent.lilac,
        mode = isDark
            ? StationeryThemeMode.blueprintChalkboard
            : ((accentPalette ?? accent) == ToolerAccent.rose
                ? StationeryThemeMode.neonHighlighter
                : StationeryThemeMode.classicDoodle);

  MaterialYouPalette get _resolvedMaterialYou =>
      materialYouPalette ?? MaterialYouPalette.fallback(isDark: isDark);

  String get activeColorName =>
      useMaterialYou ? 'Material You' : accentPalette.displayName;

  // Surface & Canvas Backgrounds
  Color get bg => useMaterialYou
      ? _resolvedMaterialYou.bg
      : (isDark ? const Color(0xFF09090B) : const Color(0xFFFAFAFC));
  Color get cardBg => useMaterialYou
      ? _resolvedMaterialYou.cardBg
      : (isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF));
  Color get border => useMaterialYou
      ? _resolvedMaterialYou.border
      : (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7));
  Color get text => useMaterialYou
      ? _resolvedMaterialYou.text
      : (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B));
  Color get textSecondary => useMaterialYou
      ? _resolvedMaterialYou.textSecondary
      : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A));

  // Dynamic Primary Accent
  Color get primary {
    if (useMaterialYou) return _resolvedMaterialYou.primary;
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
        case ToolerAccent.brown:
          return const Color(0xFFC08A72);
        case ToolerAccent.yellow:
          return const Color(0xFFFACC15);
        case ToolerAccent.maroon:
          return const Color(0xFFC94A60);
        case ToolerAccent.darkBlue:
          return const Color(0xFF4B7BEC);
        case ToolerAccent.terracotta:
          return const Color(0xFFE07A5F);
        case ToolerAccent.olive:
          return const Color(0xFF9AB04F);
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
        case ToolerAccent.brown:
          return const Color(0xFF794A3A);
        case ToolerAccent.yellow:
          return const Color(0xFFEAB308);
        case ToolerAccent.maroon:
          return const Color(0xFF881337);
        case ToolerAccent.darkBlue:
          return const Color(0xFF1E3A8A);
        case ToolerAccent.terracotta:
          return const Color(0xFFB54930);
        case ToolerAccent.olive:
          return const Color(0xFF556624);
      }
    }
  }

  Color get primaryDark {
    if (useMaterialYou) return _resolvedMaterialYou.primaryDark;
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
      case ToolerAccent.brown:
        return const Color(0xFF523024);
      case ToolerAccent.yellow:
        return const Color(0xFFA16207);
      case ToolerAccent.maroon:
        return const Color(0xFF5E0B24);
      case ToolerAccent.darkBlue:
        return const Color(0xFF172554);
      case ToolerAccent.terracotta:
        return const Color(0xFF7C2D1B);
      case ToolerAccent.olive:
        return const Color(0xFF3A4716);
    }
  }

  Color get secondary {
    if (useMaterialYou) return _resolvedMaterialYou.secondary;
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
      case ToolerAccent.brown:
        return const Color(0xFFD6A896);
      case ToolerAccent.yellow:
        return const Color(0xFFFDE047);
      case ToolerAccent.maroon:
        return const Color(0xFFE57A8D);
      case ToolerAccent.darkBlue:
        return const Color(0xFF6B93F5);
      case ToolerAccent.terracotta:
        return const Color(0xFFF0A28E);
      case ToolerAccent.olive:
        return const Color(0xFFB7C975);
    }
  }

  Color get accent {
    if (useMaterialYou) return _resolvedMaterialYou.accent;
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
        case ToolerAccent.brown:
          return const Color(0xFFEDD6CC);
        case ToolerAccent.yellow:
          return const Color(0xFFFEF08A);
        case ToolerAccent.maroon:
          return const Color(0xFFF7C3CD);
        case ToolerAccent.darkBlue:
          return const Color(0xFFBFDBFE);
        case ToolerAccent.terracotta:
          return const Color(0xFFFBD5CB);
        case ToolerAccent.olive:
          return const Color(0xFFE3ECB8);
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
        case ToolerAccent.brown:
          return const Color(0xFFA87360);
        case ToolerAccent.yellow:
          return const Color(0xFFFDE047);
        case ToolerAccent.maroon:
          return const Color(0xFFAD2846);
        case ToolerAccent.darkBlue:
          return const Color(0xFF2563EB);
        case ToolerAccent.terracotta:
          return const Color(0xFFD66A4E);
        case ToolerAccent.olive:
          return const Color(0xFF7D913B);
      }
    }
  }

  Color get accentColorDot {
    if (useMaterialYou) return _resolvedMaterialYou.swatch;
    return accentPalette.swatchColor;
  }

  // Soft Tinted Hero & Card Background
  Color get lavenderCard {
    if (useMaterialYou) return _resolvedMaterialYou.lavenderCard;
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
      case ToolerAccent.brown:
        return const Color(0xFFFAF5F2);
      case ToolerAccent.yellow:
        return const Color(0xFFFEFCE8);
      case ToolerAccent.maroon:
        return const Color(0xFFFDF2F4);
      case ToolerAccent.darkBlue:
        return const Color(0xFFEFF6FF);
      case ToolerAccent.terracotta:
        return const Color(0xFFFEF5F2);
      case ToolerAccent.olive:
        return const Color(0xFFF8FAEE);
    }
  }

  // 2D Backdrop Bubble Accent
  Color get lavenderBubble {
    if (useMaterialYou) return _resolvedMaterialYou.lavenderBubble;
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
      case ToolerAccent.brown:
        return const Color(0xFFF1E3DC);
      case ToolerAccent.yellow:
        return const Color(0xFFFEF9C3);
      case ToolerAccent.maroon:
        return const Color(0xFFFCE2E7);
      case ToolerAccent.darkBlue:
        return const Color(0xFFDBEAFE);
      case ToolerAccent.terracotta:
        return const Color(0xFFFCE2DA);
      case ToolerAccent.olive:
        return const Color(0xFFECF2D0);
    }
  }

  /// Background tint for character backdrops across all themes (Light pastel, Dark surface)
  Color get characterBg {
    if (useMaterialYou) return _resolvedMaterialYou.characterBg;
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
      case ToolerAccent.brown:
        return const Color(0xFFFAF5F2);
      case ToolerAccent.yellow:
        return const Color(0xFFFEFCE8);
      case ToolerAccent.maroon:
        return const Color(0xFFFDF2F4);
      case ToolerAccent.darkBlue:
        return const Color(0xFFEFF6FF);
      case ToolerAccent.terracotta:
        return const Color(0xFFFEF5F2);
      case ToolerAccent.olive:
        return const Color(0xFFF8FAEE);
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
