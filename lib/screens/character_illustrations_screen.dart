import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// CHARACTER ILLUSTRATIONS SCREEN (2D Flat Vector Studio)
/// Faithful vector characters dynamically themed with user-selected theme color
/// (Mint, Rose, Lilac, Sky, Amber), white outlines in dark mode, and pure SVG.
/// ---------------------------------------------------------------------------

class CharacterPoseItem {
  final String id;
  final String title;
  final String category;
  final String assetPath;
  final String description;
  final List<String> tags;

  const CharacterPoseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.assetPath,
    required this.description,
    required this.tags,
  });
}

class CharacterIllustrationsScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CharacterIllustrationsScreen({super.key, required this.theme});

  @override
  State<CharacterIllustrationsScreen> createState() => _CharacterIllustrationsScreenState();
}

class _CharacterIllustrationsScreenState extends State<CharacterIllustrationsScreen> {
  String _selectedCategory = 'All';
  final Map<String, String> _svgCache = {};
  bool _isLoading = true;

  final List<CharacterPoseItem> _poses = const [
    CharacterPoseItem(
      id: 'working_laptop',
      title: 'Working at Desk with Laptop',
      category: 'Work & Desk',
      assetPath: 'assets/illustrations/character_working_laptop.svg',
      description: 'Side view of professional typing on laptop at modern desk with coffee mug and succulent plant.',
      tags: ['Laptop', 'Desk', 'Coffee', 'Coding', 'Focus'],
    ),
    CharacterPoseItem(
      id: 'whiteboard_planning',
      title: 'Whiteboard Strategy & Planning',
      category: 'Planning & Strategy',
      assetPath: 'assets/illustrations/character_whiteboard_planning.svg',
      description: 'Standing at large whiteboard holding marker, connecting sticky notes with workflow arrows.',
      tags: ['Whiteboard', 'Flowchart', 'Sticky Notes', 'Strategy'],
    ),
    CharacterPoseItem(
      id: 'tablet_thinking',
      title: 'Ergonomic Chair & Tablet (Thinking)',
      category: 'Mobile & Tablet',
      assetPath: 'assets/illustrations/character_tablet_thinking.svg',
      description: 'Reclining in office chair with crossed legs, holding tablet and hand on chin in deep thought.',
      tags: ['Tablet', 'Thinking', 'Chair', 'Brainstorming'],
    ),
    CharacterPoseItem(
      id: 'presentation_chart',
      title: 'Presentation Flipchart & Analytics',
      category: 'Planning & Strategy',
      assetPath: 'assets/illustrations/character_presentation_chart.svg',
      description: 'Standing beside tripod flipchart easel pointing at exponential growth line curve and pie chart.',
      tags: ['Presentation', 'Easel', 'Growth', 'Metrics', 'Pie Chart'],
    ),
    CharacterPoseItem(
      id: 'video_call',
      title: 'Video Call & Virtual Meeting',
      category: 'Work & Desk',
      assetPath: 'assets/illustrations/character_video_call.svg',
      description: 'Sitting at desk waving hand at laptop webcam in a friendly virtual call with floating camera badge.',
      tags: ['Video Call', 'Meeting', 'Waving', 'Remote Work'],
    ),
    CharacterPoseItem(
      id: 'celebrating_success',
      title: 'Celebrating Success & Task Done',
      category: 'Work & Desk',
      assetPath: 'assets/illustrations/character_celebrating_success.svg',
      description: 'Fist pump in victory at desk with completed tasks checklist floating on wall.',
      tags: ['Victory', 'Fist Pump', 'Checklist', 'Success', 'Achievement'],
    ),
    CharacterPoseItem(
      id: 'study_writing',
      title: 'Study & Journaling with Desk Lamp',
      category: 'Work & Desk',
      assetPath: 'assets/illustrations/character_study_writing.svg',
      description: 'Leaning forward writing in notebook with angle task lamp and stack of books.',
      tags: ['Writing', 'Notebook', 'Study', 'Lamp', 'Education'],
    ),
    CharacterPoseItem(
      id: 'phone_multitasking',
      title: 'Phone Call & Contract Review',
      category: 'Mobile & Tablet',
      assetPath: 'assets/illustrations/character_phone_multitasking.svg',
      description: 'Speaking on mobile smartphone while pointing at floating certified contract document.',
      tags: ['Phone Call', 'Smartphone', 'Multitasking', 'Contract'],
    ),
    CharacterPoseItem(
      id: 'dual_monitor',
      title: 'Dual Monitors Power Workstation',
      category: 'Work & Desk',
      assetPath: 'assets/illustrations/character_dual_monitor.svg',
      description: 'Sitting at workstation desk with dual screens and pedestal cabinet holding paper printout.',
      tags: ['Dual Monitors', 'Coding', 'Workstation', 'Productivity'],
    ),
    CharacterPoseItem(
      id: 'creative_drawing',
      title: 'Creative UI Wireframe & Stylus',
      category: 'Mobile & Tablet',
      assetPath: 'assets/illustrations/character_creative_drawing.svg',
      description: 'Reclining in chair drawing with digital stylus on tablet with UI wireframe board on wall.',
      tags: ['UI/UX', 'Stylus', 'Wireframe', 'Design', 'Creative'],
    ),
    CharacterPoseItem(
      id: 'project_roadmap',
      title: 'Project Roadmap & Gantt Schedule',
      category: 'Planning & Strategy',
      assetPath: 'assets/illustrations/character_project_roadmap.svg',
      description: 'Standing with clipboard pointing marker at project roadmap schedule board.',
      tags: ['Gantt Chart', 'Timeline', 'Roadmap', 'Clipboard', 'Planning'],
    ),
    CharacterPoseItem(
      id: 'brainstorm_sticky_wall',
      title: 'Brainstorming Sticky Wall Cluster',
      category: 'Planning & Strategy',
      assetPath: 'assets/illustrations/character_brainstorm_sticky_wall.svg',
      description: 'Placing sticky notes onto idea cluster web on whiteboard.',
      tags: ['Brainstorm', 'Sticky Wall', 'Ideas', 'Network'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllSvgs();
  }

  Future<void> _loadAllSvgs() async {
    for (final pose in _poses) {
      try {
        final svgString = await rootBundle.loadString(pose.assetPath);
        _svgCache[pose.id] = svgString;
      } catch (e) {
        _svgCache[pose.id] = '<!-- ${pose.title} SVG asset: ${pose.assetPath} -->';
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getThemedSvg(String rawSvg) {
    final hexPrimary = '#${(widget.theme.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final hexLight = '#${(widget.theme.primary.withValues(alpha: 0.25).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final isDark = widget.theme.isDark;

    var svg = rawSvg
        .replaceAll('#9468E8', hexPrimary)
        .replaceAll('#A855F7', hexPrimary)
        .replaceAll('var(--char-accent, #9468E8)', hexPrimary)
        .replaceAll('#C8B6FA', hexLight)
        .replaceAll('#EDE9FE', hexLight);

    if (isDark) {
      svg = svg
          .replaceAll('#1D2436', '#F4F4F5')
          .replaceAll('#23233A', '#F4F4F5')
          .replaceAll('#181829', '#F4F4F5')
          .replaceAll('#18181B', '#F4F4F5')
          .replaceAll('#F4F1F8', 'transparent');
    } else {
      svg = svg.replaceAll('#F4F1F8', 'transparent');
    }
    return svg;
  }

  List<CharacterPoseItem> get _filteredPoses {
    if (_selectedCategory == 'All') return _poses;
    return _poses.where((p) => p.category == _selectedCategory).toList();
  }

  void _copySvgCode(CharacterPoseItem pose) {
    SoundService().playClick();
    final rawCode = _svgCache[pose.id] ?? '';
    final svgCode = _getThemedSvg(rawCode);
    Clipboard.setData(ClipboardData(text: svgCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Copied '${pose.title}' Themed SVG code to clipboard!",
          style: widget.theme.fontDoodle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSvgModal(CharacterPoseItem pose) {
    SoundService().playClick();
    final rawCode = _svgCache[pose.id] ?? '';
    final svgCode = _getThemedSvg(rawCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: widget.theme.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: widget.theme.border, width: 2.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pose.title,
                      style: widget.theme.fontDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: widget.theme.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                pose.description,
                style: widget.theme.fontDoodle(fontSize: 13, color: widget.theme.text.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 12),

              // Themed Preview Box
              Container(
                height: 190,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.isDark ? const Color(0xFF1E1E24) : widget.theme.lavenderCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.theme.isDark
                        ? widget.theme.primary.withValues(alpha: 0.25)
                        : widget.theme.lavenderBubble,
                    width: 1.5,
                  ),
                ),
                child: SvgPicture.string(
                  svgCode,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),

              // Color Palette Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildColorChip("Theme Accent", widget.theme.primary),
                  _buildColorChip(
                    widget.theme.isDark ? "Inverted White Lines" : "Charcoal Lines",
                    widget.theme.isDark ? const Color(0xFFF4F4F5) : const Color(0xFF23233A),
                  ),
                  _buildColorChip("Light Tint", widget.theme.primary.withValues(alpha: 0.25)),
                  _buildColorChip("Pure White", const Color(0xFFFFFFFF)),
                ],
              ),
              const SizedBox(height: 14),

              // Code Viewer Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.theme.border, width: 2),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      svgCode,
                      style: widget.theme.fontMono(fontSize: 11, color: const Color(0xFFC9B4F8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Copy Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy, size: 20),
                label: Text(
                  "Copy Themed SVG Code",
                  style: widget.theme.fontDisplay(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _copySvgCode(pose);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black26)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold, color: widget.theme.text),
          ),
        ],
      ),
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
          "Character Vector Studio",
          style: widget.theme.fontDisplay(fontSize: 20, fontWeight: FontWeight.bold),
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
                // Top Banner with Description & Palette
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.theme.isDark ? const Color(0xFF1E1E24) : widget.theme.lavenderCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.theme.isDark ? widget.theme.primary.withValues(alpha: 0.3) : widget.theme.primary,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.theme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.palette_outlined, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "2D Flat Vector Character Pack",
                              style: widget.theme.fontDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: widget.theme.text),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Dynamic Theme Accent • White Outlines in Dark Mode • Vector SVG",
                              style: widget.theme.fontMono(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Work & Desk'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Planning & Strategy'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Mobile & Tablet'),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Main Character List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredPoses.length,
                          itemBuilder: (context, index) {
                            final pose = _filteredPoses[index];
                            return _buildPoseCard(pose);
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

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        SoundService().playClick();
        setState(() => _selectedCategory = category);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : widget.theme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? widget.theme.primary : widget.theme.border,
            width: 2,
          ),
        ),
        child: Text(
          category,
          style: widget.theme.fontDisplay(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : widget.theme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildPoseCard(CharacterPoseItem pose) {
    final rawSvg = _svgCache[pose.id];
    final themedSvg = rawSvg != null ? _getThemedSvg(rawSvg) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: widget.theme.doodleCard(borderWidth: 2.2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.theme.isDark
                      ? widget.theme.primary.withValues(alpha: 0.18)
                      : widget.theme.lavenderBubble,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.theme.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.palette_outlined, color: widget.theme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pose.title,
                      style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pose.category,
                      style: widget.theme.fontMono(
                        fontSize: 11,
                        color: widget.theme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.theme.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.theme.border, width: 1.5),
                ),
                child: Text(
                  "SVG 2D",
                  style: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Dynamic Vector Character Preview
          Container(
            height: 190,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.isDark ? const Color(0xFF1E1E24) : widget.theme.lavenderCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.theme.isDark
                    ? widget.theme.primary.withValues(alpha: 0.25)
                    : widget.theme.lavenderBubble,
                width: 1.5,
              ),
            ),
            child: themedSvg != null
                ? SvgPicture.string(
                    themedSvg,
                    fit: BoxFit.contain,
                  )
                : const Center(child: CircularProgressIndicator.adaptive()),
          ),

          Text(
            pose.description,
            style: widget.theme.fontDoodle(
              fontSize: 13,
              color: widget.theme.text.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),

          // Tag Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pose.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.theme.isDark
                      ? widget.theme.primary.withValues(alpha: 0.16)
                      : widget.theme.lavenderBubble,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#$tag",
                  style: widget.theme.fontMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Inspect Code & Copy SVG
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: widget.theme.border, width: 1.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.code, size: 16),
                  label: Text("Inspect Code", style: widget.theme.fontDisplay(fontSize: 13)),
                  onPressed: () => _showSvgModal(pose),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text("Copy SVG", style: widget.theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () => _copySvgCode(pose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
