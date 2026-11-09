import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class StopwatchScreen extends StatefulWidget {
  final StationeryTheme theme;
  const StopwatchScreen({super.key, required this.theme});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  void _startTimer() {
    SoundService().playClick();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {});
    });
  }

  void _pauseTimer() {
    SoundService().playClick();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _resetTimer() {
    SoundService().playClick();
    _stopwatch.reset();
    _timer?.cancel();
    setState(() {
      _laps.clear();
    });
  }

  void _lapTimer() {
    if (!_stopwatch.isRunning) return;
    SoundService().playKey();
    setState(() {
      _laps.insert(0, _formatTime(_stopwatch.elapsedMilliseconds));
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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int elapsedMs = _stopwatch.elapsedMilliseconds;
    final double secondsFraction = (elapsedMs % 60000) / 1000.0;
    final double needleAngle = (secondsFraction / 60.0) * 2 * math.pi;

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
          "Stopwatch ⏱️",
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
            child: Column(
              children: [
                const SizedBox(height: 12),

                // 3D Stopwatch Dial Face
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: widget.theme.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.theme.border, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.border.withOpacity(0.35),
                          offset: const Offset(4, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ticks Painter
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: _StopwatchDialPainter(border: widget.theme.border),
                        ),
                        // Rotating Needle
                        Transform.rotate(
                          angle: needleAngle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 25),
                              width: 3.5,
                              height: 85,
                              decoration: BoxDecoration(
                                color: widget.theme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        // Center Pivot Pin
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: widget.theme.border,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Digital Readout Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: widget.theme.doodleCard(
                    color: widget.theme.accent.withOpacity(0.2),
                    borderWidth: 2.5,
                  ),
                  child: Text(
                    _formatTime(elapsedMs),
                    style: widget.theme.fontMono(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset / Clear
                      _buildRoundBtn(
                        label: "Reset",
                        icon: Icons.refresh,
                        color: widget.theme.cardBg,
                        onTap: _resetTimer,
                      ),
                      // Start / Pause
                      _buildRoundBtn(
                        label: _stopwatch.isRunning ? "Pause" : "Start",
                        icon: _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                        color: _stopwatch.isRunning
                            ? const Color(0xFFFFB300)
                            : widget.theme.primary,
                        isLarge: true,
                        onTap: _stopwatch.isRunning ? _pauseTimer : _startTimer,
                      ),
                      // Lap
                      _buildRoundBtn(
                        label: "Lap",
                        icon: Icons.flag_outlined,
                        color: widget.theme.secondary.withOpacity(0.4),
                        onTap: _lapTimer,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                // Laps List
                Expanded(
                  child: _laps.isEmpty
                      ? Center(
                          child: Text(
                            "No laps recorded yet 🏁",
                            style: widget.theme.fontDoodle(
                              fontSize: 16,
                              color: widget.theme.text.withOpacity(0.6),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: _laps.length,
                          itemBuilder: (context, index) {
                            final lapNum = _laps.length - index;
                            final lapTime = _laps[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: widget.theme.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: widget.theme.border, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Lap $lapNum",
                                    style: widget.theme.fontDisplay(fontSize: 16),
                                  ),
                                  Text(
                                    lapTime,
                                    style: widget.theme.fontMono(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.primary,
                                    ),
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
    final double size = isLarge ? 72 : 56;
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
              size: isLarge ? 34 : 26,
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
  _StopwatchDialPainter({required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 12;

    final Paint tickPaint = Paint()
      ..color = border.withOpacity(0.4)
      ..strokeWidth = 1.5;

    final Paint majorTickPaint = Paint()
      ..color = border
      ..strokeWidth = 2.5;

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
