import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';

/// ---------------------------------------------------------------------------
/// REDESIGNED MINIMAL SETTINGS SCREEN
/// - Pure Tooler identity
/// - Modern Dark Mode switch
/// - Compact Color Accent bars with round color preview dots
/// - Tactile Sound & Haptic Vibration toggles
/// - Notifications & Background persistence toggle
/// - Terms and Conditions & Privacy Policy dialogs
/// - About Developer (Ayush Harinkhede) with direct Send Feedback email launch
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
    final nextMode = _isDark
        ? StationeryThemeMode.blueprintChalkboard
        : (_accent == ToolerAccent.rose
            ? StationeryThemeMode.neonHighlighter
            : StationeryThemeMode.classicDoodle);
    widget.onThemeChanged(nextMode);
  }

  void _onSelectAccent(ToolerAccent accent) async {
    SoundService().playClick();
    setState(() => _accent = accent);
    await StorageService().saveTheme(_isDark, _accent);
    final nextMode = _isDark
        ? StationeryThemeMode.blueprintChalkboard
        : (accent == ToolerAccent.rose
            ? StationeryThemeMode.neonHighlighter
            : StationeryThemeMode.classicDoodle);
    widget.onThemeChanged(nextMode);
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
                      'v1.0.0 • Tooler Master Edition',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Direct Send Feedback Button in About
              BouncyTap(
                onTap: () {
                  Navigator.pop(context);
                  _launchSendFeedback();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Send Feedback',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    final theme = widget.theme;

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

            // 2. Color Accent Palette
            _buildSectionCard(
              title: 'Color Palette',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select accent color for buttons, badges & cards',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAccentTile('Lilac Violet', const Color(0xFFA855F7), ToolerAccent.lilac),
                  _buildAccentTile('Soft Blush Rose', const Color(0xFFFB7185), ToolerAccent.rose),
                  _buildAccentTile('Sage Mint', const Color(0xFF10B981), ToolerAccent.mint),
                  _buildAccentTile('Ocean Sky', const Color(0xFF0EA5E9), ToolerAccent.sky),
                  _buildAccentTile('Sunset Amber', const Color(0xFFF59E0B), ToolerAccent.amber),
                ],
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
                            SoundService().soundEnabled = val;
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
                            SoundService().hapticsEnabled = val;
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = widget.theme;
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

  Widget _buildAccentTile(String name, Color dotColor, ToolerAccent accent) {
    final theme = widget.theme;
    final isSelected = _accent == accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BouncyTap(
        onTap: () => _onSelectAccent(accent),
        scaleFraction: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.lavenderCard : theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? theme.primary : theme.border,
              width: isSelected ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              // 14px Circular Color Dot with AnimatedScale
              AnimatedScale(
                scale: isSelected ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: theme.text,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: theme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
