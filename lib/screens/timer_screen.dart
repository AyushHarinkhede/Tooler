import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class TimerScreen extends StatefulWidget {
  final StationeryTheme theme;
  const TimerScreen({super.key, required this.theme});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  int _initialSeconds = 300; // 5 min default
  int _currentSeconds = 300;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _pulseController;

  // Custom manual time inputs
  int _customHours = 0;
  int _customMinutes = 5;
  int _customSeconds = 0;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    if (_currentSeconds <= 0) {
      if (_initialSeconds > 0) {
        setState(() => _currentSeconds = _initialSeconds);
      } else {
        return;
      }
    }
    SoundService().playClick();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 1) {
        setState(() => _currentSeconds--);
      } else if (_currentSeconds == 1) {
        setState(() => _currentSeconds = 0);
        _onTimerFinished();
      }
    });
  }

  void _pauseTimer() {
    SoundService().playClick();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    SoundService().playClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentSeconds = _initialSeconds;
    });
  }

  void _setPreset(int totalSec) {
    SoundService().playClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _initialSeconds = totalSec;
      _currentSeconds = totalSec;
      _customHours = totalSec ~/ 3600;
      _customMinutes = (totalSec % 3600) ~/ 60;
      _customSeconds = totalSec % 60;
    });
  }

  /// Direct quick-add time to running or paused timer
  void _addTime(int secondsToAdd) {
    SoundService().playTap();
    setState(() {
      _currentSeconds += secondsToAdd;
      _initialSeconds = math.max(_initialSeconds, _currentSeconds);
    });
  }

  void _applyCustomTime() {
    final int total = (_customHours * 3600) + (_customMinutes * 60) + _customSeconds;
    if (total <= 0) return;
    SoundService().playClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _initialSeconds = total;
      _currentSeconds = total;
      _showCustomInput = false;
    });
  }

  /// Alarm chime sound sequence when countdown completes
  void _onTimerFinished() {
    _timer?.cancel();
    setState(() => _isRunning = false);

    // Play initial alert sound
    SoundService().playAlert();

    // Repeating audio chimes sequence
    Timer(const Duration(milliseconds: 350), () => SoundService().playAlert());
    Timer(const Duration(milliseconds: 700), () => SoundService().playAlert());

    _showFinishedDialog();
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: widget.theme.border, width: 2.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF2ED573),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Time's Up!",
                style: widget.theme.fontDisplay(
                  fontSize: 22,
                  color: widget.theme.primary,
                ),
              ),
            ],
          ),
          content: Text(
            "Your countdown timer has completed successfully.",
            style: widget.theme.fontDoodle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _resetTimer();
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  String _formatTimerDisplay(int totalSec) {
    final int hr = totalSec ~/ 3600;
    final int min = (totalSec % 3600) ~/ 60;
    final int sec = totalSec % 60;

    if (hr > 0) {
      return "${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
    }
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_initialSeconds > 0)
        ? (_currentSeconds / _initialSeconds)
        : 0.0;
    final int percentRemaining = (progress * 100).round();

    Color progressColor = const Color(0xFF2ED573);
    if (_currentSeconds <= 10) {
      progressColor = const Color(0xFFFF4757);
    } else if (_currentSeconds <= 30) {
      progressColor = const Color(0xFFFFA502);
    }

    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Countdown Timer",
          style: widget.theme.fontDisplay(fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: "Custom Time",
            icon: Icon(
              _showCustomInput ? Icons.close : Icons.tune_rounded,
              color: widget.theme.text,
            ),
            onPressed: () {
              setState(() => _showCustomInput = !_showCustomInput);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Best Way: Circular Countdown Progress Instrument
                  Center(
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated pulse ring when under 10 seconds
                          if (_isRunning && _currentSeconds <= 10)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 250 + (_pulseController.value * 12),
                                  height: 250 + (_pulseController.value * 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFF4757).withValues(alpha: 0.4 * (1 - _pulseController.value)),
                                      width: 4,
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Custom Progress Painter
                          CustomPaint(
                            size: const Size(260, 260),
                            painter: _TimerProgressPainter(
                              progress: progress,
                              color: progressColor,
                              bgColor: widget.theme.border.withValues(alpha: 0.15),
                              borderColor: widget.theme.border,
                            ),
                          ),

                          // Inside Time & Percent Info
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // State badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isRunning
                                      ? progressColor.withValues(alpha: 0.15)
                                      : widget.theme.border.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _isRunning ? "RUNNING" : (_currentSeconds == 0 ? "FINISHED" : "PAUSED"),
                                  style: widget.theme.fontMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isRunning ? progressColor : widget.theme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Big crisp digital digits
                              Text(
                                _formatTimerDisplay(_currentSeconds),
                                style: widget.theme.fontMono(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: widget.theme.text,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Percent remaining pill
                              Text(
                                "$percentRemaining% remaining",
                                style: widget.theme.fontMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick live add buttons (+30s, +1m, +5m)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAddChip("+30s", 30),
                      const SizedBox(width: 10),
                      _buildQuickAddChip("+1m", 60),
                      const SizedBox(width: 10),
                      _buildQuickAddChip("+5m", 300),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Controls: Reset & Start / Pause
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionBtn(
                        label: "Reset",
                        icon: Icons.refresh_rounded,
                        color: widget.theme.cardBg,
                        onTap: _resetTimer,
                      ),
                      const SizedBox(width: 24),
                      _buildActionBtn(
                        label: _isRunning ? "Pause" : "Start",
                        icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _isRunning ? const Color(0xFFFFA502) : widget.theme.primary,
                        isLarge: true,
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Manual Custom Time Adder Accordion/Card
                  if (_showCustomInput) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: widget.theme.doodleCard(borderWidth: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Manual Time Input",
                                style: widget.theme.fontDisplay(fontSize: 16),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => setState(() => _showCustomInput = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimeStepper(
                                label: "Hours",
                                value: _customHours,
                                max: 23,
                                onChanged: (val) => setState(() => _customHours = val),
                              ),
                              Text(":", style: widget.theme.fontMono(fontSize: 24, fontWeight: FontWeight.bold)),
                              _buildTimeStepper(
                                label: "Minutes",
                                value: _customMinutes,
                                max: 59,
                                onChanged: (val) => setState(() => _customMinutes = val),
                              ),
                              Text(":", style: widget.theme.fontMono(fontSize: 24, fontWeight: FontWeight.bold)),
                              _buildTimeStepper(
                                label: "Seconds",
                                value: _customSeconds,
                                max: 59,
                                onChanged: (val) => setState(() => _customSeconds = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.theme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _applyCustomTime,
                              child: Text(
                                "Set Custom Duration",
                                style: widget.theme.fontDisplay(fontSize: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Quick Select Presets Toolbar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Quick Select Presets",
                              style: widget.theme.fontDisplay(fontSize: 16),
                            ),
                            InkWell(
                              onTap: () => setState(() => _showCustomInput = !_showCustomInput),
                              child: Text(
                                _showCustomInput ? "Hide Custom" : "Custom +",
                                style: widget.theme.fontMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip("30s", 30),
                            _buildPresetChip("1m", 60),
                            _buildPresetChip("2m", 120),
                            _buildPresetChip("5m", 300),
                            _buildPresetChip("10m", 600),
                            _buildPresetChip("15m", 900),
                            _buildPresetChip("25m (Pomodoro)", 1500),
                            _buildPresetChip("30m", 1800),
                            _buildPresetChip("45m", 2700),
                            _buildPresetChip("1h", 3600),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStepper({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(label, style: widget.theme.fontMono(fontSize: 11, color: widget.theme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.theme.border, width: 1.5),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => onChanged(value < max ? value + 1 : 0),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                ),
              ),
              Text(
                value.toString().padLeft(2, '0'),
                style: widget.theme.fontMono(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => onChanged(value > 0 ? value - 1 : max),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddChip(String label, int secondsToAdd) {
    return InkWell(
      onTap: () => _addTime(secondsToAdd),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.theme.border, width: 1.5),
        ),
        child: Text(
          label,
          style: widget.theme.fontMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: widget.theme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final double size = isLarge ? 68 : 54;
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
              border: Border.all(color: widget.theme.border, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.3),
                  offset: const Offset(2, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: isLarge ? 32 : 24,
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

  Widget _buildPresetChip(String label, int seconds) {
    final bool isSelected = (_initialSeconds == seconds);
    return InkWell(
      onTap: () => _setPreset(seconds),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : widget.theme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? widget.theme.primary : widget.theme.border,
            width: 1.8,
          ),
        ),
        child: Text(
          label,
          style: widget.theme.fontMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : widget.theme.text,
          ),
        ),
      ),
    );
  }
}

class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  _TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 14;

    // Background track groove
    final Paint bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Subtle tick markings along track
    final Paint tickPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 60; i++) {
      final double angle = (i * 6) * math.pi / 180;
      final double innerR = (i % 5 == 0) ? radius - 10 : radius - 5;
      final Offset p1 = Offset(
        center.dx + innerR * math.sin(angle),
        center.dy - innerR * math.cos(angle),
      );
      final Offset p2 = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Active progress arc
    final Paint activePaint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
