import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
import 'widget_settings_screen.dart';

/// ---------------------------------------------------------------------------
/// REDESIGNED MINIMAL SETTINGS SCREEN
/// - Pure Tooler identity
/// - Modern Dark Mode switch
/// - Compact Color Accent bars with round color preview dots
/// - Tactile Sound & Haptic Vibration toggles
/// - Notifications & Background persistence toggle
/// - Terms and Conditions & Privacy Policy dialogs
/// - About Developer (Ayush Harinkhede) and dedicated Send Feedback email launch
/// ---------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  final StationeryTheme theme;
  final Function(StationeryThemeMode mode) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDark;
  late ToolerAccent _accent;
  late bool _soundOn;
  late bool _hapticsOn;
  bool _notificationsOn = true;
  bool _tamperProtection = true;

  @override
  void initState() {
    super.initState();
    _isDark = widget.theme.isDark;
    _accent = widget.theme.accentPalette;
    _soundOn = SoundService().soundEnabled;
    _hapticsOn = SoundService().hapticsEnabled;
    _loadNotificationPref();
    _loadTamperPref();
  }

  void _loadNotificationPref() async {
    final enabled = await StorageService().loadNotificationsEnabled();
    if (mounted) {
      setState(() => _notificationsOn = enabled);
    }
  }

  void _loadTamperPref() async {
    final enabled = await StorageService().loadTamperProtection();
    if (mounted) {
      setState(() => _tamperProtection = enabled);
    }
  }

  void _onToggleTamperProtection(bool val) async {
    SoundService().playSpecialClick();
    setState(() => _tamperProtection = val);
    await StorageService().saveTamperProtection(val);
  }

  void _onToggleDarkMode(bool val) async {
    SoundService().playClick();
    setState(() => _isDark = val);
    await StorageService().saveTheme(_isDark, _accent);
    final updatedTheme = await StorageService().loadTheme();
    await WidgetService().syncToNative(updatedTheme);
    final nextMode = _isDark
        ? StationeryThemeMode.blueprintChalkboard
        : (_accent == ToolerAccent.rose
            ? StationeryThemeMode.neonHighlighter
            : StationeryThemeMode.classicDoodle);
    widget.onThemeChanged(nextMode);
  }

  StationeryTheme get _currentTheme => StationeryTheme.custom(
        isDark: _isDark,
        accent: _accent,
      );

  void _onSelectAccent(ToolerAccent accent) async {
    SoundService().playClick();
    setState(() => _accent = accent);
    await StorageService().saveTheme(_isDark, _accent);
    final updatedTheme = await StorageService().loadTheme();
    await WidgetService().syncToNative(updatedTheme);
    final nextMode = _isDark
        ? StationeryThemeMode.blueprintChalkboard
        : (accent == ToolerAccent.rose
            ? StationeryThemeMode.neonHighlighter
            : StationeryThemeMode.classicDoodle);
    widget.onThemeChanged(nextMode);
  }

  void _openColorPaletteHoverSheet() {
    SoundService().playClick();
    ToolerHoverSheet.show(
      context: context,
      title: 'Color Palette',
      subtitle: 'Select accent color for buttons, badges & cards',
      tag: '${ToolerAccent.values.length} Themes',
      theme: _currentTheme,
      child: _ColorPaletteHoverContent(
        initialAccent: _accent,
        isDark: _isDark,
        onAccentChanged: (newAccent) {
          _onSelectAccent(newAccent);
        },
      ),
    );
  }

  void _onToggleNotifications(bool val) async {
    SoundService().playSpecialClick();
    setState(() => _notificationsOn = val);
    await StorageService().saveNotificationsEnabled(val);
    if (val) {
      await NotificationService().init();
    }
  }

  void _launchSendFeedback() async {
    SoundService().playSpecialClick();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ayushharinkhere2005@gmail.com',
      queryParameters: {
        'subject': 'Tooler App Feedback & Suggestions',
        'body': 'Hi Ayush,\n\nI have the following feedback regarding Tooler:\n\n',
      },
    );
    try {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open default email client.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTermsDialog() {
    SoundService().playClick();
    showDialog(
      context: context,
      builder: (context) {
        final theme = widget.theme;
        return AlertDialog(
          backgroundColor: theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.border, width: 1.2),
          ),
          title: Row(
            children: [
              Icon(Icons.gavel_rounded, color: theme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Terms & Conditions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated: November 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegalSection(
                    '1. Acceptance of Terms',
                    'By downloading, accessing, or utilizing the Tooler multi-utility application, you acknowledge and agree to be bound by these Terms and Conditions.',
                    theme,
                  ),
                  _buildLegalSection(
                    '2. Offline Utility & Calculations',
                    'Tooler is designed as a standalone offline utility providing mathematical calculations, geometric sizers, unit conversions, and productivity helpers. All results are computed directly on your device. Measurements and conversions are for general informational and reference purposes.',
                    theme,
                  ),
                  _buildLegalSection(
                    '3. Intellectual Property',
                    'All original designs, algorithms, 3D stationery assets, visual branding, and codebases associated with Tooler are created and owned by Ayush Harinkhede. Unauthorized redistribution, reverse-engineering, or commercial resale is strictly prohibited.',
                    theme,
                  ),
                  _buildLegalSection(
                    '4. Disclaimer of Warranties',
                    'The application is provided "as is" without warranty of any kind. While precision and accuracy are paramount in our mathematical algorithms, the developer assumes no liability for critical reliance on physical screen calibrations or hardware sensor tolerances.',
                    theme,
                  ),
                  _buildLegalSection(
                    '5. Modifications',
                    'We reserve the right to modify these terms at any time through application updates. Continued use of Tooler signifies your acceptance of updated terms.',
                    theme,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SoundService().playClick();
                Navigator.pop(context);
              },
              child: Text(
                'Understood',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    SoundService().playClick();
    showDialog(
      context: context,
      builder: (context) {
        final theme = widget.theme;
        return AlertDialog(
          backgroundColor: theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.border, width: 1.2),
          ),
          title: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: theme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Privacy Policy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effective Date: November 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegalSection(
                    '1. 100% On-Device & Zero Tracking',
                    'Tooler is built on a privacy-by-design foundation. We do NOT track, collect, store, transmit, or monetize any personal identification data, location history, or usage analytics.',
                    theme,
                  ),
                  _buildLegalSection(
                    '2. Local Storage Persistence',
                    'All your calculations, custom counters, task schedules, notes, and appearance settings are stored strictly in local device sandboxed storage (SharedPreferences). When you clear data or uninstall the app, all records are permanently erased from your device.',
                    theme,
                  ),
                  _buildLegalSection(
                    '3. System Permissions',
                    '• Notifications: Used solely for alerting you when a Timer finishes, when a Stopwatch crosses a milestone, or when a Task is due.\n• Vibration / Haptics: Used only to provide tactile feedback during interactions.\nTooler does NOT require internet access or background telemetry servers.',
                    theme,
                  ),
                  _buildLegalSection(
                    '4. Third-Party Sharing',
                    'We do not integrate third-party advertising SDKs or tracking pixels. Your data never leaves your smartphone.',
                    theme,
                  ),
                  _buildLegalSection(
                    '5. Contact & Inquiries',
                    'For inquiries regarding privacy or your rights, you can reach out directly via the in-app Send Feedback option.',
                    theme,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SoundService().playClick();
                Navigator.pop(context);
              },
              child: Text(
                'Accept',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegalSection(String title, String body, StationeryTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.45,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    SoundService().playSpecialClick();
    showDialog(
      context: context,
      builder: (context) {
        final theme = widget.theme;
        return AlertDialog(
          backgroundColor: theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.border, width: 1.2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ToolerCharacter.designing(
                theme: theme,
                width: 140,
                height: 105,
                animate: true,
              ),
              const SizedBox(height: 12),
              ToolerLogo(
                height: 40,
                color: theme.text,
                accentColor: theme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'A clean, aesthetic, minimal multi-utility application offering precision calculators, unit converters, geometric sizers, live compass sensors, and productivity tools with zero clutter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.lavenderCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.border, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'Created by',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ayush Harinkhede',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.43 • Tooler Master Edition',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                SoundService().playClick();
                Navigator.pop(context);
              },
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearData() {
    SoundService().playClick();
    showDialog(
      context: context,
      builder: (context) {
        final theme = widget.theme;
        return AlertDialog(
          backgroundColor: theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.border, width: 1.2),
          ),
          title: Text(
            'Clear Local Data?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          content: Text(
            'This will reset calculation history, custom counters, active timer/stopwatch states, and tasks.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                SoundService().playClick();
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await StorageService().clearAllData();
                await StorageService().clearTimerState();
                await StorageService().clearStopwatchState();
                if (mounted) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All local data cleared successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: BouncyTap(
            onTap: () {
              SoundService().playClick();
              Navigator.pop(context);
            },
            scaleFraction: 0.88,
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: theme.text),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: theme.text,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Dark Mode Toggle Card
            _buildSectionCard(
              title: 'Appearance',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.lavenderCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 20,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.text,
                            ),
                          ),
                          Text(
                            _isDark ? 'Midnight Obsidian' : 'Clean Pure White',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isDark,
                    activeTrackColor: theme.primary,
                    onChanged: _onToggleDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Color Accent Palette (Tap to open Color Palette Hover Page)
            _buildSectionCard(
              title: 'Color Palette',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select accent color for buttons, badges, icons & cards',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Active Palette Showcase Card (Tap to open full Hover Page!)
                  BouncyTap(
                    onTap: _openColorPaletteHoverSheet,
                    scaleFraction: 0.96,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.lavenderCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Glowing circular color swatch
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _accent.swatchColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.swatchColor.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _accent.displayName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: theme.text,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: theme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _accent.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Explore',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Horizontal Quick-Access Color Swatches Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ToolerAccent.values.map((accent) {
                        final isSelected = _accent == accent;
                        return Padding(
                          padding: const EdgeInsets.only(right: 9),
                          child: BouncyTap(
                            onTap: () => _onSelectAccent(accent),
                            scaleFraction: 0.88,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? theme.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: accent.swatchColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.swatchColor.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2.5 Home Screen Widgets (4x1 Quick Bar & 1x1 Favorite Icon Shortcut)
            _buildSectionCard(
              title: 'Widgets',
              child: BouncyTap(
                onTap: () {
                  SoundService().playClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WidgetSettingsScreen(theme: theme),
                    ),
                  );
                },
                scaleFraction: 0.97,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.lavenderCard,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.widgets_rounded,
                              size: 21,
                              color: theme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home Screen Widgets',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: theme.text,
                                  ),
                                ),
                                Text(
                                  '4×1 Bar, Tasks & Notes, Steps, Tally & 1×1 Icon',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Audio, Haptics & Notifications
            _buildSectionCard(
              title: 'Feedback & Notifications',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_up_outlined, size: 20, color: theme.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            'Sound Click on Tap',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _soundOn,
                        activeTrackColor: theme.primary,
                        onChanged: (val) {
                          setState(() {
                            _soundOn = val;
                            SoundService().setSound(val);
                          });
                          SoundService().playClick();
                        },
                      ),
                    ],
                  ),
                  Divider(color: theme.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vibration_rounded, size: 20, color: theme.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            'Haptic Vibration on Tap',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _hapticsOn,
                        activeTrackColor: theme.primary,
                        onChanged: (val) {
                          setState(() {
                            _hapticsOn = val;
                            SoundService().setHaptics(val);
                          });
                          SoundService().playClick();
                        },
                      ),
                    ],
                  ),
                  Divider(color: theme.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, size: 20, color: theme.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Background Notifications',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.text,
                                    ),
                                  ),
                                  Text(
                                    'Timer ring, stopwatch & task alerts',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _notificationsOn,
                        activeTrackColor: theme.primary,
                        onChanged: _onToggleNotifications,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Security & Data Shield Card
            _buildSectionCard(
              title: 'Security & Data Shield',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 20, color: theme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'App Data Tamper Protection',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.text,
                                    ),
                                  ),
                                  Text(
                                    'SHA-256 cryptographic integrity verification',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _tamperProtection,
                        activeTrackColor: theme.primary,
                        onChanged: _onToggleTamperProtection,
                      ),
                    ],
                  ),
                  Divider(color: theme.border, height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.lavenderCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, size: 18, color: theme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Play Protect Verified • RSA-2048 Signed • Zero Cloud Leaks • Encrypted App Sandbox',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Developer & Feedback Card
            _buildSectionCard(
              title: 'Developer & Support',
              child: Column(
                children: [
                  InkWell(
                    onTap: _showAboutDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_pin_rounded, size: 20, color: theme.primary),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About Developer',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.text,
                                    ),
                                  ),
                                  Text(
                                    'Ayush Harinkhede',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: theme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  Divider(color: theme.border, height: 16),
                  InkWell(
                    onTap: _launchSendFeedback,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.feedback_outlined, size: 20, color: theme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Send Feedback',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.open_in_new_rounded, size: 18, color: theme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Legal & Policies Card
            _buildSectionCard(
              title: 'Legal & Privacy',
              child: Column(
                children: [
                  InkWell(
                    onTap: _showTermsDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel_outlined, size: 20, color: theme.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                'Terms & Conditions',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: theme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  Divider(color: theme.border, height: 16),
                  InkWell(
                    onTap: _showPrivacyPolicyDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined, size: 20, color: theme.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                'Privacy Policy',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: theme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  Divider(color: theme.border, height: 16),
                  InkWell(
                    onTap: _confirmClearData,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                'Clear Local Saved Data',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: ToolerLogo(
                height: 30,
                color: theme.text,
                accentColor: theme.primary,
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = _currentTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DEDICATED THEME COLOR PALETTE HOVER SHEET
/// ---------------------------------------------------------------------------
class _ColorPaletteHoverContent extends StatefulWidget {
  final ToolerAccent initialAccent;
  final bool isDark;
  final ValueChanged<ToolerAccent> onAccentChanged;

  const _ColorPaletteHoverContent({
    required this.initialAccent,
    required this.isDark,
    required this.onAccentChanged,
  });

  @override
  State<_ColorPaletteHoverContent> createState() =>
      _ColorPaletteHoverContentState();
}

class _ColorPaletteHoverContentState extends State<_ColorPaletteHoverContent> {
  late ToolerAccent _selectedAccent;
  String _activeFilter = 'All';

  final List<String> _filters = [
    'All',
    'Popular',
    'Vibrant',
    'Pastel',
    'Cool',
    'Warm',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccent = widget.initialAccent;
  }

  List<ToolerAccent> get _filteredAccents {
    if (_activeFilter == 'All') return ToolerAccent.values;
    return ToolerAccent.values.where((accent) {
      switch (_activeFilter) {
        case 'Popular':
          return [
            ToolerAccent.lilac,
            ToolerAccent.sky,
            ToolerAccent.indigo,
            ToolerAccent.emerald,
            ToolerAccent.amber,
          ].contains(accent);
        case 'Vibrant':
          return [
            ToolerAccent.indigo,
            ToolerAccent.coral,
            ToolerAccent.cyan,
            ToolerAccent.berry,
            ToolerAccent.lemon,
            ToolerAccent.crimson,
          ].contains(accent);
        case 'Pastel':
          return [
            ToolerAccent.lilac,
            ToolerAccent.rose,
            ToolerAccent.mint,
            ToolerAccent.sky,
            ToolerAccent.amber,
          ].contains(accent);
        case 'Cool':
          return [
            ToolerAccent.sky,
            ToolerAccent.cyan,
            ToolerAccent.indigo,
            ToolerAccent.mint,
            ToolerAccent.emerald,
            ToolerAccent.slate,
          ].contains(accent);
        case 'Warm':
          return [
            ToolerAccent.rose,
            ToolerAccent.coral,
            ToolerAccent.amber,
            ToolerAccent.crimson,
            ToolerAccent.berry,
            ToolerAccent.lemon,
          ].contains(accent);
        default:
          return true;
      }
    }).toList();
  }

  void _selectAccent(ToolerAccent accent) {
    if (_selectedAccent == accent) return;
    SoundService().playTap();
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAccent = accent;
    });
    widget.onAccentChanged(accent);
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = StationeryTheme.custom(
      isDark: widget.isDark,
      accent: _selectedAccent,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Active Theme Showcase Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: activeTheme.lavenderCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: activeTheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Glowing aura circle with swatch
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedAccent.swatchColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _selectedAccent.swatchColor
                                .withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedAccent.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: activeTheme.text,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: activeTheme.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: activeTheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'CURRENTLY SELECTED',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: activeTheme.primary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedAccent.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: activeTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Divider
                Container(
                  height: 1,
                  color: activeTheme.primary.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),

                // Live UI Simulation Preview Strip
                Text(
                  'LIVE UI ELEMENT PREVIEW',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: activeTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Filled Primary Button Preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: activeTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: activeTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Accent Button',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tinted Chip Badge Preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: activeTheme.lavenderBubble,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: activeTheme.primary.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: activeTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active Pill Badge',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: activeTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Slider / Switch preview dot
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: activeTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: activeTheme.border, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: activeTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live Accent',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: activeTheme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Filter Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Colors (${ToolerAccent.values.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: activeTheme.text,
                ),
              ),
              Text(
                'Tap to apply instantly',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: activeTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _filters.map((filter) {
                final isFilterActive = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BouncyTap(
                    onTap: () {
                      SoundService().playTap();
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                    scaleFraction: 0.94,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFilterActive
                            ? activeTheme.primary
                            : activeTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFilterActive
                              ? activeTheme.primary
                              : activeTheme.border,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isFilterActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isFilterActive
                              ? Colors.white
                              : activeTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Grid of Color Palettes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: _filteredAccents.length,
            itemBuilder: (context, index) {
              final accent = _filteredAccents[index];
              final isSelected = _selectedAccent == accent;

              return BouncyTap(
                onTap: () => _selectAccent(accent),
                scaleFraction: 0.94,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeTheme.lavenderCard
                        : activeTheme.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? accent.swatchColor : activeTheme.border,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? accent.swatchColor.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Swatch Circle + Status/Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Color Swatch Circle
                          AnimatedScale(
                            scale: isSelected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: accent.swatchColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.swatchColor
                                        .withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Active Badge or Tag
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.swatchColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeTheme.border.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                accent.tag,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: activeTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Bottom Info: Name & Short Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accent.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: activeTheme.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            accent.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: activeTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // Done / Dismiss Button
          BouncyTap(
            onTap: () {
              SoundService().playClick();
              Navigator.pop(context);
            },
            scaleFraction: 0.96,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: activeTheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: activeTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Apply & Close',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
