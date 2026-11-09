import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/stationery_3d_box.dart';
import 'calculator_screen.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  late final List<Map<String, dynamic>> _tools;

  @override
  void initState() {
    super.initState();
    _tools = [
      {
        'key': 'calc',
        'title': 'Calculator',
        'subtitle': 'Normal & Scientific with tape',
        'icon': '📐',
        'color': const Color(0xFFFF6B6B),
        'builder': (context) => CalculatorScreen(theme: widget.theme),
      },
      {
        'key': 'ageCalc',
        'title': 'Age Calculator',
        'subtitle': 'Birthdays & life milestones',
        'icon': '🎂',
        'color': const Color(0xFFF9D423),
        'builder': (context) => AgeCalculatorScreen(theme: widget.theme),
      },
      {
        'key': 'converters',
        'title': 'Converters',
        'subtitle': 'Length, Mass, Temp, Speed, Data',
        'icon': '📏',
        'color': const Color(0xFF4ECDC4),
        'builder': (context) => ConvertersScreen(theme: widget.theme),
      },
      {
        'key': 'stopwatch',
        'title': 'Stopwatch',
        'subtitle': 'Millisecond precision & laps',
        'icon': '⏱️',
        'color': const Color(0xFFFF85A2),
        'builder': (context) => StopwatchScreen(theme: widget.theme),
      },
      {
        'key': 'timer',
        'title': 'Timer',
        'subtitle': 'Countdown arc with presets',
        'icon': '⏳',
        'color': const Color(0xFF00D4FF),
        'builder': (context) => TimerScreen(theme: widget.theme),
      },
      {
        'key': 'sizer',
        'title': 'Sizer Tools',
        'subtitle': 'Ring, Bangle, Strap & Ruler',
        'icon': '💍',
        'color': const Color(0xFFD2A679),
        'builder': (context) => SizerScreen(theme: widget.theme),
      },
      {
        'key': 'counters',
        'title': 'Custom Counters',
        'subtitle': 'Tally goals & habits',
        'icon': '🔢',
        'color': const Color(0xFFFFA502),
        'builder': (context) => CountersScreen(theme: widget.theme),
      },
      {
        'key': 'tasks',
        'title': 'Task Manager',
        'subtitle': 'Homework & study to-dos',
        'icon': '📝',
        'color': const Color(0xFF2ED573),
        'builder': (context) => TasksScreen(theme: widget.theme),
      },
      {
        'key': 'currency',
        'title': 'Currency',
        'subtitle': '15+ global exchange rates',
        'icon': '💱',
        'color': const Color(0xFF1E90FF),
        'builder': (context) => CurrencyScreen(theme: widget.theme),
      },
      {
        'key': 'games',
        'title': 'Games Arcade',
        'subtitle': 'Tic-Tac-Toe, Snake, 3D Dice',
        'icon': '🎮',
        'color': const Color(0xFFFF4757),
        'builder': (context) => GamesScreen(theme: widget.theme),
      },
      {
        'key': 'browser',
        'title': 'Web Browser',
        'subtitle': 'Research & educational links',
        'icon': '🌐',
        'color': const Color(0xFF3742FA),
        'builder': (context) => BrowserScreen(theme: widget.theme),
      },
      {
        'key': 'compass',
        'title': 'Digital Compass',
        'subtitle': '3D Rose needle & tilt level',
        'icon': '🧭',
        'color': const Color(0xFFE84118),
        'builder': (context) => CompassScreen(theme: widget.theme),
      },
      {
        'key': 'passGen',
        'title': 'Password Gen',
        'subtitle': 'Custom length & strength meter',
        'icon': '🔐',
        'color': const Color(0xFF57606F),
        'builder': (context) => PasswordGeneratorScreen(theme: widget.theme),
      },
      {
        'key': 'settings',
        'title': 'Settings',
        'subtitle': 'Themes, Sound & Preferences',
        'icon': '⚙️',
        'color': const Color(0xFF747D8C),
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

  void _openToolByKey(String key) {
    final tool = _tools.firstWhere(
      (t) => t['key'] == key,
      orElse: () => _tools.first,
    );
    _openTool(tool);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning ☀️";
    if (hour < 17) return "Good Afternoon 🌤️";
    return "Good Evening 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final filteredTools = _tools.where((t) {
      final title = (t['title'] as String).toLowerCase();
      final sub = (t['subtitle'] as String).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || sub.contains(q);
    }).toList();

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TOOLER ✂️📏",
                              style: widget.theme.fontDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.primary,
                              ),
                            ),
                            Text(
                              "${_getGreeting()} • ${DateFormat('EEEE, MMM d').format(now)}",
                              style: widget.theme.fontDoodle(
                                fontSize: 13,
                                color: widget.theme.text.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, color: widget.theme.text, size: 26),
                          tooltip: "Settings",
                          onPressed: () => _openToolByKey('settings'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive 3D School Geometry Box
                SliverToBoxAdapter(
                  child: Stationery3DPencilBox(
                    theme: widget.theme,
                    onToolSelected: _openToolByKey,
                  ),
                ),

                // Mascot Card with Shinchan.png
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: widget.theme.doodleCard(
                      color: widget.theme.cardBg,
                      borderWidth: 2.0,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/shinchan.png',
                            height: 60,
                            width: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 40),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Study Buddy Shinchan Says:",
                                style: widget.theme.fontMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Sharpen your pencils and check your homework tasks! All tools are ready! ✏️",
                                style: widget.theme.fontDoodle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: widget.theme.doodleCard(borderWidth: 2.0),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: widget.theme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: widget.theme.fontDoodle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: "Search any stationery tool (calculator, timer...)",
                                hintStyle: widget.theme.fontDoodle(
                                  fontSize: 13,
                                  color: widget.theme.text.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Tools Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = filteredTools[index];
                        return _buildToolCard(tool);
                      },
                      childCount: filteredTools.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return InkWell(
      onTap: () => _openTool(tool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: widget.theme.doodleCard(
          color: widget.theme.cardBg,
          borderWidth: 2.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (tool['color'] as Color).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tool['icon'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: widget.theme.text.withOpacity(0.4),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool['title'] as String,
                  style: widget.theme.fontDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tool['subtitle'] as String,
                  style: widget.theme.fontDoodle(
                    fontSize: 11,
                    color: widget.theme.text.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
