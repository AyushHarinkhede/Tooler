import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER VECTOR CHARACTER (Faithful to Reference Poses)
/// High-fidelity, smooth vector curves, human proportions, clean lines,
/// theme-adaptive trousers & accents, and dark-mode outline inversion.
/// ---------------------------------------------------------------------------

enum ToolerCharacterPose {
  workingLaptop('character_working_laptop.svg', 'Working at Desk with Laptop', 'Side view typing on laptop at desk with coffee and succulent plant'),
  whiteboardPlanning('character_whiteboard_planning.svg', 'Whiteboard Strategy & Planning', 'Standing at whiteboard holding marker, connecting sticky notes flowchart'),
  tabletThinking('character_tablet_thinking.svg', 'Ergonomic Chair & Tablet (Thinking)', 'Reclining in office chair with crossed legs, holding tablet and hand on chin'),
  presentationChart('character_presentation_chart.svg', 'Presentation Flipchart & Analytics', 'Standing beside tripod flipchart easel pointing at exponential growth curve'),
  dualMonitor('character_dual_monitor.svg', 'Dual Monitors Power Workstation', 'Sitting at workstation desk with dual screens and pedestal drawers holding document'),
  celebratingSuccess('character_celebrating_success.svg', 'Celebrating Success & Task Done', 'Fist pump in victory at desk with completed tasks checklist floating on wall'),
  brainstormStickyWall('character_brainstorm_sticky_wall.svg', 'Brainstorming Sticky Wall Cluster', 'Placing sticky notes onto idea cluster web on whiteboard'),
  videoCall('character_video_call.svg', 'Video Call & Virtual Meeting', 'Sitting at desk waving hand at laptop webcam in a friendly virtual call'),
  studyWriting('character_study_writing.svg', 'Study & Journaling with Desk Lamp', 'Leaning forward writing in notebook with angle task lamp and books'),
  creativeDrawing('character_creative_drawing.svg', 'Creative UI Wireframe & Stylus', 'Reclining in chair drawing with digital stylus on tablet with UI wireframe board'),
  projectRoadmap('character_project_roadmap.svg', 'Project Roadmap & Gantt Schedule', 'Standing with clipboard pointing marker at project roadmap schedule board'),
  phoneMultitasking('character_phone_multitasking.svg', 'Phone Call & Contract Review', 'Speaking on smartphone while pointing at floating certified contract document'),
  weatherClean('character_weather_clean.svg', 'Weather & Clean Air Guardian', 'Standing vector character for live weather, air quality and atmospheric ecology'),
  weatherGood('character_aqi_pose1_good.svg', 'Clean Air Breathing Mascot', 'Deep breathing with open arms, fresh air trails and green leaves'),
  weatherCough('character_aqi_pose2_cough.svg', 'Moderate Air Cough Mascot', 'Coughing with hand to mouth and drifting autumn leaves'),
  weatherMask('character_aqi_pose3_mask.svg', 'Protective Mask Air Mascot', 'Wearing protective N95 mask in rising smog'),
  weatherSadMask('character_aqi_pose4_sad.svg', 'Heavy Pollution Sad Mascot', 'Sad slouched posture with mask in thick particulate smog'),
  weatherOxygen('character_aqi_pose5_oxygen.svg', 'Hazardous Air Oxygen Mascot', 'Wearing oxygen mask connected to medical cylinder tank'),
  weatherWorst('character_aqi_pose6_worst.svg', 'Critical Toxic Weather Mascot', 'Emaciated and wrinkled with oxygen cylinder and dead tree in heavy smog');

  final String assetName;
  final String title;
  final String description;

  const ToolerCharacterPose(this.assetName, this.title, this.description);

  String get assetPath => 'assets/illustrations/$assetName';
}

class ToolerCharacter extends StatefulWidget {
  final ToolerCharacterPose pose;
  final double width;
  final double height;
  final StationeryTheme theme;
  final VoidCallback? onTap;
  final bool animate;
  final BoxFit fit;
  final bool withBackdrop;

  const ToolerCharacter({
    super.key,
    required this.pose,
    required this.theme,
    this.width = 160,
    this.height = 140,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  });

  // Convenience named constructors for popular screen roles
  const ToolerCharacter.working({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.workingLaptop;

  const ToolerCharacter.celebrating({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.celebratingSuccess;

  const ToolerCharacter.studying({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.studyWriting;

  const ToolerCharacter.planning({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.whiteboardPlanning;

  const ToolerCharacter.waving({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.videoCall;

  const ToolerCharacter.thinking({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.tabletThinking;

  const ToolerCharacter.designing({
    super.key,
    required this.theme,
    this.width = 150,
    this.height = 130,
    this.onTap,
    this.animate = false,
    this.fit = BoxFit.contain,
    this.withBackdrop = false,
  }) : pose = ToolerCharacterPose.creativeDrawing;

  @override
  State<ToolerCharacter> createState() => _ToolerCharacterState();
}

class _ToolerCharacterState extends State<ToolerCharacter> with SingleTickerProviderStateMixin {
  static final Map<String, String> _rawAssetCache = {};
  static final Map<String, String> _themedSvgCache = {};
  String? _svgString;
  AnimationController? _animController;
  Animation<double>? _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _loadSvg();

    if (widget.animate) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat(reverse: true);

      _hoverAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
        CurvedAnimation(parent: _animController!, curve: Curves.easeInOutSine),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ToolerCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose ||
        oldWidget.theme.mode != widget.theme.mode ||
        oldWidget.theme.isDark != widget.theme.isDark ||
        oldWidget.theme.useMaterialYou != widget.theme.useMaterialYou ||
        oldWidget.theme.primary != widget.theme.primary) {
      _loadSvg();
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _loadSvg() async {
    final assetPath = widget.pose.assetPath;
    final cacheKey = '${assetPath}_${widget.theme.mode}_${widget.theme.isDark}_${widget.theme.primary.toARGB32()}';
    if (_themedSvgCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _svgString = _themedSvgCache[cacheKey]!;
        });
      }
      return;
    }

    String raw;
    if (_rawAssetCache.containsKey(assetPath)) {
      raw = _rawAssetCache[assetPath]!;
    } else {
      try {
        raw = await rootBundle.loadString(assetPath);
        _rawAssetCache[assetPath] = raw;
      } catch (e) {
        return;
      }
    }

    final themed = _processThemedSvg(raw, widget.theme);
    _themedSvgCache[cacheKey] = themed;
    if (mounted) {
      setState(() {
        _svgString = themed;
      });
    }
  }

  static String _processThemedSvg(String rawSvg, StationeryTheme theme) {
    final hexPrimary = '#${(theme.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final hexLight = '#${(theme.primary.withValues(alpha: 0.22).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final hexPantsBack = '#${(theme.primary.withValues(alpha: 0.78).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    var svg = rawSvg
        .replaceAll('var(--char-accent, #9468E8)', hexPrimary)
        .replaceAll('#9468E8', hexPrimary)
        .replaceAll('#F43F5E', hexPrimary)
        .replaceAll('var(--char-accent, #F43F5E)', hexPrimary)
        .replaceAll('#7E4EE0', hexPantsBack)
        .replaceAll('#EDE9FE', hexLight)
        .replaceAll('#C8B6FA', hexLight)
        .replaceAll('#DDD6FE', hexLight);

    // Keep character's hair and clothes authentic black (#1D2436, #1E2235) in both Light and Dark mode!
    // Never turn human hair or dress into white.
    return svg;
  }

  @override
  Widget build(BuildContext context) {
    if (_svgString == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    Widget content = SvgPicture.string(
      _svgString!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );

    if (_hoverAnimation != null) {
      content = RepaintBoundary(
        child: AnimatedBuilder(
          animation: _hoverAnimation!,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _hoverAnimation!.value),
              child: child,
            );
          },
          child: content,
        ),
      );
    }

    if (widget.withBackdrop) {
      content = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.theme.characterBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.theme.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.theme.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: content,
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: () {
          SoundService().playClick();
          widget.onTap!();
        },
        child: content,
      );
    }

    return content;
  }
}
