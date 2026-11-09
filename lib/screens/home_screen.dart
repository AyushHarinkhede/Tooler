import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/pencil_calculator_bar.dart';
import '../widgets_3d/sticky_note_card.dart';
import '../widgets_3d/stationery_3d_icons.dart';
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
    // 13 tools with authentic 3D Vector Icons (Zero Emojis)
    _stickyTools = [
      {
        'title': 'Age Calculator',
        'subtitle': 'Birthdays & milestones',
        'iconWidget': const Icon3DCalendarMilestone(size: 26),
        'noteColor': const Color(0xFFFEF08A), // Canary Yellow
        'borderColor': const Color(0xFFEAB308),
        'textColor': const Color(0xFF713F12),
        'angle': -0.024, // ~ -1.4°
        'builder': (context) => AgeCalculatorScreen(theme: widget.theme),
      },
      {
        'title': 'Converters',
        'subtitle': 'Length, Mass, Speed, Data',
        'iconWidget': const Icon3DRulerScissors(size: 26),
        'noteColor': const Color(0xFFA7F3D0), // Fresh Mint
        'borderColor': const Color(0xFF10B981),
        'textColor': const Color(0xFF064E3B),
        'angle': 0.022, // ~ +1.3°
        'builder': (context) => ConvertersScreen(theme: widget.theme),
      },
      {
        'title': 'Stopwatch',
        'subtitle': 'Precision laps & splits',
        'iconWidget': const Icon3DStopwatch(size: 26),
        'noteColor': const Color(0xFFFBCFE8), // Bubblegum Pink
        'borderColor': const Color(0xFFF43F5E),
        'textColor': const Color(0xFF831843),
        'angle': -0.018,
        'builder': (context) => StopwatchScreen(theme: widget.theme),
      },
      {
        'title': 'Timer',
        'subtitle': 'Countdown arc presets',
        'iconWidget': const Icon3DHourglass(size: 26),
        'noteColor': const Color(0xFFBAE6FD), // Sky Blue
        'borderColor': const Color(0xFF0EA5E9),
        'textColor': const Color(0xFF0C4A6E),
        'angle': 0.020,
        'builder': (context) => TimerScreen(theme: widget.theme),
      },
      {
        'title': 'Sizer Tools',
        'subtitle': 'Ring, Bangle, Strap & Ruler',
        'iconWidget': const Icon3DCaliperRing(size: 26),
        'noteColor': const Color(0xFFFED7AA), // Pastel Peach
        'borderColor': const Color(0xFFF97316),
        'textColor': const Color(0xFF7C2D12),
        'angle': -0.022,
        'builder': (context) => SizerScreen(theme: widget.theme),
      },
      {
        'title': 'Custom Counters',
        'subtitle': 'Tally habits & goals',
        'iconWidget': const Icon3DTallyCounter(size: 26),
        'noteColor': const Color(0xFFDDD6FE), // Soft Lavender
        'borderColor': const Color(0xFF8B5CF6),
        'textColor': const Color(0xFF4C1D95),
        'angle': 0.016,
        'builder': (context) => CountersScreen(theme: widget.theme),
      },
      {
        'title': 'Task Manager',
        'subtitle': 'Homework & study to-dos',
        'iconWidget': const Icon3DClipboard(size: 26),
        'noteColor': const Color(0xFFBBF7D0), // Pale Lime
        'borderColor': const Color(0xFF22C55E),
        'textColor': const Color(0xFF14532D),
        'angle': -0.020,
        'builder': (context) => TasksScreen(theme: widget.theme),
      },
      {
        'title': 'Currency',
        'subtitle': '15+ global exchange rates',
        'iconWidget': const Icon3DGoldCoins(size: 26),
        'noteColor': const Color(0xFFC7D2FE), // Periwinkle Blue
        'borderColor': const Color(0xFF6366F1),
        'textColor': const Color(0xFF312E81),
        'angle': 0.024,
        'builder': (context) => CurrencyScreen(theme: widget.theme),
      },
      {
        'title': 'Games Arcade',
        'subtitle': 'Tic-Tac-Toe, Snake, 3D Dice',
        'iconWidget': const Icon3DDiceArcade(size: 26),
        'noteColor': const Color(0xFFFECDD3), // Soft Rose
        'borderColor': const Color(0xFFFB7185),
        'textColor': const Color(0xFF881337),
        'angle': -0.015,
        'builder': (context) => GamesScreen(theme: widget.theme),
      },
      {
        'title': 'Web Browser',
        'subtitle': 'Fast links & research',
        'iconWidget': const Icon3DGlobe(size: 26),
        'noteColor': const Color(0xFFE0E7FF), // Ice Indigo
        'borderColor': const Color(0xFF4F46E5),
        'textColor': const Color(0xFF1E1B4B),
        'angle': 0.018,
        'builder': (context) => BrowserScreen(theme: widget.theme),
      },
      {
        'title': 'Digital Compass',
        'subtitle': '3D Rose needle & level',
        'iconWidget': const Icon3DCompass(size: 26),
        'noteColor': const Color(0xFFFEF3C7), // Warm Amber
        'borderColor': const Color(0xFFD97706),
        'textColor': const Color(0xFF78350F),
        'angle': -0.022,
        'builder': (context) => CompassScreen(theme: widget.theme),
      },
      {
        'title': 'Password Gen',
        'subtitle': 'Secure tokens & strength',
        'iconWidget': const Icon3DPadlock(size: 26),
        'noteColor': const Color(0xFFE2E8F0), // Cool Slate
        'borderColor': const Color(0xFF64748B),
        'textColor': const Color(0xFF1E293B),
        'angle': 0.019,
        'builder': (context) => PasswordGeneratorScreen(theme: widget.theme),
      },
      {
        'title': 'Settings',
        'subtitle': 'Themes, sounds & modes',
        'iconWidget': const Icon3DGears(size: 26),
        'noteColor': const Color(0xFFF3E8FF), // Pastel Violet
        'borderColor': const Color(0xFFA855F7),
        'textColor': const Color(0xFF581C87),
        'angle': -0.017,
        'builder': (context) => SettingsScreen(
          theme: widget.theme,
          onThemeChanged: widget.onThemeChanged,
        ),
      },
    ];
  }

  void _openTool(Map<String, dynamic> tool) {
    SoundService().playClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: tool['builder']),
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
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Stack(
        children: [
          // 1. Notebook Paper Background with blue rules & red margin
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),

          // 2. Main Scrollable Desk
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Clean Minimal Top Header (No clunky banners)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tooler",
                              style: GoogleFonts.architectsDaughter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.text,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d').format(now),
                              style: GoogleFonts.kalam(
                                fontSize: 13,
                                color: widget.theme.text.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),

                        // Quick Theme Toggle Pill
                        InkWell(
                          onTap: _cycleTheme,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.theme.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.theme.border,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.theme.border.withValues(alpha: 0.25),
                                  offset: const Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.theme.mode == StationeryThemeMode.classicDoodle
                                        ? const Color(0xFFF59E0B)
                                        : widget.theme.mode == StationeryThemeMode.blueprintChalkboard
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF22C55E),
                                  ),
                                ),
                                Text(
                                  widget.theme.mode == StationeryThemeMode.classicDoodle
                                      ? "Classic Desk"
                                      : widget.theme.mode ==
                                              StationeryThemeMode.blueprintChalkboard
                                          ? "Blueprint"
                                          : "Neon Glow",
                                  style: GoogleFonts.kalam(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive Expandable Pencil Calculator Bar
                SliverToBoxAdapter(
                  child: PencilCalculatorBar(theme: widget.theme),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Sticky Notes Section Label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Text(
                          "STUDY DESK NOTES",
                          style: GoogleFonts.architectsDaughter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text.withValues(alpha: 0.5),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1.5,
                            color: widget.theme.border.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // Sticky Notes Grid for All Tools
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.98, // Square sticky note proportion
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = _stickyTools[index];
                        return StickyNoteCard(
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
