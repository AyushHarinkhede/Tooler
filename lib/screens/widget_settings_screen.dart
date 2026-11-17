import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/widget_service.dart';
import '../widgets_3d/minimal_2d_illustrations.dart';
import '../widgets_3d/bouncy_tap.dart';

class WidgetSettingsScreen extends StatefulWidget {
  final StationeryTheme theme;

  const WidgetSettingsScreen({
    super.key,
    required this.theme,
  });

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  String _selectedRatio = '4x1'; // '4x1' or '1x1'
  String _colorMode = 'app';     // 'app' or 'system'
  String _favToolId = 'calc';
  WidgetSystemColors? _systemColors;
  bool _isPinning = false;

  static const List<Map<String, String>> _allSections = [
    {'id': 'calc', 'title': 'Calculator', 'iconType': 'calc'},
    {'id': 'calendar', 'title': 'Calendar', 'iconType': 'calendar'},
    {'id': 'weather', 'title': 'Weather', 'iconType': 'weather'},
    {'id': 'games', 'title': 'Games', 'iconType': 'games'},
    {'id': 'recorder', 'title': 'Noise & Rec', 'iconType': 'recorder'},
    {'id': 'radio', 'title': 'FM Radio', 'iconType': 'radio'},
    {'id': 'power', 'title': 'Power', 'iconType': 'power'},
    {'id': 'compass', 'title': 'Compass', 'iconType': 'compass'},
    {'id': 'converters', 'title': 'Converters', 'iconType': 'converters'},
    {'id': 'currency', 'title': 'Currency', 'iconType': 'currency'},
    {'id': 'tasks', 'title': 'Tasks & Notes', 'iconType': 'tasks'},
    {'id': 'alarm', 'title': 'Smart Alarm', 'iconType': 'alarm'},
    {'id': 'stopwatch', 'title': 'Stopwatch', 'iconType': 'stopwatch'},
    {'id': 'timer', 'title': 'Timer', 'iconType': 'timer'},
    {'id': 'sizer', 'title': 'Sizer', 'iconType': 'sizer'},
    {'id': 'counters', 'title': 'Counters', 'iconType': 'counters'},
    {'id': 'age', 'title': 'Age Calc', 'iconType': 'age'},
    {'id': 'password', 'title': 'Password', 'iconType': 'password'},
    {'id': 'security', 'title': 'Security', 'iconType': 'security'},
    {'id': 'browser', 'title': 'Browser', 'iconType': 'browser'},
    {'id': 'illustrations', 'title': 'Studio', 'iconType': 'illustrations'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await WidgetService().loadPrefs();
    final sys = await WidgetService().getSystemColors(widget.theme);
    if (mounted) {
      setState(() {
        _selectedRatio = WidgetService().selectedRatio;
        _colorMode = WidgetService().colorMode;
        _favToolId = WidgetService().favToolId;
        _systemColors = sys;
      });
    }
  }

  Future<void> _updateConfig({
    String? ratio,
    String? colorMode,
    String? favToolId,
  }) async {
    SoundService().playClick();
    HapticFeedback.selectionClick();
    setState(() {
      if (ratio != null) _selectedRatio = ratio;
      if (colorMode != null) _colorMode = colorMode;
      if (favToolId != null) _favToolId = favToolId;
    });
    await WidgetService().saveConfig(
      theme: widget.theme,
      selectedRatio: _selectedRatio,
      colorMode: _colorMode,
      favToolId: _favToolId,
    );
  }

  Future<void> _pinSelectedWidget() async {
    SoundService().playSpecialClick();
    HapticFeedback.mediumImpact();
    setState(() => _isPinning = true);

    final bool ok = await WidgetService().pinWidgetToHomeScreen(
      _selectedRatio,
      widget.theme,
    );

    if (mounted) {
      setState(() => _isPinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (_selectedRatio == '4x1'
                    ? 'Tap "Add" to place Tooler 4×1 Quick Bar on Home Screen!'
                    : 'Tap "Add" to place your 1×1 Icon Shortcut on Home Screen!')
                : 'Long-press your phone Home Screen → Widgets → Tooler to place it.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: widget.theme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Resolve live preview palette based on selected Color Mode ('app' vs 'system')
    final bool useSystem = _colorMode == 'system' && _systemColors != null;
    final Color previewCardBg = useSystem ? _systemColors!.cardBg : theme.cardBg;
    final Color previewBubble = useSystem ? _systemColors!.bubbleBg : theme.lavenderBubble;
    final Color previewPrimary = useSystem ? _systemColors!.primary : theme.primary;
    final Color previewBorder = useSystem ? _systemColors!.border : theme.border;
    final bool previewIsDark = useSystem ? _systemColors!.isDark : theme.isDark;

    final selectedSection = _allSections.firstWhere(
      (s) => s['id'] == _favToolId,
      orElse: () => _allSections.first,
    );

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
          'Home Screen Widgets',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: theme.text,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // 1. Live Home Screen Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.isDark
                      ? [const Color(0xFF1F2333), const Color(0xFF141722)]
                      : [
                          theme.primary.withValues(alpha: 0.14),
                          theme.lavenderCard.withValues(alpha: 0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: theme.border, width: 1.3),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LIVE PREVIEW',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: theme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.cardBg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.border),
                        ),
                        child: Text(
                          _selectedRatio == '4x1' ? '4 × 1 Bar' : '1 × 1 Icon',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Render 4x1 or 1x1 Widget Preview
                  if (_selectedRatio == '4x1')
                    Container(
                      height: 76,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: previewCardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: previewBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: previewIsDark ? 0.35 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPreview4x1Slot(
                            iconType: 'calc',
                            bubble: previewBubble,
                            accent: previewPrimary,
                            isDark: previewIsDark,
                          ),
                          _buildPreview4x1Slot(
                            iconType: 'calendar',
                            bubble: previewBubble,
                            accent: previewPrimary,
                            isDark: previewIsDark,
                          ),
                          _buildPreview4x1Slot(
                            iconType: 'weather',
                            bubble: previewBubble,
                            accent: previewPrimary,
                            isDark: previewIsDark,
                          ),
                          // 4th button: All Tools (switches straight to Tooler Home)
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: previewPrimary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // 1x1 Icon-Only Squircle Preview (Zero Name Text!)
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: previewCardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: previewBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: previewIsDark ? 0.35 : 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Minimal2DIcon(
                          type: selectedSection['iconType']!,
                          size: 50,
                          bubbleColor: previewBubble,
                          accentColor: previewPrimary,
                          isDark: previewIsDark,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  Text(
                    _selectedRatio == '4x1'
                        ? 'Calculator · Calendar · Weather · All Tools'
                        : 'Icon-only shortcut · Opens ${selectedSection['title']} hover page',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Ratio Selector (4x1 vs 1x1)
            _buildSectionCard(
              title: 'Widget Ratio',
              child: Row(
                children: [
                  Expanded(
                    child: _buildChoiceTile(
                      label: '4 × 1 Quick Bar',
                      subtitle: '4 direct icons',
                      icon: Icons.view_week_rounded,
                      isSelected: _selectedRatio == '4x1',
                      onTap: () => _updateConfig(ratio: '4x1'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChoiceTile(
                      label: '1 × 1 Shortcut',
                      subtitle: 'Fav icon only',
                      icon: Icons.crop_square_rounded,
                      isSelected: _selectedRatio == '1x1',
                      onTap: () => _updateConfig(ratio: '1x1'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Color Style Selector (App Theme vs Device System)
            _buildSectionCard(
              title: 'Widget Color Theme',
              child: Row(
                children: [
                  Expanded(
                    child: _buildChoiceTile(
                      label: 'App Theme',
                      subtitle: 'Tooler colors',
                      icon: Icons.palette_rounded,
                      isSelected: _colorMode == 'app',
                      onTap: () => _updateConfig(colorMode: 'app'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChoiceTile(
                      label: 'Device System',
                      subtitle: 'Phone palette',
                      icon: Icons.phone_android_rounded,
                      isSelected: _colorMode == 'system',
                      onTap: () => _updateConfig(colorMode: 'system'),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Favorite Tool Picker (for 1x1 Widget)
            if (_selectedRatio == '1x1') ...[
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Select 1×1 Section Icon',
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allSections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final sec = _allSections[index];
                    final bool isSelected = sec['id'] == _favToolId;
                    return InkWell(
                      onTap: () => _updateConfig(favToolId: sec['id']),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primary.withValues(alpha: 0.14)
                              : theme.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? theme.primary : theme.border,
                            width: isSelected ? 1.8 : 1.1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Minimal2DIcon(
                              type: sec['iconType']!,
                              size: 36,
                              bubbleColor: isSelected
                                  ? theme.primary.withValues(alpha: 0.2)
                                  : theme.lavenderBubble,
                              accentColor: theme.primary,
                              isDark: theme.isDark,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sec['title']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? theme.primary : theme.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 22),

            // 5. Primary CTA: Add Widget Directly to Home Screen
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 3,
                ),
                onPressed: _isPinning ? null : _pinSelectedWidget,
                icon: _isPinning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_to_home_screen_rounded, size: 22),
                label: Text(
                  _selectedRatio == '4x1'
                      ? 'Add 4×1 Widget to Home Screen'
                      : 'Add 1×1 Widget to Home Screen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Already placed widgets update their color & icon automatically.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: theme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview4x1Slot({
    required String iconType,
    required Color bubble,
    required Color accent,
    required bool isDark,
  }) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: bubble,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Minimal2DIcon(
          type: iconType,
          size: 38,
          bubbleColor: Colors.transparent,
          accentColor: accent,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    final theme = widget.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = widget.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : theme.bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? theme.primary : theme.border,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : theme.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : theme.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
