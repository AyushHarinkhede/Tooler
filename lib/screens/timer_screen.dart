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

class _TimerScreenState extends State<TimerScreen> {
  int _initialSeconds = 300; // 5 min default
  int _currentSeconds = 300;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_currentSeconds <= 0) return;
    SoundService().playClick();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() => _currentSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        SoundService().playAlert();
        _showFinishedDialog();
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

  void _setPreset(int minutes) {
    SoundService().playClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _initialSeconds = minutes * 60;
      _currentSeconds = _initialSeconds;
    });
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: widget.theme.border, width: 2.5),
          ),
          title: Text(
            "⏰ Time's Up!",
            style: widget.theme.fontDisplay(
              fontSize: 22,
              color: widget.theme.primary,
            ),
          ),
          content: Text(
            "Your timer has finished counting down! 🎉",
            style: widget.theme.fontDoodle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _resetTimer();
              },
              child: const Text("OK"),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_initialSeconds > 0)
        ? (_currentSeconds / _initialSeconds)
        : 0.0;

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
          "Countdown Timer ⏳",
          style: widget.theme.fontDisplay(fontSize: 22),
        ),
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
                  const SizedBox(height: 10),

                  // Circular Progress Arc
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(240, 240),
                            painter: _TimerProgressPainter(
                              progress: progress,
                              color: progressColor,
                              bgColor: widget.theme.border.withOpacity(0.15),
                              borderColor: widget.theme.border,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTimerDisplay(_currentSeconds),
                                style: widget.theme.fontMono(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRunning ? "RUNNING..." : "PAUSED",
                                style: widget.theme.fontMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.text.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Start / Pause & Reset Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionBtn(
                        label: "Reset",
                        icon: Icons.refresh,
                        color: widget.theme.cardBg,
                        onTap: _resetTimer,
                      ),
                      const SizedBox(width: 20),
                      _buildActionBtn(
                        label: _isRunning ? "Pause" : "Start",
                        icon: _isRunning ? Icons.pause : Icons.play_arrow,
                        color: _isRunning ? const Color(0xFFFFA502) : widget.theme.primary,
                        isLarge: true,
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Preset Buttons Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quick Presets ⚡",
                          style: widget.theme.fontDisplay(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildPresetChip("1 min", 1),
                            _buildPresetChip("5 min", 5),
                            _buildPresetChip("10 min", 10),
                            _buildPresetChip("15 min", 15),
                            _buildPresetChip("25 min 🍅", 25),
                            _buildPresetChip("30 min", 30),
                            _buildPresetChip("60 min", 60),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  color: widget.theme.border.withOpacity(0.3),
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
        const SizedBox(height: 4),
        Text(
          label,
          style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, int minutes) {
    final bool isSelected = (_initialSeconds == minutes * 60);
    return InkWell(
      onTap: () => _setPreset(minutes),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : widget.theme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.theme.border, width: 1.8),
        ),
        child: Text(
          label,
          style: widget.theme.fontMono(
            fontSize: 13,
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

    // Background track
    final Paint bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

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
