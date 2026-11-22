import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/pedometer_sensor_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
import 'step_route_map_screen.dart';

/// ---------------------------------------------------------------------------
/// TOOLER HARDWARE-SYNCED STEP COUNTER & PEDOMETER (COMPACT HOVER STUDIO)
/// - Device Hardware Acceleration & Step Sensor Real-Time Sync
/// - Today's Live Steps, Calculated Distance (km), Avg Speed (km/h) & Calories
/// - Minimal Clean Toggle Bar: [ 7D | 1M | 3M | 6M | 1Y ]
/// - Interactive Dynamic History Graph with peak days & daily average
/// - Dedicated Real Route Trajectory Map Hover Sheet with GPS polyline & speed
/// ---------------------------------------------------------------------------

class StepCounterScreen extends StatefulWidget {
  final StationeryTheme theme;
  const StepCounterScreen({super.key, required this.theme});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen>
    with TickerProviderStateMixin {
  final PedometerSensorService _pedometer = PedometerSensorService();
  StreamSubscription<int>? _stepSub;

  // Selected history range: '7D', '1M', '3M', '6M', '1Y'
  String _activeRange = '7D';
  int? _selectedBarIndex;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pedometer.initialize();

    _stepSub = _pedometer.stepStream.listen((_) {
      if (mounted) setState(() {});
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _openRouteMap() {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    ToolerHoverSheet.show(
      context: context,
      title: "Today's Walk Trail",
      subtitle: 'Real-time GPS trajectory & speed waypoints',
      tag: 'Trail Map',
      theme: widget.theme,
      child: StepRouteMapScreen(theme: widget.theme),
    );
  }

  void _showGoalPickerDialog() {
    SoundService().playClick();
    final theme = widget.theme;
    final goals = [5000, 8000, 10000, 12000, 15000];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: theme.border, width: 1.2),
        ),
        title: Text(
          'Set Daily Step Goal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: goals.map((g) {
            final isSel = _pedometer.dailyGoal == g;
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isSel ? theme.primary.withValues(alpha: 0.12) : null,
              title: Text(
                '${NumberFormat('#,###').format(g)} steps',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                  color: isSel ? theme.primary : theme.text,
                ),
              ),
              trailing: isSel
                  ? Icon(Icons.check_circle_rounded, color: theme.primary)
                  : null,
              onTap: () {
                SoundService().playTap();
                setState(() => _pedometer.setDailyGoal(g));
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final todaySteps = _pedometer.todaySteps;
    final goal = _pedometer.dailyGoal <= 0 ? 10000 : _pedometer.dailyGoal;
    final progress = goal > 0 ? (todaySteps / goal).clamp(0.0, 1.0) : 0.0;
    final distKm = _pedometer.distanceKm;
    final speed = _pedometer.avgSpeedKmh;
    final cals = _pedometer.caloriesKcal;
    final isWalking = _pedometer.isWalkingNow;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO COMPACT STEP DIAL + LIVE HARDWARE BEACON
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isWalking
                    ? theme.primary.withValues(alpha: 0.55)
                    : theme.border,
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isWalking ? theme.primary : Colors.black)
                      .withValues(alpha: theme.isDark ? 0.22 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Row: Hardware Sync Status + Edit Goal
                Row(
                  children: [
                    // Hardware Sync Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              return Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withValues(
                                              alpha: _pulseController.value *
                                                  0.7),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isWalking ? 'WALKING LIVE' : 'HARDWARE SYNCED',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Edit Daily Goal Chip
                    BouncyTap(
                      onTap: _showGoalPickerDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_rounded,
                                size: 12, color: theme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Goal: ${NumberFormat.compact().format(goal)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: theme.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Center Compact Dial Progress Ring & Big Step Count (Noise-Meter Style)
                SizedBox(
                  height: 175,
                  width: 175,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(175, 175),
                        painter: _StepRadialBarPainter(
                          progress: progress,
                          theme: theme,
                          isWalking: isWalking,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isWalking ? Icons.directions_walk_rounded : Icons.directions_walk_outlined,
                            size: 24,
                            color: progress >= 1.0 ? const Color(0xFF10B981) : theme.primary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat('#,###').format(todaySteps),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: theme.text,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (progress >= 1.0 ? const Color(0xFF10B981) : theme.primary).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'STEPS TODAY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: progress >= 1.0 ? const Color(0xFF10B981) : theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Goal Completion Percentage Tag
                Text(
                  '${(progress * 100).toInt()}% of daily goal · ${(goal - todaySteps) > 0 ? "${NumberFormat('#,###').format(goal - todaySteps)} steps to go" : "Goal reached! 🎉"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: progress >= 1.0
                        ? const Color(0xFF10B981)
                        : theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. TRIO METRIC CARDS (Distance · Speed · Calories)
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  icon: Icons.straighten_rounded,
                  iconColor: theme.primary,
                  title: 'DISTANCE',
                  value: '$distKm km',
                  subtitle: '${(distKm * 1000).toInt()} meters',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricCard(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'AVG SPEED',
                  value: '$speed km/h',
                  subtitle: speed > 6.0
                      ? 'Jogging Pace'
                      : (speed > 4.2 ? 'Brisk Pace' : 'Gentle Walk'),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF43F5E),
                  title: 'CALORIES',
                  value: '$cals kcal',
                  subtitle: '${(_pedometer.activeSeconds / 60).round()} min active',
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. REAL MAP TRAJECTORY ENTRY CARD
          BouncyTap(
            onTap: _openRouteMap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.map_rounded,
                        color: theme.primary, size: 20),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "OPEN TODAY'S WALK MAP",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          'View real street trajectory line & speed points',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: theme.primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 4. MINIMAL CLEAN TIME-RANGE TOGGLE BAR [ 7D | 1M | 3M | 6M | 1Y ]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border, width: 1.1),
            ),
            child: Row(
              children: ['7D', '1M', '3M', '6M', '1Y'].map((range) {
                final isSel = _activeRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      SoundService().playTap();
                      HapticFeedback.selectionClick();
                      setState(() {
                        _activeRange = range;
                        _selectedBarIndex = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? theme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          range,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight:
                                isSel ? FontWeight.w900 : FontWeight.w700,
                            color: isSel ? Colors.white : theme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 5. INTERACTIVE STEP ACTIVITY GRAPH
          _buildActivityGraph(theme),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required StationeryTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: theme.text,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. HISTORICAL ACTIVITY GRAPH (7D · 1M · 3M · 6M · 1Y)
  // ===========================================================================
  Widget _buildActivityGraph(StationeryTheme theme) {
    final history = _pedometer.historyRecords;
    List<_GraphBarData> dataPoints = [];

    final now = DateTime.now();

    if (_activeRange == '7D') {
      // 7 Days
      for (int i = 6; i >= 0; i--) {
        if (i == 0) {
          dataPoints.add(_GraphBarData(
            label: DateFormat('E').format(now),
            steps: _pedometer.todaySteps,
            date: now,
            isToday: true,
          ));
        } else {
          final targetDate = now.subtract(Duration(days: i));
          final rec = history.where((r) =>
              r.date.year == targetDate.year &&
              r.date.month == targetDate.month &&
              r.date.day == targetDate.day).firstOrNull;
          dataPoints.add(_GraphBarData(
            label: DateFormat('E').format(targetDate),
            steps: rec?.steps ?? 0,
            date: targetDate,
          ));
        }
      }
    } else if (_activeRange == '1M') {
      // 30 Days (Sampled into 15 bars for compact clarity)
      for (int i = 28; i >= 0; i -= 2) {
        final targetDate = now.subtract(Duration(days: i));
        final rec = history.where((r) =>
            r.date.year == targetDate.year &&
            r.date.month == targetDate.month &&
            r.date.day == targetDate.day).firstOrNull;
        dataPoints.add(_GraphBarData(
          label: '${targetDate.day}',
          steps: i == 0 ? _pedometer.todaySteps : (rec?.steps ?? 0),
          date: targetDate,
          isToday: i == 0,
        ));
      }
    } else if (_activeRange == '3M') {
      // 12 Weeks
      for (int w = 11; w >= 0; w--) {
        final weekStart = now.subtract(Duration(days: w * 7));
        final recs = history.where((r) =>
            r.date.isAfter(weekStart.subtract(const Duration(days: 7))) &&
            r.date.isBefore(weekStart.add(const Duration(days: 1)))).toList();
        final avgSteps = recs.isNotEmpty
            ? (recs.map((e) => e.steps).reduce((a, b) => a + b) / recs.length).round()
            : 0;
        dataPoints.add(_GraphBarData(
          label: 'W${12 - w}',
          steps: avgSteps,
          date: weekStart,
        ));
      }
    } else if (_activeRange == '6M') {
      // 6 Months
      for (int m = 5; m >= 0; m--) {
        final mDate = DateTime(now.year, now.month - m, 1);
        final recs = history.where((r) =>
            r.date.year == mDate.year && r.date.month == mDate.month).toList();
        final avgSteps = recs.isNotEmpty
            ? (recs.map((e) => e.steps).reduce((a, b) => a + b) / recs.length).round()
            : 0;
        dataPoints.add(_GraphBarData(
          label: DateFormat('MMM').format(mDate),
          steps: avgSteps,
          date: mDate,
        ));
      }
    } else {
      // 1Y (12 Months)
      for (int m = 11; m >= 0; m--) {
        final mDate = DateTime(now.year, now.month - m, 1);
        final recs = history.where((r) =>
            r.date.year == mDate.year && r.date.month == mDate.month).toList();
        final avgSteps = recs.isNotEmpty
            ? (recs.map((e) => e.steps).reduce((a, b) => a + b) / recs.length).round()
            : 0;
        dataPoints.add(_GraphBarData(
          label: DateFormat('MMM').format(mDate).substring(0, 1),
          steps: avgSteps,
          date: mDate,
        ));
      }
    }

    final maxSteps = math.max(
        _pedometer.dailyGoal,
        dataPoints.map((d) => d.steps).fold<int>(0, math.max));
    final nonZeroData = dataPoints.where((d) => d.steps > 0).toList();
    final avgSteps = nonZeroData.isNotEmpty
        ? (nonZeroData.map((d) => d.steps).reduce((a, b) => a + b) /
                nonZeroData.length)
            .round()
        : _pedometer.todaySteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Average & Selected Tooltip Readout
          Row(
            children: [
              Text(
                'ACTIVITY TREND',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _selectedBarIndex != null && _selectedBarIndex! < dataPoints.length
                    ? (dataPoints[_selectedBarIndex!].steps == 0
                        ? '${dataPoints[_selectedBarIndex!].label}: 0 steps'
                        : '${dataPoints[_selectedBarIndex!].label}: ${NumberFormat('#,###').format(dataPoints[_selectedBarIndex!].steps)} steps')
                    : (avgSteps > 0
                        ? 'Avg: ${NumberFormat('#,###').format(avgSteps)} / day'
                        : 'Tracking Live'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: theme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Graph Canvas / Bars
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(dataPoints.length, (idx) {
                final pt = dataPoints[idx];
                final safeMax = maxSteps <= 0 ? 10000 : maxSteps;
                final frac = pt.steps > 0 ? (pt.steps / safeMax).clamp(0.08, 1.0) : 0.0;
                final barHeight = pt.steps > 0 ? (74 * frac) : 3.0;
                final isSelected = _selectedBarIndex == idx;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBarIndex = idx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF43F5E)
                                  : (pt.isToday
                                      ? theme.primary
                                      : (pt.steps >= 10000
                                          ? const Color(0xFF10B981)
                                          : (pt.steps > 0
                                              ? theme.primary.withValues(alpha: 0.35)
                                              : theme.border.withValues(alpha: 0.7)))),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Label
                          Text(
                            pt.label,
                            maxLines: 1,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: isSelected || pt.isToday
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isSelected
                                  ? theme.primary
                                  : theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphBarData {
  final String label;
  final int steps;
  final DateTime date;
  final bool isToday;

  const _GraphBarData({
    required this.label,
    required this.steps,
    required this.date,
    this.isToday = false,
  });
}

/// Silky Smooth Radial Step Bar Gauge (Noise Meter Style)
class _StepRadialBarPainter extends CustomPainter {
  final double progress;
  final StationeryTheme theme;
  final bool isWalking;

  _StepRadialBarPainter({
    required this.progress,
    required this.theme,
    required this.isWalking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 16;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // 260° sweep from bottom-left (140°) to bottom-right (400°)
    const double startAngle = 140.0 * math.pi / 180.0;
    const double totalSweep = 260.0 * math.pi / 180.0;

    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double activeSweep = totalSweep * clampedProgress;

    final Color gaugeColor = progress >= 1.0
        ? const Color(0xFF10B981)
        : (isWalking ? const Color(0xFF06B6D4) : theme.primary);

    // 1. Subtle Inner Micro-Tick Scale Dots (24 precision ticks)
    const int tickCount = 24;
    for (int i = 0; i <= tickCount; i++) {
      final double frac = i / tickCount;
      final double ang = startAngle + (totalSweep * frac);
      final bool isMajor = i % 6 == 0;
      final bool isLit = frac <= clampedProgress;
      final double innerR = radius - (isMajor ? 14.5 : 12.0);
      final double outerR = radius - 9.0;
      final Paint tickPaint = Paint()
        ..color = isLit
            ? gaugeColor.withValues(alpha: isMajor ? 0.75 : 0.45)
            : theme.border.withValues(alpha: isMajor ? 0.65 : 0.35)
        ..strokeWidth = isMajor ? 2.0 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(ang), center.dy + innerR * math.sin(ang)),
        Offset(center.dx + outerR * math.cos(ang), center.dy + outerR * math.sin(ang)),
        tickPaint,
      );
    }

    // 2. Smooth Recessed Background Track Arc
    final Paint trackPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, totalSweep, false, trackPaint);

    // 3. Soft Ambient Glow Under Active Arc
    if (activeSweep > 0.01) {
      final Paint glowPaint = Paint()
        ..color = gaugeColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawArc(arcRect, startAngle, activeSweep, false, glowPaint);

      // 4. Silky SweepGradient Active Step Arc
      final Shader arcShader = SweepGradient(
        startAngle: 0.0,
        endAngle: totalSweep,
        colors: [
          theme.primary,
          Color.lerp(theme.primary, gaugeColor, 0.55)!,
          gaugeColor,
        ],
        stops: const [0.0, 0.62, 1.0],
        transform: const GradientRotation(startAngle),
      ).createShader(arcRect);

      final Paint activePaint = Paint()
        ..shader = arcShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, startAngle, activeSweep, false, activePaint);

      // 5. Crisp Luminous Leading Tip Orb
      final double tipAngle = startAngle + activeSweep;
      final Offset tipCenter = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipCenter,
        6.5,
        Paint()
          ..color = gaugeColor.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
      canvas.drawCircle(
        tipCenter,
        3.8,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }

    // 6. Daily Goal (100%) Milestone Benchmark Marker Dot
    if (clampedProgress < 0.98) {
      const double goalAngle = startAngle + totalSweep;
      final Offset goalPos = Offset(
        center.dx + radius * math.cos(goalAngle),
        center.dy + radius * math.sin(goalAngle),
      );
      canvas.drawCircle(
        goalPos,
        3.5,
        Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepRadialBarPainter old) =>
      old.progress != progress || old.isWalking != isWalking;
}
