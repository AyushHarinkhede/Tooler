import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// CALENDAR EVENT & NOTE MODEL
/// ---------------------------------------------------------------------------
/// Supports:
/// - One-time & recurring events (yearly, monthly, weekly)
/// - Tags (Birthday, Anniversary, Meeting, Exam, Reminder, Note)
/// - Instructions and details
/// - Notification reminder time
/// - Integration with Tasks checklist
/// ---------------------------------------------------------------------------

class CalendarEventModel {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final String tag; // 'Birthday', 'Anniversary', 'Meeting', 'Exam', 'Reminder', 'Note'
  final String repeat; // 'none', 'yearly', 'monthly', 'weekly'
  final int reminderHour;
  final int reminderMinute;
  final bool addToTasks;
  final bool isCompleted;

  CalendarEventModel({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    this.tag = 'Reminder',
    this.repeat = 'none',
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.addToTasks = true,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'tag': tag,
        'repeat': repeat,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'addToTasks': addToTasks,
        'isCompleted': isCompleted,
      };

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) => CalendarEventModel(
        id: json['id'] as String,
        title: json['title'] as String,
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        tag: json['tag'] as String? ?? 'Reminder',
        repeat: json['repeat'] as String? ?? 'none',
        reminderHour: json['reminderHour'] as int? ?? 9,
        reminderMinute: json['reminderMinute'] as int? ?? 0,
        addToTasks: json['addToTasks'] as bool? ?? true,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  CalendarEventModel copyWith({
    String? title,
    String? note,
    DateTime? date,
    String? tag,
    String? repeat,
    int? reminderHour,
    int? reminderMinute,
    bool? addToTasks,
    bool? isCompleted,
  }) {
    return CalendarEventModel(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      repeat: repeat ?? this.repeat,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      addToTasks: addToTasks ?? this.addToTasks,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool occursOn(DateTime queryDate) {
    if (repeat == 'none') {
      return date.year == queryDate.year && date.month == queryDate.month && date.day == queryDate.day;
    } else if (repeat == 'yearly') {
      return date.month == queryDate.month &&
          date.day == queryDate.day &&
          (queryDate.isAfter(date) || (queryDate.year == date.year && queryDate.month == date.month && queryDate.day == date.day));
    } else if (repeat == 'monthly') {
      return date.day == queryDate.day &&
          (queryDate.isAfter(date) || (queryDate.year == date.year && queryDate.month == date.month && queryDate.day == date.day));
    } else if (repeat == 'weekly') {
      return date.weekday == queryDate.weekday &&
          (queryDate.isAfter(date) || (queryDate.year == date.year && queryDate.month == date.month && queryDate.day == date.day));
    }
    return false;
  }

  IconData get tagIcon {
    switch (tag) {
      case 'Birthday':
        return Icons.cake_rounded;
      case 'Anniversary':
        return Icons.diamond_rounded;
      case 'Meeting':
        return Icons.business_center_rounded;
      case 'Exam':
        return Icons.school_rounded;
      case 'Note':
        return Icons.edit_note_rounded;
      case 'Reminder':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get tagColor {
    switch (tag) {
      case 'Birthday':
        return const Color(0xFFE84393);
      case 'Anniversary':
        return const Color(0xFF9B59B6);
      case 'Meeting':
        return const Color(0xFF2980B9);
      case 'Exam':
        return const Color(0xFFE67E22);
      case 'Note':
        return const Color(0xFF27AE60);
      case 'Reminder':
      default:
        return const Color(0xFFF39C12);
    }
  }
}

/// ---------------------------------------------------------------------------
/// UNIVERSALLY CELEBRATED INTERNATIONAL DAYS (Fixed Annual Worldwide Days Only)
/// ---------------------------------------------------------------------------
class InternationalDay {
  final int month;
  final int day;
  final String title;
  final String description;
  final IconData icon;

  const InternationalDay({
    required this.month,
    required this.day,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const List<InternationalDay> kInternationalDays = [
  // January
  InternationalDay(
    month: 1,
    day: 1,
    title: "Global Family & New Year's Day",
    description: "Worldwide celebration of peace, family unity, and a fresh beginning across all cultures.",
    icon: Icons.celebration_rounded,
  ),
  InternationalDay(
    month: 1,
    day: 24,
    title: "International Day of Education",
    description: "UN day celebrating the fundamental human right to education for peace and development.",
    icon: Icons.school_rounded,
  ),
  InternationalDay(
    month: 1,
    day: 27,
    title: "International Holocaust Remembrance Day",
    description: "Global day of solemn commemoration honoring the victims of the Holocaust.",
    icon: Icons.brightness_medium_rounded,
  ),

  // February
  InternationalDay(
    month: 2,
    day: 4,
    title: "World Cancer Day",
    description: "Global initiative uniting the world to raise cancer awareness, prevention, and treatment.",
    icon: Icons.favorite_rounded,
  ),
  InternationalDay(
    month: 2,
    day: 11,
    title: "International Day of Women & Girls in Science",
    description: "Recognizing and empowering the vital role of women and girls in scientific breakthroughs.",
    icon: Icons.science_rounded,
  ),
  InternationalDay(
    month: 2,
    day: 13,
    title: "World Radio Day",
    description: "Celebrating radio as an enduring, democratic medium of global communication and music.",
    icon: Icons.radio_rounded,
  ),
  InternationalDay(
    month: 2,
    day: 14,
    title: "International Book Giving Day",
    description: "Worldwide volunteer initiative dedicated to getting books into the hands of children and readers.",
    icon: Icons.menu_book_rounded,
  ),
  InternationalDay(
    month: 2,
    day: 20,
    title: "World Day of Social Justice",
    description: "UN observance promoting poverty eradication, dignified employment, and gender equality.",
    icon: Icons.balance_rounded,
  ),
  InternationalDay(
    month: 2,
    day: 21,
    title: "International Mother Language Day",
    description: "UNESCO observance promoting linguistic diversity, multilingualism, and cultural preservation.",
    icon: Icons.translate_rounded,
  ),

  // March
  InternationalDay(
    month: 3,
    day: 3,
    title: "World Wildlife Day",
    description: "Celebrating the beauty of wild animals and plants and raising awareness of urgent conservation.",
    icon: Icons.pets_rounded,
  ),
  InternationalDay(
    month: 3,
    day: 8,
    title: "International Women's Day",
    description: "Worldwide celebration of the social, economic, cultural, and scientific achievements of women.",
    icon: Icons.female_rounded,
  ),
  InternationalDay(
    month: 3,
    day: 14,
    title: "International Day of Mathematics",
    description: "Global celebration of the beauty, power, and universal language of mathematics (Pi Day).",
    icon: Icons.calculate_rounded,
  ),
  InternationalDay(
    month: 3,
    day: 20,
    title: "International Day of Happiness",
    description: "UN day recognizing happiness, wellbeing, and kindness as universal human aspirations.",
    icon: Icons.sentiment_very_satisfied_rounded,
  ),
  InternationalDay(
    month: 3,
    day: 21,
    title: "International Day of Forests & Poetry",
    description: "Raising awareness of the vital role of woodlands and the linguistic expression of poetry.",
    icon: Icons.park_rounded,
  ),
  InternationalDay(
    month: 3,
    day: 22,
    title: "World Water Day",
    description: "UN day highlighting the critical importance of freshwater and advocating sustainable water management.",
    icon: Icons.water_drop_rounded,
  ),
  InternationalDay(
    month: 3,
    day: 23,
    title: "World Meteorological Day",
    description: "Observing weather patterns, global climate resilience, and Earth's atmospheric balance.",
    icon: Icons.wb_sunny_rounded,
  ),

  // April
  InternationalDay(
    month: 4,
    day: 7,
    title: "World Health Day",
    description: "WHO global health awareness day focusing attention on universal healthcare for everyone, everywhere.",
    icon: Icons.health_and_safety_rounded,
  ),
  InternationalDay(
    month: 4,
    day: 12,
    title: "International Day of Human Space Flight",
    description: "Celebrating the dawn of the space exploration era for peaceful advancement of mankind.",
    icon: Icons.rocket_launch_rounded,
  ),
  InternationalDay(
    month: 4,
    day: 22,
    title: "International Earth Day",
    description: "Worldwide demonstration of environmental protection, climate action, and ecological conservation.",
    icon: Icons.public_rounded,
  ),
  InternationalDay(
    month: 4,
    day: 23,
    title: "World Book & Copyright Day",
    description: "UNESCO celebration of authors, books, reading culture, and intellectual property.",
    icon: Icons.auto_stories_rounded,
  ),

  // May
  InternationalDay(
    month: 5,
    day: 1,
    title: "International Workers' Day",
    description: "Worldwide observance honoring the historic struggles, solidarity, and contributions of labor.",
    icon: Icons.engineering_rounded,
  ),
  InternationalDay(
    month: 5,
    day: 3,
    title: "World Press Freedom Day",
    description: "UN day defending free, independent, and pluralistic journalism across all countries.",
    icon: Icons.newspaper_rounded,
  ),
  InternationalDay(
    month: 5,
    day: 15,
    title: "International Day of Families",
    description: "Recognizing the essential social, economic, and emotional support of families worldwide.",
    icon: Icons.family_restroom_rounded,
  ),
  InternationalDay(
    month: 5,
    day: 21,
    title: "World Day for Cultural Diversity",
    description: "UNESCO day fostering intercultural dialogue, peace, harmony, and mutual respect.",
    icon: Icons.diversity_3_rounded,
  ),
  InternationalDay(
    month: 5,
    day: 22,
    title: "International Day for Biological Diversity",
    description: "Advocating the preservation of the Earth's intricate variety of life and ecosystems.",
    icon: Icons.nature_people_rounded,
  ),
  InternationalDay(
    month: 5,
    day: 31,
    title: "World No Tobacco Day",
    description: "WHO global health initiative spotlighting the risks of tobacco and advocating clean air.",
    icon: Icons.smoke_free_rounded,
  ),

  // June
  InternationalDay(
    month: 6,
    day: 3,
    title: "World Bicycle Day",
    description: "UN day celebrating the sustainable, healthy, and clean transport power of the bicycle.",
    icon: Icons.directions_bike_rounded,
  ),
  InternationalDay(
    month: 6,
    day: 5,
    title: "World Environment Day",
    description: "UN flagship platform rallying millions across the globe for environmental action and planet restoration.",
    icon: Icons.eco_rounded,
  ),
  InternationalDay(
    month: 6,
    day: 8,
    title: "World Oceans Day",
    description: "Highlighting the vital role of the ocean in regulating climate and sustaining life on Earth.",
    icon: Icons.waves_rounded,
  ),
  InternationalDay(
    month: 6,
    day: 14,
    title: "World Blood Donor Day",
    description: "Expressing heartfelt gratitude to voluntary, unpaid blood donors who save human lives.",
    icon: Icons.bloodtype_rounded,
  ),
  InternationalDay(
    month: 6,
    day: 21,
    title: "International Day of Yoga & World Music Day",
    description: "Celebrating holistic mindfulness, physical wellbeing, and the universal melody of music.",
    icon: Icons.self_improvement_rounded,
  ),
  InternationalDay(
    month: 6,
    day: 23,
    title: "International Olympic Day",
    description: "Promoting physical fitness, sportsmanship, and fair play without boundaries.",
    icon: Icons.fitness_center_rounded,
  ),
  InternationalDay(
    month: 6,
    day: 30,
    title: "International Asteroid Day",
    description: "UN-sanctioned day dedicated to asteroid science, space awareness, and planetary defense.",
    icon: Icons.satellite_alt_rounded,
  ),

  // July
  InternationalDay(
    month: 7,
    day: 11,
    title: "World Population Day",
    description: "UN day focusing attention on the urgency and importance of sustainable population dynamics.",
    icon: Icons.groups_rounded,
  ),
  InternationalDay(
    month: 7,
    day: 15,
    title: "World Youth Skills Day",
    description: "Equipping young people with technical, vocational, and digital skills for economic empowerment.",
    icon: Icons.construction_rounded,
  ),
  InternationalDay(
    month: 7,
    day: 20,
    title: "International Chess Day",
    description: "Celebrating chess as one of humanity's most ancient, strategic, and intellectual games.",
    icon: Icons.sports_esports_rounded,
  ),
  InternationalDay(
    month: 7,
    day: 30,
    title: "International Day of Friendship",
    description: "UN day inspiring peace efforts and building bridges between people, countries, and cultures.",
    icon: Icons.handshake_rounded,
  ),

  // August
  InternationalDay(
    month: 8,
    day: 12,
    title: "International Youth Day",
    description: "Celebrating the vibrant energy, innovation, and leadership of young leaders worldwide.",
    icon: Icons.bolt_rounded,
  ),
  InternationalDay(
    month: 8,
    day: 19,
    title: "World Humanitarian Day",
    description: "Honoring brave humanitarian aid workers who provide life-saving assistance in global crises.",
    icon: Icons.volunteer_activism_rounded,
  ),

  // September
  InternationalDay(
    month: 9,
    day: 8,
    title: "International Literacy Day",
    description: "UNESCO day underscoring literacy as an essential pillar of human dignity and societal growth.",
    icon: Icons.menu_book_rounded,
  ),
  InternationalDay(
    month: 9,
    day: 15,
    title: "International Day of Democracy",
    description: "UN day encouraging participatory, accountable, and transparent governance worldwide.",
    icon: Icons.how_to_vote_rounded,
  ),
  InternationalDay(
    month: 9,
    day: 16,
    title: "International Day for the Preservation of the Ozone Layer",
    description: "Commemorating the landmark Montreal Protocol protecting the atmospheric ozone shield.",
    icon: Icons.shield_rounded,
  ),
  InternationalDay(
    month: 9,
    day: 21,
    title: "International Day of Peace",
    description: "UN global observance devoted to strengthening the ideals of peace, ceasefire, and non-violence.",
    icon: Icons.spa_rounded,
  ),
  InternationalDay(
    month: 9,
    day: 27,
    title: "World Tourism Day",
    description: "Highlighting the cultural, economic, and social significance of responsible global travel.",
    icon: Icons.flight_takeoff_rounded,
  ),

  // October
  InternationalDay(
    month: 10,
    day: 1,
    title: "International Day of Older Persons",
    description: "UN day appreciating the lifelong wisdom, mentorship, and contributions of senior citizens.",
    icon: Icons.elderly_rounded,
  ),
  InternationalDay(
    month: 10,
    day: 4,
    title: "World Animal Day",
    description: "Global mission for animal rights, ethical welfare, and compassionate protection.",
    icon: Icons.pets_rounded,
  ),
  InternationalDay(
    month: 10,
    day: 5,
    title: "World Teachers' Day",
    description: "UNESCO day expressing gratitude to educators who shape minds and inspire generations.",
    icon: Icons.psychology_rounded,
  ),
  InternationalDay(
    month: 10,
    day: 11,
    title: "International Day of the Girl Child",
    description: "Advocating for girls' rights, education, digital inclusion, and freedom from discrimination.",
    icon: Icons.star_rounded,
  ),
  InternationalDay(
    month: 10,
    day: 16,
    title: "World Food Day",
    description: "FAO observance promoting sustainable food systems, balanced nutrition, and zero world hunger.",
    icon: Icons.restaurant_rounded,
  ),
  InternationalDay(
    month: 10,
    day: 24,
    title: "United Nations Day",
    description: "Commemorating the founding of the UN Charter and multilateral collaboration for humanity.",
    icon: Icons.flag_rounded,
  ),

  // November
  InternationalDay(
    month: 11,
    day: 10,
    title: "World Science Day for Peace and Development",
    description: "Highlighting the critical role of science in society and advancing peaceful technological progress.",
    icon: Icons.science_rounded,
  ),
  InternationalDay(
    month: 11,
    day: 13,
    title: "World Kindness Day",
    description: "Promoting empathy, common goodwill, and positive acts of kindness across communities.",
    icon: Icons.favorite_border_rounded,
  ),
  InternationalDay(
    month: 11,
    day: 16,
    title: "International Day for Tolerance",
    description: "UNESCO observance fostering mutual respect, open-minded dialogue, and human dignity.",
    icon: Icons.diversity_1_rounded,
  ),
  InternationalDay(
    month: 11,
    day: 20,
    title: "World Children's Day",
    description: "UN day advocating for children's safety, creative development, and equal opportunities.",
    icon: Icons.child_care_rounded,
  ),
  InternationalDay(
    month: 11,
    day: 21,
    title: "World Television Day",
    description: "Recognizing the impact of broadcast television in educating and connecting worldwide audiences.",
    icon: Icons.tv_rounded,
  ),

  // December
  InternationalDay(
    month: 12,
    day: 1,
    title: "World AIDS Day",
    description: "Global solidarity in supporting people living with HIV and advancing global public health.",
    icon: Icons.healing_rounded,
  ),
  InternationalDay(
    month: 12,
    day: 3,
    title: "International Day of Persons with Disabilities",
    description: "Advocating for accessibility, dignity, and full inclusion of persons with disabilities.",
    icon: Icons.accessible_rounded,
  ),
  InternationalDay(
    month: 12,
    day: 5,
    title: "World Soil Day",
    description: "Focusing attention on healthy soil, ecological balance, and sustainable food production.",
    icon: Icons.grass_rounded,
  ),
  InternationalDay(
    month: 12,
    day: 10,
    title: "Human Rights Day",
    description: "Commemorating the historic Universal Declaration of Human Rights and inalienable freedoms.",
    icon: Icons.gavel_rounded,
  ),
  InternationalDay(
    month: 12,
    day: 18,
    title: "International Migrants Day",
    description: "Acknowledging the resilience and essential economic contributions of migrants worldwide.",
    icon: Icons.travel_explore_rounded,
  ),
  InternationalDay(
    month: 12,
    day: 20,
    title: "International Human Solidarity Day",
    description: "Celebrating global unity in diversity and joint multilateral action against poverty.",
    icon: Icons.handshake_rounded,
  ),
  InternationalDay(
    month: 12,
    day: 25,
    title: "Global Festive Day",
    description: "Universal celebration of goodwill, generosity, peace, and festive cheer across the world.",
    icon: Icons.card_giftcard_rounded,
  ),
];
