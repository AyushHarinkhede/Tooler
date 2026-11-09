import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/counter_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

class CountersScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CountersScreen({super.key, required this.theme});

  @override
  State<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends State<CountersScreen> {
  List<CounterItem> _counters = [];
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    final list = await StorageService().loadCounters();
    setState(() => _counters = list);
  }

  void _addCounter() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    SoundService().playClick();
    setState(() {
      _counters.add(CounterItem(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        value: 0,
      ));
      _nameCtrl.clear();
    });
    StorageService().saveCounters(_counters);
  }

  void _updateCounter(int id, int amount) {
    SoundService().playKey();
    setState(() {
      final item = _counters.firstWhere((c) => c.id == id);
      item.value += amount;
      if (item.value < 0) item.value = 0;
    });
    StorageService().saveCounters(_counters);
  }

  void _resetCounter(int id) {
    SoundService().playClick();
    setState(() {
      final item = _counters.firstWhere((c) => c.id == id);
      item.value = 0;
    });
    StorageService().saveCounters(_counters);
  }

  void _removeCounter(int id) {
    SoundService().playAlert();
    setState(() {
      _counters.removeWhere((c) => c.id == id);
    });
    StorageService().saveCounters(_counters);
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
          "Custom Counters 🔢",
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
                              hintText: "New Counter Name (e.g. Pushups 💪)",
                              hintStyle: widget.theme.fontDoodle(
                                fontSize: 14,
                                color: widget.theme.text.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addCounter(),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _addCounter,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add"),
                        ),
                      ],
                    ),
                  ),
                ),

                // Counters List
                Expanded(
                  child: _counters.isEmpty
                      ? Center(
                          child: Text(
                            "No counters yet.\nAdd one above! ✏️",
                            textAlign: TextAlign.center,
                            style: widget.theme.fontDoodle(
                              fontSize: 18,
                              color: widget.theme.text.withOpacity(0.6),
                            ),
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
                                        Text(
                                          c.name,
                                          style: widget.theme.fontDisplay(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Step: ±${c.step}",
                                          style: widget.theme.fontMono(
                                            fontSize: 11,
                                            color: widget.theme.text.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Decrement
                                  _buildCounterBtn(
                                    icon: Icons.remove,
                                    onTap: () => _updateCounter(c.id, -c.step),
                                  ),
                                  const SizedBox(width: 12),

                                  // Count Display
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 54),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${c.value}",
                                      style: widget.theme.fontMono(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: widget.theme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Increment
                                  _buildCounterBtn(
                                    icon: Icons.add,
                                    isPrimary: true,
                                    onTap: () => _updateCounter(c.id, c.step),
                                  ),
                                  const SizedBox(width: 10),

                                  // Reset / Delete Menu
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: widget.theme.text),
                                    color: widget.theme.cardBg,
                                    onSelected: (val) {
                                      if (val == 'reset') _resetCounter(c.id);
                                      if (val == 'delete') _removeCounter(c.id);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'reset',
                                        child: Text("Reset to 0"),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text("Delete Counter", style: TextStyle(color: Colors.red)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
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
