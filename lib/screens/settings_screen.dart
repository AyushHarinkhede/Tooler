import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../services/app_update_service.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';
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

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final AppUpdateService _updateService = AppUpdateService();
  late bool _isDark;
  late ToolerAccent _accent;
  late bool _useMaterialYou;
  MaterialYouPalette? _materialYouPalette;
  late bool _soundOn;
  late bool _hapticsOn;
  bool _notificationsOn = true;
  bool _tamperProtection = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateService.ensureListening();
    _isDark = widget.theme.isDark;
    _accent = widget.theme.accentPalette;
    _useMaterialYou = widget.theme.useMaterialYou;
    _materialYouPalette = widget.theme.materialYouPalette;
    _soundOn = SoundService().soundEnabled;
    _hapticsOn = SoundService().hapticsEnabled;
    _loadMaterialYouPalette();
    _loadNotificationPref();
    _loadTamperPref();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _updateService.status == AppUpdateStatus.needsPermission) {
      _checkAndResumePendingInstall();
    }
  }

  Future<void> _checkAndResumePendingInstall() async {
    final allowed = await _updateService.canInstallUnknownPackages();
    if (allowed) {
      await _updateService.launchPendingInstall();
    }
  }

  Future<void> _loadMaterialYouPalette() async {
    final palette = await WidgetService().getMaterialYouPalette(isDark: _isDark);
    if (mounted) {
      setState(() => _materialYouPalette = palette);
    }
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

  StationeryThemeMode _resolveThemeMode() {
    if (_isDark) return StationeryThemeMode.blueprintChalkboard;
    if (!_useMaterialYou && _accent == ToolerAccent.rose) {
      return StationeryThemeMode.neonHighlighter;
    }
    return StationeryThemeMode.classicDoodle;
  }

  void _onToggleDarkMode(bool val) async {
    SoundService().playClick();
    setState(() => _isDark = val);
    final sysPalette = await WidgetService().getMaterialYouPalette(isDark: _isDark);
    if (!mounted) return;
    setState(() => _materialYouPalette = sysPalette);
    await StorageService().saveTheme(
      _isDark,
      _accent,
      useMaterialYou: _useMaterialYou,
    );
    final updatedTheme = await StorageService().loadTheme();
    await WidgetService().syncToNative(updatedTheme);
    widget.onThemeChanged(_resolveThemeMode());
  }

  StationeryTheme get _currentTheme => StationeryTheme.custom(
        isDark: _isDark,
        accent: _accent,
        useMaterialYou: _useMaterialYou,
        materialYouPalette: _materialYouPalette,
      );

  void _onToggleMaterialYou(bool val) async {
    SoundService().playClick();
    HapticFeedback.selectionClick();
    setState(() => _useMaterialYou = val);
    if (val) {
      final sysPalette =
          await WidgetService().getMaterialYouPalette(isDark: _isDark);
      if (mounted) {
        setState(() => _materialYouPalette = sysPalette);
      }
    }
    await StorageService().saveTheme(
      _isDark,
      _accent,
      useMaterialYou: val,
    );
    final updatedTheme = await StorageService().loadTheme();
    await WidgetService().syncToNative(updatedTheme);
    widget.onThemeChanged(_resolveThemeMode());
  }

  void _onSelectAccent(ToolerAccent accent) async {
    SoundService().playClick();
    setState(() {
      _accent = accent;
      _useMaterialYou = false;
    });
    await StorageService().saveTheme(
      _isDark,
      _accent,
      useMaterialYou: false,
    );
    final updatedTheme = await StorageService().loadTheme();
    await WidgetService().syncToNative(updatedTheme);
    widget.onThemeChanged(_resolveThemeMode());
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
        final theme = _currentTheme;
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
        final theme = _currentTheme;
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
        final theme = _currentTheme;
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

  void _showUpdateWarningHoverPage() {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) {
        final theme = _currentTheme;
        final isDark = theme.isDark;
        const warnAmber = Color(0xFFF59E0B);

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A20) : Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: warnAmber.withValues(alpha: 0.45),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: warnAmber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: warnAmber.withValues(alpha: 0.4),
                                width: 1.1,
                              ),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: warnAmber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Update App Warning',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: theme.text,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              SoundService().playClick();
                              Navigator.pop(ctx);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildUpdateWarningRow(
                        theme,
                        icon: Icons.cloud_download_rounded,
                        text:
                            'Downloads the latest Tooler.apk directly from github.com/AyushHarinkhede/Tooler.',
                      ),
                      const SizedBox(height: 10),
                      _buildUpdateWarningRow(
                        theme,
                        icon: Icons.cleaning_services_rounded,
                        text:
                            'Removes older Tooler.apk files saved by the app on your device and replaces them with the new package.',
                      ),
                      const SizedBox(height: 10),
                      _buildUpdateWarningRow(
                        theme,
                        icon: Icons.install_mobile_rounded,
                        text:
                            'Opens Android\'s system Package Installer so the update installs cleanly over the current app.',
                      ),
                      const SizedBox(height: 10),
                      _buildUpdateWarningRow(
                        theme,
                        icon: Icons.shield_outlined,
                        text:
                            'Allow "Install unknown apps" if asked. Google Play Protect cannot be disabled by an app; tap "Install anyway" if prompted.',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                SoundService().playClick();
                                Navigator.pop(ctx);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: theme.border, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                SoundService().playSpecialClick();
                                HapticFeedback.mediumImpact();
                                Navigator.pop(ctx);
                                _updateService.startUpdate();
                              },
                              icon: const Icon(
                                Icons.system_update_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Download & Update',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildUpdateWarningRow(
    StationeryTheme theme, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 17, color: theme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateAppCard(StationeryTheme theme) {
    return _buildSectionCard(
      title: 'Update App',
      child: AnimatedBuilder(
        animation: _updateService,
        builder: (context, _) {
          final status = _updateService.status;
          final isBusy = _updateService.isBusy;
          final percent = _updateService.percent;
          final bytesText = _updateService.formatBytesProgress();

          final bool isReadyToInstall = status == AppUpdateStatus.ready ||
              status == AppUpdateStatus.installing ||
              status == AppUpdateStatus.needsPermission;
          final bool isError = status == AppUpdateStatus.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: BouncyTap(
                      onTap: () {
                        if (isBusy) return;
                        if (isReadyToInstall) {
                          SoundService().playClick();
                          _updateService.launchPendingInstall();
                        } else {
                          _showUpdateWarningHoverPage();
                        }
                      },
                      scaleFraction: isBusy ? 1.0 : 0.97,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isError
                                ? Colors.red.withValues(alpha: 0.12)
                                : theme.primary.withValues(
                                    alpha: isBusy ? 0.14 : 1.0,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isError
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : theme.primary,
                              width: 1.3,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isBusy)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _updateService.progress
                                        .clamp(0.04, 1.0),
                                    heightFactor: 1.0,
                                    child: Container(
                                      color:
                                          theme.primary.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isBusy) ...[
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          value: status ==
                                                  AppUpdateStatus.downloading
                                              ? _updateService.progress
                                                  .clamp(0.05, 1.0)
                                              : null,
                                          color: Colors.white,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Icon(
                                        status == AppUpdateStatus.replacing
                                            ? Icons.cleaning_services_rounded
                                            : Icons.downloading_rounded,
                                        size: 19,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 9),
                                      Flexible(
                                        child: Text(
                                          bytesText.isNotEmpty
                                              ? '$percent%  •  $bytesText'
                                              : '$percent%',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ] else if (isReadyToInstall) ...[
                                      const Icon(
                                        Icons.install_mobile_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        status ==
                                                AppUpdateStatus.needsPermission
                                            ? 'Allow & Install'
                                            : 'Install Update',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ] else if (isError) ...[
                                      const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Update',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ] else ...[
                                      const Icon(
                                        Icons.system_update_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Update',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isReadyToInstall) ...[
                    const SizedBox(width: 10),
                    BouncyTap(
                      onTap: () {
                        SoundService().playClick();
                        _showUpdateWarningHoverPage();
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.border, width: 1.2),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 22,
                          color: theme.text,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if ((isError || status == AppUpdateStatus.needsPermission) &&
                  _updateService.message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _updateService.message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.red : theme.primary,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _confirmClearData() {
    SoundService().playClick();
    showDialog(
      context: context,
      builder: (context) {
        final theme = _currentTheme;
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
                  Expanded(
                    child: Row(
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
                        Expanded(
                          child: Column(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
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
                    value: _isDark,
                    activeTrackColor: theme.primary,
                    onChanged: _onToggleDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Color Accent Palette (Material You system toggle + animated gliding palette carousel)
            _buildSectionCard(
              title: 'Color Palette',
              child: Builder(
                builder: (context) {
                  final Color previewSwatch = _useMaterialYou
                      ? theme.accentColorDot
                      : _accent.swatchColor;
                  final Color swatchContrast =
                      previewSwatch.computeLuminance() > 0.55
                          ? const Color(0xFF18181B)
                          : Colors.white;
                  final String activeLabel = _useMaterialYou
                      ? 'Material You'
                      : _accent.displayName;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Material You vs Custom Palette Switch Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: theme.lavenderCard,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _useMaterialYou
                                      ? Icons.auto_awesome_rounded
                                      : Icons.palette_outlined,
                                  size: 18,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Material You',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            key: const ValueKey('material_you_switch'),
                            value: _useMaterialYou,
                            activeTrackColor: theme.primary,
                            onChanged: _onToggleMaterialYou,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Clean Active Color Banner (no captions, no ACTIVE badge, no Explore button)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: previewSwatch,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: previewSwatch.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 2.2),
                              ),
                              child: Center(
                                child: Icon(
                                  _useMaterialYou
                                      ? Icons.auto_awesome_rounded
                                      : Icons.check_rounded,
                                  size: _useMaterialYou ? 18 : 20,
                                  color: swatchContrast,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, anim) =>
                                    SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.10, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child:
                                      FadeTransition(opacity: anim, child: child),
                                ),
                                child: Align(
                                  key: ValueKey<String>(activeLabel),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    activeLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: theme.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Smooth Gliding Animated Color Dots Carousel
                      _AnimatedColorPaletteSlider(
                        accents: ToolerAccent.values,
                        selectedAccent: _accent,
                        isMaterialYouActive: _useMaterialYou,
                        theme: theme,
                        onAccentSelected: _onSelectAccent,
                      ),
                    ],
                  );
                },
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
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.volume_up_outlined, size: 20, color: theme.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sound Click on Tap',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.vibration_rounded, size: 20, color: theme.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Haptic Vibration on Tap',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                    'Timers, Stopwatch, Alarm, Tasks, Tally, Weather & Steps',
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
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.person_pin_rounded, size: 20, color: theme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'About Developer',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: theme.text,
                                        ),
                                      ),
                                      Text(
                                        'Ayush Harinkhede',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: theme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.feedback_outlined, size: 20, color: theme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Send Feedback',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

            // 5.5 Update App Card (Directly before Legal & Privacy, zero caption)
            _buildUpdateAppCard(theme),

            const SizedBox(height: 18),

            // 6. Legal & Policies Card
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
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.gavel_outlined, size: 20, color: theme.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Terms & Conditions',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.privacy_tip_outlined, size: 20, color: theme.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Privacy Policy',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Clear Local Saved Data',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
/// ANIMATED GLIDING COLOR PALETTE CAROUSEL
/// - Scroll-driven curved scale, floating arc lift, and horizontal convergence
/// - Supports smooth touch/mouse slide-to-select & tap-to-glide centering
/// ---------------------------------------------------------------------------
class _AnimatedColorPaletteSlider extends StatefulWidget {
  final List<ToolerAccent> accents;
  final ToolerAccent selectedAccent;
  final bool isMaterialYouActive;
  final StationeryTheme theme;
  final ValueChanged<ToolerAccent> onAccentSelected;

  const _AnimatedColorPaletteSlider({
    required this.accents,
    required this.selectedAccent,
    required this.isMaterialYouActive,
    required this.theme,
    required this.onAccentSelected,
  });

  @override
  State<_AnimatedColorPaletteSlider> createState() =>
      _AnimatedColorPaletteSliderState();
}

class _AnimatedColorPaletteSliderState
    extends State<_AnimatedColorPaletteSlider> {
  late PageController _pageController;
  int? _programmaticTargetPage;

  @override
  void initState() {
    super.initState();
    final initialIdx = widget.accents
        .indexOf(widget.selectedAccent)
        .clamp(0, widget.accents.length - 1);
    _pageController = PageController(
      initialPage: initialIdx,
      viewportFraction: 0.20,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedColorPaletteSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAccent != widget.selectedAccent &&
        _programmaticTargetPage == null &&
        _pageController.hasClients) {
      final target = widget.accents.indexOf(widget.selectedAccent);
      final current = _pageController.page?.round();
      if (target != -1 && current != target) {
        _animateToIndex(target);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _animateToIndex(int index) async {
    _programmaticTargetPage = index;
    try {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (mounted && _programmaticTargetPage == index) {
        _programmaticTargetPage = null;
      }
    }
  }

  void _handleDotTap(int index) {
    final accent = widget.accents[index];
    HapticFeedback.selectionClick();
    widget.onAccentSelected(accent);
    _animateToIndex(index);
  }

  void _handlePageChanged(int index) {
    if (_programmaticTargetPage != null) {
      if (index == _programmaticTargetPage) {
        _programmaticTargetPage = null;
      }
      return;
    }
    final accent = widget.accents[index];
    if (accent != widget.selectedAccent || widget.isMaterialYouActive) {
      HapticFeedback.selectionClick();
      widget.onAccentSelected(accent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 70,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.08, 0.92, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: PageView.builder(
                key: const ValueKey('color_palette_slider'),
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _handlePageChanged,
                itemCount: widget.accents.length,
                itemBuilder: (context, index) {
                  final accent = widget.accents[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      double currentPage = widget.accents
                          .indexOf(widget.selectedAccent)
                          .clamp(0, widget.accents.length - 1)
                          .toDouble();
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        currentPage = _pageController.page ??
                            _pageController.initialPage.toDouble();
                      }

                      final double delta = index - currentPage;
                      final double absDelta = delta.abs();
                      final double focus =
                          (1.0 - (absDelta / 2.3)).clamp(0.0, 1.0);
                      final double smoothFocus =
                          Curves.easeOutCubic.transform(focus);

                      // Smooth scroll-driven scale, floating arc lift & glide drift
                      final double scale = 0.78 + (0.42 * smoothFocus);
                      final double arcOffsetY = -6.5 * smoothFocus;
                      final double glideOffsetX =
                          -delta * (1.0 - smoothFocus) * 3.0;
                      final double opacity = widget.isMaterialYouActive
                          ? (0.45 + 0.27 * smoothFocus)
                          : (0.58 + 0.42 * smoothFocus);

                      final bool isSelected = !widget.isMaterialYouActive &&
                          widget.selectedAccent == accent;
                      final Color dotColor = accent.swatchColor;
                      final Color checkColor =
                          dotColor.computeLuminance() > 0.55
                              ? const Color(0xFF18181B)
                              : Colors.white;

                      return Transform.translate(
                        offset: Offset(glideOffsetX, arcOffsetY),
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Center(
                              child: BouncyTap(
                                onTap: () => _handleDotTap(index),
                                scaleFraction: 0.86,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding: EdgeInsets.all(isSelected ? 3.0 : 2.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? widget.theme.primary
                                          : Colors.transparent,
                                      width: 2.2,
                                    ),
                                  ),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.55),
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: dotColor.withValues(
                                            alpha: isSelected
                                                ? 0.50
                                                : (0.18 + 0.18 * smoothFocus),
                                          ),
                                          blurRadius: isSelected
                                              ? 10
                                              : (3 + 5 * smoothFocus),
                                          offset: Offset(
                                              0, 2 + 1.5 * smoothFocus),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedOpacity(
                                      opacity: isSelected ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 160),
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.0 : 0.4,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOutBack,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: checkColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: widget.isMaterialYouActive ? 14 : 26,
            height: 3.5,
            decoration: BoxDecoration(
              color: widget.theme.primary.withValues(
                alpha: widget.isMaterialYouActive ? 0.22 : 0.65,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
