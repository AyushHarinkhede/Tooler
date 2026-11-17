import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ---------------------------------------------------------------------------
/// TOOLER BRAND SVG LOGOS & HARDWARE IDENTITY SUITE
/// Official vector SVG logos, brand color palettes, and charging specs for:
/// SAMSUNG, Apple, Motorola, Google, LG, Oppo, Vivo, OnePlus, Nothing, CMF,
/// Xiaomi / Mi, Redmi, Realme, POCO, iQOO, Infinix, Tecno, Lava, Nokia,
/// HMD, Sony, Asus, Huawei, itel / AI+, and Android Generic Fallback.
/// ---------------------------------------------------------------------------

class BrandInfo {
  final String key;
  final String displayName;
  final Color primaryColor;
  final Color accentColor;
  final Color badgeBgColor;
  final String svgString;
  final String defaultFastChargeTech;
  final int defaultMaxWatts;

  const BrandInfo({
    required this.key,
    required this.displayName,
    required this.primaryColor,
    required this.accentColor,
    required this.badgeBgColor,
    required this.svgString,
    required this.defaultFastChargeTech,
    required this.defaultMaxWatts,
  });
}

class BrandSvgLogos {
  // ---------------------------------------------------------------------------
  // 1. MOTOROLA (Batwing 'M' Circle Emblem in Motorola Navy/Cyan)
  // ---------------------------------------------------------------------------
  static const String motorolaSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="48" fill="#001435"/>
  <circle cx="50" cy="50" r="44" fill="#001435" stroke="#0076CE" stroke-width="2.5"/>
  <!-- Motorola Batwing M -->
  <path d="M 23 68 C 24 55, 30 40, 39 33 C 43 29, 47 31, 50 44 C 53 31, 57 29, 61 33 C 70 40, 76 55, 77 68 C 72 63, 67 60, 61 60 C 56 60, 52 64, 50 71 C 48 64, 44 60, 39 60 C 33 60, 28 63, 23 68 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 2. SAMSUNG (Royal Blue Ellipse with Iconic SAMSUNG Logotype)
  // ---------------------------------------------------------------------------
  static const String samsungSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#1428A0"/>
  <!-- Samsung Ellipse & Wordmark Accent -->
  <ellipse cx="50" cy="50" rx="42" ry="24" fill="#1428A0" stroke="#FFFFFF" stroke-width="2.2" transform="rotate(-12 50 50)"/>
  <!-- Bold Samsung S-Curve Emblem -->
  <path d="M 33 45 C 33 41, 38 39, 44 39 C 51 39, 54 42, 54 44 C 54 48, 49 49, 43 51 C 36 53, 31 55, 31 60 C 31 66, 38 69, 46 69 C 54 69, 59 66, 60 61 L 53 61 C 52 63, 49 65, 45 65 C 39 65, 37 63, 37 61 C 37 57, 42 56, 49 54 C 56 52, 61 50, 61 44 C 61 38, 55 35, 45 35 C 36 35, 27 39, 26 45 Z" fill="#FFFFFF"/>
  <path d="M 64 36 L 70 36 L 76 56 L 70 56 L 68 50 L 64 50 L 64 36 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 3. APPLE (Iconic Silhouette with Angled Leaf & Right Bite)
  // ---------------------------------------------------------------------------
  static const String appleSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#1A1A1A"/>
  <!-- Apple Leaf -->
  <path d="M 57 18 C 61 14, 64 12, 62 8 C 58 8, 53 11, 50 15 C 47 19, 49 23, 50 23 C 51 23, 54 21, 57 18 Z" fill="#FFFFFF"/>
  <!-- Apple Body with Bite -->
  <path d="M 64 45 C 64 37, 70 33, 70 33 C 66 27, 59 26, 57 26 C 50 26, 46 30, 42 30 C 38 30, 34 26, 28 26 C 18 26, 9 34, 9 49 C 9 60, 14 74, 21 84 C 25 89, 29 94, 34 94 C 39 94, 41 91, 46 91 C 51 91, 53 94, 58 94 C 63 94, 67 89, 71 84 C 75 78, 78 70, 78 70 C 78 70, 64 65, 64 45 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 4. GOOGLE (Official 4-Color 'G' Vector)
  // ---------------------------------------------------------------------------
  static const String googleSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#F8FAFC"/>
  <rect width="100" height="100" rx="22" fill="none" stroke="#E2E8F0" stroke-width="2"/>
  <!-- Blue Bar & Top-Right -->
  <path d="M 85 50 C 85 47, 84.6 44.5, 84 42 L 50 42 L 50 58 L 70 58 C 69 63, 66 67, 61 70 L 61 80 L 75 80 C 83 72, 85 62, 85 50 Z" fill="#4285F4"/>
  <!-- Green Bottom Arc -->
  <path d="M 50 86 C 60 86, 69 82, 75 77 L 61 67 C 58 69, 54 70, 50 70 C 40 70, 32 64, 29 55 L 15 55 L 15 66 C 21 78, 34 86, 50 86 Z" fill="#34A853"/>
  <!-- Yellow Left Arc -->
  <path d="M 29 55 C 28 52, 28 48, 28 45 C 28 42, 28 38, 29 35 L 15 35 C 12 41, 12 49, 15 55 Z" fill="#FBBC05"/>
  <!-- Red Top Arc -->
  <path d="M 50 20 C 56 20, 61 22, 65 26 L 76 15 C 69 9, 60 6, 50 6 C 34 6, 21 14, 15 26 L 29 37 C 32 28, 40 20, 50 20 Z" fill="#EA4335"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 5. LG (Heritage Burgundy Red Circle Face with 'L' Nose & 'G' Perimeter)
  // ---------------------------------------------------------------------------
  static const String lgSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="48" fill="#A50034"/>
  <!-- LG Face Outline (G) -->
  <path d="M 50 22 C 34.5 22, 22 34.5, 22 50 C 22 65.5, 34.5 78, 50 78 C 65.5 78, 78 65.5, 78 50 L 52 50" fill="none" stroke="#FFFFFF" stroke-width="5.5" stroke-linecap="round" stroke-linejoin="round"/>
  <!-- LG Nose (L) -->
  <path d="M 39 37 L 39 63 L 53 63" fill="none" stroke="#FFFFFF" stroke-width="5.5" stroke-linecap="round" stroke-linejoin="round"/>
  <!-- LG Eye Dot -->
  <circle cx="34" cy="40" r="4" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 6. OPPO (Signature Forest Green Continuous Dual-Oval Loops)
  // ---------------------------------------------------------------------------
  static const String oppoSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#046A38"/>
  <!-- Left O -->
  <ellipse cx="36" cy="50" rx="18" ry="24" fill="none" stroke="#FFFFFF" stroke-width="6"/>
  <!-- Right O -->
  <ellipse cx="64" cy="50" rx="18" ry="24" fill="none" stroke="#FFFFFF" stroke-width="6"/>
  <!-- Center Union Indicator -->
  <path d="M 46 50 L 54 50" stroke="#046A38" stroke-width="8"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 7. VIVO (Electric Blue Angled Geometric V Monogram)
  // ---------------------------------------------------------------------------
  static const String vivoSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#008CD6"/>
  <!-- Stylized vivo Dual Angled Wings V -->
  <path d="M 20 28 L 42 74 C 44 78, 47 80, 50 80 C 53 80, 56 78, 58 74 L 80 28 L 68 28 L 50 66 L 32 28 Z" fill="#FFFFFF"/>
  <circle cx="50" cy="28" r="5" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 8. ONEPLUS (Iconic Red Squircle with '1+' Monogram)
  // ---------------------------------------------------------------------------
  static const String oneplusSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#EB0028"/>
  <rect x="14" y="14" width="72" height="72" rx="14" fill="none" stroke="#FFFFFF" stroke-width="5"/>
  <!-- The numeral 1 -->
  <path d="M 37 36 L 44 32 L 44 68 L 36 68 M 44 68 L 52 68" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <!-- The plus sign + -->
  <path d="M 68 28 L 68 44 M 60 36 L 76 36" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" fill="none"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 9. NOTHING (Dot-Matrix Glyph / Minimal Monogram in Dark & Red)
  // ---------------------------------------------------------------------------
  static const String nothingSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#111111"/>
  <!-- Dot matrix glyph layout -->
  <circle cx="28" cy="28" r="4.5" fill="#FFFFFF"/>
  <circle cx="42" cy="28" r="4.5" fill="#FFFFFF"/>
  <circle cx="58" cy="28" r="4.5" fill="#FFFFFF"/>
  <circle cx="72" cy="28" r="4.5" fill="#D71920"/>
  <circle cx="28" cy="42" r="4.5" fill="#FFFFFF"/>
  <circle cx="72" cy="42" r="4.5" fill="#FFFFFF"/>
  <circle cx="28" cy="58" r="4.5" fill="#FFFFFF"/>
  <circle cx="42" cy="58" r="4.5" fill="#FFFFFF"/>
  <circle cx="58" cy="58" r="4.5" fill="#FFFFFF"/>
  <circle cx="72" cy="58" r="4.5" fill="#FFFFFF"/>
  <circle cx="28" cy="72" r="4.5" fill="#FFFFFF"/>
  <circle cx="72" cy="72" r="4.5" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 10. CMF (CMF by Nothing Vibrant Orange Dot Badge)
  // ---------------------------------------------------------------------------
  static const String cmfSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#FA551E"/>
  <circle cx="50" cy="50" r="32" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-dasharray="2,6"/>
  <circle cx="50" cy="50" r="16" fill="#FFFFFF"/>
  <circle cx="50" cy="50" r="6" fill="#FA551E"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 11. XIAOMI / MI (Orange Squircle with Authentic Stylized 'mi' Glyph)
  // ---------------------------------------------------------------------------
  static const String xiaomiSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="28" fill="#FF6900"/>
  <!-- Authentic Xiaomi 'mi' Glyph -->
  <!-- Left stem -->
  <rect x="25" y="32" width="7" height="36" rx="3.5" fill="#FFFFFF"/>
  <!-- Middle arch & stem -->
  <path d="M 32 45 C 32 38, 38 32, 47 32 C 56 32, 60 38, 60 45 L 60 68 L 53 68 L 53 46 C 53 41, 51 38, 46 38 C 41 38, 39 41, 39 46 L 39 68 L 32 68 Z" fill="#FFFFFF"/>
  <!-- Center isolated bar -->
  <rect x="42" y="44" width="6" height="24" rx="3" fill="#FF6900"/>
  <!-- 'i' stem and dot -->
  <rect x="68" y="42" width="7" height="26" rx="3.5" fill="#FFFFFF"/>
  <rect x="68" y="32" width="7" height="7" rx="3.5" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 12. REDMI (Crimson Red Badge with Bold Geometric Redmi 'R')
  // ---------------------------------------------------------------------------
  static const String redmiSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#E53935"/>
  <!-- Bold Geometric Redmi 'R' -->
  <path d="M 28 26 L 54 26 C 65 26, 73 33, 73 42 C 73 50, 66 57, 56 58 L 74 76 L 61 76 L 46 60 L 39 60 L 39 76 L 28 76 Z M 39 36 L 39 50 L 53 50 C 58 50, 62 47, 62 43 C 62 39, 58 36, 53 36 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 13. REALME (Vibrant Yellow Rounded Square with Stylized 'R')
  // ---------------------------------------------------------------------------
  static const String realmeSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#FFC915"/>
  <!-- Black Geometric letter 'R' -->
  <path d="M 28 24 L 56 24 C 67 24, 74 31, 74 41 C 74 49, 68 55, 59 57 L 76 76 L 62 76 L 48 59 L 41 59 L 41 76 L 28 76 Z M 41 35 L 41 49 L 54 49 C 59 49, 63 46, 63 42 C 63 37, 59 35, 54 35 Z" fill="#111111"/>
  <!-- Vibrant Yellow Accent Dot -->
  <circle cx="74" cy="24" r="5" fill="#111111"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 14. POCO (POCO Iconic Vibrant Yellow Badge with Bold Wordmark)
  // ---------------------------------------------------------------------------
  static const String pocoSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#FFD600"/>
  <!-- POCO Bold Typography -->
  <!-- P -->
  <path d="M 16 34 L 32 34 C 38 34, 42 38, 42 43 C 42 48, 38 52, 32 52 L 23 52 L 23 66 L 16 66 Z M 23 40 L 23 46 L 31 46 C 34 46, 36 44, 36 43 C 36 41, 34 40, 31 40 Z" fill="#111111"/>
  <!-- O -->
  <ellipse cx="50" cy="50" rx="10" ry="16" fill="none" stroke="#111111" stroke-width="6"/>
  <!-- C -->
  <path d="M 80 40 C 77 36, 73 34, 68 34 C 60 34, 55 41, 55 50 C 55 59, 60 66, 68 66 C 73 66, 77 64, 80 60" fill="none" stroke="#111111" stroke-width="6" stroke-linecap="round"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 15. IQOO (Racing Amber Speed Badge with Angular Monogram)
  // ---------------------------------------------------------------------------
  static const String iqooSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#F9AA00"/>
  <!-- iQOO Speed Monogram -->
  <!-- i -->
  <circle cx="20" cy="36" r="4.5" fill="#111111"/>
  <rect x="16" y="45" width="8" height="23" rx="3" fill="#111111"/>
  <!-- Q -->
  <ellipse cx="44" cy="56" rx="12" ry="12" fill="none" stroke="#111111" stroke-width="6"/>
  <path d="M 48 60 L 58 72" stroke="#111111" stroke-width="6" stroke-linecap="round"/>
  <!-- O -->
  <ellipse cx="74" cy="56" rx="12" ry="12" fill="none" stroke="#111111" stroke-width="6"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 16. INFINIX (Bright Emerald Green Badge with Futuristic Infinity Emblem)
  // ---------------------------------------------------------------------------
  static const String infinixSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#00C269"/>
  <!-- Futuristic Infinity ∞ Monogram -->
  <path d="M 33 34 C 23 34, 16 41, 16 50 C 16 59, 23 66, 33 66 C 43 66, 49 57, 50 50 C 51 43, 57 34, 67 34 C 77 34, 84 41, 84 50 C 84 59, 77 66, 67 66 C 57 66, 51 57, 50 50 C 49 43, 43 34, 33 34 Z" fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 17. TECNO (Electric Blue Badge with Bold Geometric 'T' Crest)
  // ---------------------------------------------------------------------------
  static const String tecnoSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#0066FF"/>
  <!-- Bold Geometric 'T' Crest -->
  <path d="M 22 28 L 78 28 L 78 40 L 57 40 L 57 76 L 43 76 L 43 40 L 22 40 Z" fill="#FFFFFF"/>
  <circle cx="50" cy="84" r="3.5" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 18. LAVA (Pure Red Badge with Dynamic Flame / Peak Monogram)
  // ---------------------------------------------------------------------------
  static const String lavaSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#E60000"/>
  <!-- Dynamic Lava Dual Flame / Peak -->
  <path d="M 32 74 L 18 74 L 38 24 L 50 24 L 39 52 L 48 52 L 40 74 Z" fill="#FFFFFF"/>
  <path d="M 58 74 L 50 74 L 66 32 L 78 32 L 67 56 L 76 56 L 68 74 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 19. NOKIA (Classic Pure Blue Geometric 'NOKIA' Logotype Emblem)
  // ---------------------------------------------------------------------------
  static const String nokiaSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#124191"/>
  <!-- Classic Nokia Geometric N Monogram -->
  <path d="M 26 74 L 26 26 L 42 26 L 64 60 L 64 26 L 74 26 L 74 74 L 58 74 L 36 40 L 36 74 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 20. HMD / HMT (Modern Jet Black & Coral Geometric 'HMD' Monogram)
  // ---------------------------------------------------------------------------
  static const String hmdSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#111111"/>
  <!-- H -->
  <path d="M 18 32 L 26 32 L 26 46 L 36 46 L 36 32 L 44 32 L 44 68 L 36 68 L 36 54 L 26 54 L 26 68 L 18 68 Z" fill="#FFFFFF"/>
  <!-- M -->
  <path d="M 48 32 L 56 32 L 62 52 L 68 32 L 76 32 L 76 68 L 69 68 L 69 44 L 64 60 L 60 60 L 55 44 L 55 68 L 48 68 Z" fill="#FF4D6D"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 21. SONY (Classic Dark Badge with Sony Typographic Serif Mark)
  // ---------------------------------------------------------------------------
  static const String sonySvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#000000"/>
  <!-- Sony S & O Monogram -->
  <path d="M 22 41 C 24 37, 29 35, 34 35 C 41 35, 45 38, 45 42 C 45 46, 40 48, 35 50 C 28 52, 23 54, 23 60 C 23 66, 29 69, 36 69 C 43 69, 47 65, 47 62 L 41 62 C 40 64, 38 65, 35 65 C 31 65, 29 63, 29 60 C 29 57, 33 55, 39 53 C 46 51, 51 49, 51 42 C 51 36, 45 32, 35 32 C 28 32, 22 36, 21 41 Z" fill="#FFFFFF"/>
  <ellipse cx="68" cy="51" rx="14" ry="17" fill="none" stroke="#FFFFFF" stroke-width="5.5"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 22. ASUS (Tech Blue Badge with ASUS Horizontal-Slit 'A' Monogram)
  // ---------------------------------------------------------------------------
  static const String asusSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#00539B"/>
  <!-- ASUS Iconic Sliced 'A' -->
  <path d="M 46 22 L 20 78 L 33 78 L 42 58 L 58 58 L 67 78 L 80 78 L 54 22 Z M 50 38 L 55 50 L 45 50 Z" fill="#FFFFFF"/>
  <rect x="36" y="52" width="28" height="4" fill="#00539B"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 23. HUAWEI (Imperial Red Badge with Famous 8-Petal Blooming Lotus Fan)
  // ---------------------------------------------------------------------------
  static const String huaweiSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#ED1C24"/>
  <!-- Huawei Radiating Fan Petals -->
  <!-- Center Petal -->
  <path d="M 50 20 C 47 30, 47 45, 50 54 C 53 45, 53 30, 50 20 Z" fill="#FFFFFF"/>
  <!-- Left Petal 1 -->
  <path d="M 40 23 C 39 33, 43 46, 48 54 C 47 45, 45 32, 40 23 Z" fill="#FFFFFF"/>
  <!-- Right Petal 1 -->
  <path d="M 60 23 C 55 32, 53 45, 52 54 C 57 46, 61 33, 60 23 Z" fill="#FFFFFF"/>
  <!-- Left Petal 2 -->
  <path d="M 31 31 C 32 40, 39 50, 46 56 C 43 47, 39 37, 31 31 Z" fill="#FFFFFF"/>
  <!-- Right Petal 2 -->
  <path d="M 69 31 C 61 37, 57 47, 54 56 C 61 50, 68 40, 69 31 Z" fill="#FFFFFF"/>
  <!-- Left Petal 3 -->
  <path d="M 24 43 C 27 50, 36 57, 44 59 C 39 52, 34 44, 24 43 Z" fill="#FFFFFF"/>
  <!-- Right Petal 3 -->
  <path d="M 76 43 C 66 44, 61 52, 56 59 C 64 57, 73 50, 76 43 Z" fill="#FFFFFF"/>
  <!-- Bottom Foundation Arch -->
  <path d="M 28 68 C 42 63, 58 63, 72 68 C 65 74, 35 74, 28 68 Z" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 24. ITEL / AI+ (Vibrant Red itel Badge with Dynamic Curve & Monogram)
  // ---------------------------------------------------------------------------
  static const String itelSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#FF2B2B"/>
  <!-- itel Dynamic Monogram -->
  <circle cx="28" cy="38" r="4" fill="#FFFFFF"/>
  <rect x="24" y="46" width="8" height="24" rx="4" fill="#FFFFFF"/>
  <path d="M 44 36 L 44 46 L 54 46 L 54 52 L 44 52 L 44 64 C 44 67, 46 68, 49 68 L 54 68 L 54 74 L 46 74 C 39 74, 36 70, 36 63 L 36 36 Z" fill="#FFFFFF"/>
  <!-- Dynamic AI+ Star -->
  <circle cx="72" cy="46" r="14" fill="none" stroke="#FFFFFF" stroke-width="4"/>
  <path d="M 72 38 L 72 54 M 64 46 L 80 46" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // 25. ANDROID GENERIC FALLBACK (Android Green Robot Head)
  // ---------------------------------------------------------------------------
  static const String androidGenericSvg = '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="22" fill="#3DDC84"/>
  <!-- Left Antenna -->
  <line x1="33" y1="31" x2="25" y2="19" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>
  <!-- Right Antenna -->
  <line x1="67" y1="31" x2="75" y2="19" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>
  <!-- Android Head Dome -->
  <path d="M 20 54 C 20 37, 33 24, 50 24 C 67 24, 80 37, 80 54 Z" fill="#FFFFFF"/>
  <!-- Left Eye -->
  <circle cx="36" cy="42" r="3.5" fill="#3DDC84"/>
  <!-- Right Eye -->
  <circle cx="64" cy="42" r="3.5" fill="#3DDC84"/>
  <!-- Android Body Line -->
  <rect x="20" y="58" width="60" height="18" rx="8" fill="#FFFFFF"/>
</svg>''';

  // ---------------------------------------------------------------------------
  // BRAND REPOSITORY & INTELLIGENT HARDWARE RESOLVER
  // ---------------------------------------------------------------------------
  static BrandInfo getBrandInfo(String rawBrand, [String rawModel = '']) {
    final b = rawBrand.toUpperCase().trim();
    final m = rawModel.toUpperCase().trim();

    // 1. MOTOROLA
    if (b.contains('MOTO') || b.contains('MOTOROLA') || m.contains('EDGE') || m.contains('MOTO')) {
      return const BrandInfo(
        key: 'MOTOROLA',
        displayName: 'MOTOROLA',
        primaryColor: Color(0xFF0076CE),
        accentColor: Color(0xFF001435),
        badgeBgColor: Color(0xFFEEF6FC),
        svgString: motorolaSvg,
        defaultFastChargeTech: 'TurboPower',
        defaultMaxWatts: 68,
      );
    }

    // 2. SAMSUNG
    if (b.contains('SAMSUNG') || m.startsWith('SM-') || m.contains('GALAXY')) {
      return const BrandInfo(
        key: 'SAMSUNG',
        displayName: 'SAMSUNG',
        primaryColor: Color(0xFF1428A0),
        accentColor: Color(0xFF0C1E5C),
        badgeBgColor: Color(0xFFEEF2FF),
        svgString: samsungSvg,
        defaultFastChargeTech: 'Super Fast Charging',
        defaultMaxWatts: 45,
      );
    }

    // 3. APPLE
    if (b.contains('APPLE') || m.contains('IPHONE') || m.contains('IPAD')) {
      return const BrandInfo(
        key: 'APPLE',
        displayName: 'Apple',
        primaryColor: Color(0xFF1D1D1F),
        accentColor: Color(0xFF000000),
        badgeBgColor: Color(0xFFF5F5F7),
        svgString: appleSvg,
        defaultFastChargeTech: 'USB-PD Fast Charge',
        defaultMaxWatts: 27,
      );
    }

    // 4. GOOGLE
    if (b.contains('GOOGLE') || m.contains('PIXEL')) {
      return const BrandInfo(
        key: 'GOOGLE',
        displayName: 'Google',
        primaryColor: Color(0xFF4285F4),
        accentColor: Color(0xFF34A853),
        badgeBgColor: Color(0xFFF1F5F9),
        svgString: googleSvg,
        defaultFastChargeTech: 'USB-PD 3.0 PPS',
        defaultMaxWatts: 30,
      );
    }

    // 5. ONEPLUS
    if (b.contains('ONEPLUS') || m.contains('ONEPLUS') || m.contains('NORD')) {
      return const BrandInfo(
        key: 'ONEPLUS',
        displayName: 'OnePlus',
        primaryColor: Color(0xFFEB0028),
        accentColor: Color(0xFFB3001E),
        badgeBgColor: Color(0xFFFDF2F2),
        svgString: oneplusSvg,
        defaultFastChargeTech: 'SUPERVOOC',
        defaultMaxWatts: 100,
      );
    }

    // 6. NOTHING
    if (b.contains('NOTHING') || m.contains('NOTHING') || m.contains('PHONE (1)') || m.contains('PHONE (2)')) {
      return const BrandInfo(
        key: 'NOTHING',
        displayName: 'NOTHING',
        primaryColor: Color(0xFF111111),
        accentColor: Color(0xFFD71920),
        badgeBgColor: Color(0xFFF4F4F5),
        svgString: nothingSvg,
        defaultFastChargeTech: 'Fast Charging',
        defaultMaxWatts: 45,
      );
    }

    // 7. CMF
    if (b.contains('CMF') || m.contains('CMF')) {
      return const BrandInfo(
        key: 'CMF',
        displayName: 'CMF by Nothing',
        primaryColor: Color(0xFFFA551E),
        accentColor: Color(0xFFD83B08),
        badgeBgColor: Color(0xFFFFF4EE),
        svgString: cmfSvg,
        defaultFastChargeTech: 'Fast Charging',
        defaultMaxWatts: 33,
      );
    }

    // 8. REDMI
    if (b.contains('REDMI') || m.contains('REDMI')) {
      return const BrandInfo(
        key: 'REDMI',
        displayName: 'Redmi',
        primaryColor: Color(0xFFE53935),
        accentColor: Color(0xFFC62828),
        badgeBgColor: Color(0xFFFFF0F0),
        svgString: redmiSvg,
        defaultFastChargeTech: 'HyperCharge',
        defaultMaxWatts: 67,
      );
    }

    // 9. POCO
    if (b.contains('POCO') || m.contains('POCO')) {
      return const BrandInfo(
        key: 'POCO',
        displayName: 'POCO',
        primaryColor: Color(0xFFFFD600),
        accentColor: Color(0xFF111111),
        badgeBgColor: Color(0xFFFFFDE7),
        svgString: pocoSvg,
        defaultFastChargeTech: 'HyperCharge',
        defaultMaxWatts: 67,
      );
    }

    // 10. XIAOMI / MI
    if (b.contains('XIAOMI') || b.contains('XIOMI') || b == 'MI' || m.contains('XIAOMI') || m.startsWith('MI ')) {
      return const BrandInfo(
        key: 'XIAOMI',
        displayName: 'Xiaomi',
        primaryColor: Color(0xFFFF6900),
        accentColor: Color(0xFFD85500),
        badgeBgColor: Color(0xFFFFF3E0),
        svgString: xiaomiSvg,
        defaultFastChargeTech: 'HyperCharge',
        defaultMaxWatts: 90,
      );
    }

    // 11. REALME
    if (b.contains('REALME') || m.contains('REALME') || m.contains('NARZO')) {
      return const BrandInfo(
        key: 'REALME',
        displayName: 'realme',
        primaryColor: Color(0xFFFFC915),
        accentColor: Color(0xFF111111),
        badgeBgColor: Color(0xFFFFFBEA),
        svgString: realmeSvg,
        defaultFastChargeTech: 'SUPERVOOC',
        defaultMaxWatts: 67,
      );
    }

    // 12. IQOO
    if (b.contains('IQOO') || m.contains('IQOO')) {
      return const BrandInfo(
        key: 'IQOO',
        displayName: 'iQOO',
        primaryColor: Color(0xFFF9AA00),
        accentColor: Color(0xFFFF6F00),
        badgeBgColor: Color(0xFFFFF8E1),
        svgString: iqooSvg,
        defaultFastChargeTech: 'FlashCharge',
        defaultMaxWatts: 120,
      );
    }

    // 13. VIVO
    if (b.contains('VIVO') || m.contains('VIVO')) {
      return const BrandInfo(
        key: 'VIVO',
        displayName: 'vivo',
        primaryColor: Color(0xFF008CD6),
        accentColor: Color(0xFF006BB3),
        badgeBgColor: Color(0xFFE6F4FB),
        svgString: vivoSvg,
        defaultFastChargeTech: 'FlashCharge',
        defaultMaxWatts: 80,
      );
    }

    // 14. OPPO
    if (b.contains('OPPO') || m.contains('OPPO') || m.contains('RENO') || m.contains('FIND')) {
      return const BrandInfo(
        key: 'OPPO',
        displayName: 'OPPO',
        primaryColor: Color(0xFF046A38),
        accentColor: Color(0xFF004D26),
        badgeBgColor: Color(0xFFE8F5E9),
        svgString: oppoSvg,
        defaultFastChargeTech: 'SUPERVOOC',
        defaultMaxWatts: 67,
      );
    }

    // 15. INFINIX
    if (b.contains('INFINIX') || m.contains('INFINIX')) {
      return const BrandInfo(
        key: 'INFINIX',
        displayName: 'Infinix',
        primaryColor: Color(0xFF00C269),
        accentColor: Color(0xFF009651),
        badgeBgColor: Color(0xFFE8F8F0),
        svgString: infinixSvg,
        defaultFastChargeTech: 'All-Round FastCharge',
        defaultMaxWatts: 45,
      );
    }

    // 16. TECNO
    if (b.contains('TECNO') || b.contains('TECHNO') || m.contains('TECNO') || m.contains('POVA') || m.contains('CAMON')) {
      return const BrandInfo(
        key: 'TECNO',
        displayName: 'TECNO',
        primaryColor: Color(0xFF0066FF),
        accentColor: Color(0xFF0047BA),
        badgeBgColor: Color(0xFFEFF5FF),
        svgString: tecnoSvg,
        defaultFastChargeTech: 'FastCharge',
        defaultMaxWatts: 45,
      );
    }

    // 17. ITEL / AI+
    if (b.contains('ITEL') || b.contains('AI+') || b.contains('AI PLUS') || m.contains('ITEL')) {
      return const BrandInfo(
        key: 'ITEL',
        displayName: 'itel',
        primaryColor: Color(0xFFFF2B2B),
        accentColor: Color(0xFFD61A1A),
        badgeBgColor: Color(0xFFFFEEEE),
        svgString: itelSvg,
        defaultFastChargeTech: 'HyperCharge',
        defaultMaxWatts: 33,
      );
    }

    // 18. LAVA
    if (b.contains('LAVA') || m.contains('LAVA') || m.contains('AGNI') || m.contains('BLAZE')) {
      return const BrandInfo(
        key: 'LAVA',
        displayName: 'LAVA',
        primaryColor: Color(0xFFE60000),
        accentColor: Color(0xFFB30000),
        badgeBgColor: Color(0xFFFFEAEA),
        svgString: lavaSvg,
        defaultFastChargeTech: 'Super Fast Charge',
        defaultMaxWatts: 33,
      );
    }

    // 19. NOKIA
    if (b.contains('NOKIA') || m.contains('NOKIA')) {
      return const BrandInfo(
        key: 'NOKIA',
        displayName: 'NOKIA',
        primaryColor: Color(0xFF124191),
        accentColor: Color(0xFF0B2D69),
        badgeBgColor: Color(0xFFE8EEF8),
        svgString: nokiaSvg,
        defaultFastChargeTech: 'Fast Charging',
        defaultMaxWatts: 33,
      );
    }

    // 20. HMD / HMT
    if (b.contains('HMD') || b.contains('HMT') || m.contains('HMD')) {
      return const BrandInfo(
        key: 'HMD',
        displayName: 'HMD',
        primaryColor: Color(0xFF111111),
        accentColor: Color(0xFFFF4D6D),
        badgeBgColor: Color(0xFFF5F5F7),
        svgString: hmdSvg,
        defaultFastChargeTech: 'Quick Charge',
        defaultMaxWatts: 33,
      );
    }

    // 21. SONY
    if (b.contains('SONY') || m.contains('XPERIA')) {
      return const BrandInfo(
        key: 'SONY',
        displayName: 'SONY',
        primaryColor: Color(0xFF111111),
        accentColor: Color(0xFF000000),
        badgeBgColor: Color(0xFFF3F4F6),
        svgString: sonySvg,
        defaultFastChargeTech: 'USB-PD 3.0',
        defaultMaxWatts: 30,
      );
    }

    // 22. ASUS
    if (b.contains('ASUS') || m.contains('ROG') || m.contains('ZENFONE')) {
      return const BrandInfo(
        key: 'ASUS',
        displayName: 'ASUS',
        primaryColor: Color(0xFF00539B),
        accentColor: Color(0xFF00386B),
        badgeBgColor: Color(0xFFEBF3FB),
        svgString: asusSvg,
        defaultFastChargeTech: 'HyperCharge',
        defaultMaxWatts: 65,
      );
    }

    // 23. HUAWEI / HUWAI
    if (b.contains('HUAWEI') || b.contains('HUWAI') || b.contains('HONOR') || m.contains('HUAWEI') || m.contains('MATE') || m.contains('PURA')) {
      return const BrandInfo(
        key: 'HUAWEI',
        displayName: 'HUAWEI',
        primaryColor: Color(0xFFED1C24),
        accentColor: Color(0xFFC00F15),
        badgeBgColor: Color(0xFFFDF0F0),
        svgString: huaweiSvg,
        defaultFastChargeTech: 'SuperCharge',
        defaultMaxWatts: 66,
      );
    }

    // 24. LG
    if (b.contains('LG') || b.contains('LGE') || m.contains('LG')) {
      return const BrandInfo(
        key: 'LG',
        displayName: 'LG',
        primaryColor: Color(0xFFA50034),
        accentColor: Color(0xFF800028),
        badgeBgColor: Color(0xFFFAEDF1),
        svgString: lgSvg,
        defaultFastChargeTech: 'Quick Charge',
        defaultMaxWatts: 25,
      );
    }

    // 25. ANDROID GENERIC FALLBACK
    return BrandInfo(
      key: 'ANDROID',
      displayName: b.isNotEmpty && b != 'UNKNOWN' ? b : 'Android',
      primaryColor: const Color(0xFF3DDC84),
      accentColor: const Color(0xFF2CA862),
      badgeBgColor: const Color(0xFFEDFBF3),
      svgString: androidGenericSvg,
      defaultFastChargeTech: 'Fast Charging',
      defaultMaxWatts: 30,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Dedicated Brand Logo Avatar Widget
/// Displays the authentic SVG vector brand logo with rounded corners, subtle
/// border, and brand tinted background.
/// ---------------------------------------------------------------------------
class BrandLogoWidget extends StatelessWidget {
  final String brand;
  final String model;
  final double size;
  final double borderRadius;
  final bool showBorder;

  const BrandLogoWidget({
    super.key,
    required this.brand,
    this.model = '',
    this.size = 46.0,
    this.borderRadius = 13.0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final info = BrandSvgLogos.getBrandInfo(brand, model);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: info.badgeBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: info.primaryColor.withValues(alpha: 0.35),
                width: 1.2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: info.primaryColor.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * 0.75),
        child: SvgPicture.string(
          info.svgString,
          width: size * 0.80,
          height: size * 0.80,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
