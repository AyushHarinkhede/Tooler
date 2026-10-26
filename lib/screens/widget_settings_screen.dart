import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../models/counter_model.dart';
import '../models/task_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../services/pedometer_sensor_service.dart';
import '../widgets_3d/minimal_2d_illustrations.dart';
import '../widgets_3d/bouncy_tap.dart';
import 'tasks_screen.dart';

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
  String _selectedRatio = '4x1'; // '4x1', 'tasks', 'steps', '2x2', or '1x1'
  String _colorMode = 'app';     // 'app' or 'system'
  String _favToolId = 'calc';
  WidgetSystemColors? _systemColors;
  bool _isPinning = false;

  int? _counterId;
  String _counterName = 'Tally Counter';
  int _counterValue = 0;
  int _counterStep = 1;
  List<CounterItem> _userCounters = [];
  List<TaskItem> _userTasks = [];

  int _todaySteps = 0;
  double _stepDistanceKm = 0.0;
  double _stepAvgSpeed = 4.5;
  int _stepCalories = 0;

  static const List<Map<String, String>> _allSections = [
    {'id': 'calc', 'title': 'Calculator', 'iconType': 'calc'},
    {'id': 'calendar', 'title': 'Calendar', 'iconType': 'calendar'},
    {'id': 'weather', 'title': 'Weather', 'iconType': 'weather'},
    {'id': 'games', 'title': 'Games', 'iconType': 'games'},
    {'id': 'steps', 'title': 'Step Counter', 'iconType': 'steps'},
    {'id': 'recorder', 'title': 'Noise & Rec', 'iconType': 'recorder'},
    {'id': 'radio', 'title': 'FM Radio', 'iconType': 'radio'},
    {'id': 'power', 'title': 'Power', 'iconType': 'power'},
    {'id': 'speed_test', 'title': 'Speed Test', 'iconType': 'speed_test'},
    {'id': 'compass', 'title': 'Compass', 'iconType': 'compass'},
    {'id': 'converters', 'title': 'Converters', 'iconType': 'converters'},
    {'id': 'currency', 'title': 'Currency', 'iconType': 'currency'},
    {'id': 'tasks', 'title': 'Tasks & Notes', 'iconType': 'tasks'},
    {'id': 'alarm', 'title': 'Alarm', 'iconType': 'alarm'},
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
    final counters = await StorageService().loadCounters();
    final tasks = await StorageService().loadTasks();
    final sys = await WidgetService().getSystemColors(widget.theme);
    final pedometer = PedometerSensorService();
    if (mounted) {
      setState(() {
        _selectedRatio = WidgetService().selectedRatio;
        _colorMode = WidgetService().colorMode;
        _favToolId = WidgetService().favToolId;
        _systemColors = sys;
        _userCounters = counters;
        _userTasks = tasks;
        _todaySteps = pedometer.todaySteps;
        _stepDistanceKm = pedometer.distanceKm;
        _stepAvgSpeed = pedometer.avgSpeedKmh;
        _stepCalories = pedometer.caloriesKcal;
        if (counters.isNotEmpty) {
          final active = counters.firstWhere(
            (c) => c.id == WidgetService().counterId,
            orElse: () => counters.first,
          );
          _counterId = active.id;
          _counterName = active.name;
          _counterValue = active.value;
          _counterStep = active.step;
        } else {
          _counterId = 0;
          _counterName = 'Tally Counter';
          _counterValue = 0;
          _counterStep = 1;
        }
      });
    }
  }

  void _togglePreviewTask(int id) async {
    SoundService().playTaskComplete();
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _userTasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _userTasks[idx].completed = !_userTasks[idx].completed;
      }
    });
    await StorageService().saveTasks(_userTasks);
    await WidgetService().syncToNative(widget.theme);
  }

  void _addNewTaskFromPreview() {
    SoundService().playClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasksScreen(theme: widget.theme, autoOpenComposer: true),
      ),
    ).then((_) {
      _loadInitial();
    });
  }

  void _updatePreviewCounter(int delta) {
    SoundService().playKey();
    HapticFeedback.lightImpact();
    setState(() {
      _counterValue += delta;
      if (_counterValue < 0) _counterValue = 0;
      if (_counterId != null && _counterId != 0) {
        final idx = _userCounters.indexWhere((c) => c.id == _counterId);
        if (idx != -1) {
          _userCounters[idx].value = _counterValue;
          StorageService().saveCounters(_userCounters);
        }
      }
    });
    WidgetService().syncCounterToNative(
      id: _counterId ?? 0,
      name: _counterName,
      value: _counterValue,
      step: _counterStep,
      theme: widget.theme,
    );
  }

  void _selectLinkedCounter(CounterItem item) {
    SoundService().playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _counterId = item.id;
      _counterName = item.name;
      _counterValue = item.value;
      _counterStep = item.step;
    });
    WidgetService().syncCounterToNative(
      id: item.id,
      name: item.name,
      value: item.value,
      step: item.step,
      theme: widget.theme,
    );
  }

  void _createQuickCounter() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'New Tally Counter',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: widget.theme.text),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: widget.theme.text),
          decoration: InputDecoration(
            hintText: 'Counter Name (e.g. Daily Habits)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = ctrl.text.trim();
              Navigator.pop(ctx);
              if (name.isNotEmpty) {
                SoundService().playClick();
                final newItem = CounterItem(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  value: 0,
                  step: 1,
                );
                final updatedList = [..._userCounters, newItem];
                await StorageService().saveCounters(updatedList);
                if (mounted) {
                  setState(() {
                    _userCounters = updatedList;
                    _counterId = newItem.id;
                    _counterName = newItem.name;
                    _counterValue = newItem.value;
                    _counterStep = newItem.step;
                  });
                }
                WidgetService().syncCounterToNative(
                  id: newItem.id,
                  name: newItem.name,
                  value: newItem.value,
                  step: newItem.step,
                  theme: widget.theme,
                );
              }
            },
            child: const Text('Add & Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                    : (_selectedRatio == 'tasks'
                        ? 'Tap "Add" to place Resizable Tasks Widget on Home Screen!'
                        : (_selectedRatio == 'steps'
                            ? 'Tap "Add" to place Tooler 3×2 Step Counter on Home Screen!'
                            : (_selectedRatio == '2x2'
                                ? 'Tap "Add" to place Tooler 2×2 Tally Counter on Home Screen!'
                                : 'Tap "Add" to place your 1×1 Icon Shortcut on Home Screen!'))))
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
    final Color previewInk = useSystem ? _systemColors!.ink : theme.text;
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
                          _selectedRatio == '4x1'
                              ? '4 × 1 Bar'
                              : (_selectedRatio == 'tasks'
                                  ? 'Tasks & Notes'
                                  : (_selectedRatio == 'steps'
                                      ? 'Steps 3×2'
                                      : (_selectedRatio == '2x2' ? 'Tally 2×2' : '1 × 1 Icon'))),
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

                  // Render 4x1, tasks, steps, 2x2, or 1x1 Widget Preview
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
                  else if (_selectedRatio == 'tasks')
                    _buildPreviewTasksWidget(
                      previewCardBg: previewCardBg,
                      previewBorder: previewBorder,
                      previewBubble: previewBubble,
                      previewPrimary: previewPrimary,
                      previewInk: previewInk,
                      previewIsDark: previewIsDark,
                    )
                  else if (_selectedRatio == 'steps')
                    Container(
                      width: 250,
                      height: 165,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: previewCardBg,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: previewBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: previewIsDark ? 0.35 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header: Shoes icon + STEPS + TODAY badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: previewBubble,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.directions_walk_rounded, size: 16, color: previewPrimary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'STEPS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: previewPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: previewPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TODAY',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: previewPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Main Prominent Step Count
                          Center(
                            child: Text(
                              _todaySteps > 0 ? '$_todaySteps' : '6,420',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: previewPrimary,
                              ),
                            ),
                          ),

                          // Trio metrics: Distance, Speed, Calories with icons
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                            decoration: BoxDecoration(
                              color: previewBubble.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Distance
                                Expanded(
                                  child: Column(
                                    children: [
                                      Icon(Icons.straighten_rounded, size: 13, color: previewPrimary),
                                      const SizedBox(height: 2),
                                      Text(
                                        _stepDistanceKm > 0 ? '${_stepDistanceKm.toStringAsFixed(1)} km' : '4.8 km',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: theme.text,
                                        ),
                                      ),
                                      Text('Distance', style: TextStyle(fontSize: 7.5, color: theme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 22, color: previewBorder),
                                // Speed
                                Expanded(
                                  child: Column(
                                    children: [
                                      Icon(Icons.speed_rounded, size: 13, color: previewPrimary),
                                      const SizedBox(height: 2),
                                      Text(
                                        _stepAvgSpeed > 0 ? '${_stepAvgSpeed.toStringAsFixed(1)} km/h' : '4.5 km/h',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: theme.text,
                                        ),
                                      ),
                                      Text('Avg Speed', style: TextStyle(fontSize: 7.5, color: theme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 22, color: previewBorder),
                                // Calories
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, size: 13, color: Color(0xFFF97316)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _stepCalories > 0 ? '$_stepCalories kcal' : '270 kcal',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: theme.text,
                                        ),
                                      ),
                                      Text('Calories', style: TextStyle(fontSize: 7.5, color: theme.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_selectedRatio == '2x2')
                    Container(
                      width: 172,
                      height: 172,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: previewCardBg,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: previewBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: previewIsDark ? 0.35 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header: Icon + Name + Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: previewBubble,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.exposure_plus_1_rounded, size: 15, color: previewPrimary),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _counterName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: previewPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: previewPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '2×2',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: previewPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Number count in center
                          Center(
                            child: Text(
                              '$_counterValue',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: previewPrimary,
                              ),
                            ),
                          ),

                          // Interactive - and + buttons
                          Row(
                            children: [
                              Expanded(
                                child: BouncyTap(
                                  onTap: () => _updatePreviewCounter(-_counterStep),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: previewBubble,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: previewBorder),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.remove_rounded, size: 22, color: previewPrimary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: BouncyTap(
                                  onTap: () => _updatePreviewCounter(_counterStep),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: previewPrimary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add_rounded, size: 22, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                        : (_selectedRatio == 'tasks'
                            ? 'Resizable Tasks & Notes Widget · Complete tasks & add new ones directly from Home Screen'
                            : (_selectedRatio == 'steps'
                                ? 'Step Counter · Steps, Distance, Avg Speed & Calories with live hardware telemetry'
                                : (_selectedRatio == '2x2'
                                    ? 'Interactive Tally Counter · Tap + / - directly from phone Home Screen'
                                    : 'Icon-only shortcut · Opens ${selectedSection['title']} hover page'))),
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

            // 2. Ratio Selector (4x1 vs Tasks vs Steps vs Tally vs 1x1)
            _buildSectionCard(
              title: 'Widget Ratio & Type',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceTile(
                          label: '4 × 1 Bar',
                          subtitle: 'Quick Bar',
                          icon: Icons.view_week_rounded,
                          isSelected: _selectedRatio == '4x1',
                          onTap: () => _updateConfig(ratio: '4x1'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceTile(
                          label: 'Tasks & Notes',
                          subtitle: 'Resizable List',
                          icon: Icons.checklist_rounded,
                          isSelected: _selectedRatio == 'tasks',
                          onTap: () => _updateConfig(ratio: 'tasks'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceTile(
                          label: 'Steps 3×2',
                          subtitle: 'Fitness Pedometer',
                          icon: Icons.directions_walk_rounded,
                          isSelected: _selectedRatio == 'steps',
                          onTap: () => _updateConfig(ratio: 'steps'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceTile(
                          label: 'Tally 2×2',
                          subtitle: 'Counter & Ginti',
                          icon: Icons.exposure_plus_1_rounded,
                          isSelected: _selectedRatio == '2x2',
                          onTap: () => _updateConfig(ratio: '2x2'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceTile(
                          label: '1 × 1 Icon',
                          subtitle: 'Fav Shortcut',
                          icon: Icons.crop_square_rounded,
                          isSelected: _selectedRatio == '1x1',
                          onTap: () => _updateConfig(ratio: '1x1'),
                        ),
                      ),
                    ],
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

            // 4a. Linked Tally Counter Picker (for 2x2 Widget)
            if (_selectedRatio == '2x2') ...[
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Linked Tally Counter',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userCounters.isNotEmpty) ...[
                      Text(
                        'Tap a counter to link it to your 2×2 Home Screen Widget:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _userCounters.map((item) {
                          final isSel = item.id == _counterId;
                          return InkWell(
                            onTap: () => _selectLinkedCounter(item),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? theme.primary.withValues(alpha: 0.16) : theme.bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? theme.primary : theme.border,
                                  width: isSel ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 16,
                                    color: isSel ? theme.primary : theme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? theme.primary : theme.text,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSel ? theme.primary : theme.border,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.value}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSel ? Colors.white : theme.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      Text(
                        'No counters created yet. Create one below to link with your 2×2 widget:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(color: theme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _createQuickCounter,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create New Counter'),
                    ),
                  ],
                ),
              ),
            ],

            // 4b. Favorite Tool Picker (for 1x1 Widget)
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
                      : (_selectedRatio == 'tasks'
                          ? 'Add Tasks Widget to Home Screen'
                          : (_selectedRatio == 'steps'
                              ? 'Add 3×2 Step Counter to Home Screen'
                              : (_selectedRatio == '2x2'
                                  ? 'Add 2×2 Counter Widget to Home Screen'
                                  : 'Add 1×1 Widget to Home Screen'))),
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

  Widget _buildPreviewTasksWidget({
    required Color previewCardBg,
    required Color previewBorder,
    required Color previewBubble,
    required Color previewPrimary,
    required Color previewInk,
    required bool previewIsDark,
  }) {
    final pendingTasks = _userTasks.where((t) => !t.completed).toList();
    final visibleCount = pendingTasks.length.clamp(0, 3);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: previewCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: previewBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: previewIsDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: previewBubble,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.checklist_rounded,
                    size: 16,
                    color: previewPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TASKS & NOTES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: previewInk,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: previewPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pendingTasks.isEmpty ? 'ALL DONE' : '${pendingTasks.length} PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: previewPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BouncyTap(
                onTap: _addNewTaskFromPreview,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: previewPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: previewBorder.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 8),

          // Tasks List
          if (pendingTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 26,
                      color: previewPrimary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No pending tasks!\nTap + to create one',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: previewInk.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (int i = 0; i < visibleCount; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    BouncyTap(
                      onTap: () => _togglePreviewTask(pendingTasks[i].id),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: previewBubble,
                          shape: BoxShape.circle,
                          border: Border.all(color: previewPrimary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pendingTasks[i].text.isNotEmpty
                                ? pendingTasks[i].text
                                : pendingTasks[i].notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: previewInk,
                            ),
                          ),
                          Text(
                            pendingTasks[i].notes.isNotEmpty && pendingTasks[i].text.isNotEmpty
                                ? pendingTasks[i].notes
                                : '${pendingTasks[i].category} • ${pendingTasks[i].priority}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: previewInk.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (pendingTasks.length > 3) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '+ ${pendingTasks.length - 3} more tasks in app',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: previewPrimary,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
