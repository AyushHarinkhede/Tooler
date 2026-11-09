import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets_3d/stationery_3d_modal.dart';

class SettingsScreen extends StatefulWidget {
  final StationeryTheme theme;
  final Function(StationeryThemeMode mode) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundOn;
  late bool _hapticsOn;

  @override
  void initState() {
    super.initState();
    _soundOn = SoundService().soundEnabled;
    _hapticsOn = SoundService().hapticsEnabled;
  }

  void _showAboutModal() {
    Stationery3DModal.show(
      context: context,
      title: "About Tooler",
      subtitle: "Your Complete School Kit Toolkit",
      theme: widget.theme,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/shinchan.png',
              height: 110,
              errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 70),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Tooler is designed like a nostalgic school pencil box & geometry kit, packed with essential daily utility tools, scientific calculators, unit converters, games, and tactile productivity helpers.",
            style: widget.theme.fontDoodle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Text(
            "Version 1.0.0 (Flutter Multiplatform for Android & iOS)",
            style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Created by Ayush Harinkhede",
            style: widget.theme.fontDisplay(fontSize: 14, color: widget.theme.primary),
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
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
            "Clear All Saved Data?",
            style: widget.theme.fontDisplay(fontSize: 18, color: Colors.red),
          ),
          content: Text(
            "This will delete your calculation history, custom counters, and homework tasks.",
            style: widget.theme.fontDoodle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await StorageService().clearAllData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All saved data cleared!")),
                  );
                }
              },
              child: const Text("Clear Data"),
            ),
          ],
        );
      },
    );
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
          "Settings",
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Theme Selection Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: widget.theme.doodleCard(borderWidth: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Stationery Themes",
                        style: widget.theme.fontDisplay(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      _buildThemeOption(
                        "Classic School Kit (Doodle Notebook)",
                        "Cream paper, graphite borders, pastel ruler tones",
                        StationeryThemeMode.classicDoodle,
                      ),
                      const Divider(),
                      _buildThemeOption(
                        "Blueprint / Chalkboard Navy",
                        "Deep navy chalkboard, cyan and white chalk lines",
                        StationeryThemeMode.blueprintChalkboard,
                      ),
                      const Divider(),
                      _buildThemeOption(
                        "Neon Highlighter",
                        "Carbon black desk with electric highlighter markers",
                        StationeryThemeMode.neonHighlighter,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tactile Feedback & Sound Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: widget.theme.doodleCard(borderWidth: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tactile & Sound Feedback",
                        style: widget.theme.fontDisplay(fontSize: 18),
                      ),
                      SwitchListTile(
                        title: Text("Pencil & Key Click Sounds", style: widget.theme.fontDoodle(fontSize: 15)),
                        value: _soundOn,
                        activeColor: widget.theme.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _soundOn = val;
                            SoundService().soundEnabled = val;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: Text("Haptic Vibration Clicks", style: widget.theme.fontDoodle(fontSize: 15)),
                        value: _hapticsOn,
                        activeColor: widget.theme.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _hapticsOn = val;
                            SoundService().hapticsEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Data & Reset Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: widget.theme.doodleCard(borderWidth: 2.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Color(0xFF4ECDC4)),
                        title: Text("About Tooler Stationery Kit", style: widget.theme.fontDisplay(fontSize: 16)),
                        contentPadding: EdgeInsets.zero,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showAboutModal,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: Text("Clear Local Data", style: widget.theme.fontDisplay(fontSize: 16, color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _confirmClearData,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String desc, StationeryThemeMode mode) {
    final bool isSelected = (widget.theme.mode == mode);
    return RadioListTile<StationeryThemeMode>(
      title: Text(
        title,
        style: widget.theme.fontDisplay(
          fontSize: 15,
          color: isSelected ? widget.theme.primary : widget.theme.text,
        ),
      ),
      subtitle: Text(
        desc,
        style: widget.theme.fontDoodle(fontSize: 12, color: widget.theme.text.withOpacity(0.7)),
      ),
      value: mode,
      groupValue: widget.theme.mode,
      activeColor: widget.theme.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        if (val != null) {
          SoundService().playClick();
          widget.onThemeChanged(val);
          StorageService().saveThemeMode(val);
        }
      },
    );
  }
}
