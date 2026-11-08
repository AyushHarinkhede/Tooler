import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/minimal_2d_illustrations.dart';
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

/// ---------------------------------------------------------------------------
/// REDESIGNED AESTHETIC MINIMAL TOOLER HOME
/// Directly matching the reference UI design (Images 1 & 2):
/// - Clean Pure White (#FFFFFF) & Soft Slate (#FAFAFC) palette
/// - Pastel Lilac / Lavender accents (#EDE9FE / #A855F7 / #F5F3FF)
/// - Modern 2D Vector Line Art Illustrations with Lavender Accent Bubbles
/// - Custom Tooler Brand Logo (Zero Emojis, 100% Vector Geometry)
/// - Hero "What are you looking for?" Card with 2D Desk Illustration & Search
/// - 2x2 Quick Access Grid + Horizontal Category Filter Chips
/// - Sleek Tool Cards with Clean 1.2px Borders & Zero Childish Textures
/// - Modern Docked Bottom Navigation Bar
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _selectedNavIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late final List<Map<String, dynamic>> _tools;

  final List<String> _categories = [
    'All',
    'Calculate',
    'Convert',
    'Time & Tasks',
    'Utilities',
  ];

  @override
  void initState() {
    super.initState();
    _initTools();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initTools() {
    _tools = [
      {
        'id': 'calc',
        'title': 'Calculator',
        'subtitle': 'Normal & scientific math functions',
        'category': 'Calculate',
        'tag': 'Precision',
        'iconType': 'calc',
        'isFeatured': true,
        'builder': (context) => CalculatorScreen(theme: widget.theme),
      },
      {
        'id': 'converters',
        'title': 'Unit Converters',
        'subtitle': 'Length, Mass, Speed, Data, Temp',
        'category': 'Convert',
        'tag': 'Multi-unit',
        'iconType': 'converters',
        'isFeatured': true,
        'builder': (context) => ConvertersScreen(theme: widget.theme),
      },
      {
        'id': 'compass',
        'title': 'Digital Compass',
        'subtitle': 'Real-time gyro & spirit level sensor',
        'category': 'Utilities',
        'tag': 'Live Sensor',
        'iconType': 'compass',
        'isFeatured': true,
        'builder': (context) => CompassScreen(theme: widget.theme),
      },
      {
        'id': 'age',
        'title': 'Age Calculator',
        'subtitle': 'Birthdays, age breakdown & milestones',
        'category': 'Calculate',
        'tag': 'Date Math',
        'iconType': 'age',
        'isFeatured': false,
        'builder': (context) => AgeCalculatorScreen(theme: widget.theme),
      },
      {
        'id': 'stopwatch',
        'title': 'Stopwatch',
        'subtitle': 'Split laps, millisecond timer',
        'category': 'Time & Tasks',
        'tag': 'Accurate',
        'iconType': 'stopwatch',
        'isFeatured': false,
        'builder': (context) => StopwatchScreen(theme: widget.theme),
      },
      {
        'id': 'timer',
        'title': 'Timer',
        'subtitle': 'Preset countdowns & circular progress',
        'category': 'Time & Tasks',
        'tag': 'Background',
        'iconType': 'timer',
        'isFeatured': false,
        'builder': (context) => TimerScreen(theme: widget.theme),
      },
      {
        'id': 'sizer',
        'title': 'Sizer & Caliper',
        'subtitle': 'Screen measurement ruler with mm/inch',
        'category': 'Convert',
        'tag': 'Screen Scale',
        'iconType': 'sizer',
        'isFeatured': false,
        'builder': (context) => SizerScreen(theme: widget.theme),
      },
      {
        'id': 'counters',
        'title': 'Tally Counters',
        'subtitle': 'Multi-counter tracking with step counts',
        'category': 'Calculate',
        'tag': 'Persistent',
        'iconType': 'counters',
        'isFeatured': false,
        'builder': (context) => CountersScreen(theme: widget.theme),
      },
      {
        'id': 'tasks',
        'title': 'Tasks & Notes',
        'subtitle': 'Clean checklist & quick daily memo',
        'category': 'Time & Tasks',
        'tag': 'Checklist',
        'iconType': 'tasks',
        'isFeatured': false,
        'builder': (context) => TasksScreen(theme: widget.theme),
      },
      {
        'id': 'currency',
        'title': 'Currency Converter',
        'subtitle': 'Global forex exchange rate estimator',
        'category': 'Convert',
        'tag': 'Forex',
        'iconType': 'currency',
        'isFeatured': false,
        'builder': (context) => CurrencyScreen(theme: widget.theme),
      },
      {
        'id': 'password',
        'title': 'Password Generator',
        'subtitle': 'Cryptographic entropy & custom rules',
        'category': 'Utilities',
        'tag': 'Security',
        'iconType': 'password',
        'isFeatured': false,
        'builder': (context) => PasswordGeneratorScreen(theme: widget.theme),
      },
      {
        'id': 'browser',
        'title': 'Mini Browser',
        'subtitle': 'Lightweight web search & quick reference',
        'category': 'Utilities',
        'tag': 'Web Utility',
        'iconType': 'browser',
        'isFeatured': false,
        'builder': (context) => BrowserScreen(theme: widget.theme),
      },
      {
        'id': 'games',
        'title': 'Focus Mini Games',
        'subtitle': 'Tic-Tac-Toe & reflex training',
        'category': 'Utilities',
        'tag': 'Offline Play',
        'iconType': 'games',
        'isFeatured': false,
        'builder': (context) => GamesScreen(theme: widget.theme),
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredTools {
    return _tools.where((tool) {
      final matchesCategory = _selectedCategory == 'All' || tool['category'] == _selectedCategory;
      if (_searchQuery.isEmpty) return matchesCategory;

      final title = (tool['title'] as String).toLowerCase();
      final subtitle = (tool['subtitle'] as String).toLowerCase();
      final tag = (tool['tag'] as String).toLowerCase();
      final matchesSearch = title.contains(_searchQuery) ||
          subtitle.contains(_searchQuery) ||
          tag.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openTool(WidgetBuilder builder) {
    SoundService().playTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: builder),
    );
  }

  void _toggleTheme() {
    SoundService().playTap();
    final nextMode = widget.theme.mode == StationeryThemeMode.classicDoodle
        ? StationeryThemeMode.blueprintChalkboard
        : StationeryThemeMode.classicDoodle;
    widget.onThemeChanged(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.mode == StationeryThemeMode.blueprintChalkboard;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Bar with Tooler Logo
            _buildTopBar(isDark),

            // 2. Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Hero Banner Card ("What are you looking for?")
                    _buildHeroBanner(isDark),

                    const SizedBox(height: 22),

                    // B. Categories Header & Filter Chips
                    _buildCategoriesSection(isDark),

                    const SizedBox(height: 20),

                    // C. 2x2 Quick Grid (shown when category is 'All' and not searching)
                    if (_selectedCategory == 'All' && _searchQuery.isEmpty) ...[
                      _buildQuick2x2Grid(isDark),
                      const SizedBox(height: 24),
                    ],

                    // D. Recommendations / Filtered Tools List
                    _buildRecommendationsHeader(isDark),

                    const SizedBox(height: 14),

                    // E. List of Tool Cards
                    _buildToolsList(isDark),

                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  /// -------------------------------------------------------------------------
  /// 1. Top Bar: Custom 2D Logo + Tooler Name + Theme/Settings Button
  /// -------------------------------------------------------------------------
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.theme.bg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const ToolerLogo(size: 38),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tooler',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: widget.theme.text,
                    ),
                  ),
                  Text(
                    'Smart Utility Kit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Theme Toggle Circular Outline Button
              InkWell(
                onTap: _toggleTheme,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.theme.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.theme.border, width: 1.2),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 19,
                    color: widget.theme.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Settings Shortcut Circular Button
              InkWell(
                onTap: () {
                  SoundService().playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        theme: widget.theme,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.theme.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.theme.border, width: 1.2),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: widget.theme.text,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 2. Hero Banner Card ("What are you looking for?" + 2D Illustration + Search)
  /// -------------------------------------------------------------------------
  Widget _buildHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.lavenderCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFEDE9FE),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you\nlooking for?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.5,
                        color: widget.theme.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All smart utilities in one place',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 2D Desk & Person Illustration (from Image 1!)
              const Minimal2DHeroDesk(width: 110, height: 85),
            ],
          ),
          const SizedBox(height: 16),
          // Clean White Pill Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: widget.theme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.theme.border, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: widget.theme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.text,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search tools (e.g. calc, units, timer)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: widget.theme.textSecondary.withValues(alpha: 0.7),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: widget.theme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 3. Categories Section & Filter Chips
  /// -------------------------------------------------------------------------
  Widget _buildCategoriesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: widget.theme.text,
              ),
            ),
            Text(
              '13 Utilities',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    SoundService().playTap();
                    setState(() => _selectedCategory = cat);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFEDE9FE))
                          : widget.theme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? widget.theme.primary : widget.theme.border,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF7C3AED))
                            : widget.theme.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// 4. 2x2 Quick Grid (directly inspired by Image 2's 2x2 category block)
  /// -------------------------------------------------------------------------
  Widget _buildQuick2x2Grid(bool isDark) {
    final calcTool = _tools.firstWhere((t) => t['id'] == 'calc');
    final convTool = _tools.firstWhere((t) => t['id'] == 'converters');
    final compTool = _tools.firstWhere((t) => t['id'] == 'compass');

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 12) / 2;
        return Column(
          children: [
            Row(
              children: [
                _buildQuickCard(calcTool, cardW, isDark),
                const SizedBox(width: 12),
                _buildQuickCard(convTool, cardW, isDark),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickCard(compTool, cardW, isDark),
                const SizedBox(width: 12),
                // 4th Card: Filled Lilac "All Tools" card (like Image 2!)
                InkWell(
                  onTap: () {
                    SoundService().playTap();
                    _scrollController.animateTo(
                      400,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: cardW,
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFDDD6FE),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.theme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Explore',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: widget.theme.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: widget.theme.primary,
                            ),
                          ],
                        ),
                        Text(
                          'All Tools',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickCard(Map<String, dynamic> tool, double width, bool isDark) {
    return InkWell(
      onTap: () => _openTool(tool['builder']),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.theme.border, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Minimal2DIcon(
              type: tool['iconType'],
              size: 44,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tool['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool['tag'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.theme.primary,
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

  /// -------------------------------------------------------------------------
  /// 5. Recommendations Header
  /// -------------------------------------------------------------------------
  Widget _buildRecommendationsHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _searchQuery.isNotEmpty
              ? 'Search Results'
              : (_selectedCategory == 'All' ? 'Recommendations' : '$_selectedCategory Tools'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: widget.theme.text,
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Text(
            '${_filteredTools.length} found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.theme.primary,
            ),
          )
        else
          InkWell(
            onTap: () {
              setState(() => _selectedCategory = 'All');
            },
            child: Text(
              'See all',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.theme.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// 6. List of Clean Modern Tool Cards (matching Image 1 & 2)
  /// -------------------------------------------------------------------------
  Widget _buildToolsList(bool isDark) {
    final list = _filteredTools;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Minimal2DIcon(type: 'settings', size: 54, color: widget.theme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No utility tools found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.theme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: list.map((tool) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.theme.border, width: 1.2),
          ),
          child: InkWell(
            onTap: () => _openTool(tool['builder']),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // 2D Line Illustration with Lavender Accent Bubble
                  Minimal2DIcon(
                    type: tool['iconType'],
                    size: 46,
                  ),
                  const SizedBox(width: 14),
                  // Tool Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tool['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.theme.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tag Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3F3F46)
                                      : const Color(0xFFEDE9FE),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tool['tag'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.theme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool['subtitle'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Circular outline arrow button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.theme.border, width: 1.2),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// -------------------------------------------------------------------------
  /// 7. Docked Bottom Navigation Bar (identical to Image 1 & 2)
  /// -------------------------------------------------------------------------
  Widget _buildBottomNav(bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        border: Border(
          top: BorderSide(color: widget.theme.border, width: 1.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded),
          _buildNavItem(1, Icons.search_rounded, Icons.search_rounded),
          _buildNavItem(2, Icons.grid_view_outlined, Icons.grid_view_rounded),
          _buildNavItem(3, Icons.tune_rounded, Icons.tune_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        SoundService().playTap();
        setState(() => _selectedNavIndex = index);

        if (index == 0) {
          _searchController.clear();
          setState(() => _selectedCategory = 'All');
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else if (index == 1) {
          _searchFocusNode.requestFocus();
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else if (index == 2) {
          setState(() => _selectedCategory = 'All');
          _scrollController.animateTo(
            220,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsScreen(
                theme: widget.theme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: isSelected
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.theme.lavenderCard,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconFilled,
                  size: 22,
                  color: widget.theme.primary,
                ),
              )
            : Icon(
                iconOutlined,
                size: 22,
                color: widget.theme.textSecondary,
              ),
      ),
    );
  }
}
