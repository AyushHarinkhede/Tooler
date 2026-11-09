import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class AgeCalculatorScreen extends StatefulWidget {
  final StationeryTheme theme;
  const AgeCalculatorScreen({super.key, required this.theme});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  DateTime _selectedDate = DateTime(2000, 1, 1);
  DateTime _targetDate = DateTime.now();

  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _calculateAge();
  }

  void _calculateAge() {
    final birth = _selectedDate;
    final now = _targetDate;

    if (birth.isAfter(now)) {
      setState(() => _results = null);
      return;
    }

    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    final totalDays = now.difference(birth).inDays;
    final totalWeeks = totalDays ~/ 7;
    final totalHours = totalDays * 24;

    // Next birthday calculation
    DateTime nextBday = DateTime(now.year, birth.month, birth.day);
    if (nextBday.isBefore(now)) {
      nextBday = DateTime(now.year + 1, birth.month, birth.day);
    }
    final daysToNextBday = nextBday.difference(now).inDays;
    final nextBdayDayOfWeek = DateFormat('EEEE').format(nextBday);
    final bornDayOfWeek = DateFormat('EEEE').format(birth);

    setState(() {
      _results = {
        'years': years,
        'months': months,
        'days': days,
        'totalDays': totalDays,
        'totalWeeks': totalWeeks,
        'totalHours': totalHours,
        'daysToNextBday': daysToNextBday,
        'nextBdayDayOfWeek': nextBdayDayOfWeek,
        'bornDayOfWeek': bornDayOfWeek,
      };
    });
  }

  Future<void> _pickDate() async {
    SoundService().playClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.primary,
              onPrimary: Colors.white,
              surface: widget.theme.cardBg,
              onSurface: widget.theme.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculateAge();
      });
      SoundService().playSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Age Calculator 🎂",
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Birthday Picker Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: widget.theme.doodleCard(borderWidth: 2.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cake, color: Color(0xFFFF6B6B), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              "Date of Birth 🎈",
                              style: widget.theme.fontDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.theme.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.theme.border, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                                  style: widget.theme.fontDisplay(
                                    fontSize: 18,
                                    color: widget.theme.text,
                                  ),
                                ),
                                Icon(Icons.calendar_month, color: widget.theme.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Results Breakdown Cards
                  if (_results != null) ...[
                    // Primary Age Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: widget.theme.doodleCard(
                        color: widget.theme.accent.withOpacity(0.2),
                        borderWidth: 3.0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "YOUR CURRENT AGE",
                            style: widget.theme.fontMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBubble("${_results!['years']}", "YEARS"),
                              _buildStatBubble("${_results!['months']}", "MONTHS"),
                              _buildStatBubble("${_results!['days']}", "DAYS"),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.theme.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: widget.theme.border, width: 1.5),
                            ),
                            child: Text(
                              "Born on a ${_results!['bornDayOfWeek']} 🎉",
                              style: widget.theme.fontDoodle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Next Birthday Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: widget.theme.doodleCard(borderWidth: 2.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.theme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.celebration, color: Color(0xFF4ECDC4), size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Next Birthday Countdown",
                                  style: widget.theme.fontDisplay(fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${_results!['daysToNextBday']} days to go (${_results!['nextBdayDayOfWeek']})",
                                  style: widget.theme.fontDoodle(
                                    fontSize: 14,
                                    color: widget.theme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Life Milestones Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMilestoneCard(
                            "Total Days",
                            NumberFormat.decimalPattern().format(_results!['totalDays']),
                            Icons.wb_sunny_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallMilestoneCard(
                            "Total Weeks",
                            NumberFormat.decimalPattern().format(_results!['totalWeeks']),
                            Icons.view_week_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMilestoneCard(
                            "Total Hours",
                            NumberFormat.decimalPattern().format(_results!['totalHours']),
                            Icons.hourglass_bottom,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallMilestoneCard(
                            "Heart Beats ~",
                            "${(_results!['totalDays'] * 100000 ~/ 1000000)}M",
                            Icons.favorite_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String value, String label) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: widget.theme.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: widget.theme.border.withOpacity(0.3),
                offset: const Offset(3, 4),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: widget.theme.fontDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: widget.theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: widget.theme.fontMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMilestoneCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: widget.theme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: widget.theme.fontMono(
                  fontSize: 11,
                  color: widget.theme.text.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: widget.theme.fontDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.theme.text,
            ),
          ),
        ],
      ),
    );
  }
}
