import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/minimal_2d_illustrations.dart';
import '../widgets_3d/tooler_character.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
import '../widgets_3d/bouncy_tap.dart';
import 'calculator_screen.dart';
import 'age_calculator_screen.dart';
import 'converters_screen.dart';
import 'stopwatch_screen.dart';
import 'timer_screen.dart';
import 'sizer_screen.dart';
import 'counters_screen.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'currency_screen.dart';
import 'games_screen.dart';
import 'browser_screen.dart';
import 'compass_screen.dart';
import 'password_generator_screen.dart';
import 'sound_recorder_screen.dart';
import 'character_illustrations_screen.dart';
import 'settings_screen.dart';

/// ---------------------------------------------------------------------------
/// TOOLER MINIMAL HOME (Images 1 & 2 Match)
/// - Bottom Nav Bar REMOVED completely (clean edge-to-edge scroll)
/// - Full-color Pastel Header background with 2D Hanging Lamp, Curly Cord & Plant
/// - Every tool opens in a Pop-up Hover Page (ToolerHoverSheet)
/// - Modern Search Bar with instant filtering and clear action
/// - Clean 2x2 Category Grid + Filter Chips
/// - Sound and Haptic feedback on every tap
/// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  final StationeryTheme theme;
  final Function(StationeryThemeMode mode) onThemeChanged;

  const HomeScreen({
    super.key,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearchFocused = false;
  ToolerCharacterPose _heroPose = ToolerCharacterPose.workingLaptop;

  void _cycleHeroPose() {
    final nextIdx = (_heroPose.index + 1) % ToolerCharacterPose.values.length;
    setState(() {
      _heroPose = ToolerCharacterPose.values[nextIdx];
    });
  }

  late final List<Map<String, dynamic>> _tools;
  List<String> _favoriteToolTitles = [];

  final List<String> _categories = [
    'All',
    'Calculate',
    'Convert',
    'Time & Tasks',
    'Utilities',
  ];

  @override
  void initState() {
    super.initState();
    _initTools();
    _loadFavorites();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  Future<void> _loadFavorites() async {
    final favs = await StorageService().loadFavorites();
    if (mounted) {
      setState(() {
        _favoriteToolTitles = favs;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initTools() {
    _tools = [
      {
        'id': 'calc',
        'title': 'Calculator',
        'subtitle': 'Basic, Scientific & Programmer Modes',
        'category': 'Calculate',
        'tag': 'Precision',
        'iconType': 'calc',
        'isFeatured': true,
        'features': [
          {'name': 'Programmer Mode', 'desc': 'BIN, HEX, DEC, OCT conversions, 8/16/32/64-bit word sizes & bitwise operations (AND, OR, XOR, NOT, LSH, RSH, MOD)'},
          {'name': 'Scientific Functions', 'desc': 'Trigonometry (sin, cos, tan, asin, acos, atan), log, ln, sqrt, powers & pi/e constants'},
          {'name': 'Live Digital Clock', 'desc': 'Hold C button for 2-3 seconds to transform screen into live digital clock'},
          {'name': 'Easter Eggs & Logic', 'desc': 'Thala #7 for a reason, Nothing 0, Never Settle 1+, Ask your ChatBot on 0/0 and errors'},
          {'name': 'Keyboard Shortcuts', 'desc': 'Full physical keyboard input (0-9, operators, Enter for answer, Backspace, ESC)'},
          {'name': 'Basic Arithmetic', 'desc': 'Animated digit expressions with smooth pop-up answer resizing'},
        ],
        'keywords': [
          'calculator', 'calc', 'basic', 'scientific', 'programmer', 'prog',
          'binary', 'bin', 'hex', 'hexadecimal', 'octal', 'oct', 'dec', 'decimal',
          'bitwise', 'and', 'or', 'xor', 'not', 'lsh', 'rsh', 'mod',
          'qword', 'dword', 'word', 'byte', '64-bit', '32-bit', '16-bit', '8-bit',
          'trigonometry', 'trig', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
          'sqrt', 'root', 'square root', 'cube', 'power', 'log', 'ln', 'pi', 'e',
          'easter egg', 'thala', 'thala for a reason', '7', 'nothing', '0',
          'never settle', '1+', '67', '911', '404', '0xdeadbeef', '0xcafebabe',
          'clock', 'digital clock', 'real time clock', 'hold c', 'shortcuts',
          'esc', 'backspace', 'enter', 'ask your chatbot', 'error', 'math', 'ganit', 'hisaab',
        ],
        'builder': (context) => CalculatorScreen(theme: widget.theme),
      },
      {
        'id': 'converters',
        'title': 'Unit Converters',
        'subtitle': 'Length, Mass, Speed, Data, Temp, Area, Vol',
        'category': 'Convert',
        'tag': 'Multi-unit',
        'iconType': 'converters',
        'isFeatured': true,
        'features': [
          {'name': 'Length & Distance', 'desc': 'Meter, kilometer, centimeter, millimeter, inch, foot, yard, mile'},
          {'name': 'Mass & Weight', 'desc': 'Kilogram, gram, milligram, pound (lbs), ounce (oz), metric ton, quintal'},
          {'name': 'Temperature', 'desc': 'Celsius (°C), Fahrenheit (°F), Kelvin (K), Rankine (°R), Réaumur (°Re)'},
          {'name': 'Digital Data Storage', 'desc': 'Bytes, Kilobytes (KB), Megabytes (MB), Gigabytes (GB), Terabytes (TB), Petabytes (PB)'},
          {'name': 'Speed & Velocity', 'desc': 'Kilometers per hour (km/h), miles per hour (mph), meters per second (m/s), knots'},
          {'name': 'Area & Land Measurement', 'desc': 'Square meter, square kilometer, acre, hectare, square foot, square yard'},
          {'name': 'Volume & Liquid', 'desc': 'Liter, milliliter, cubic meter, US gallon, imperial gallon, fluid ounce'},
        ],
        'keywords': [
          'unit converters', 'converters', 'converter', 'length', 'distance',
          'meter', 'metre', 'kilometer', 'km', 'centimeter', 'cm', 'millimeter', 'mm',
          'inch', 'inches', 'foot', 'feet', 'yard', 'mile',
          'mass', 'weight', 'kilogram', 'kg', 'gram', 'g', 'milligram', 'mg',
          'pound', 'lbs', 'ounce', 'oz', 'ton', 'tonne', 'quintal',
          'temperature', 'temp', 'celsius', 'fahrenheit', 'kelvin', 'rankine', 'reaumur', 'heat',
          'speed', 'velocity', 'kmh', 'mph', 'knot',
          'data', 'storage', 'byte', 'kb', 'mb', 'gb', 'tb', 'pb', 'gigabyte', 'megabyte', 'terabyte',
          'area', 'acre', 'hectare', 'sqft',
          'volume', 'liter', 'litre', 'ml', 'gallon', 'pint', 'conversion', 'naap', 'badalna',
        ],
        'builder': (context) => ConvertersScreen(theme: widget.theme),
      },
      {
        'id': 'compass',
        'title': 'Digital Compass',
        'subtitle': 'Real-time gyro, magnetic heading & spirit level',
        'category': 'Utilities',
        'tag': 'Live Sensor',
        'iconType': 'compass',
        'isFeatured': true,
        'features': [
          {'name': 'Digital Magnetic Compass', 'desc': 'Real-time azimuth degrees, cardinal headings (N, NE, E, SE, S, SW, W, NW)'},
          {'name': 'Spirit Bubble Leveler', 'desc': 'Surface leveling with dual circular bubble gauge, pitch & roll tilt angles'},
          {'name': 'Inclinometer & Angle Gauge', 'desc': 'Precision tilt measurement in degrees for horizontal & vertical surfaces'},
          {'name': 'Live Sensor Calibration', 'desc': 'Real-time magnetometer and gyroscope hardware sensor integration'},
        ],
        'keywords': [
          'compass', 'digital compass', 'spirit level', 'bubble level', 'leveler',
          'surface level', 'gyro', 'gyroscope', 'azimuth', 'heading', 'degrees',
          'north', 'south', 'east', 'west', 'pitch', 'roll', 'tilt', 'inclinometer',
          'angle', 'horizontal level', 'vertical level', 'sensor', 'magnetometer',
          'magnetic field', 'calibration', 'disha', 'diksudhar',
        ],
        'builder': (context) => CompassScreen(theme: widget.theme),
      },
      {
        'id': 'age',
        'title': 'Age Calculator',
        'subtitle': 'Live precision clock, milestones & legal eligibility',
        'category': 'Calculate',
        'tag': 'Date Math',
        'iconType': 'age',
        'isFeatured': false,
        'features': [
          {'name': 'Live Precision Age Clock', 'desc': 'Real-time ticker showing exact Years, Months, Days, Hours, Minutes, and Seconds'},
          {'name': 'Direct Age Selector', 'desc': 'Tap [-] and [+] or tap number to pick direct age (0-160+ years) with zero typing'},
          {'name': 'Gender Identity Themes', 'desc': 'Distinct Male Blue (#2980B9), Female Pink (#E84393), and Other Red (#E74C3C) color highlights'},
          {'name': 'Life Milestone & Era Badges', 'desc': '25yr Silver, 50yr Golden, 75yr Platinum, 100yr Full Century, 100+ Supercentenarian, 150+ IMMORTAL'},
          {'name': 'Legal Eligibility Checklist', 'desc': 'Voting rights (18+), Driving License (18+), Marriage Age (21+), Employment (18+), Military Enlistment (17.5+), MLA/MP (25+), Rajya Sabha (30+), President/Governor (35+), Alcohol Age (21+), Senior Citizen (60+), Super Senior (80+)'},
          {'name': 'Next Birthday Countdown', 'desc': 'Days, hours, minutes until your next birthday celebration'},
        ],
        'keywords': [
          'age calculator', 'age', 'birthday', 'birth date', 'dob', 'years', 'months', 'days',
          'hours', 'minutes', 'seconds', 'live age', 'precision clock', 'direct age selector',
          'stepper', 'slider', 'number selector', 'legal eligibility', 'criteria',
          'voting rights', 'vote', '18+', 'driving license', 'driver license', 'marriage age',
          'marriage', '21+', 'employment', 'full time job', 'military enlistment', 'armed forces',
          'army', 'mla', 'mp', 'member of parliament', 'rajya sabha', 'president', 'governor',
          'alcohol age', 'senior citizen', 'super senior citizen', 'milestone', 'era',
          'half century', 'full century', '25yr silver jubilee', '50yr golden jubilee',
          '75yr platinum', '100yr century', 'supercentenarian', '100+', '150+', 'immortal',
          'male blue', 'female pink', 'other red', 'gender', 'next birthday countdown',
          'janamdin', 'aayu', 'umar',
        ],
        'builder': (context) => AgeCalculatorScreen(theme: widget.theme),
      },
      {
        'id': 'stopwatch',
        'title': 'Stopwatch',
        'subtitle': 'Split laps, millisecond timer',
        'category': 'Time & Tasks',
        'tag': 'Accurate',
        'iconType': 'stopwatch',
        'isFeatured': false,
        'features': [
          {'name': 'Millisecond Precision Timer', 'desc': 'Accurate split-second stopwatch with smooth ticking display'},
          {'name': 'Split Lap Recording', 'desc': 'Record unlimited laps with instant lap delta calculations'},
          {'name': 'Lap History & Highlights', 'desc': 'Color-coded fastest and slowest lap comparisons'},
        ],
        'keywords': [
          'stopwatch', 'split lap', 'lap timer', 'laps', 'millisecond timer',
          'precision timer', 'accurate timer', 'lap history', 'chronometer',
          'workout timer', 'race timer', 'sports timer', 'running', 'timer', 'samay',
        ],
        'builder': (context) => StopwatchScreen(theme: widget.theme),
      },
      {
        'id': 'timer',
        'title': 'Timer',
        'subtitle': 'Preset countdowns & circular progress',
        'category': 'Time & Tasks',
        'tag': 'Background',
        'iconType': 'timer',
        'isFeatured': false,
        'features': [
          {'name': 'Preset Countdowns', 'desc': 'Quick one-tap presets for 1m, 5m, 15m, 25m Pomodoro, 45m & 60m'},
          {'name': 'Custom Duration Picker', 'desc': 'Flexible hours, minutes, and seconds countdown selector'},
          {'name': 'Circular Progress Ring', 'desc': 'Visual countdown ring with remaining time animation and completion chime'},
        ],
        'keywords': [
          'timer', 'countdown', 'countdown timer', 'preset timers', 'pomodoro',
          'focus timer', 'study timer', 'work timer', 'kitchen timer', 'circular progress',
          'alarm', 'alert', 'interval timer', 'background timer',
        ],
        'builder': (context) => TimerScreen(theme: widget.theme),
      },
      {
        'id': 'sizer',
        'title': 'Sizer & Caliper',
        'subtitle': 'Ring, Bangle, Watch Strap & Edge/Scrollable Ruler',
        'category': 'Convert',
        'tag': 'Screen Scale',
        'iconType': 'sizer',
        'isFeatured': false,
        'features': [
          {'name': 'Ring Sizer Circle', 'desc': 'Place physical ring on screen circle (14.0–24.5mm); numbers outside circle; tape formula C = D × 3.1416'},
          {'name': 'Bangle Sizer Circle', 'desc': 'Place bangle on screen circle (sizes 2-2 to 3-0); knuckle tape formula D = Knuckle / 3.1416'},
          {'name': 'Watch Strap Caliper', 'desc': 'Vector leather strap visualizer with stitching & buckle; 12–26mm lug width caliper'},
          {'name': 'Flush Screen Edge Ruler', 'desc': 'True 1:1 ruler flush with physical phone device edge for quick measurements'},
          {'name': 'Full Screen Scrollable Ruler', 'desc': 'Full-screen scrollable tape up to 320cm+ (3.2m / 126 in) with mm/cm/inch scales & interactive pin point drop markers'},
        ],
        'keywords': [
          'sizer', 'caliper', 'ruler', 'ring sizer', 'ring size', 'ring',
          'hollow circle', 'ring diameter', 'ring circumference', 'ring formula',
          '6.1*3.140', 'c = d * 3.1416', 'finger size', 'bangle sizer', 'bangle size',
          'bangle', 'kangan', 'kada', 'bangle diameter', 'knuckle tape formula',
          'watch strap', 'strap', 'strap size', 'lug width', 'strap visualizer',
          'leather strap', 'buckle', 'stitching', 'phone edge ruler', 'flush ruler',
          'edge ruler', 'full screen ruler', 'scrollable ruler', 'scroll ruler',
          'tape measure', '100cm', '200cm', '300cm', '320cm', 'meter banner',
          'inch scale', 'millimeter', 'mm', 'centimeter', 'cm', 'meter', 'inch',
          'pin point', 'drop pin', 'checkpoint', 'screen calibration', 'naap', 'scale', 'paimana',
        ],
        'builder': (context) => SizerScreen(theme: widget.theme),
      },
      {
        'id': 'counters',
        'title': 'Tally Counters',
        'subtitle': 'Multi-counter tracking with step counts',
        'category': 'Calculate',
        'tag': 'Persistent',
        'iconType': 'counters',
        'isFeatured': false,
        'features': [
          {'name': 'Multi-Counter System', 'desc': 'Create and manage multiple named tally counters simultaneously'},
          {'name': 'Custom Step Increments', 'desc': 'Tap +1, +5, +10 or custom step values with haptic clicks'},
          {'name': 'Persistent Local Storage', 'desc': 'Counts automatically saved and preserved across app sessions'},
        ],
        'keywords': [
          'tally counters', 'tally counter', 'counter', 'clicker', 'multi counter',
          'step counter', 'tasbeeh', 'mantra counter', 'attendance counter', 'lap counter',
          'persistent count', 'counting', 'ginti', 'ginna',
        ],
        'builder': (context) => CountersScreen(theme: widget.theme),
      },
      {
        'id': 'tasks',
        'title': 'Tasks & Notes',
        'subtitle': 'Clean checklist & quick daily memo',
        'category': 'Time & Tasks',
        'tag': 'Checklist',
        'iconType': 'tasks',
        'isFeatured': false,
        'features': [
          {'name': 'Clean Checklist', 'desc': 'Add, complete, and organize daily tasks with strike-through animations'},
          {'name': 'Daily Quick Memo', 'desc': 'Fast scratchpad notes with timestamped entries'},
          {'name': 'Active & Completed Filters', 'desc': 'Easily filter completed items or clear finished tasks'},
        ],
        'keywords': [
          'tasks', 'notes', 'todo', 'to-do', 'checklist', 'daily memo',
          'task organizer', 'memo', 'quick notes', 'scratchpad', 'completed tasks',
          'productivity', 'planner', 'reminders', 'suchi', 'kaam',
        ],
        'builder': (context) => TasksScreen(theme: widget.theme),
      },
      {
        'id': 'calendar',
        'title': 'Calendar & Observances',
        'subtitle': 'International days, swipe navigation & reminders',
        'category': 'Time & Tasks',
        'tag': 'Global & Personal',
        'iconType': 'calendar',
        'isFeatured': true,
        'features': [
          {'name': 'Horizontal Month Swipe', 'desc': 'Slide smoothly between months with exact mathematical weekday alignment'},
          {'name': 'Pure Red Sundays', 'desc': 'All Sunday dates rendered in striking pure red typography matching calendar conventions'},
          {'name': 'Universal Celebration Days', 'desc': 'Fixed annual worldwide international days with vector icons & themed containers'},
          {'name': 'Personal Event & Note Reminders', 'desc': 'Add birthdays, anniversaries, meetings with alarm notifications and repeat cycles'},
          {'name': 'Annual & Monthly Recurrence', 'desc': 'Configurable repeat rules (yearly, monthly, weekly) for recurring events'},
          {'name': 'Tasks Checklist Synchronization', 'desc': 'Personal calendar events automatically sync with your Tasks & Notes checklist'},
        ],
        'keywords': [
          'calendar', 'calender', 'date', 'month', 'year', 'swipe calendar', 'horizontal swipe',
          'sunday', 'pure red sunday', 'red sunday', 'international days', 'world days', 'un days',
          'celebration', 'observance', 'birthday', 'anniversary', 'reminder', 'personal note',
          'instruction', 'repeat', 'annual reminder', 'monthly reminder', 'task sync', 'schedule',
          'panchang', 'tarikh', 'mahina', 'sal', 'din', 'event reminder',
        ],
        'builder': (context) => CalendarScreen(theme: widget.theme),
      },
      {
        'id': 'currency',
        'title': 'Currency Converter',
        'subtitle': 'Live forex rates, vector symbols & last updated',
        'category': 'Convert',
        'tag': 'Forex',
        'iconType': 'currency',
        'isFeatured': false,
        'features': [
          {'name': 'Real-Time Forex API', 'desc': 'Live exchange rates automatically synced when device has active internet'},
          {'name': 'Last Updated Timestamp', 'desc': 'Clean small font timestamp displaying exact last sync time & date'},
          {'name': 'Currency Names & SVG Symbols', 'desc': 'Full currency names with stylized vector SVG symbols (\$, ₹, €, £, ¥, ₩)'},
          {'name': 'Global Currency Exchange', 'desc': 'USD, INR, EUR, GBP, JPY, AUD, CAD, CNY, SGD, CHF, AED & 30+ currencies'},
        ],
        'keywords': [
          'currency converter', 'currency', 'forex', 'exchange rate', 'foreign exchange',
          'live rate', 'real time currency', 'real time exchange', 'forex api', 'last updated',
          'currency name', 'currency sign', 'svg symbol', 'usd', 'dollar', 'inr', 'rupee',
          'eur', 'euro', 'gbp', 'pound', 'jpy', 'yen', 'aud', 'cad', 'cny', 'sgd',
          'chf', 'aed', 'dirham', 'money', 'cash', 'rate', 'money converter', 'paisa', 'mudra',
        ],
        'builder': (context) => CurrencyScreen(theme: widget.theme),
      },
      {
        'id': 'password',
        'title': 'Password Generator',
        'subtitle': 'Cryptographic entropy & custom rules',
        'category': 'Utilities',
        'tag': 'Security',
        'iconType': 'password',
        'isFeatured': false,
        'features': [
          {'name': 'Cryptographic Random Generator', 'desc': 'High-entropy secure password generation using CSPRNG'},
          {'name': 'Custom Rule Sliders', 'desc': 'Configure uppercase, lowercase, numbers, special symbols & length (4-64 chars)'},
          {'name': 'Password Strength Meter', 'desc': 'Real-time bit-entropy evaluation and visual strength bar'},
          {'name': 'One-Tap Secure Copy', 'desc': 'Instant clipboard copy with safety clearing'},
        ],
        'keywords': [
          'password generator', 'password', 'secure password', 'random password',
          'security', 'cryptographic entropy', 'entropy', 'pin generator', 'strong password',
          'custom rules', 'symbols', 'digits', 'copy password', 'credentials', 'passcode',
          'suraksha', 'chabhi',
        ],
        'builder': (context) => PasswordGeneratorScreen(theme: widget.theme),
      },
      {
        'id': 'browser',
        'title': 'Mini Browser',
        'subtitle': 'Clean web search & direct media downloader',
        'category': 'Utilities',
        'tag': 'Web Utility',
        'iconType': 'browser',
        'isFeatured': false,
        'features': [
          {'name': 'Direct Web Search', 'desc': 'Minimal address bar without clutter or pre-suggestions; instantly navigates to query or URL'},
          {'name': 'Web Media Downloader', 'desc': 'Automatic top bar download button to save images and videos from any website directly to device files'},
          {'name': 'Fast Lightweight WebView', 'desc': 'Zero-bloat browser with back, forward, refresh, secure lock & clean tabs'},
          {'name': 'Private Browsing', 'desc': 'Fast incognito web exploration with privacy and zero ad tracking'},
        ],
        'keywords': [
          'mini browser', 'browser', 'web search', 'search web', 'web', 'internet',
          'url', 'search engine', 'duckduckgo', 'google', 'download video', 'download image',
          'video downloader', 'image downloader', 'media downloader', 'download button',
          'save to device', 'save to files', 'save image', 'save video', 'clean browser',
          'no suggestions', 'private browsing', 'incognito', 'webview', 'surf', 'net',
        ],
        'builder': (context) => BrowserScreen(theme: widget.theme),
      },
      {
        'id': 'games',
        'title': 'Game',
        'subtitle': 'Ludo, UNO, Snake & Ladder, Tic-Tac-Toe, Tetris & Snake',
        'category': 'Utilities',
        'tag': 'Arcade & Board',
        'iconType': 'games',
        'isFeatured': false,
        'features': [
          {'name': 'Ludo Board Game', 'desc': 'Classic board game with animated token movement paths, animated dice roll & multi-color pawns'},
          {'name': 'UNO Card Game', 'desc': 'Full card deck with animated card drops, draw 2, draw 4, skip, reverse & opponent animations'},
          {'name': 'Snake & Ladder', 'desc': 'Realistic SVG snakes with defined mouths & tails, authentic step ladders, and animated piece movement'},
          {'name': 'Tic-Tac-Toe', 'desc': 'Clean 3x3 grid with win/lose/draw modal popups, custom player icons & bot difficulty'},
          {'name': 'Retro Snake Arcade', 'desc': 'Classic arcade snake with golden apple power-ups, smooth controls & score tracking'},
          {'name': 'Tetris Block Puzzle', 'desc': 'Block falling puzzle arcade with line clearing and score levels'},
          {'name': 'Player Selection & Options', 'desc': 'Pick your player side, bot vs human mode & toggle game options with hide/unhide button'},
        ],
        'keywords': [
          'game', 'games', 'mini game', 'ludo', 'uno', 'snake and ladder', 'snakes and ladders',
          'saanp seedhi', 'snake & ladder', 'tic tac toe', 'tic-tac-toe', 'noughts and crosses',
          'xo', 'tetris', 'brick game', 'retro snake', 'snake game', 'snake', 'golden apple',
          'arcade', 'board game', 'dice', 'dice roll', 'animated tokens', 'opponent animation',
          'card animation', 'svg snake', 'svg ladder', 'win popup', 'lose popup', 'draw popup',
          'player selection', 'hide unhide options', 'bot', 'multiplayer', 'khel', 'maza',
        ],
        'builder': (context) => GamesScreen(theme: widget.theme),
      },
      {
        'id': 'recorder',
        'title': 'Noise Meter & Recorder',
        'subtitle': 'Live dB gauge, noise safety & audio capture',
        'category': 'Utilities',
        'tag': 'Acoustic dB',
        'iconType': 'recorder',
        'isFeatured': false,
        'features': [
          {'name': 'Live Decibel (dB) Meter', 'desc': 'Real-time acoustic loudness measurement with circular needle gauge'},
          {'name': 'Noise Safety & Harm Levels', 'desc': 'Color-coded safety zones (Quiet <40dB, Normal 40-70dB, Loud 70-85dB, Dangerous >85dB)'},
          {'name': 'Live Waveform Visualizer', 'desc': 'Dynamic sound wave visualizer reflecting ambient microphone amplitude'},
          {'name': 'High-Fidelity Audio Recorder', 'desc': 'Crystal clear voice and audio recording with pause, resume & instant playback'},
        ],
        'keywords': [
          'noise meter', 'decibel meter', 'decibel', 'db', 'sound level', 'noise check',
          'sound meter', 'audio recorder', 'voice recorder', 'microphone', 'mic',
          'sound wave', 'waveform', 'harm level', 'safe level', 'hearing protection',
          'acoustic', 'loudness', 'volume meter', 'audio recording', 'voice memo',
          'awaaz', 'shor', 'dhwani',
        ],
        'builder': (context) => SoundRecorderScreen(theme: widget.theme),
      },
      {
        'id': 'illustrations',
        'title': 'Character Studio',
        'subtitle': '2D Flat vector characters & SVG code',
        'category': 'Utilities',
        'tag': 'Vector SVG',
        'iconType': 'illustrations',
        'isFeatured': true,
        'features': [
          {'name': '2D Stationery Mascots', 'desc': 'Interactive Pen, Pencil, Ruler, Compass & Paperclip mascot illustrations'},
          {'name': 'Vector SVG Code Viewer', 'desc': 'Inspect clean SVG source code for each stationery illustration'},
          {'name': 'Copy Vector Code', 'desc': 'One-tap SVG export to clipboard for web & graphic design'},
        ],
        'keywords': [
          'character studio', 'character', 'illustrations', 'stationery 2d', 'stationery 3d',
          'vector art', 'svg code', 'svg', 'pencil', 'pen', 'ruler', 'compass', 'paperclip',
          'mascot', 'doodle', 'chitra',
        ],
        'builder': (context) => CharacterIllustrationsScreen(theme: widget.theme),
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredTools {
    if (_searchQuery.isEmpty) {
      final base = _tools.where((tool) {
        return _selectedCategory == 'All' || tool['category'] == _selectedCategory;
      }).map((t) => Map<String, dynamic>.from(t)).toList();

      if (_favoriteToolTitles.isNotEmpty) {
        base.sort((a, b) {
          final aTitle = a['title'] as String;
          final bTitle = b['title'] as String;
          final aIdx = _favoriteToolTitles.indexOf(aTitle);
          final bIdx = _favoriteToolTitles.indexOf(bTitle);
          final aFav = aIdx != -1;
          final bFav = bIdx != -1;
          if (aFav && bFav) return aIdx.compareTo(bIdx);
          if (aFav) return -1;
          if (bFav) return 1;
          return 0;
        });
      }
      return base;
    }

    final query = _searchQuery.trim().toLowerCase();
    final queryTokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    final List<Map<String, dynamic>> scored = [];

    for (final rawTool in _tools) {
      final tool = Map<String, dynamic>.from(rawTool);
      final title = (tool['title'] as String? ?? '').toLowerCase();
      final subtitle = (tool['subtitle'] as String? ?? '').toLowerCase();
      final tag = (tool['tag'] as String? ?? '').toLowerCase();
      final keywords = (tool['keywords'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final features = (tool['features'] as List<dynamic>? ?? []).cast<Map<String, String>>();

      int score = 0;
      String? matchedSnippet;

      // 0. Favorite Priority Bonus
      if (_favoriteToolTitles.contains(tool['title'])) {
        score += 350;
      }

      // 1. Direct Title Match
      if (title == query) {
        score += 2000;
        matchedSnippet = 'Direct tool title match';
      } else if (title.startsWith(query)) {
        score += 1200;
        matchedSnippet = 'Tool: ${tool['title']}';
      } else if (title.contains(query)) {
        score += 800;
        matchedSnippet = 'Tool: ${tool['title']}';
      }

      // 2. Sub-Feature Deep Scan
      for (final feat in features) {
        final featName = (feat['name'] ?? '').toLowerCase();
        final featDesc = (feat['desc'] ?? '').toLowerCase();

        if (featName == query) {
          score += 1500;
          matchedSnippet ??= 'Feature: ${feat['name']}';
        } else if (featName.contains(query)) {
          score += 1000;
          matchedSnippet ??= 'Feature: ${feat['name']}';
        } else if (featDesc.contains(query)) {
          score += 650;
          matchedSnippet ??= '${feat['name']} (${feat['desc']})';
        } else if (queryTokens.isNotEmpty && queryTokens.every((t) => featName.contains(t) || featDesc.contains(t))) {
          score += 550;
          matchedSnippet ??= '${feat['name']}';
        }
      }

      // 3. Keyword / Alias Scan
      for (final kw in keywords) {
        final kwLower = kw.toLowerCase();
        if (kwLower == query) {
          score += 900;
          matchedSnippet ??= 'Matches: $kw';
        } else if (kwLower.contains(query)) {
          score += 450;
          matchedSnippet ??= 'Matches: $kw';
        }
      }

      // 4. Subtitle and Tag Scan
      if (subtitle.contains(query)) {
        score += 300;
        matchedSnippet ??= tool['subtitle'];
      }
      if (tag.contains(query)) {
        score += 250;
        matchedSnippet ??= 'Tag: ${tool['tag']}';
      }

      // 5. Multi-token partial matches
      if (queryTokens.length > 1) {
        int tokenMatches = 0;
        for (final token in queryTokens) {
          if (title.contains(token) ||
              subtitle.contains(token) ||
              tag.contains(token) ||
              keywords.any((kw) => kw.toLowerCase().contains(token)) ||
              features.any((f) => (f['name'] ?? '').toLowerCase().contains(token) || (f['desc'] ?? '').toLowerCase().contains(token))) {
            tokenMatches++;
          }
        }
        if (tokenMatches == queryTokens.length) {
          score += 600;
        } else if (tokenMatches > 0) {
          score += tokenMatches * 100;
        }
      }

      // 6. Context category relevance boost
      if (_selectedCategory != 'All' && tool['category'] == _selectedCategory) {
        score += 80;
      }

      if (score > 0) {
        tool['_score'] = score;
        tool['searchHighlight'] = matchedSnippet;
        scored.add(tool);
      }
    }

    scored.sort((a, b) => (b['_score'] as int).compareTo(a['_score'] as int));
    return scored;
  }

  /// Opens any tool in the sleek Pop-up Hover Page (Screen 3 style)
  void _openTool(Map<String, dynamic> tool) {
    SoundService().playClick();
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    ToolerHoverSheet.show(
      context: context,
      title: tool['title'],
      subtitle: tool['subtitle'],
      tag: tool['tag'],
      theme: widget.theme,
      onFavorite: () {
        _loadFavorites();
      },
      child: (tool['builder'] as WidgetBuilder)(context),
    ).then((_) {
      if (mounted) {
        _loadFavorites();
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _openSettings() {
    SoundService().playClick();
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          theme: widget.theme,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Bar with Logo & Settings Button
              _buildTopBar(isDark),

              // 2. Main Scrollable Content (No bottom nav bar!)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Hero Banner Card with 2D Artwork (Lamp & Desk) & Search Bar
                    RepaintBoundary(
                      child: _buildHeroBanner(isDark),
                    ),

                    const SizedBox(height: 16),

                    // B. Main 2x2 Section: Calculator, Calendar, Games, All Tools (SVG icons, no extra text)
                    if (_searchQuery.isEmpty) ...[
                      RepaintBoundary(
                        child: _buildQuick2x2Grid(isDark),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // C. Categories Slide Buttons (Only sliding buttons with smooth slide transitions)
                    RepaintBoundary(
                      child: _buildCategoriesSection(isDark),
                    ),

                    const SizedBox(height: 14),

                    // D. List of Tool Cards (Favorites prioritized at top, clean without tags)
                    _buildToolsList(isDark),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 1. Top Bar: Custom 2D Monogram + Brand + Settings Button
  /// -------------------------------------------------------------------------
  Widget _buildTopBar(bool isDark) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: theme.bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncyTap(
            onTap: () {
              SoundService().playClick();
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            scaleFraction: 0.95,
            child: ToolerLogo(
              height: 36,
              color: theme.text,
              accentColor: theme.primary,
            ),
          ),

          // Settings Action Button (opens modern settings with bouncy tactile pop)
          BouncyTap(
            onTap: _openSettings,
            scaleFraction: 0.88,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: theme.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: theme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 2. Hero Banner Card with 2D Artwork (Desk & Plant) + Search Bar
  /// -------------------------------------------------------------------------
  Widget _buildHeroBanner(bool isDark) {
    final theme = widget.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.lavenderCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : theme.lavenderBubble,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you\nlooking for?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.5,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fast & minimal smart utility kit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Interactive Themed Vector Character (Tap to Cycle Poses!)
              ToolerCharacter(
                pose: _heroPose,
                width: 125,
                height: 100,
                theme: theme,
                animate: true,
                onTap: _cycleHeroPose,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Clean Search Bar (Image 2 style)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearchFocused ? theme.primary : theme.border,
                width: _isSearchFocused ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _isSearchFocused ? theme.primary : theme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onTapOutside: (_) {
                      _searchFocusNode.unfocus();
                    },
                    onSubmitted: (_) {
                      _searchFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search tools',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: theme.textSecondary.withValues(alpha: 0.7),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  BouncyTap(
                    onTap: () {
                      SoundService().playClick();
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                    },
                    scaleFraction: 0.85,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 3. Categories Slide Buttons (Clean animated sliding chips with zero clutter text)
  /// -------------------------------------------------------------------------
  Widget _buildCategoriesSection(bool isDark) {
    final theme = widget.theme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 180 + (index * 35)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset((1.0 - value) * 18, 0),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: BouncyTap(
              onTap: () {
                SoundService().playClick();
                _searchFocusNode.unfocus();
                FocusScope.of(context).unfocus();
                setState(() => _selectedCategory = cat);
              },
              scaleFraction: 0.93,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.lavenderBubble : theme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.border,
                    width: isSelected ? 1.4 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? theme.primaryDark : theme.text,
                  ),
                  child: Text(cat),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 4. Main 2x2 Section: Calculator, Calendar, Games, All Tools (SVG Icons only, no extra text)
  /// -------------------------------------------------------------------------
  Widget _buildQuick2x2Grid(bool isDark) {
    final calcTool = _tools.firstWhere((t) => t['id'] == 'calc');
    final calendarTool = _tools.firstWhere((t) => t['id'] == 'calendar');
    final gamesTool = _tools.firstWhere((t) => t['id'] == 'games');

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 12) / 2;
        return Column(
          children: [
            Row(
              children: [
                _buildQuickCard(calcTool, cardW, overrideTitle: 'Calculator'),
                const SizedBox(width: 12),
                _buildQuickCard(calendarTool, cardW, overrideTitle: 'Calendar'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickCard(gamesTool, cardW, overrideTitle: 'Games'),
                const SizedBox(width: 12),
                _buildAllToolsQuickCard(cardW),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickCard(Map<String, dynamic> tool, double width, {String? overrideTitle}) {
    final theme = widget.theme;
    final isDark = theme.isDark;
    final title = overrideTitle ?? tool['title'] as String;

    return BouncyTap(
      onTap: () => _openTool(tool),
      scaleFraction: 0.94,
      child: Container(
        width: width,
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Minimal2DIcon(
              type: tool['iconType'],
              size: 42,
              bubbleColor: theme.lavenderBubble,
              accentColor: theme.primary,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllToolsQuickCard(double width) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return BouncyTap(
      onTap: () {
        SoundService().playClick();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            290,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      },
      scaleFraction: 0.94,
      child: Container(
        width: width,
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.lavenderBubble,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Minimal2DIcon(
              type: 'all_tools',
              size: 42,
              bubbleColor: theme.cardBg,
              accentColor: theme.primary,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All Tools',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 6. List of Clean Modern Tool Cards (Pop-up Hover on tap with Staggered Slide & Bouncyness!)
  /// -------------------------------------------------------------------------
  Widget _buildToolsList(bool isDark) {
    final theme = widget.theme;
    final list = _filteredTools;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            ToolerCharacter.thinking(
              theme: theme,
              width: 150,
              height: 130,
              animate: true,
            ),
            const SizedBox(height: 12),
            Text(
              'No utility tools found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey<String>(_selectedCategory),
        children: list.asMap().entries.map((entry) {
          final index = entry.key;
          final tool = entry.value;
          final highlight = tool['searchHighlight'] as String?;

          return StaggeredSlideItem(
            index: _searchQuery.isNotEmpty ? 0 : (index < 6 ? index : 6),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: BouncyTap(
                onTap: () => _openTool(tool),
                scaleFraction: 0.96,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // 2D Line Illustration with Accent Bubble
                      Minimal2DIcon(
                        type: tool['iconType'],
                        size: 46,
                        bubbleColor: theme.lavenderBubble,
                        accentColor: theme.primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 14),
                      // Tool Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tool['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tool['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.textSecondary,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty && highlight != null) ...[
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.primary.withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 11,
                                      color: theme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        highlight,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Trailing morph: favorite heart when favorited, chevron arrow when normal
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: _favoriteToolTitles.contains(tool['title'])
                            ? Container(
                                key: const ValueKey('fav_active'),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.lavenderBubble,
                                  border: Border.all(color: theme.primary, width: 1.4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primary.withValues(alpha: 0.16),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 18,
                                  color: theme.primary,
                                ),
                              )
                            : Container(
                                key: const ValueKey('fav_inactive'),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.border, width: 1.2),
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: theme.textSecondary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}