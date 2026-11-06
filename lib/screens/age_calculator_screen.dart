import 'dart:async';
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
                                  // Minus button
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _decrementAge,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 18,
                                    tooltip: "Decrease Age",
                                  ),
                                  // Clickable Number Badge (Opens Number Selector Sheet)
                                  InkWell(
                                    onTap: () => _showAgePickerSheet(context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: widget.theme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "$years",
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
                                  // Plus button
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: _incrementAge,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 18,
                                    tooltip: "Increase Age",
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

                  // 3. Live Precision Age Breakdown (Years, Months, Days, Hours, Minutes, Seconds)
                  if (_results != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: widget.theme.doodleCard(
                        color: widget.theme.accent.withValues(alpha: 0.15),
                        borderWidth: 2.5,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF27AE60),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "YOUR CURRENT AGE (LIVE PRECISION)",
                                style: widget.theme.fontMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.text.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Row 1: Years, Months, Days
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBubble("${_results!['years']}", "YEARS"),
                              _buildStatBubble("${_results!['months']}", "MONTHS"),
                              _buildStatBubble("${_results!['days']}", "DAYS"),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Row 2: Hours, Minutes, Seconds (Live Ticking)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBubble("${_results!['hours']}".padLeft(2, '0'), "HOURS"),
                              _buildStatBubble("${_results!['minutes']}".padLeft(2, '0'), "MINUTES"),
                              _buildStatBubble("${_results!['seconds']}".padLeft(2, '0'), "SECONDS", isLive: true),
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
                          // Note: Redundant 18+ tag box removed from here per user request!
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Life Milestone & Century Era Status Card (25yr, 50yr, 75yr, 100yr, 100+, 150+)
                    _buildMilestoneStatusBanner(years),

                    const SizedBox(height: 18),

                    // 5. Legal Eligibility Status Header
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 22),
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
                    const SizedBox(height: 10),

                    // Criteria 1: Legal Adulthood (Full Civic Rights)
                    _buildEligibilityItem(
                      title: "18+ Legal Adulthood",
                      subtitle: "Full civic rights, bank accounts & contracts",
                      icon: Icons.verified_rounded,
                      isEligible: years >= 18,
                      minAge: 18,
                      currentYears: years,
                    ),

                    // Criteria 2: Voting Rights
                    _buildEligibilityItem(
                      title: "Voting Rights (Elections)",
                      subtitle: "Cast vote in parliamentary & local elections",
                      icon: Icons.how_to_vote_rounded,
                      isEligible: years >= 18,
                      minAge: 18,
                      currentYears: years,
                    ),

                    // Criteria 3: Driving License
                    _buildEligibilityItem(
                      title: "Driving License (Motor Vehicles)",
                      subtitle: "Permanent motor vehicle driving license",
                      icon: Icons.directions_car_rounded,
                      isEligible: years >= 18,
                      minAge: 18,
                      currentYears: years,
                    ),

                    // Criteria 4: Legal Marriage
                    _buildEligibilityItem(
                      title: "Marriage (${_gender.toUpperCase()})",
                      subtitle: "Legal marriage age for $_gender ($marriageMinAge+)",
                      icon: Icons.favorite_rounded,
                      isEligible: years >= marriageMinAge,
                      minAge: marriageMinAge,
                      currentYears: years,
                    ),

                    // Criteria 5: Unrestricted Employment
                    _buildEligibilityItem(
                      title: "Full-Time Employment",
                      subtitle: "Unrestricted contractual labor & legal employment",
                      icon: Icons.work_rounded,
                      isEligible: years >= 18,
                      minAge: 18,
                      currentYears: years,
                    ),

                    // Criteria 6: Armed Forces Enlistment (18 to 25 yrs)
                    _buildEligibilityItem(
                      title: "Armed Forces & Military Enlistment",
                      subtitle: "Active service entry window (18 - 25 yrs)",
                      icon: Icons.shield_rounded,
                      isEligible: (years >= 18 && years <= 25),
                      minAge: 18,
                      maxAge: 25,
                      currentYears: years,
                    ),

                    // Criteria 7: Contest MLA / MP (25+ yrs)
                    _buildEligibilityItem(
                      title: "Contest MLA / MP (Lok Sabha)",
                      subtitle: "Right to contest Legislative Assembly & Parliament",
                      icon: Icons.account_balance_rounded,
                      isEligible: years >= 25,
                      minAge: 25,
                      currentYears: years,
                    ),

                    // Criteria 8: Contest Rajya Sabha (30+ yrs)
                    _buildEligibilityItem(
                      title: "Contest Rajya Sabha (Upper House)",
                      subtitle: "Council of States & Legislative Council",
                      icon: Icons.gavel_rounded,
                      isEligible: years >= 30,
                      minAge: 30,
                      currentYears: years,
                    ),

                    // Criteria 9: President / Governor (35+ yrs)
                    _buildEligibilityItem(
                      title: "President / Governor Office",
                      subtitle: "Supreme constitutional head of state office",
                      icon: Icons.stars_rounded,
                      isEligible: years >= 35,
                      minAge: 35,
                      currentYears: years,
                    ),

                    // Criteria 10: Alcohol Purchase & Consumption (21+ yrs)
                    _buildEligibilityItem(
                      title: "Alcohol Purchase & Consumption",
                      subtitle: "Standard legal drinking age limit",
                      icon: Icons.wine_bar_rounded,
                      isEligible: years >= 21,
                      minAge: 21,
                      currentYears: years,
                    ),

                    // Criteria 11: Senior Citizen Benefits (60+ yrs)
                    _buildEligibilityItem(
                      title: "Senior Citizen Welfare & Pension",
                      subtitle: "Tax rebates, transit concessions & elder care",
                      icon: Icons.elderly_rounded,
                      isEligible: years >= 60,
                      minAge: 60,
                      currentYears: years,
                    ),

                    // Criteria 12: Super Senior Citizen Status (80+ yrs)
                    _buildEligibilityItem(
                      title: "Super Senior Citizen Status (80+)",
                      subtitle: "Highest tier medical care & tax exemptions",
                      icon: Icons.health_and_safety_rounded,
                      isEligible: years >= 80,
                      minAge: 80,
                      currentYears: years,
                    ),

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
      child: InkWell(
        onTap: () => _setGender(key),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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

  // --- Milestone Life Stage Banner (25yr, 50yr, 75yr, 100yr, 100+, 150+) ---
  Widget _buildMilestoneStatusBanner(int years) {
    String milestoneTitle;
    String milestoneSubtitle;
    Color milestoneColor;
    IconData milestoneIcon;

    if (years >= 150) {
      milestoneTitle = "IMMORTAL";
      milestoneSubtitle = "👑 Beyond Human Lifespan • Eternal Mythic Being";
      milestoneColor = const Color(0xFF8E44AD);
      milestoneIcon = Icons.all_inclusive_rounded;
    } else if (years > 100) {
      milestoneTitle = "SUPERCENTENARIAN • LIVING LEGEND";
      milestoneSubtitle = "Century Club Elite • 100+ Years Milestone";
      milestoneColor = const Color(0xFFD4AF37);
      milestoneIcon = Icons.workspace_premium_rounded;
    } else if (years == 100) {
      milestoneTitle = "FULL CENTURY COMPLETE!";
      milestoneSubtitle = "Centenarian Milestone (100 Years) 💯";
      milestoneColor = const Color(0xFFF39C12);
      milestoneIcon = Icons.celebration_rounded;
    } else if (years >= 75) {
      milestoneTitle = "PLATINUM MILESTONE (3/4th Century)";
      milestoneSubtitle = "Diamond / Platinum Era • 75+ Years Celebrated 💎";
      milestoneColor = const Color(0xFF00CEC9);
      milestoneIcon = Icons.diamond_rounded;
    } else if (years >= 50) {
      milestoneTitle = "HALF CENTURY (Golden Milestone)";
      milestoneSubtitle = "Golden Jubilee • 50+ Glorious Years Completed ✨";
      milestoneColor = const Color(0xFFE67E22);
      milestoneIcon = Icons.emoji_events_rounded;
    } else if (years >= 25) {
      milestoneTitle = "QUARTER CENTURY (Silver Milestone)";
      milestoneSubtitle = "Silver Jubilee • 25+ Years of Youth & Drive 🥈";
      milestoneColor = const Color(0xFF3498DB);
      milestoneIcon = Icons.shield_rounded;
    } else if (years >= 18) {
      milestoneTitle = "YOUNG ADULT (Prime Youth)";
      milestoneSubtitle = "Legal Adulthood • World of Opportunities Ahead";
      milestoneColor = const Color(0xFF27AE60);
      milestoneIcon = Icons.verified_rounded;
    } else {
      milestoneTitle = "BUDDING YOUTH (Minor)";
      milestoneSubtitle = "Schooling & Growth Years • Under 18";
      milestoneColor = const Color(0xFFE17055);
      milestoneIcon = Icons.child_care_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: milestoneColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: milestoneColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: milestoneColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(milestoneIcon, color: milestoneColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestoneTitle,
                  style: widget.theme.fontDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: milestoneColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestoneSubtitle,
                  style: widget.theme.fontDoodle(
                    fontSize: 12,
                    color: widget.theme.text.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Clean Legal Eligibility Item (Green Tick if eligible, Red/Warning with Right Age if not eligible) ---
  Widget _buildEligibilityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEligible,
    required int minAge,
    int? maxAge,
    required int currentYears,
  }) {
    final statusColor = isEligible ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);

    String rightAgeNote = "";
    if (!isEligible) {
      if (currentYears < minAge) {
        final diff = minAge - currentYears;
        rightAgeNote = "Right Age: $minAge+ Years ($diff year${diff > 1 ? 's' : ''} remaining)";
      } else if (maxAge != null && currentYears > maxAge) {
        rightAgeNote = "Exceeded Upper Limit (Max: $maxAge Years)";
      }
    }

    final double progress = (currentYears / minAge).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: widget.theme.doodleCard(borderWidth: 1.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: widget.theme.fontDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: widget.theme.fontMono(
                        fontSize: 11,
                        color: widget.theme.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Capsule
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

          // If NOT eligible, show the exact right age clearly underneath
          if (!isEligible && rightAgeNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFE74C3C)),
                  const SizedBox(width: 5),
                  Text(
                    rightAgeNote,
                    style: widget.theme.fontMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD63031),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: widget.theme.border.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isEligible ? const Color(0xFF27AE60) : widget.theme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String value, String label, {bool isLive = false}) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isLive ? const Color(0xFF27AE60) : widget.theme.border,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.theme.border.withValues(alpha: 0.3),
                offset: const Offset(2, 3),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: widget.theme.fontDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isLive ? const Color(0xFF27AE60) : widget.theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: widget.theme.fontMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
        ),
      ],
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
