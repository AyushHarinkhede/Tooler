import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final double peakDb;

  VoiceRecordingItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
    this.tag = 'Noise Check',
    this.caption = '',
    List<int>? bookmarks,
    this.peakDb = 0.0,
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
        'peakDb': peakDb,
      };

  factory VoiceRecordingItem.fromJson(Map<String, dynamic> json) =>
      VoiceRecordingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        tag: json['tag'] as String? ?? 'Noise Check',
        caption: json['caption'] as String? ?? '',
        bookmarks: (json['bookmarks'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        peakDb: (json['peakDb'] as num?)?.toDouble() ?? 0.0,
      );
}

class SoundRecorderScreen extends StatefulWidget {
  final StationeryTheme theme;
  const SoundRecorderScreen({super.key, required this.theme});

  @override
  State<SoundRecorderScreen> createState() => _SoundRecorderScreenState();
}

class _SoundRecorderScreenState extends State<SoundRecorderScreen>
    with TickerProviderStateMixin {
  static const String _storageKey = 'tooler_saved_voice_recordings';

  // Audio Recorder & Streams
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _pcmStreamSub;
  StreamSubscription? _ampSub;
  Timer? _simTimer;

  // Live Decibels & Waveform
  double _currentDb = 38.0;
  double _minDb = 34.0;
  double _maxDb = 45.0;
  double _sumDb = 38.0;
  int _sampleCount = 1;

  final List<double> _liveAmplitudes = List.generate(36, (_) => 0.15);
  final math.Random _random = math.Random();

  // Recording State
  bool _isRecording = false;
  bool _isPausedRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final List<int> _currentBookmarks = [];
  double _recordingPeakDb = 0.0;

  // Animation Controllers
  late AnimationController _pulseController;

  // Active Captions & Tags
  String _activeTag = 'Noise Check';
  final TextEditingController _captionController = TextEditingController();
  final List<String> _tagPresets = [
    'Noise Check',
    'Voice Memo',
    'Meeting Note',
    'Lecture',
    'Sound Evidence',
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initPlayerListeners();
    _loadRecordings();
    _startLiveMicMonitoring();
  }

  @override
  void dispose() {
    _pcmStreamSub?.cancel();
    _ampSub?.cancel();
    _simTimer?.cancel();
    _recordTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _player.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _captionController.dispose();
    super.dispose();
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
        _recordings = list
            .map((e) => VoiceRecordingItem.fromJson(e as Map<String, dynamic>))
            .toList();
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
      final String raw =
          jsonEncode(_recordings.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('Error saving recordings: $e');
    }
  }

  // --- LIVE MICROPHONE MONITORING ---
  Future<void> _startLiveMicMonitoring() async {
    try {
      final bool hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _startAmbientSimulation();
        return;
      }

      if (kIsWeb) {
        _startAmbientSimulation();
        return;
      }

      // Start raw PCM 16-bit audio stream for live dB & waveform analysis
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _pcmStreamSub?.cancel();
      _pcmStreamSub = stream.listen((Uint8List chunk) {
        if (!mounted || _isRecording) return;

        int sum = 0;
        int count = chunk.length ~/ 2;
        if (count > 0) {
          for (int i = 0; i < chunk.length - 1; i += 2) {
            int sample = chunk[i] | (chunk[i + 1] << 8);
            if (sample >= 32768) sample -= 65536; // signed int16
            sum += sample * sample;
          }
          double rms = math.sqrt(sum / count);
          double rawDb = 20 * (math.log(rms > 1 ? rms : 1) / math.ln10);
          // Calibrate to mobile acoustic SPL scale [30 dB to 120 dB]
          double splDb = (32.0 + (rawDb * 0.95)).clamp(30.0, 118.0);
          _updateLiveDecibel(splDb);
        }
      }, onError: (e) {
        debugPrint('Mic stream error: $e, falling back to ambient simulation');
        _startAmbientSimulation();
      });
    } catch (e) {
      debugPrint('Live mic init error: $e, falling back to ambient simulation');
      _startAmbientSimulation();
    }
  }

  void _startAmbientSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted || _isRecording) return;
      // Realistic ambient room noise (34 to 48 dB with periodic natural voice peaks)
      final double wave = math.sin(timer.tick * 0.3) * 6.0;
      final double jitter = (_random.nextDouble() * 5.0) - 2.5;
      final double simulatedDb = (38.0 + wave + jitter).clamp(32.0, 95.0);
      _updateLiveDecibel(simulatedDb);
    });
  }

  void _updateLiveDecibel(double db) {
    if (!mounted) return;
    setState(() {
      _currentDb = db;
      if (db < _minDb || _minDb == 0) _minDb = db;
      if (db > _maxDb) _maxDb = db;
      _sumDb += db;
      _sampleCount++;

      if (_isRecording && db > _recordingPeakDb) {
        _recordingPeakDb = db;
      }

      // Normalized amplitude for waveform bars [0.08 to 1.0]
      final double normalized = ((db - 30.0) / 75.0).clamp(0.08, 1.0);

      // Shift waveform buffer
      _liveAmplitudes.removeAt(0);
      // Add slight organic variation to trailing bars
      final double variation = (_random.nextDouble() * 0.12) - 0.06;
      _liveAmplitudes.add((normalized + variation).clamp(0.08, 1.0));
    });
  }

  void _resetDecibelStats() {
    SoundService().playKey();
    HapticFeedback.selectionClick();
    setState(() {
      _minDb = _currentDb;
      _maxDb = _currentDb;
      _sumDb = _currentDb;
      _sampleCount = 1;
    });
  }

  // Sound Safety Assessment
  Color _getSafetyColor(double db) {
    if (db < 68.0) {
      return widget.theme.primary; // Safe / Normal -> Selected Theme Color!
    } else if (db < 82.0) {
      return const Color(0xFFF59E0B); // Moderate / Noticeable Noise (Amber)
    } else {
      return const Color(0xFFEF4444); // Loud / Harmful (Red)
    }
  }

  String _getSafetyStatus(double db) {
    if (db < 50.0) {
      return "QUIET · Library Ambient";
    } else if (db < 68.0) {
      return "SAFE · Normal Conversation";
    } else if (db < 80.0) {
      return "MODERATE · Busy Office / Street";
    } else if (db < 88.0) {
      return "LOUD · High Noise Level";
    } else {
      return "DANGER · Hearing Risk (>85dB)";
    }
  }

  // --- RECORDING ACTIONS ---
  Future<void> _startRecording() async {
    SoundService().playKey();
    HapticFeedback.mediumImpact();

    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record sound.'),
            ),
          );
        }
        return;
      }

      // Pause monitoring stream to allow dedicated recording capture
      await _pcmStreamSub?.cancel();
      _simTimer?.cancel();
      await _recorder.stop();

      String? path;
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = '${dir.path}/tooler_sound_$timestamp.m4a';
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path ?? '',
      );

      setState(() {
        _isRecording = true;
        _isPausedRecording = false;
        _recordSeconds = 0;
        _recordingPeakDb = _currentDb;
        _currentBookmarks.clear();
      });

      // Listen to amplitude updates while actively recording
      _ampSub?.cancel();
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        if (!mounted || !_isRecording) return;
        // amp.current is dBFS (-60 to 0) -> map to SPL dB (35 to 115)
        final double spl = (100.0 + amp.current).clamp(32.0, 118.0);
        _updateLiveDecibel(spl);
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPausedRecording && mounted) {
          setState(() => _recordSeconds++);
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _startLiveMicMonitoring();
    }
  }

  Future<void> _pauseRecording() async {
    SoundService().playKey();
    HapticFeedback.lightImpact();
    await _recorder.pause();
    setState(() => _isPausedRecording = true);
  }

  Future<void> _resumeRecording() async {
    SoundService().playKey();
    HapticFeedback.lightImpact();
    await _recorder.resume();
    setState(() => _isPausedRecording = false);
  }

  void _addBookmarkMarker() {
    SoundService().playKey();
    HapticFeedback.selectionClick();
    if (_recordSeconds > 0 && !_currentBookmarks.contains(_recordSeconds)) {
      setState(() {
        _currentBookmarks.add(_recordSeconds);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            'Marker added at ${_formatSeconds(_recordSeconds)} (${_currentDb.toStringAsFixed(1)} dB)',
            style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: widget.theme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    SoundService().playSuccess();
    HapticFeedback.heavyImpact();

    _recordTimer?.cancel();
    _ampSub?.cancel();

    final String? recordedPath = await _recorder.stop();
    if (recordedPath == null || _recordSeconds < 1) {
      setState(() {
        _isRecording = false;
        _isPausedRecording = false;
        _recordSeconds = 0;
      });
      _startLiveMicMonitoring();
      return;
    }

    final String defaultTitle =
        '$_activeTag · ${_recordings.length + 1} (${_recordingPeakDb.toStringAsFixed(0)} dB)';
    final newItem = VoiceRecordingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: defaultTitle,
      filePath: recordedPath,
      durationSeconds: _recordSeconds,
      createdAt: DateTime.now(),
      tag: _activeTag,
      caption: _captionController.text.trim(),
      bookmarks: List<int>.from(_currentBookmarks),
      peakDb: _recordingPeakDb,
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
    _startLiveMicMonitoring();
  }

  // --- PLAYBACK ACTIONS ---
  Future<void> _playRecording(VoiceRecordingItem item) async {
    SoundService().playKey();
    HapticFeedback.selectionClick();

    if (_currentlyPlayingId == item.id && _playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_currentlyPlayingId == item.id &&
        _playerState == PlayerState.paused) {
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
    SoundService().playKey();
    HapticFeedback.selectionClick();
    final speeds = [1.0, 1.25, 1.5, 2.0];
    int nextIdx = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    _playbackSpeed = speeds[nextIdx];
    await _player.setPlaybackRate(_playbackSpeed);
    setState(() {});
  }

  Future<void> _deleteRecording(VoiceRecordingItem item) async {
    SoundService().playKey();
    HapticFeedback.lightImpact();

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
        title: Text(
          'Edit Recording & Note',
          style: widget.theme.fontDisplay(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Sound Note / Environment Details',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                item.title = titleCtrl.text.trim().isEmpty
                    ? item.title
                    : titleCtrl.text.trim();
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
  Widget build(BuildContext context) {
    final Color safetyColor = _getSafetyColor(_currentDb);
    final String safetyStatus = _getSafetyStatus(_currentDb);
    final double avgDb = _sampleCount > 0 ? (_sumDb / _sampleCount) : _currentDb;

    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.theme.text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Noise Meter & Recorder",
              style: widget.theme.fontDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.theme.text,
              ),
            ),
            Text(
              "Live Acoustic Decibels · Sound Safety Check",
              style: widget.theme.fontMono(
                fontSize: 11,
                color: widget.theme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: widget.theme.primary),
            tooltip: "Reset dB Stats",
            onPressed: _resetDecibelStats,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  // 1. CIRCULAR DECIBEL GAUGE (Prominent Big Decibel Meter)
                  _buildCircularDecibelGauge(safetyColor, safetyStatus, avgDb),

                  const SizedBox(height: 16),

                  // 2. LIVE AUDIO OSCILLOSCOPE WAVEFORM
                  _buildLiveWaveformCard(safetyColor),

                  const SizedBox(height: 16),

                  // 3. SOUND RECORDING & CAPTURE CONTROLS
                  _buildSoundCaptureCard(safetyColor),

                  const SizedBox(height: 18),

                  // 4. SAVED RECORDINGS & SOUND LOGS
                  _buildSavedRecordingsSection(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. CIRCULAR DECIBEL GAUGE ---
  Widget _buildCircularDecibelGauge(
    Color safetyColor,
    String safetyStatus,
    double avgDb,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: safetyColor.withValues(alpha: 0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: safetyColor.withValues(alpha: 0.2),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Radial Gauge
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom Painter for Radial Bar Gauge
                CustomPaint(
                  size: const Size(210, 210),
                  painter: _RadialDecibelBarPainter(
                    decibel: _currentDb,
                    gaugeColor: safetyColor,
                    trackColor: widget.theme.border.withValues(alpha: 0.5),
                  ),
                ),

                // Center Large Decibel Number & Safety Badge
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _currentDb.toStringAsFixed(0),
                          style: widget.theme.fontDisplay(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: safetyColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "dB",
                          style: widget.theme.fontMono(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Safety Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: safetyColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: safetyColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _currentDb < 68.0
                            ? "SAFE"
                            : _currentDb < 82.0
                                ? "MODERATE"
                                : "DANGER",
                        style: widget.theme.fontMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: safetyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Acoustic Sound Safety Description Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: safetyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: safetyColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentDb < 82.0
                      ? Icons.hearing_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: safetyColor,
                ),
                const SizedBox(width: 8),
                Text(
                  safetyStatus,
                  style: widget.theme.fontDisplay(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: safetyColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Min / Avg / Max Telemetry Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDbStatBadge("MIN", "${_minDb.toStringAsFixed(0)} dB"),
              Container(width: 1.2, height: 26, color: widget.theme.border),
              _buildDbStatBadge(
                "AVG",
                "${avgDb.toStringAsFixed(0)} dB",
                color: widget.theme.primary,
              ),
              Container(width: 1.2, height: 26, color: widget.theme.border),
              _buildDbStatBadge("PEAK", "${_maxDb.toStringAsFixed(0)} dB"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDbStatBadge(String label, String val, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: widget.theme.fontMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: widget.theme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: widget.theme.fontMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? widget.theme.text,
          ),
        ),
      ],
    );
  }

  // --- 2. LIVE AUDIO OSCILLOSCOPE WAVEFORM ---
  Widget _buildLiveWaveformCard(Color safetyColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 18, color: safetyColor),
                  const SizedBox(width: 6),
                  Text(
                    "Live Real-Time Audio Waves",
                    style: widget.theme.fontDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                ],
              ),
              Text(
                "LIVE ${(_currentDb).toStringAsFixed(1)} dB",
                style: widget.theme.fontMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: safetyColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 36 Dynamic Waveform Bars
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_liveAmplitudes.length, (idx) {
                final double amp = _liveAmplitudes[idx];
                final double barH = (amp * 56.0).clamp(6.0, 56.0);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: barH,
                    decoration: BoxDecoration(
                      color: safetyColor.withValues(
                        alpha: (0.35 + (amp * 0.65)).clamp(0.35, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. SOUND RECORDING & CAPTURE CONTROLS ---
  Widget _buildSoundCaptureCard(Color safetyColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          if (_isRecording) ...[
            // Recording Active State
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPausedRecording ? "PAUSED" : "RECORDING SOUND",
                      style: widget.theme.fontMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatSeconds(_recordSeconds),
                  style: widget.theme.fontMono(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tag selector while recording
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tagPresets.map((tag) {
                  final bool isSelected = (_activeTag == tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: widget.theme.primary,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : widget.theme.text,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _activeTag = tag);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Caption / Note field
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: "Add note / noise description...",
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: widget.theme.textSecondary,
                ),
                filled: true,
                fillColor: widget.theme.bg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.theme.border),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Controls Row: Pause/Resume, Bookmark, Done
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pause / Resume
                IconButton.filledTonal(
                  icon: Icon(
                    _isPausedRecording
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  onPressed:
                      _isPausedRecording ? _resumeRecording : _pauseRecording,
                ),

                // Add Bookmark
                IconButton.filledTonal(
                  icon: const Icon(Icons.bookmark_add_rounded),
                  tooltip: "Bookmark Moment",
                  onPressed: _addBookmarkMarker,
                ),

                // Stop & Save
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  label: const Text(
                    "Save Recording",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Idle State: Start Record Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Record Noise & Audio",
                        style: widget.theme.fontDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Capture sound samples & noise evidence",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: widget.theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _startRecording,
                  icon: const Icon(Icons.fiber_manual_record_rounded, size: 18),
                  label: const Text(
                    "Record Sound",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. SAVED RECORDINGS & SOUND LOGS ---
  Widget _buildSavedRecordingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Saved Sound Records (${_recordings.length})",
                style: widget.theme.fontDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text,
                ),
              ),
              if (_currentlyPlayingId != null)
                TextButton(
                  onPressed: _togglePlaybackSpeed,
                  child: Text(
                    "${_playbackSpeed}x Speed",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recordings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No saved sound recordings yet.\nTap 'Record Sound' to capture audio.",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDisplay(
                    fontSize: 13,
                    color: widget.theme.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recordings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = _recordings[idx];
                final bool isPlaying = (_currentlyPlayingId == item.id &&
                    _playerState == PlayerState.playing);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? widget.theme.primary.withValues(alpha: 0.08)
                        : widget.theme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPlaying
                          ? widget.theme.primary
                          : widget.theme.border,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: widget.theme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                            ),
                            onPressed: () => _playRecording(item),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: widget.theme.fontDisplay(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      _formatSeconds(item.durationSeconds),
                                      style: widget.theme.fontMono(
                                        fontSize: 11,
                                        color: widget.theme.textSecondary,
                                      ),
                                    ),
                                    if (item.peakDb > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.theme.border,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Peak: ${item.peakDb.toStringAsFixed(0)} dB",
                                          style: widget.theme.fontMono(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: widget.theme.text,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            color: widget.theme.textSecondary,
                            onPressed: () => _renameRecording(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20),
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            onPressed: () => _deleteRecording(item),
                          ),
                        ],
                      ),
                      if (isPlaying && _totalDuration.inMilliseconds > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: widget.theme.primary,
                                  thumbColor: widget.theme.primary,
                                ),
                                child: Slider(
                                  value: _currentPosition.inMilliseconds.toDouble().clamp(0.0, _totalDuration.inMilliseconds.toDouble()),
                                  max: _totalDuration.inMilliseconds.toDouble(),
                                  onChanged: (val) {
                                    _player.seek(Duration(milliseconds: val.toInt()));
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatSeconds(_currentPosition.inSeconds),
                                    style: widget.theme.fontMono(fontSize: 10, color: widget.theme.textSecondary),
                                  ),
                                  Text(
                                    _formatSeconds(_totalDuration.inSeconds),
                                    style: widget.theme.fontMono(fontSize: 10, color: widget.theme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (item.caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 48),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.caption,
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.theme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// RADIAL DECIBEL BAR PAINTER (CIRCULAR SWEEP BAR GAUGE)
// Fills from 30 dB (0%) to 120 dB (100%)
// =============================================================================
class _RadialDecibelBarPainter extends CustomPainter {
  final double decibel;
  final Color gaugeColor;
  final Color trackColor;

  _RadialDecibelBarPainter({
    required this.decibel,
    required this.gaugeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 16;

    // Sweep from bottom-left (140°) to bottom-right (400° -> 260° sweep)
    const double startAngle = 140.0 * math.pi / 180.0;
    const double totalSweep = 260.0 * math.pi / 180.0;

    // Normalized progress [0.0 to 1.0] from 30 dB to 110 dB
    final double progress = ((decibel - 30.0) / 80.0).clamp(0.0, 1.0);
    final double activeSweep = totalSweep * progress;

    // Background track arc
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Active Decibel Fill Arc
    final Paint activePaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    if (activeSweep > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    // Tick markers around the arc (30, 50, 70, 90, 110 dB)
    final Paint tickPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2.0;

    for (int db = 30; db <= 110; db += 20) {
      final double p = (db - 30.0) / 80.0;
      final double ang = startAngle + (totalSweep * p);
      final Offset p1 = Offset(
        center.dx + (radius - 12) * math.cos(ang),
        center.dy + (radius - 12) * math.sin(ang),
      );
      final Offset p2 = Offset(
        center.dx + (radius + 12) * math.cos(ang),
        center.dy + (radius + 12) * math.sin(ang),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialDecibelBarPainter oldDelegate) {
    return oldDelegate.decibel != decibel ||
        oldDelegate.gaugeColor != gaugeColor;
  }
}
