import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/minimal_2d_illustrations.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
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
/// TOOLER MINIMAL HOME (Images 1 & 2 Match)
/// - Bottom Nav Bar REMOVED completely (clean edge-to-edge scroll)
/// - Full-color Pastel Header background with 2D Hanging Lamp, Curly Cord & Plant
/// - Every tool opens in a Pop-up Hover Page (ToolerHoverSheet)
/// - Modern Search Bar with instant filtering and clear action
/// - Clean 2x2 Category Grid + Filter Chips
/// - Sound and Haptic feedback on every tap
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

  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearchFocused = false;

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
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
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

  /// Opens any tool in the sleek Pop-up Hover Page (Screen 3 style)
  void _openTool(Map<String, dynamic> tool) {
    SoundService().playClick();
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    ToolerHoverSheet.show(
      context: context,
      title: tool['title'],
      subtitle: tool['subtitle'],
      tag: tool['tag'],
      theme: widget.theme,
      child: (tool['builder'] as WidgetBuilder)(context),
    ).then((_) {
      if (mounted) {
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _openSettings() {
    SoundService().playClick();
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          theme: widget.theme,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Bar with Logo & Settings Button
              _buildTopBar(isDark),

              // 2. Main Scrollable Content (No bottom nav bar!)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Hero Banner Card with 2D Artwork (Lamp & Desk)
                    _buildHeroBanner(isDark),

                    const SizedBox(height: 20),

                    // B. Categories Header & Filter Chips
                    _buildCategoriesSection(isDark),

                    const SizedBox(height: 18),

                    // C. 2x2 Quick Grid (shown when category is 'All' and not searching)
                    if (_selectedCategory == 'All' && _searchQuery.isEmpty) ...[
                      _buildQuick2x2Grid(isDark),
                      const SizedBox(height: 22),
                    ],

                    // D. Recommendations / Filtered Tools List
                    _buildRecommendationsHeader(isDark),

                    const SizedBox(height: 14),

                    // E. List of Tool Cards
                    _buildToolsList(isDark),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 1. Top Bar: Custom 2D Monogram + Brand + Settings Button
  /// -------------------------------------------------------------------------
  Widget _buildTopBar(bool isDark) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: theme.bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ToolerLogo(
            height: 36,
            color: theme.text,
            accentColor: theme.primary,
          ),

          // Settings Action Button (opens modern settings with color dots & dark mode)
          InkWell(
            onTap: _openSettings,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: theme.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: theme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 2. Hero Banner Card with 2D Artwork (Desk & Plant) + Search Bar
  /// -------------------------------------------------------------------------
  Widget _buildHeroBanner(bool isDark) {
    final theme = widget.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.lavenderCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : theme.lavenderBubble,
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
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fast & minimal smart utility kit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 2D Line Artwork (Person at desk + soft accent bubble)
              const Minimal2DHeroDesk(width: 110, height: 85),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Clean Search Bar (Image 2 style)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearchFocused ? theme.primary : theme.border,
                width: _isSearchFocused ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _isSearchFocused ? theme.primary : theme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onTapOutside: (_) {
                      _searchFocusNode.unfocus();
                    },
                    onSubmitted: (_) {
                      _searchFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search tools (e.g. calc, units, compass)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: theme.textSecondary.withValues(alpha: 0.7),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      SoundService().playClick();
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                    },
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: theme.textSecondary,
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
  /// 3. Categories Header & Filter Chips
  /// -------------------------------------------------------------------------
  Widget _buildCategoriesSection(bool isDark) {
    final theme = widget.theme;

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
                color: theme.text,
              ),
            ),
            Text(
              '13 Utilities',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.primary,
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
                    SoundService().playClick();
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    setState(() => _selectedCategory = cat);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.lavenderBubble : theme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.primary : theme.border,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? theme.primaryDark : theme.text,
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
  /// 4. 2x2 Quick Grid (Image 2 style)
  /// -------------------------------------------------------------------------
  Widget _buildQuick2x2Grid(bool isDark) {
    final theme = widget.theme;
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
                _buildQuickCard(calcTool, cardW),
                const SizedBox(width: 12),
                _buildQuickCard(convTool, cardW),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickCard(compTool, cardW),
                const SizedBox(width: 12),
                // 4th Card: Filled Lilac "All Tools" card (like Image 2!)
                InkWell(
                  onTap: () {
                    SoundService().playClick();
                    _scrollController.animateTo(
                      380,
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
                      color: theme.lavenderBubble,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.4),
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
                                color: theme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Explore',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primaryDark,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: theme.primaryDark,
                            ),
                          ],
                        ),
                        Text(
                          'All Tools',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.primaryDark,
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

  Widget _buildQuickCard(Map<String, dynamic> tool, double width) {
    final theme = widget.theme;

    return InkWell(
      onTap: () => _openTool(tool),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Minimal2DIcon(
              type: tool['iconType'],
              size: 44,
              bubbleColor: theme.lavenderBubble,
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
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool['tag'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
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
    final theme = widget.theme;

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
            color: theme.text,
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Text(
            '${_filteredTools.length} found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          )
        else
          InkWell(
            onTap: () {
              SoundService().playClick();
              setState(() => _selectedCategory = 'All');
            },
            child: Text(
              'See all',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// 6. List of Clean Modern Tool Cards (Pop-up Hover on tap!)
  /// -------------------------------------------------------------------------
  Widget _buildToolsList(bool isDark) {
    final theme = widget.theme;
    final list = _filteredTools;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Minimal2DIcon(type: 'settings', size: 54, color: theme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No utility tools found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
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
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _openTool(tool),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // 2D Line Illustration with Accent Bubble
                  Minimal2DIcon(
                    type: tool['iconType'],
                    size: 46,
                    bubbleColor: theme.lavenderBubble,
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
                                color: theme.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tag Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.lavenderCard,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tool['tag'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                          ],
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
                      border: Border.all(color: theme.border, width: 1.2),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.textSecondary,
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
}
