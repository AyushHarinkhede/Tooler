import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/tooler_character.dart';

class StopwatchScreen extends StatefulWidget {
  final StationeryTheme theme;
  const StopwatchScreen({super.key, required this.theme});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _LapRecord {
  final int lapNumber;
  final int totalMs;
  final int lapDurationMs;

  _LapRecord({
    required this.lapNumber,
    required this.totalMs,
    required this.lapDurationMs,
  });
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isRunning = false;
  int _startEpochMs = 0;
  int _savedElapsedMs = 0;
  Timer? _ticker;
  final List<_LapRecord> _laps = [];
  int _lastLapTotalMs = 0;

  int get _elapsedMs {
    if (_isRunning && _startEpochMs > 0) {
      return DateTime.now().millisecondsSinceEpoch - _startEpochMs;
    }
    return _savedElapsedMs;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreStopwatchState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _persistStopwatchState();
      if (_isRunning) {
        NotificationService().showStopwatchActiveNotification(
          timeStr: _formatTime(_elapsedMs),
          ongoing: true,
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      NotificationService().cancelStopwatchNotification();
      _restoreStopwatchState();
    }
  }

  void _persistStopwatchState() {
    if (_isRunning) {
      StorageService().saveStopwatchState(
        isRunning: true,
        startEpochMs: _startEpochMs,
        elapsedMs: _elapsedMs,
      );
    } else if (_savedElapsedMs > 0) {
      StorageService().saveStopwatchState(
        isRunning: false,
        startEpochMs: 0,
        elapsedMs: _savedElapsedMs,
      );
    }
  }

  void _restoreStopwatchState() async {
    final state = await StorageService().loadStopwatchState();
    if (!mounted) return;

    final isRunning = state['isRunning'] as bool? ?? false;
    final startEpoch = state['startEpochMs'] as int? ?? 0;
    final elapsed = state['elapsedMs'] as int? ?? 0;

    if (isRunning && startEpoch > 0) {
      setState(() {
        _isRunning = true;
        _startEpochMs = startEpoch;
      });
      _startTicker();
    } else if (elapsed > 0) {
      setState(() {
        _isRunning = false;
        _savedElapsedMs = elapsed;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
    });
  }

  void _startTimer() {
    SoundService().playSpecialClick();
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _isRunning = true;
      _startEpochMs = now - _savedElapsedMs;
    });

    StorageService().saveStopwatchState(
      isRunning: true,
      startEpochMs: _startEpochMs,
      elapsedMs: _elapsedMs,
    );

    _startTicker();
  }

  void _pauseTimer() {
    SoundService().playClick();
    NotificationService().cancelStopwatchNotification();
    final current = _elapsedMs;
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _savedElapsedMs = current;
    });

    StorageService().saveStopwatchState(
      isRunning: false,
      startEpochMs: 0,
      elapsedMs: _savedElapsedMs,
    );
  }

  void _resetTimer() {
    SoundService().playClick();
    NotificationService().cancelStopwatchNotification();
    _ticker?.cancel();
    StorageService().clearStopwatchState();
    setState(() {
      _isRunning = false;
      _startEpochMs = 0;
      _savedElapsedMs = 0;
      _laps.clear();
      _lastLapTotalMs = 0;
    });
  }

  void _lapTimer() {
    if (!_isRunning) return;
    SoundService().playKey();
    final int currentMs = _elapsedMs;
    final int lapDuration = currentMs - _lastLapTotalMs;
    _lastLapTotalMs = currentMs;

    setState(() {
      _laps.insert(
        0,
        _LapRecord(
          lapNumber: _laps.length + 1,
          totalMs: currentMs,
          lapDurationMs: lapDuration,
        ),
      );
    });
  }

  String _formatTime(int ms) {
    final int minutes = (ms ~/ 60000);
    final int seconds = (ms % 60000) ~/ 1000;
    final int hundredths = (ms % 1000) ~/ 10;

    final String minStr = minutes.toString().padLeft(2, '0');
    final String secStr = seconds.toString().padLeft(2, '0');
    final String msStr = hundredths.toString().padLeft(2, '0');

    return "$minStr:$secStr.$msStr";
  }

  @override
  void dispose() {
    if (_isRunning) {
      NotificationService().showStopwatchActiveNotification(
        timeStr: _formatTime(_elapsedMs),
        ongoing: true,
      );
    }
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int elapsedMs = _elapsedMs;
    final double secondsFraction = (elapsedMs % 60000) / 1000.0;
    final double needleAngle = (secondsFraction / 60.0) * 2 * math.pi;

    // Find fastest and slowest lap duration for highlighting
    int? minLapMs;
    int? maxLapMs;
    if (_laps.length >= 2) {
      minLapMs = _laps.map((l) => l.lapDurationMs).reduce(math.min);
      maxLapMs = _laps.map((l) => l.lapDurationMs).reduce(math.max);
    }

    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Precision Dual-Ring Stopwatch Dial Face
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: widget.theme.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.theme.border, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.border.withValues(alpha: 0.25),
                          offset: const Offset(3, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ticks & Numerical Dial Painter
                        CustomPaint(
                          size: const Size(240, 240),
                          painter: _StopwatchDialPainter(
                            border: widget.theme.border,
                            primaryColor: widget.theme.primary,
                          ),
                        ),

                        // Rotating Needle
                        Transform.rotate(
                          angle: needleAngle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 24),
                              width: 3.5,
                              height: 96,
                              decoration: BoxDecoration(
                                color: widget.theme.primary,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.theme.primary.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Center Pivot Reticle Pin
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: widget.theme.cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: widget.theme.primary, width: 3),
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: widget.theme.text,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Digital Readout Display with Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: widget.theme.doodleCard(
                    color: widget.theme.lavenderCard,
                    borderWidth: 2.0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isRunning
                              ? const Color(0xFF2ED573).withValues(alpha: 0.2)
                              : widget.theme.border.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isRunning ? "RUNNING" : (elapsedMs > 0 ? "PAUSED" : "STOPPED"),
                          style: widget.theme.fontMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isRunning ? const Color(0xFF2ED573) : widget.theme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(elapsedMs),
                        style: widget.theme.fontMono(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: widget.theme.text,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset / Clear
                      _buildRoundBtn(
                        label: "Reset",
                        icon: Icons.refresh_rounded,
                        color: widget.theme.cardBg,
                        onTap: _resetTimer,
                      ),
                      // Start / Pause
                      _buildRoundBtn(
                        label: _isRunning ? "Pause" : "Start",
                        icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _isRunning
                            ? const Color(0xFFFFB300)
                            : widget.theme.primary,
                        isLarge: true,
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                      ),
                      // Lap
                      _buildRoundBtn(
                        label: "Lap",
                        icon: Icons.flag_outlined,
                        color: widget.theme.lavenderCard,
                        onTap: _lapTimer,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),

                // Laps List with Best/Worst Split Highlighting
                Expanded(
                  child: _laps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ToolerCharacter(
                                pose: ToolerCharacterPose.dualMonitor,
                                theme: widget.theme,
                                width: 140,
                                height: 110,
                                animate: _isRunning,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No laps recorded yet",
                                style: widget.theme.fontDoodle(
                                  fontSize: 15,
                                  color: widget.theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap 'Lap' while running to track split records",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.theme.textSecondary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _laps.length,
                          itemBuilder: (context, index) {
                            final lap = _laps[index];
                            final bool isFastest = minLapMs != null && lap.lapDurationMs == minLapMs;
                            final bool isSlowest = maxLapMs != null && lap.lapDurationMs == maxLapMs;

                            Color badgeBg = widget.theme.cardBg;
                            Color badgeColor = widget.theme.textSecondary;
                            String? badgeText;

                            if (isFastest) {
                              badgeBg = const Color(0xFF2ED573).withValues(alpha: 0.15);
                              badgeColor = const Color(0xFF2ED573);
                              badgeText = "Fastest";
                            } else if (isSlowest) {
                              badgeBg = const Color(0xFFFF4757).withValues(alpha: 0.15);
                              badgeColor = const Color(0xFFFF4757);
                              badgeText = "Slowest";
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: widget.theme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFastest
                                      ? const Color(0xFF2ED573)
                                      : widget.theme.border,
                                  width: isFastest ? 1.8 : 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Lap ${lap.lapNumber}",
                                        style: widget.theme.fontDisplay(fontSize: 15),
                                      ),
                                      if (badgeText != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: widget.theme.fontMono(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTime(lap.lapDurationMs),
                                        style: widget.theme.fontMono(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isFastest ? const Color(0xFF2ED573) : widget.theme.primary,
                                        ),
                                      ),
                                      Text(
                                        "Total: ${_formatTime(lap.totalMs)}",
                                        style: widget.theme.fontMono(
                                          fontSize: 11,
                                          color: widget.theme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final double size = isLarge ? 72 : 54;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: widget.theme.border, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.25),
                  offset: const Offset(2, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: isLarge ? 34 : 24,
              color: isLarge ? Colors.white : widget.theme.text,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StopwatchDialPainter extends CustomPainter {
  final Color border;
  final Color primaryColor;
  _StopwatchDialPainter({required this.border, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 14;

    final Paint tickPaint = Paint()
      ..color = border.withValues(alpha: 0.3)
      ..strokeWidth = 1.2;

    final Paint majorTickPaint = Paint()
      ..color = border
      ..strokeWidth = 2.4;

    for (int i = 0; i < 60; i++) {
      final double angle = (i * 6) * math.pi / 180;
      final bool isMajor = (i % 5 == 0);
      final double tickLen = isMajor ? 12 : 6;

      final Offset p1 = Offset(
        center.dx + (radius - tickLen) * math.sin(angle),
        center.dy - (radius - tickLen) * math.cos(angle),
      );
      final Offset p2 = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StopwatchDialPainter oldDelegate) => false;
}
