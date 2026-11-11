import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets_3d/tooler_logo.dart';

/// ---------------------------------------------------------------------------
/// REDESIGNED MINIMAL SETTINGS SCREEN
/// - Pure Tooler identity (Zero "Stationery" / "School Kit" mentions)
/// - Modern Dark Mode switch
/// - Compact Color Accent bars with round color preview dots
/// - Tactile Sound & Haptic Vibration toggles
/// - Clean dialogs with 1.2px borders
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

  @override
  void initState() {
    super.initState();
    _isDark = widget.theme.isDark;
    _accent = widget.theme.accentPalette;
    _soundOn = SoundService().soundEnabled;
    _hapticsOn = SoundService().hapticsEnabled;
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

  void _showAboutDialog() {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              ToolerLogo(
                height: 44,
                color: theme.text,
                accentColor: theme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'A clean, aesthetic, minimal multi-utility application offering precision calculators, unit converters, live compass sensors, and productivity tools with zero clutter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.lavenderCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border, width: 1),
                ),
                child: Text(
                  'v1.0.0 • Ayush Harinkhede',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
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
                  color: theme.primary,
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
            'This will reset calculation history, custom counters, and tasks.',
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
                await StorageService().clearAllData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All local data cleared successfully')),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: theme.text),
          onPressed: () {
            SoundService().playClick();
            Navigator.pop(context);
          },
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
                    activeColor: theme.primary,
                    onChanged: _onToggleDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Color Accent Palette (Compact Bars with Color Dots)
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

            // 3. Audio & Haptics Feedback
            _buildSectionCard(
              title: 'Feedback & Sound',
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
                        activeColor: theme.primary,
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
                        activeColor: theme.primary,
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
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. System & About Card
            _buildSectionCard(
              title: 'About',
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
                          Text(
                            'About Tooler',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
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
                          Text(
                            'Clear Local Saved Data',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
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
      child: InkWell(
        onTap: () => _onSelectAccent(accent),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.lavenderCard : theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? theme.primary : theme.border,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // 14px Circular Color Dot
              Container(
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
