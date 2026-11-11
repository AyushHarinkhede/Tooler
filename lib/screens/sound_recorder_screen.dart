import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class VoiceRecordingItem {
  final String id;
  String title;
  final String filePath;
  final int durationSeconds;
  final DateTime createdAt;
  String tag;
  String caption;
  final List<int> bookmarks;

  VoiceRecordingItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
    this.tag = 'Voice Memo',
    this.caption = '',
    List<int>? bookmarks,
  }) : bookmarks = bookmarks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
        'tag': tag,
        'caption': caption,
        'bookmarks': bookmarks,
      };

  factory VoiceRecordingItem.fromJson(Map<String, dynamic> json) => VoiceRecordingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        tag: json['tag'] as String? ?? 'Voice Memo',
        caption: json['caption'] as String? ?? '',
        bookmarks: (json['bookmarks'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      );
}

class SoundRecorderScreen extends StatefulWidget {
  final StationeryTheme theme;
  const SoundRecorderScreen({super.key, required this.theme});

  @override
  State<SoundRecorderScreen> createState() => _SoundRecorderScreenState();
}

class _SoundRecorderScreenState extends State<SoundRecorderScreen> with TickerProviderStateMixin {
  static const String _storageKey = 'tooler_saved_voice_recordings';

  // Audio Recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPausedRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final List<int> _currentBookmarks = [];

  // Live Audio Waveform Animation
  late AnimationController _waveformAnimController;
  late AnimationController _pulseAnimController;
  final List<double> _liveAmplitudes = List.generate(28, (_) => 0.15);
  final math.Random _random = math.Random();

  // Active Captions & Tags
  String _activeTag = 'Voice Memo';
  final TextEditingController _captionController = TextEditingController();
  final List<String> _tagPresets = [
    'Voice Memo',
    'Meeting Note',
    'Lecture',
    'Quick Idea',
    'Interview',
  ];

  // Audio Playback
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  // Saved Recordings List
  List<VoiceRecordingItem> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _waveformAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(_updateWaveform);

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _initPlayerListeners();
    _loadRecordings();
  }

  void _initPlayerListeners() {
    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _durSub = _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
    _stateSub = _player.onPlayerStateChanged.listen((st) {
      if (mounted) setState(() => _playerState = st);
    });
  }

  Future<void> _loadRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _recordings = list.map((e) => VoiceRecordingItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String raw = jsonEncode(_recordings.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('Error saving recordings: $e');
    }
  }

  void _updateWaveform() {
    if (_isRecording && !_isPausedRecording) {
      setState(() {
        for (int i = 0; i < _liveAmplitudes.length; i++) {
          final double base = 0.2 + (math.sin((_recordSeconds * 5) + i * 0.4).abs() * 0.55);
          final double jitter = (_random.nextDouble() * 0.25);
          _liveAmplitudes[i] = (base + jitter).clamp(0.12, 0.98);
        }
      });
    }
  }

  Future<void> _startRecording() async {
    SoundService().playClick();
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record audio.')),
          );
        }
        return;
      }

      String? path;
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = '${dir.path}/tooler_audio_$timestamp.m4a';
      }

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path ?? '',
      );

      setState(() {
        _isRecording = true;
        _isPausedRecording = false;
        _recordSeconds = 0;
        _currentBookmarks.clear();
      });

      _waveformAnimController.repeat();
      _pulseAnimController.repeat(reverse: true);

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPausedRecording && mounted) {
          setState(() => _recordSeconds++);
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    SoundService().playTap();
    await _recorder.pause();
    setState(() => _isPausedRecording = true);
    _pulseAnimController.stop();
  }

  Future<void> _resumeRecording() async {
    SoundService().playTap();
    await _recorder.resume();
    setState(() => _isPausedRecording = false);
    _pulseAnimController.repeat(reverse: true);
  }

  void _addBookmarkMarker() {
    SoundService().playKey();
    if (_recordSeconds > 0 && !_currentBookmarks.contains(_recordSeconds)) {
      setState(() {
        _currentBookmarks.add(_recordSeconds);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('Marker added at ${_formatSeconds(_recordSeconds)}'),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    SoundService().playClick();
    _recordTimer?.cancel();
    _waveformAnimController.stop();
    _pulseAnimController.stop();

    final String? recordedPath = await _recorder.stop();
    if (recordedPath == null || _recordSeconds < 1) {
      setState(() {
        _isRecording = false;
        _isPausedRecording = false;
        _recordSeconds = 0;
      });
      return;
    }

    final String defaultTitle = 'Recording ${_recordings.length + 1}';
    final newItem = VoiceRecordingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: defaultTitle,
      filePath: recordedPath,
      durationSeconds: _recordSeconds,
      createdAt: DateTime.now(),
      tag: _activeTag,
      caption: _captionController.text.trim(),
      bookmarks: List<int>.from(_currentBookmarks),
    );

    setState(() {
      _recordings.insert(0, newItem);
      _isRecording = false;
      _isPausedRecording = false;
      _recordSeconds = 0;
      _captionController.clear();
      _currentBookmarks.clear();
    });

    await _saveRecordings();
  }

  Future<void> _playRecording(VoiceRecordingItem item) async {
    SoundService().playClick();
    if (_currentlyPlayingId == item.id && _playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_currentlyPlayingId == item.id && _playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.stop();
      _currentlyPlayingId = item.id;
      if (kIsWeb) {
        await _player.play(UrlSource(item.filePath));
      } else {
        await _player.play(DeviceFileSource(item.filePath));
      }
      await _player.setPlaybackRate(_playbackSpeed);
    }
    setState(() {});
  }

  Future<void> _togglePlaybackSpeed() async {
    SoundService().playTap();
    final speeds = [1.0, 1.25, 1.5, 2.0];
    int nextIdx = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    _playbackSpeed = speeds[nextIdx];
    await _player.setPlaybackRate(_playbackSpeed);
    setState(() {});
  }

  Future<void> _deleteRecording(VoiceRecordingItem item) async {
    SoundService().playClick();
    if (_currentlyPlayingId == item.id) {
      await _player.stop();
      _currentlyPlayingId = null;
    }
    try {
      if (!kIsWeb) {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}

    setState(() {
      _recordings.removeWhere((r) => r.id == item.id);
    });
    await _saveRecordings();
  }

  void _renameRecording(VoiceRecordingItem item) {
    final titleCtrl = TextEditingController(text: item.title);
    final noteCtrl = TextEditingController(text: item.caption);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.theme.border, width: 2),
        ),
        title: Text('Edit Recording Note', style: widget.theme.fontDisplay(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Caption / Memo Notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                item.title = titleCtrl.text.trim().isEmpty ? item.title : titleCtrl.text.trim();
                item.caption = noteCtrl.text.trim();
              });
              _saveRecordings();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int sec) {
    final int m = sec ~/ 60;
    final int s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _waveformAnimController.dispose();
    _pulseAnimController.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    _captionController.dispose();
    super.dispose();
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
          "Sound Recorder",
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
                // Top Studio Recording Deck
                _buildRecordingDeck(),

                const Divider(height: 1),

                // Saved Recordings List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Saved Recordings (${_recordings.length})",
                        style: widget.theme.fontDisplay(fontSize: 16),
                      ),
                      if (_currentlyPlayingId != null)
                        InkWell(
                          onTap: _togglePlaybackSpeed,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.theme.lavenderCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: widget.theme.border, width: 1),
                            ),
                            child: Text(
                              "${_playbackSpeed}x Speed",
                              style: widget.theme.fontMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Saved Recordings List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _recordings.isEmpty
                          ? _buildEmptyState()
                          : _buildRecordingsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingDeck() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Column(
        children: [
          // Category Tag Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tagPresets.map((tag) {
                final bool isSelected = (_activeTag == tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: _isRecording ? null : () => setState(() => _activeTag = tag),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.theme.primary : widget.theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? widget.theme.primary : widget.theme.border,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: widget.theme.fontMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : widget.theme.text,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Fluid Live Oscillating Audio Waveform Visualizer
          SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_liveAmplitudes.length, (index) {
                final double amp = _liveAmplitudes[index];
                final double barH = _isRecording && !_isPausedRecording
                    ? 8 + (amp * 52)
                    : 6.0;
                return Container(
                  width: 3.5,
                  height: barH,
                  margin: const EdgeInsets.symmetric(horizontal: 2.2),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? (_isPausedRecording ? const Color(0xFFFFA502) : const Color(0xFF2ED573))
                        : widget.theme.border.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Elapsed Recording Digital Timer
          Text(
            _formatSeconds(_recordSeconds),
            style: widget.theme.fontMono(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _isRecording
                  ? (_isPausedRecording ? const Color(0xFFFFA502) : const Color(0xFF2ED573))
                  : widget.theme.text,
            ),
          ),

          const SizedBox(height: 6),

          // Live Bookmark Markers Row
          if (_currentBookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                children: _currentBookmarks.map((sec) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.theme.lavenderCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.primary, width: 1),
                    ),
                    child: Text(
                      'Marker: ${_formatSeconds(sec)}',
                      style: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold, color: widget.theme.primary),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Live Caption / Voice Note Field (User request: "usme kuch captions bhi hona")
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.theme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.theme.border, width: 1.2),
            ),
            child: TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: _isRecording ? 'Add live memo/caption notes as you speak...' : 'Attach caption or topic notes...',
                hintStyle: widget.theme.fontDoodle(fontSize: 12, color: widget.theme.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: widget.theme.fontDoodle(fontSize: 13),
            ),
          ),

          const SizedBox(height: 8),

          // Controls Toolbar (Record, Pause, Stop, Add Marker)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Add Bookmark Marker Button
                IconButton(
                  tooltip: "Bookmark Moment",
                  onPressed: _addBookmarkMarker,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 26),
                  color: widget.theme.primary,
                ),
                const SizedBox(width: 14),

                // Pause / Resume Button
                InkWell(
                  onTap: _isPausedRecording ? _resumeRecording : _pauseRecording,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA502),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.theme.border, width: 2),
                    ),
                    child: Icon(
                      _isPausedRecording ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
              ],

              // Central Main Action Button: Record or Stop
              AnimatedBuilder(
                animation: _pulseAnimController,
                builder: (context, child) {
                  return Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isRecording && !_isPausedRecording
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF4757).withValues(alpha: 0.35 * _pulseAnimController.value),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: InkWell(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      borderRadius: BorderRadius.circular(34),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isRecording ? const Color(0xFFFF4757) : widget.theme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (_isRecording) const SizedBox(width: 44),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 48,
            color: widget.theme.textSecondary.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            "No sound recordings yet",
            style: widget.theme.fontDisplay(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap the microphone button to record audio with live captions.",
            style: widget.theme.fontDoodle(fontSize: 13, color: widget.theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final item = _recordings[index];
        final bool isCurrent = (_currentlyPlayingId == item.id);
        final bool isPlaying = isCurrent && (_playerState == PlayerState.playing);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? widget.theme.primary : widget.theme.border,
              width: isCurrent ? 2.0 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Play/Pause Button
                    InkWell(
                      onTap: () => _playRecording(item),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPlaying ? widget.theme.primary : widget.theme.lavenderCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.theme.border, width: 1.5),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isPlaying ? Colors.white : widget.theme.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title, Tag & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: widget.theme.fontDisplay(fontSize: 15),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.theme.lavenderCard,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.tag,
                                  style: widget.theme.fontMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${_formatSeconds(item.durationSeconds)} • ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}",
                            style: widget.theme.fontMono(fontSize: 11, color: widget.theme.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Actions Menu (Edit & Delete)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _renameRecording(item),
                      tooltip: "Edit Notes",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFFF4757)),
                      onPressed: () => _deleteRecording(item),
                      tooltip: "Delete",
                    ),
                  ],
                ),
              ),

              // Caption / Audio Notes preview
              if (item.caption.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.theme.lavenderCard.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Caption: ${item.caption}",
                    style: widget.theme.fontDoodle(fontSize: 12, color: widget.theme.text),
                  ),
                ),

              // Active Player Scrubber & Bookmarks
              if (isCurrent) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: widget.theme.primary,
                          inactiveTrackColor: widget.theme.border,
                          thumbColor: widget.theme.primary,
                        ),
                        child: Slider(
                          value: _currentPosition.inMilliseconds.toDouble().clamp(
                                0.0,
                                math.max(1.0, _totalDuration.inMilliseconds.toDouble()),
                              ),
                          max: math.max(1.0, _totalDuration.inMilliseconds.toDouble()),
                          onChanged: (val) {
                            _player.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatSeconds(_currentPosition.inSeconds),
                              style: widget.theme.fontMono(fontSize: 11, color: widget.theme.textSecondary),
                            ),
                            Text(
                              _formatSeconds(_totalDuration.inSeconds),
                              style: widget.theme.fontMono(fontSize: 11, color: widget.theme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bookmarks chips for jumping to markers
                if (item.bookmarks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10, top: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: item.bookmarks.map((bSec) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text('Marker ${_formatSeconds(bSec)}'),
                              labelStyle: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold),
                              onPressed: () {
                                _player.seek(Duration(seconds: bSec));
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
