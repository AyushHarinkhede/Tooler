# ✂️📏 Tooler - Complete School Stationery Kit Doodle App

**Tooler** is an all-in-one multiplatform mobile utility toolkit (Android & iOS) designed with a nostalgic **School Stationery Kit / Pencil Box & Notebook Paper** UI/UX.

---

## 🎨 UI/UX Design & 3D Visual Aesthetics
- **School Kit Stationery Concept**: Designed like an authentic geometry box & stationery desk with wooden rulers, pencils, erasers, paper tape, and compass dividers.
- **2D & 3D Interactive Models & Modals**:
  - **3D Pencil Box**: Hinged 3D geometry box with perspective opening to reveal stationery tool trays.
  - **3D Wooden Ruler**: Calibrated beveled wooden ruler with millimeter markings and brass trim.
  - **3D Rotating Compass**: Real-time rotating needle dial with cardinal headings.
  - **3D Tumbling Dice**: Physical rolling dice with dot faces.
  - **3D Origami Fold Modals**: Popups that fold out in 3D perspective with sticky tape headers.
- **Multiple Stationery Themes**:
  - ✏️ **Classic School Kit (Doodle Notebook)**: Parchment cream paper, blue notebook rules, red margin, graphite pencil borders.
  - 📐 **Blueprint / Chalkboard Navy**: Blackboard texture with cyan and white chalk drawings.
  - 🌈 **Highlighter Neon**: Carbon black desk with fluorescent highlighter markers.

---

## 🛠️ Complete Feature Set
1. **📐 Calculator**: Standard & Scientific math (`sin`, `cos`, `tan`, `ln`, `log`, `√`, `x^y`, `!`, `π`, `e`) with persistent paper tape calculation history.
2. **🎂 Age Calculator**: Exact calendar age (years, months, days), total days/weeks lived, born day of week, and upcoming birthday countdown.
3. **📏 Universal Converters**: Real-time dynamic conversions for:
   - Length (Meters, Kilometers, Centimeters, Millimeters, Miles, Yards, Feet, Inches)
   - Weight / Mass (Kilograms, Grams, Milligrams, Pounds, Ounces, Tons)
   - Temperature (Celsius, Fahrenheit, Kelvin, Rankine, Reaumur)
   - Height (Centimeters, Meters, Feet, Inches)
   - Area (Sq Meters, Sq Kilometers, Sq Feet, Sq Yards, Acres, Hectares)
   - Volume (Liters, Milliliters, Gallons, Quarts, Pints, Cups)
   - Speed (km/h, m/s, mph, Knots)
   - Data Storage (Bytes, KB, MB, GB, TB)
4. **⏱️ Stopwatch**: Millisecond precision stopwatch with rotating second hand and lap comparison.
5. **⏳ Countdown Timer**: Circular progress arc with preset quick buttons (1m, 5m, 15m, 25m Pomodoro, 30m, 60m) and chime alert.
6. **💍 Sizer Tools & Screen Ruler**:
   - Interactive calibrated Ring Sizer with international size charts (US, UK, EU, Japan).
   - Bangle Sizer with inner circumference measurements.
   - Watch Strap Lug Width guide (18mm, 20mm, 22mm, 24mm).
   - Calibrated On-Screen Ruler in mm and inches.
7. **🔢 Custom Counters**: Multi-counter tally cards with custom step increments, goals, and sound feedback.
8. **📝 Task Manager (Homework & To-Dos)**: Notebook homework list with priority color tags, category filters, and scribble strike-through completion.
9. **💱 Currency Converter**: 15+ world currencies with instant swap and conversion calculation.
10. **🎮 Games Arcade**:
    - **Tic-Tac-Toe**: Player vs Player & Player vs Computer (AI).
    - **Retro Doodle Snake**: Grid canvas snake with food, score, and D-pad controls.
    - **3D Tumbling Dice Roller**: Random rolling dice for board games.
11. **🌐 Web Browser Viewer**: In-app web viewer with address bar, search query handler, and educational bookmarks.
12. **🧭 Digital Compass**: Rotating 3D compass rose, heading degrees (0° - 359°), cardinal directions, and level/tilt indicators.
13. **🔐 Password Generator**: Custom length slider (6-48), character toggles, real-time strength meter, and 1-tap clipboard copy.
14. **⚙️ Settings & Tactile Feedback**: Stationery theme picker, sound effects toggle, haptics toggle, and data reset.

---

## 💻 Companion C# 2D & 3D Models
Located in the `csharp_models/` folder:
- `Stationery3DGeometry.cs`: 3D Vector, 2D projection, and mesh structures.
- `Stationery3DBoxModel.cs`: 3D geometry case mesh and hinge controller.
- `Calculator3DModel.cs`: Calculation logic and history buffer.
- `AgeCalculatorModel.cs`: Exact date/time milestone calculations.
- `UniversalConverterModel.cs`: Unit conversion algorithms.
- `Sizer3DToolModel.cs`: Ring torus mesh generation & international sizing lookup.
- `DigitalCompass3DModel.cs`: Heading degrees and needle orientation vectors.
- `Stationery3DModalController.cs`: 3D origami fold-in/fold-out animation state machine.

---

## 🚀 How to Run the App

### Requirements
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.0.0 or higher)
- Android Studio / Xcode (for iOS) or VS Code

### Steps
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on connected Android / iOS device or emulator
flutter run

# 3. Build APK for Android
flutter build apk --release

# 4. Build iOS App
flutter build ios --release
```

---

## 🔗 GitHub Sync
This repository is linked with:
`https://github.com/AyushHarinkhede/Tooler.git`

To push updates:
```bash
git add .
git commit -m "Convert Tooler to full Flutter app with 2D/3D School Stationery Kit UI and C# models"
git push origin main
```
