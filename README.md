# Tooler - Complete School Stationery Kit Doodle Utility App

**Tooler** is an all-in-one multiplatform mobile utility toolkit (Android & Web) designed with a nostalgic **School Stationery Kit / Pencil Box & Notebook Paper** UI/UX.

---

## UI/UX Design & Visual Aesthetics
- **School Kit Stationery Concept**: Designed like an authentic geometry box & stationery desk with wooden rulers, pencils, erasers, paper tape, and compass dividers.
- **2D & 3D Interactive Models & Modals**:
  - **Hinged Geometry Box**: Perspective opening revealing stationery tool trays.
  - **Calibrated Wooden Ruler**: Millimeter markings and brass trim for real-world sizing.
  - **Rotating Compass & Leveler**: Real-time rotating needle dial, crosshair alignment bar, and automatic spirit leveler switch.
  - **Origami Fold Modals**: Popups that fold out in 3D perspective with sticky tape headers.
  - **2D Character Illustrations Suite**: 12 scalable flat vector poses in purple, black, and white.
- **Stationery Themes**:
  - **Classic School Kit (Doodle Notebook)**: Parchment cream paper, blue notebook rules, red margin, graphite pencil borders.
  - **Blueprint / Chalkboard Navy**: Blackboard texture with cyan and white chalk drawings.
  - **Highlighter Neon**: Carbon black desk with fluorescent highlighter markers.

---

## Complete Feature Set

1. **Calculator**: Standard & Scientific math (`sin`, `cos`, `tan`, `ln`, `log`, `sqrt`, `x^y`, `!`, `pi`, `e`) with persistent paper tape calculation history.
2. **Age Calculator & Legal Eligibility**:
   - Exact calendar age (years, months, days), total days, weeks, hours, and next birthday countdown.
   - **18+ Adult Status Banner**: Major vs Minor status with remaining years to adulthood.
   - **Legal Eligibility Verification** with SVG vector icons:
     - Drive (Motor Vehicles): 18+
     - Vote (Electoral Rights): 18+
     - Marriage: Dynamic by gender (Female: 18+, Male: 21+, Other: 21+)
     - Alcohol Consumption: 21+
3. **Universal Converters**: Real-time dynamic conversions for Length, Weight/Mass, Temperature, Height, Area, Volume, Speed, Time, Data Storage, Pressure, Energy, Power, Fuel Economy, Angle, Frequency, Typography, Density.
4. **Digital Compass & Spirit Level**:
   - Real-time magnetic azimuth with cardinal headings.
   - Calibrated precision with crosshair axis bar (Front, Back, Left, Right).
   - Auto-switching between flat compass and straight spirit level with manual toggle lock.
5. **Stopwatch**:
   - Millisecond precision dial with dual circular progression rings.
   - Split lap tracking with best/worst lap highlighting.
6. **Countdown Timer**:
   - Quick duration select pills and custom manual time entry.
   - Circular countdown progress visualizer.
   - Audio chime and sound alerts when time expires.
7. **Sound Recorder & Audio Memos**:
   - Real-time animated audio waveform visualizer.
   - Interactive timeline scrubber with bookmark annotations.
   - Audio captions, memo categorization, playback speed control (0.5x to 2.0x), and persistent storage.
8. **Games Arcade**:
   - **Tic-Tac-Toe**: Unbeatable Minimax AI algorithm with X/O selection.
   - **Real Ludo**: 15x15 board with 4 tokens, roll 6 rule, captures, and safe star zones.
   - **Snake Pro**: Anti-suicide input buffer, touch swipe controls, and golden apple powerups.
   - **Snake and Ladder**: 100-cell board with authentic snakes and ladder skips.
   - **UNO Cards**: 108 cards, wild color picker, Reverse/Skip/Draw 2/Draw 4, and UNO shout.
   - **Tetris**: 10x20 matrix, piece preview, score/level progression, and keyboard/touch controls.
9. **Character Vector Studio**:
   - 12 scalable 2D flat vector character poses in purple (`#9468E8`), black (`#23233A`), and white (`#FFFFFF`).
   - One-click SVG code copy and SVG file download.
   - Color palette picker with hex code clipboard copy.
10. **Ring & Finger Sizer**: Interactive screen-based caliper with calibrated sizing benchmarks.
11. **Tally Counters**: Multi-counter support with customizable step values, reset, and haptic feedback.
12. **Task Manager (Sticky Notes)**: Notebook-styled todo list with priority tags and completion states.
13. **Currency Converter**: Real-time foreign exchange rate calculator with multi-currency tracking.
14. **Password Generator**: Customizable strength, length, and character sets with entropy rating.
15. **Built-in Safe Browser**: Lightweight web view for quick reference lookups.
16. **Settings**: Theme switcher, sound effects toggle, vibration haptics, and display preferences.

---

## Build & Release

### Android Release APK
```bash
# Build standalone release APK
flutter build apk --release --no-tree-shake-icons

# Output path:
# build/app/outputs/flutter-apk/app-release.apk
```

### Web Application
Open `Tooler.html` in any modern web browser or host on any static web server.
