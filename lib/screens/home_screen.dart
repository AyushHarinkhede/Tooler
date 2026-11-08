import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/notebook_header_area.dart';
import '../widgets_3d/notebook_sticky_calculator.dart';
import '../widgets_3d/minimal_sticky_note.dart';
import '../widgets_3d/minimal_ink_icons.dart';
import '../widgets_3d/paper_crumple_unfold.dart';
import 'age_calculator_screen.dart';
import 'converters_screen.dart';
import 'stopwatch_screen.dart';
import 'timer_screen.dart';
import 'sizer_screen.dart';
import 'counters_screen.dart';
import 'tasks_screen.dart';
import 'currency_screen.dart';
import 'games_screen.dart';
import 'browser_screen.dart';
import 'compass_screen.dart';
import 'password_generator_screen.dart';
import 'settings_screen.dart';

/// ---------------------------------------------------------------------------
/// REDESIGNED AESTHETIC NOTEBOOK HOME DESK
/// Clean, minimal, authentic ruled paper notebook:
/// - Top notebook header index area with real Date/Page window
/// - Minimal flat pastel Sticky Note Calculator
/// - Minimal pastel Sticky Notes with ink-drawn icons & ZERO shadows
/// - Crumpled Paper Ball Unfolding / Compression page transition
/// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  final StationeryTheme theme;
  final Function(StationeryThemeMode mode) onThemeChanged;

  const HomeScreen({
    super.key,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Map<String, dynamic>> _stickyTools;

  @override
  void initState() {
    super.initState();
    _initTools();
  }

  void _initTools() {
    // 13 tools with Hand-Drawn Ink Icons & Flat Pastel Post-it Hues (Zero Shadows)
    _stickyTools = [
      {
        'title': 'Age Calculator',
        'subtitle': 'Birthdays & milestones',
        'iconWidget': const InkCalendarIcon(size: 20, color: Color(0xFF854D0E)),
        'noteColor': const Color(0xFFFEF9C3), // Butter Yellow
        'borderColor': const Color(0xFFCA8A04),
        'textColor': const Color(0xFF713F12),
        'angle': -0.018,
        'builder': (context) => AgeCalculatorScreen(theme: widget.theme),
      },
      {
        'title': 'Converters',
        'subtitle': 'Length, Mass, Speed, Data',
        'iconWidget': const InkRulerIcon(size: 20, color: Color(0xFF065F46)),
        'noteColor': const Color(0xFFD1FAE5), // Mint Sage
        'borderColor': const Color(0xFF059669),
        'textColor': const Color(0xFF064E3B),
        'angle': 0.016,
        'builder': (context) => ConvertersScreen(theme: widget.theme),
      },
      {
        'title': 'Stopwatch',
        'subtitle': 'Precision laps & splits',
        'iconWidget': const InkStopwatchIcon(size: 20, color: Color(0xFF9D174D)),
        'noteColor': const Color(0xFFFFE4E6), // Rose Petal
        'borderColor': const Color(0xFFE11D48),
        'textColor': const Color(0xFF831843),
        'angle': -0.014,
        'builder': (context) => StopwatchScreen(theme: widget.theme),
      },
      {
        'title': 'Timer',
        'subtitle': 'Countdown arc presets',
        'iconWidget': const InkHourglassIcon(size: 20, color: Color(0xFF0369A1)),
        'noteColor': const Color(0xFFE0F2FE), // Sky Wash
        'borderColor': const Color(0xFF0284C7),
        'textColor': const Color(0xFF0C4A6E),
        'angle': 0.018,
        'builder': (context) => TimerScreen(theme: widget.theme),
      },
      {
        'title': 'Sizer Tools',
        'subtitle': 'Ring, Bangle, Strap & Ruler',
        'iconWidget': const InkSizerIcon(size: 20, color: Color(0xFF9A3412)),
        'noteColor': const Color(0xFFFFEDD5), // Peach Blossom
        'borderColor': const Color(0xFFEA580C),
        'textColor': const Color(0xFF7C2D12),
        'angle': -0.016,
        'builder': (context) => SizerScreen(theme: widget.theme),
      },
      {
        'title': 'Custom Counters',
        'subtitle': 'Tally habits & daily goals',
        'iconWidget': const InkCounterIcon(size: 20, color: Color(0xFF5B21B6)),
        'noteColor': const Color(0xFFEDE9FE), // Lavender Mist
        'borderColor': const Color(0xFF7C3AED),
        'textColor': const Color(0xFF4C1D95),
        'angle': 0.015,
        'builder': (context) => CountersScreen(theme: widget.theme),
      },
      {
        'title': 'Task Manager',
        'subtitle': 'Homework & study to-dos',
        'iconWidget': const InkClipboardIcon(size: 20, color: Color(0xFF166534)),
        'noteColor': const Color(0xFFDCFCE7), // Pale Celery
        'borderColor': const Color(0xFF16A34A),
        'textColor': const Color(0xFF14532D),
        'angle': -0.018,
        'builder': (context) => TasksScreen(theme: widget.theme),
      },
      {
        'title': 'Currency',
        'subtitle': '15+ global exchange rates',
        'iconWidget': const InkCoinsIcon(size: 20, color: Color(0xFF3730A3)),
        'noteColor': const Color(0xFFE0E7FF), // Ice Indigo
        'borderColor': const Color(0xFF4F46E5),
        'textColor': const Color(0xFF312E81),
        'angle': 0.016,
        'builder': (context) => CurrencyScreen(theme: widget.theme),
      },
      {
        'title': 'Games Arcade',
        'subtitle': 'Tic-Tac-Toe, Snake, Dice',
        'iconWidget': const InkDiceIcon(size: 20, color: Color(0xFF9F1239)),
        'noteColor': const Color(0xFFFCE7F3), // Bubblegum Wash
        'borderColor': const Color(0xFFDB2777),
        'textColor': const Color(0xFF881337),
        'angle': -0.015,
        'builder': (context) => GamesScreen(theme: widget.theme),
      },
      {
        'title': 'Web Browser',
        'subtitle': 'Fast links & research',
        'iconWidget': const InkGlobeIcon(size: 20, color: Color(0xFF1E3A8A)),
        'noteColor': const Color(0xFFDBEAFE), // Soft Blue
        'borderColor': const Color(0xFF2563EB),
        'textColor': const Color(0xFF1E1B4B),
        'angle': 0.017,
        'builder': (context) => BrowserScreen(theme: widget.theme),
      },
      {
        'title': 'Digital Compass',
        'subtitle': 'Sensor rose needle & level',
        'iconWidget': const InkCompassIcon(size: 20, color: Color(0xFF92400E)),
        'noteColor': const Color(0xFFFEF3C7), // Warm Amber
        'borderColor': const Color(0xFFD97706),
        'textColor': const Color(0xFF78350F),
        'angle': -0.017,
        'builder': (context) => CompassScreen(theme: widget.theme),
      },
      {
        'title': 'Password Gen',
        'subtitle': 'Secure tokens & strength',
        'iconWidget': const InkPadlockIcon(size: 20, color: Color(0xFF334155)),
        'noteColor': const Color(0xFFF1F5F9), // Soft Slate
        'borderColor': const Color(0xFF64748B),
        'textColor': const Color(0xFF1E293B),
        'angle': 0.015,
        'builder': (context) => PasswordGeneratorScreen(theme: widget.theme),
      },
      {
        'title': 'Settings',
        'subtitle': 'Themes, sounds & modes',
        'iconWidget': const InkGearsIcon(size: 20, color: Color(0xFF6B21A8)),
        'noteColor': const Color(0xFFF3E8FF), // Pastel Violet
        'borderColor': const Color(0xFFA855F7),
        'textColor': const Color(0xFF581C87),
        'angle': -0.016,
        'builder': (context) => SettingsScreen(
          theme: widget.theme,
          onThemeChanged: widget.onThemeChanged,
        ),
      },
    ];
  }

  /// Opens the selected tool using the authentic Crumpled Paper Ball Unfolding Animation!
  void _openTool(Map<String, dynamic> tool) {
    SoundService().playClick();
    Navigator.push(
      context,
      PaperUnfoldRoute(
        title: tool['title'] as String,
        noteColor: tool['noteColor'] as Color,
        borderColor: tool['borderColor'] as Color,
        textColor: tool['textColor'] as Color,
        child: (tool['builder'] as WidgetBuilder)(context),
      ),
    );
  }

  void _cycleTheme() {
    SoundService().playClick();
    final next = widget.theme.mode == StationeryThemeMode.classicDoodle
        ? StationeryThemeMode.blueprintChalkboard
        : widget.theme.mode == StationeryThemeMode.blueprintChalkboard
            ? StationeryThemeMode.neonHighlighter
            : StationeryThemeMode.classicDoodle;
    widget.onThemeChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Stack(
        children: [
          // 1. Notebook Ruled Paper Background with blue lines, paper texture & red margins
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),

          // 2. Main Scrollable Desk
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Notebook Header / Index Space (Tooler + Date & Page Stamp)
                SliverToBoxAdapter(
                  child: NotebookHeaderArea(
                    theme: widget.theme,
                    onThemeToggle: _cycleTheme,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // Minimal Aesthetic Sticky Note Calculator (Tooler.html inspired)
                SliverToBoxAdapter(
                  child: NotebookStickyCalculator(theme: widget.theme),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Sticky Notes Section Guideline
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Text(
                          "STUDY DESK NOTES",
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: widget.theme.text.withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1.0,
                            color: widget.theme.border.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Flat Pastel Sticky Notes Grid (Zero Shadows, Drawn Ink Icons)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.98, // Square Post-it proportion
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = _stickyTools[index];
                        return MinimalStickyNote(
                          title: tool['title'] as String,
                          subtitle: tool['subtitle'] as String,
                          iconWidget: tool['iconWidget'] as Widget,
                          noteColor: tool['noteColor'] as Color,
                          borderColor: tool['borderColor'] as Color,
                          textColor: tool['textColor'] as Color,
                          rotationAngle: tool['angle'] as double,
                          onTap: () => _openTool(tool),
                        );
                      },
                      childCount: _stickyTools.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
