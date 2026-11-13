import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/counter_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';

class CountersScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CountersScreen({super.key, required this.theme});

  @override
  State<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends State<CountersScreen> with WidgetsBindingObserver {
  List<CounterItem> _counters = [];
  final TextEditingController _nameCtrl = TextEditingController();
  int? _linkedWidgetCounterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCounters();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCounters();
    }
  }

  Future<void> _loadCounters() async {
    final list = await StorageService().loadCounters();
    await WidgetService().loadPrefs();
    if (!mounted) return;
    setState(() {
      _counters = list;
      _linkedWidgetCounterId = WidgetService().counterId;
    });

    if (list.isNotEmpty) {
      final active = list.firstWhere(
        (c) => c.id == _linkedWidgetCounterId,
        orElse: () => list.first,
      );
      _linkedWidgetCounterId = active.id;
      WidgetService().syncCounterToNative(
        id: active.id,
        name: active.name,
        value: active.value,
        step: active.step,
        theme: widget.theme,
      );
    }
  }

  void _syncToWidget([CounterItem? specific]) {
    if (_counters.isEmpty) {
      WidgetService().syncCounterToNative(
        id: 0,
        name: 'Tally Counter',
        value: 0,
        step: 1,
        theme: widget.theme,
      );
      return;
    }
    final target = specific ?? _counters.firstWhere(
      (c) => c.id == _linkedWidgetCounterId,
      orElse: () => _counters.first,
    );
    _linkedWidgetCounterId = target.id;
    WidgetService().syncCounterToNative(
      id: target.id,
      name: target.name,
      value: target.value,
      step: target.step,
      theme: widget.theme,
    );
  }

  void _addCounter() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    SoundService().playClick();
    final newItem = CounterItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      value: 0,
      step: 1,
    );
    setState(() {
      _counters.add(newItem);
      _nameCtrl.clear();
      _linkedWidgetCounterId = newItem.id;
    });
    StorageService().saveCounters(_counters);
    _syncToWidget(newItem);
  }

  void _updateCounter(int id, int amount) {
    SoundService().playKey();
    CounterItem? updated;
    setState(() {
      final item = _counters.firstWhere((c) => c.id == id);
      item.value += amount;
      if (item.value < 0) item.value = 0;
      updated = item;
    });
    StorageService().saveCounters(_counters);
    if (updated != null) {
      if (updated!.id == _linkedWidgetCounterId) {
        _syncToWidget(updated);
      }
      if (amount > 0) {
        _checkCounterMilestoneNotification(updated!);
      }
    }
  }

  void _checkCounterMilestoneNotification(CounterItem item) {
    final v = item.value;
    if (v <= 0) return;
    // Notify on sacred 108 chants or centenary milestones (100, 200, 500, 1000...)
    final is108 = (v == 108);
    final isCentenary = (v % 100 == 0);
    final isMajor = (v == 500 || v == 1000 || v == 5000 || v == 10000);

    if (is108 || isCentenary || isMajor) {
      NotificationService().showTallyMilestoneNotification(
        counterId: item.id,
        counterName: item.name,
        value: item.value,
      );
    }
  }

  void _resetCounter(int id) {
    SoundService().playClick();
    CounterItem? updated;
    setState(() {
      final item = _counters.firstWhere((c) => c.id == id);
      item.value = 0;
      updated = item;
    });
    StorageService().saveCounters(_counters);
    if (updated != null && updated!.id == _linkedWidgetCounterId) {
      _syncToWidget(updated);
    }
  }

  void _setAsWidgetCounter(int id) {
    SoundService().playSpecialClick();
    final item = _counters.firstWhere((c) => c.id == id);
    setState(() => _linkedWidgetCounterId = id);
    _syncToWidget(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${item.name}" is now linked to your 2×2 Home Screen Widget!',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: widget.theme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _changeStep(int id) {
    SoundService().playTap();
    final item = _counters.firstWhere((c) => c.id == id);
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Step Increment for "${item.name}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: widget.theme.text,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  children: [1, 2, 5, 10, 25, 50, 100, 108].map((s) {
                    final isSel = item.step == s;
                    return ChoiceChip(
                      label: Text('±$s'),
                      selected: isSel,
                      selectedColor: widget.theme.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : widget.theme.text,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        SoundService().playClick();
                        setState(() => item.step = s);
                        StorageService().saveCounters(_counters);
                        if (item.id == _linkedWidgetCounterId) _syncToWidget(item);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _renameCounter(int id) {
    SoundService().playTap();
    final item = _counters.firstWhere((c) => c.id == id);
    final renameCtrl = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename Counter',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: widget.theme.text),
        ),
        content: TextField(
          controller: renameCtrl,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: widget.theme.text),
          decoration: InputDecoration(
            hintText: 'Counter Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newName = renameCtrl.text.trim();
              if (newName.isNotEmpty) {
                SoundService().playClick();
                setState(() => item.name = newName);
                StorageService().saveCounters(_counters);
                if (item.id == _linkedWidgetCounterId) _syncToWidget(item);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _removeCounter(int id) {
    SoundService().playAlert();
    setState(() {
      _counters.removeWhere((c) => c.id == id);
      if (_linkedWidgetCounterId == id) {
        _linkedWidgetCounterId = _counters.isNotEmpty ? _counters.first.id : null;
      }
    });
    StorageService().saveCounters(_counters);
    _syncToWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: Column(
              children: [
                // Add Counter Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            style: widget.theme.fontDoodle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "New Counter Name (e.g. Daily Habits)",
                              hintStyle: widget.theme.fontDoodle(
                                fontSize: 14,
                                color: widget.theme.text.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addCounter(),
                          ),
                        ),
                        BouncyTap(
                          onTap: _addCounter,
                          scaleFraction: 0.92,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.theme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 18, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  "Add",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Counters List
                Expanded(
                  child: _counters.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ToolerCharacter(
                                pose: ToolerCharacterPose.phoneMultitasking,
                                theme: widget.theme,
                                width: 140,
                                height: 110,
                                animate: true,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No counters yet.\nAdd one above!",
                                textAlign: TextAlign.center,
                                style: widget.theme.fontDoodle(
                                  fontSize: 16,
                                  color: widget.theme.text.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _counters.length,
                          itemBuilder: (context, index) {
                            final c = _counters[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: widget.theme.doodleCard(borderWidth: 2.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c.name,
                                                style: widget.theme.fontDisplay(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (c.id == _linkedWidgetCounterId) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: widget.theme.primary.withValues(alpha: 0.16),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: widget.theme.primary.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '2×2 WIDGET',
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: widget.theme.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              "Step: ±${c.step}",
                                              style: widget.theme.fontMono(
                                                fontSize: 11,
                                                color: widget.theme.text.withValues(alpha: 0.6),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _changeStep(c.id),
                                              child: Text(
                                                "Edit Step",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: widget.theme.primary,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Decrement with Bouncy Tap
                                  _buildCounterBtn(
                                    icon: Icons.remove,
                                    onTap: () => _updateCounter(c.id, -c.step),
                                  ),
                                  const SizedBox(width: 12),

                                  // Count Display with AnimatedTextPop
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 54),
                                    alignment: Alignment.center,
                                    child: AnimatedTextPop(
                                      text: "${c.value}",
                                      style: widget.theme.fontMono(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: widget.theme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Increment with Bouncy Tap
                                  _buildCounterBtn(
                                    icon: Icons.add,
                                    isPrimary: true,
                                    onTap: () => _updateCounter(c.id, c.step),
                                  ),
                                  const SizedBox(width: 6),

                                  // Options Menu
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: widget.theme.text),
                                    color: widget.theme.cardBg,
                                    onSelected: (val) {
                                      if (val == 'widget') _setAsWidgetCounter(c.id);
                                      if (val == 'step') _changeStep(c.id);
                                      if (val == 'rename') _renameCounter(c.id);
                                      if (val == 'reset') _resetCounter(c.id);
                                      if (val == 'delete') _removeCounter(c.id);
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'widget',
                                        child: Row(
                                          children: [
                                            Icon(Icons.widgets_rounded, size: 17, color: widget.theme.primary),
                                            const SizedBox(width: 8),
                                            const Text("Link to 2×2 Home Widget"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'step',
                                        child: Row(
                                          children: [
                                            Icon(Icons.tune_rounded, size: 17),
                                            SizedBox(width: 8),
                                            Text("Change Step Size"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, size: 17),
                                            SizedBox(width: 8),
                                            Text("Rename Counter"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'reset',
                                        child: Row(
                                          children: [
                                            Icon(Icons.refresh_rounded, size: 17),
                                            SizedBox(width: 8),
                                            Text("Reset to 0"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 17, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text("Delete Counter", style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
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

  Widget _buildCounterBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleFraction: 0.88,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isPrimary ? widget.theme.primary : widget.theme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.theme.border, width: 2),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? Colors.white : widget.theme.text,
        ),
      ),
    );
  }
}
