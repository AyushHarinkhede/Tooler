import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/bouncy_tap.dart';

class AgeCalculatorScreen extends StatefulWidget {
  final StationeryTheme theme;
  const AgeCalculatorScreen({super.key, required this.theme});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  DateTime _selectedDate = DateTime(2000, 1, 1);
  String _gender = 'male'; // 'male', 'female', 'other'
  Timer? _liveTicker;

  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _calculateAge();
    // Live ticker: updates every second for live Hours, Minutes, Seconds precision!
    _liveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _calculateAge();
      }
    });
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    super.dispose();
  }

  void _calculateAge() {
    final birth = _selectedDate;
    final now = DateTime.now();

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

    // Live exact seconds and minutes precision
    final int hours = now.hour;
    final int minutes = now.minute;
    final int seconds = now.second;

    final totalDays = now.difference(birth).inDays;
    final totalWeeks = totalDays ~/ 7;
    final totalHours = now.difference(birth).inHours;

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
        'hours': hours,
        'minutes': minutes,
        'seconds': seconds,
        'totalDays': totalDays,
        'totalWeeks': totalWeeks,
        'totalHours': totalHours,
        'daysToNextBday': daysToNextBday,
        'nextBdayDayOfWeek': nextBdayDayOfWeek,
        'bornDayOfWeek': bornDayOfWeek,
      };
    });
  }

  void _setDirectAge(int targetYears) {
    if (targetYears < 0 || targetYears > 200) return;
    SoundService().playClick();
    final now = DateTime.now();
    int targetMonth = _selectedDate.month;
    int targetDay = _selectedDate.day;

    // Handle leap year clamp
    final maxDay = DateTime(now.year - targetYears, targetMonth + 1, 0).day;
    if (targetDay > maxDay) targetDay = maxDay;

    DateTime newBirth = DateTime(now.year - targetYears, targetMonth, targetDay);
    if (newBirth.isAfter(now)) {
      newBirth = now;
    }

    setState(() {
      _selectedDate = newBirth;
      _calculateAge();
    });
  }

  void _incrementAge() {
    final currentYears = _results?['years'] as int? ?? 0;
    if (currentYears < 160) {
      _setDirectAge(currentYears + 1);
    }
  }

  void _decrementAge() {
    final currentYears = _results?['years'] as int? ?? 0;
    if (currentYears > 0) {
      _setDirectAge(currentYears - 1);
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
      firstDate: DateTime(1850),
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

  void _showAgePickerSheet(BuildContext context) {
    SoundService().playClick();
    final currentYears = _results?['years'] as int? ?? 26;

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: widget.theme.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Age Directly",
                    style: widget.theme.fontDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "Done",
                      style: TextStyle(
                        color: widget.theme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Quick Milestone Jump Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [0, 5, 10, 18, 21, 25, 50, 60, 75, 100, 150].map((quickAge) {
                    final bool isCur = (quickAge == currentYears);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(
                          quickAge >= 150 ? '$quickAge+ (Immortal)' : '$quickAge yrs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCur ? Colors.white : widget.theme.text,
                          ),
                        ),
                        backgroundColor: isCur ? widget.theme.primary : widget.theme.cardBg,
                        side: BorderSide(
                          color: isCur ? widget.theme.primary : widget.theme.border,
                        ),
                        onPressed: () {
                          _setDirectAge(quickAge);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Wheel / List of Numbers
              Expanded(
                child: ListView.builder(
                  itemCount: 161, // 0 to 160
                  itemExtent: 46,
                  itemBuilder: (context, idx) {
                    final ageVal = idx;
                    final isSel = (ageVal == currentYears);
                    return InkWell(
                      onTap: () {
                        _setDirectAge(ageVal);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSel ? widget.theme.primary.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isSel ? Border.all(color: widget.theme.primary, width: 1.5) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ageVal >= 150
                              ? '$ageVal Years (Immortal 👑)'
                              : ageVal == 100
                                  ? '100 Years (Full Century 💯)'
                                  : ageVal == 50
                                      ? '50 Years (Half Century ✨)'
                                      : ageVal == 25
                                          ? '25 Years (Quarter Century 🥈)'
                                          : '$ageVal Years Old',
                          style: widget.theme.fontDisplay(
                            fontSize: isSel ? 18 : 15,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? widget.theme.primary : widget.theme.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int years = _results != null ? _results!['years'] as int : 0;
    final int marriageMinAge = _gender == 'female' ? 18 : 21;

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
                  // 1. Birthday Picker & Direct Age Number Selector Card
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
                        // Date of Birth Clickable Bar
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
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
                                Icon(Icons.calendar_month_rounded, color: widget.theme.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Direct Age Number Selector (NO Typing, Direct Selection & Stepper)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Select age directly (years):",
                                style: widget.theme.fontMono(
                                  fontSize: 12,
                                  color: widget.theme.text.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: widget.theme.bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: widget.theme.border, width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus button with Bouncy Tap
                                  BouncyTap(
                                    onTap: _decrementAge,
                                    scaleFraction: 0.85,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: Icon(Icons.remove, size: 18),
                                    ),
                                  ),
                                  // Clickable Number Badge with AnimatedTextPop & BouncyTap
                                  BouncyTap(
                                    onTap: () => _showAgePickerSheet(context),
                                    scaleFraction: 0.90,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: widget.theme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedTextPop(
                                            text: "$years",
                                            style: widget.theme.fontDisplay(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: widget.theme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.unfold_more_rounded,
                                            size: 16,
                                            color: widget.theme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Plus button with Bouncy Tap
                                  BouncyTap(
                                    onTap: _incrementAge,
                                    scaleFraction: 0.85,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: Icon(Icons.add, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Gender Selection Card (Male: Blue, Female: Pink, Other: Red)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wc_rounded, size: 22),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildGenderOption(
                              key: "male",
                              label: "Male",
                              icon: Icons.male_rounded,
                              activeColor: const Color(0xFF2980B9), // Distinct Male Blue
                            ),
                            const SizedBox(width: 8),
                            _buildGenderOption(
                              key: "female",
                              label: "Female",
                              icon: Icons.female_rounded,
                              activeColor: const Color(0xFFE84393), // Distinct Female Pink
                            ),
                            const SizedBox(width: 8),
                            _buildGenderOption(
                              key: "other",
                              label: "Other",
                              icon: Icons.transgender_rounded,
                              activeColor: const Color(0xFFE74C3C), // Distinct Other Red
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Compact 2-Line Age Breakdown (Years, Months, Days & Hours, Minutes, Seconds)
                  if (_results != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: widget.theme.doodleCard(
                        color: widget.theme.accent.withValues(alpha: 0.15),
                        borderWidth: 2.5,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "YOUR CURRENT AGE",
                            style: widget.theme.fontDisplay(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: widget.theme.text.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Line 1: Years, Months, Days
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: widget.theme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.theme.border, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCompactStatItem("${_results!['years']}", "Years"),
                                _buildDivider(),
                                _buildCompactStatItem("${_results!['months']}", "Months"),
                                _buildDivider(),
                                _buildCompactStatItem("${_results!['days']}", "Days"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Line 2: Hours, Minutes, Seconds (Live Ticking)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: widget.theme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.theme.border, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCompactStatItem("${_results!['hours']}".padLeft(2, '0'), "Hours"),
                                _buildDivider(),
                                _buildCompactStatItem("${_results!['minutes']}".padLeft(2, '0'), "Minutes"),
                                _buildDivider(),
                                _buildCompactStatItem("${_results!['seconds']}".padLeft(2, '0'), "Seconds", isLive: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildPillChip("Born on ${_results!['bornDayOfWeek']}"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Eligibility Status Header (Directly after Current Age, 'Legal' removed)
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Eligibility Status",
                          style: widget.theme.fontDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Criteria 1: Legal Adulthood (18+)
                    _buildEligibilityItem(
                      title: "Legal Adulthood",
                      icon: Icons.verified_rounded,
                      isEligible: years >= 18,
                    ),

                    // Criteria 2: Voting Rights (18+)
                    _buildEligibilityItem(
                      title: "Voting Rights",
                      icon: Icons.how_to_vote_rounded,
                      isEligible: years >= 18,
                    ),

                    // Criteria 3: Driving License (18+)
                    _buildEligibilityItem(
                      title: "Driving License",
                      icon: Icons.directions_car_rounded,
                      isEligible: years >= 18,
                    ),

                    // Criteria 4: Marriage
                    _buildEligibilityItem(
                      title: "Marriage",
                      icon: Icons.favorite_rounded,
                      isEligible: years >= marriageMinAge,
                    ),

                    // Criteria 5: Employment (18+)
                    _buildEligibilityItem(
                      title: "Employment",
                      icon: Icons.work_rounded,
                      isEligible: years >= 18,
                    ),

                    const SizedBox(height: 16),

                    // 5. Generation & Citizen Era Bar Container (Alpha, Gen Z, Millennial, Citizen Type)
                    _buildGenerationCitizenBar(_selectedDate.year, years),

                    const SizedBox(height: 16),

                    // Next Birthday Countdown
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
                            child: const Icon(Icons.celebration_rounded, color: Color(0xFF4ECDC4), size: 30),
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

                    // Life Totals Grid
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
                            Icons.hourglass_bottom_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallMilestoneCard(
                            "Heart Beats ~",
                            "${(_results!['totalDays'] * 100000 ~/ 1000000)}M",
                            Icons.favorite_outline_rounded,
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

  // --- Gender Option Widget (Specific colors: Male Blue, Female Pink, Other Red) ---
  Widget _buildGenderOption({
    required String key,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = (_gender == key);
    return Expanded(
      child: BouncyTap(
        onTap: () => _setGender(key),
        scaleFraction: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : widget.theme.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : activeColor.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : activeColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: widget.theme.fontDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : widget.theme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Generation & Citizen Type Bar Container (Alpha, Gen Z, Millennial, Gen X, Citizen Type) ---
  Widget _buildGenerationCitizenBar(int birthYear, int years) {
    String genName;
    Color genColor;
    IconData genIcon;

    if (birthYear >= 2013) {
      genName = "Gen Alpha";
      genColor = const Color(0xFF9B59B6);
      genIcon = Icons.auto_awesome_rounded;
    } else if (birthYear >= 1997) {
      genName = "Gen Z";
      genColor = const Color(0xFF3498DB);
      genIcon = Icons.bolt_rounded;
    } else if (birthYear >= 1981) {
      genName = "Millennial (Gen Y)";
      genColor = const Color(0xFF2ECC71);
      genIcon = Icons.psychology_rounded;
    } else if (birthYear >= 1965) {
      genName = "Gen X";
      genColor = const Color(0xFFE67E22);
      genIcon = Icons.diamond_rounded;
    } else if (birthYear >= 1946) {
      genName = "Baby Boomer";
      genColor = const Color(0xFFE74C3C);
      genIcon = Icons.workspace_premium_rounded;
    } else {
      genName = "Silent Generation";
      genColor = const Color(0xFF34495E);
      genIcon = Icons.stars_rounded;
    }

    String citizenType;
    Color citizenColor;
    if (years < 18) {
      citizenType = "Minor Citizen";
      citizenColor = const Color(0xFFE67E22);
    } else if (years < 60) {
      citizenType = "Adult Citizen";
      citizenColor = const Color(0xFF27AE60);
    } else {
      citizenType = "Senior Citizen";
      citizenColor = const Color(0xFF8E44AD);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: genColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(genIcon, color: genColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    genName,
                    style: widget.theme.fontDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                  Text(
                    "Born in $birthYear",
                    style: widget.theme.fontDisplay(
                      fontSize: 11,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: citizenColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: citizenColor, width: 1.4),
            ),
            child: Text(
              citizenType,
              style: widget.theme.fontDisplay(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: citizenColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Clean Eligibility Item (No captions, No parentheses, Clean Status) ---
  Widget _buildEligibilityItem({
    required String title,
    required IconData icon,
    required bool isEligible,
  }) {
    final statusColor = isEligible ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: widget.theme.doodleCard(borderWidth: 1.6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEligible
                  ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                  : widget.theme.border.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEligible ? const Color(0xFF27AE60) : widget.theme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: widget.theme.fontDisplay(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEligible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isEligible ? "Eligible" : "Not Eligible",
                  style: widget.theme.fontDisplay(
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
    );
  }

  // --- Compact Stat Items for 2-Line Age Display ---
  Widget _buildCompactStatItem(String value, String label, {bool isLive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedTextPop(
          text: value,
          style: widget.theme.fontDisplay(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isLive ? const Color(0xFF27AE60) : widget.theme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: widget.theme.fontDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.theme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16,
      width: 1.2,
      color: widget.theme.border,
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
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: widget.theme.text,
            ),
          ),
        ],
      ),
    );
  }
}
