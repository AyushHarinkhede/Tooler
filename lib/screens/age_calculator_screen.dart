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
  final DateTime _targetDate = DateTime.now();
  String _gender = 'male'; // 'male', 'female', 'other'
  final TextEditingController _ageController = TextEditingController();
  bool _isDirectAgeEditing = false;

  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _calculateAge();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
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
      if (!_isDirectAgeEditing && _ageController.text != '$years') {
        _ageController.text = '$years';
      }
    });
  }

  void _onDirectAgeInput(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed >= 0 && parsed <= 130) {
      final now = DateTime.now();
      _isDirectAgeEditing = true;
      setState(() {
        _selectedDate = DateTime(now.year - parsed, now.month, now.day);
        _calculateAge();
      });
      _isDirectAgeEditing = false;
    }
  }

  void _setGender(String gender) {
    SoundService().playClick();
    setState(() {
      _gender = gender;
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
    final int years = _results != null ? _results!['years'] as int : 0;
    final bool isAdult = years >= 18;
    final int adultDiff = 18 - years;

    final int marriageMinAge = _gender == 'female' ? 18 : 21;
    final bool canMarry = years >= marriageMinAge;
    final int marriageDiff = marriageMinAge - years;

    final bool canDrive = years >= 18;
    final int driveDiff = 18 - years;

    final bool canVote = years >= 18;
    final int voteDiff = 18 - years;

    final bool canDrink = years >= 21;
    final int drinkDiff = 21 - years;

    return Scaffold(
      backgroundColor: widget.theme.bg,
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
                              "Date of Birth & Age",
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
                                    fontSize: 17,
                                    color: widget.theme.text,
                                  ),
                                ),
                                Icon(Icons.calendar_month, color: widget.theme.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Or enter age directly (years):",
                                style: widget.theme.fontMono(
                                  fontSize: 12,
                                  color: widget.theme.text.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 85,
                              height: 40,
                              child: TextField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  fillColor: widget.theme.bg,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: widget.theme.border, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: widget.theme.border, width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: widget.theme.primary, width: 2),
                                  ),
                                  hintText: "Age",
                                ),
                                style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                                onChanged: _onDirectAgeInput,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Gender Selector Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              "Gender Selection",
                              style: widget.theme.fontDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildGenderOption("male", "Male"),
                            const SizedBox(width: 8),
                            _buildGenderOption("female", "Female"),
                            const SizedBox(width: 8),
                            _buildGenderOption("other", "Other"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results Breakdown Cards
                  if (_results != null) ...[
                    // Primary Age Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: widget.theme.doodleCard(
                        color: widget.theme.accent.withValues(alpha: 0.2),
                        borderWidth: 3.0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "YOUR CURRENT AGE",
                            style: widget.theme.fontMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text.withValues(alpha: 0.8),
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
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPillChip("Born on ${_results!['bornDayOfWeek']}"),
                              _buildPillChip("Gender: ${_gender.toUpperCase()}"),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 18+ Adult Status Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isAdult
                                  ? const Color(0xFF27AE60).withValues(alpha: 0.15)
                                  : const Color(0xFFE67E22).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAdult ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isAdult ? Icons.verified : Icons.child_care,
                                  color: isAdult ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isAdult
                                        ? "18+ Adult (Major) • Full Legal Adulthood"
                                        : "Minor (Under 18) • $adultDiff year${adultDiff > 1 ? 's' : ''} to adulthood",
                                    style: widget.theme.fontDisplay(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isAdult ? const Color(0xFF27AE60) : const Color(0xFFD35400),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Eligibility Status Section Header
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Legal Eligibility Status",
                          style: widget.theme.fontDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. 18+ Adult Status Card
                    _buildEligibilityCard(
                      title: "18+ Adult Status",
                      requirement: "Legal Standard: 18+ years",
                      description: isAdult
                          ? "✓ You are legally recognized as an adult with full civic rights."
                          : "✗ Currently a minor. $adultDiff more year${adultDiff > 1 ? 's' : ''} to reach legal adulthood.",
                      isEligible: isAdult,
                      currentYears: years,
                      minAge: 18,
                      iconPainter: _AdultPainter(color: widget.theme.text),
                    ),

                    // 2. Drive Card
                    _buildEligibilityCard(
                      title: "Drive (Motor Vehicles)",
                      requirement: "Legal Age: 18+ years",
                      description: canDrive
                          ? "✓ Eligible to apply for a permanent motor vehicle driving license."
                          : "✗ Requires 18+ for driving. $driveDiff more year${driveDiff > 1 ? 's' : ''} remaining.",
                      isEligible: canDrive,
                      currentYears: years,
                      minAge: 18,
                      iconPainter: _CarPainter(color: widget.theme.text),
                    ),

                    // 3. Vote Card
                    _buildEligibilityCard(
                      title: "Vote (Electoral Rights)",
                      requirement: "Legal Age: 18+ years",
                      description: canVote
                          ? "✓ Eligible to register as a voter and cast votes in elections."
                          : "✗ Voting rights require 18+. $voteDiff more year${voteDiff > 1 ? 's' : ''} remaining.",
                      isEligible: canVote,
                      currentYears: years,
                      minAge: 18,
                      iconPainter: _VotePainter(color: widget.theme.text),
                    ),

                    // 4. Marriage Card
                    _buildEligibilityCard(
                      title: "Marriage (${_gender.toUpperCase()})",
                      requirement: "Legal Age: $marriageMinAge+ years ($_gender)",
                      description: canMarry
                          ? "✓ You meet the legal marriage age requirement ($marriageMinAge+ for $_gender)."
                          : "✗ Legal marriage age for $_gender is $marriageMinAge+. $marriageDiff more year${marriageDiff > 1 ? 's' : ''} remaining.",
                      isEligible: canMarry,
                      currentYears: years,
                      minAge: marriageMinAge,
                      iconPainter: _MarriageRingsPainter(color: widget.theme.text),
                    ),

                    // 5. Alcohol Consumption Card
                    _buildEligibilityCard(
                      title: "Alcohol Consumption",
                      requirement: "Legal Age: 21+ years (standard)",
                      description: canDrink
                          ? "✓ You meet standard legal age (21+) for purchasing and consuming alcohol."
                          : "✗ Legal drinking age is 21+ in most regions. $drinkDiff more year${drinkDiff > 1 ? 's' : ''} remaining.",
                      isEligible: canDrink,
                      currentYears: years,
                      minAge: 21,
                      iconPainter: _AlcoholGlassPainter(color: widget.theme.text),
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
                              color: widget.theme.secondary.withValues(alpha: 0.2),
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

  Widget _buildGenderOption(String key, String label) {
    final isSelected = _gender == key;
    return Expanded(
      child: InkWell(
        onTap: () => _setGender(key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? widget.theme.primary : widget.theme.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? widget.theme.primary : widget.theme.border,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: widget.theme.fontDisplay(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : widget.theme.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Text(
        text,
        style: widget.theme.fontDoodle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: widget.theme.primary,
        ),
      ),
    );
  }

  Widget _buildEligibilityCard({
    required String title,
    required String requirement,
    required String description,
    required bool isEligible,
    required int currentYears,
    required int minAge,
    required CustomPainter iconPainter,
  }) {
    final double progress = (currentYears / minAge).clamp(0.0, 1.0);
    final statusColor = isEligible ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.theme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.theme.border, width: 2),
                ),
                alignment: Alignment.center,
                child: CustomPaint(
                  size: const Size(26, 26),
                  painter: iconPainter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: widget.theme.fontDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      requirement,
                      style: widget.theme.fontMono(
                        fontSize: 11,
                        color: widget.theme.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEligible ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEligible ? "Eligible" : "Not Eligible",
                      style: widget.theme.fontMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: widget.theme.fontDoodle(
              fontSize: 13,
              color: widget.theme.text.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: widget.theme.border.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isEligible ? const Color(0xFF27AE60) : widget.theme.primary,
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
                color: widget.theme.border.withValues(alpha: 0.3),
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
                  color: widget.theme.text.withValues(alpha: 0.7),
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

// ==========================================
// VECTOR DOODLE INK PAINTERS FOR ELIGIBILITY
// ==========================================

class _AdultPainter extends CustomPainter {
  final Color color;
  _AdultPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Head
    canvas.drawCircle(Offset(w * 0.38, h * 0.32), w * 0.18, paint);
    // Body curve
    final path = Path()
      ..moveTo(w * 0.12, h * 0.88)
      ..cubicTo(w * 0.14, h * 0.65, w * 0.25, h * 0.58, w * 0.38, h * 0.58)
      ..cubicTo(w * 0.50, h * 0.58, w * 0.62, h * 0.65, w * 0.64, h * 0.88);
    canvas.drawPath(path, paint);

    // 18+ Badge container
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52, h * 0.18, w * 0.44, h * 0.36),
      const Radius.circular(5),
    );
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRect, fillPaint);
    canvas.drawRRect(badgeRect, paint);

    final plusPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.78, h * 0.36), Offset(w * 0.78, h * 0.54), plusPaint);
    canvas.drawLine(Offset(w * 0.69, h * 0.45), Offset(w * 0.87, h * 0.45), plusPaint);
  }

  @override
  bool shouldRepaint(covariant _AdultPainter oldDelegate) => oldDelegate.color != color;
}

class _CarPainter extends CustomPainter {
  final Color color;
  _CarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final body = Path()
      ..moveTo(w * 0.10, h * 0.60)
      ..lineTo(w * 0.28, h * 0.60)
      ..lineTo(w * 0.38, h * 0.30)
      ..lineTo(w * 0.72, h * 0.30)
      ..lineTo(w * 0.84, h * 0.60)
      ..lineTo(w * 0.94, h * 0.60)
      ..arcToPoint(Offset(w * 0.94, h * 0.75), radius: const Radius.circular(4))
      ..lineTo(w * 0.82, h * 0.75)
      ..arcToPoint(Offset(w * 0.66, h * 0.75), radius: Radius.circular(w * 0.08), clockwise: false)
      ..lineTo(w * 0.38, h * 0.75)
      ..arcToPoint(Offset(w * 0.22, h * 0.75), radius: Radius.circular(w * 0.08), clockwise: false)
      ..lineTo(w * 0.08, h * 0.75)
      ..close();
    canvas.drawPath(body, paint);

    canvas.drawLine(Offset(w * 0.55, h * 0.30), Offset(w * 0.55, h * 0.60), paint);

    final wheelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.30, h * 0.75), w * 0.07, wheelPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.75), w * 0.07, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) => oldDelegate.color != color;
}

class _VotePainter extends CustomPainter {
  final Color color;
  _VotePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.40, w * 0.64, h * 0.52),
      const Radius.circular(5),
    );
    canvas.drawRRect(boxRect, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.36, w * 0.76, h * 0.10),
        const Radius.circular(3),
      ),
      paint,
    );

    canvas.drawLine(Offset(w * 0.35, h * 0.41), Offset(w * 0.65, h * 0.41), paint);

    final slip = Path()
      ..moveTo(w * 0.32, h * 0.14)
      ..lineTo(w * 0.68, h * 0.14)
      ..lineTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.32, h * 0.38)
      ..close();
    canvas.drawPath(slip, paint);

    final check = Path()
      ..moveTo(w * 0.42, h * 0.25)
      ..lineTo(w * 0.48, h * 0.31)
      ..lineTo(w * 0.58, h * 0.20);
    canvas.drawPath(check, paint..strokeWidth = strokeWidth * 1.2);
  }

  @override
  bool shouldRepaint(covariant _VotePainter oldDelegate) => oldDelegate.color != color;
}

class _MarriageRingsPainter extends CustomPainter {
  final Color color;
  _MarriageRingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w * 0.36, h * 0.58), w * 0.24, paint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.58), w * 0.24, paint);

    final diamond = Path()
      ..moveTo(w * 0.36, h * 0.18)
      ..lineTo(w * 0.46, h * 0.28)
      ..lineTo(w * 0.36, h * 0.38)
      ..lineTo(w * 0.26, h * 0.28)
      ..close();
    canvas.drawPath(diamond, paint);

    canvas.drawLine(Offset(w * 0.36, h * 0.08), Offset(w * 0.36, h * 0.14), paint);
    canvas.drawLine(Offset(w * 0.18, h * 0.20), Offset(w * 0.24, h * 0.23), paint);
    canvas.drawLine(Offset(w * 0.54, h * 0.20), Offset(w * 0.48, h * 0.23), paint);
  }

  @override
  bool shouldRepaint(covariant _MarriageRingsPainter oldDelegate) => oldDelegate.color != color;
}

class _AlcoholGlassPainter extends CustomPainter {
  final Color color;
  _AlcoholGlassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final bowl = Path()
      ..moveTo(w * 0.18, h * 0.22)
      ..lineTo(w * 0.82, h * 0.22)
      ..lineTo(w * 0.50, h * 0.60)
      ..close();
    canvas.drawPath(bowl, paint);

    canvas.drawLine(Offset(w * 0.30, h * 0.36), Offset(w * 0.70, h * 0.36), paint);
    canvas.drawLine(Offset(w * 0.50, h * 0.60), Offset(w * 0.50, h * 0.84), paint);
    canvas.drawLine(Offset(w * 0.28, h * 0.84), Offset(w * 0.72, h * 0.84), paint);

    final pick = Path()
      ..moveTo(w * 0.44, h * 0.44)
      ..lineTo(w * 0.80, h * 0.10);
    canvas.drawPath(pick, paint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.56, h * 0.32), w * 0.05, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _AlcoholGlassPainter oldDelegate) => oldDelegate.color != color;
}
