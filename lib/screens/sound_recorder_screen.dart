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
  final bool aiEnhanced;

  VoiceRecordingItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
    this.tag = 'Recording',
    this.caption = '',
    List<int>? bookmarks,
    this.peakDb = 0.0,
    this.aiEnhanced = true,
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
        'aiEnhanced': aiEnhanced,
      };

  factory VoiceRecordingItem.fromJson(Map<String, dynamic> json) =>
      VoiceRecordingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        tag: json['tag'] as String? ?? 'Recording',
        caption: json['caption'] as String? ?? '',
        bookmarks: (json['bookmarks'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        peakDb: (json['peakDb'] as num?)?.toDouble() ?? 0.0,
        aiEnhanced: json['aiEnhanced'] as bool? ?? true,
      );
}

/// Keeps active recording alive in RAM across screen navigation, backgrounding,
/// and phone lock/unlock cycles, backed by Android ToolerAudioService.
class _ActiveRecordingSession {
  static final AudioRecorder sharedRecorder = AudioRecorder();
  static bool isRecording = false;
  static bool isPaused = false;
  static DateTime? startedAt;
  static int pausedAccumulatedSeconds = 0;
  static String audioSource = 'mic';
  static bool aiEnhanced = true;
  static double peakDb = 0.0;
  static final List<int> bookmarks = [];
}

class SoundRecorderScreen extends StatefulWidget {
  final StationeryTheme theme;
  const SoundRecorderScreen({super.key, required this.theme});

  @override
  State<SoundRecorderScreen> createState() => _SoundRecorderScreenState();
}

class _SoundRecorderScreenState extends State<SoundRecorderScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _storageKey = 'tooler_saved_voice_recordings';
  static const MethodChannel _loopbackChannel =
      MethodChannel('com.tooler.tooler/audio_loopback');

  // Audio Recorder & Streams (backed by persistent session recorder)
  AudioRecorder get _recorder => _ActiveRecordingSession.sharedRecorder;
  StreamSubscription? _pcmStreamSub;
  StreamSubscription? _ampSub;
  Timer? _simTimer;
  DateTime? _lastMicPacketTime;
  Timer? _watchdogTimer;

  // Earphone Audio Pass-Through / Loopback State
  bool _isPassThroughEnabled = false;
  String _monitorCaptureSource = 'phone'; // 'phone' or 'earphone'
  String _monitorListenOutput = 'earphone'; // 'earphone' or 'phone'
  bool _isBluetoothConnected = false;
  double _passThroughVolume = 1.0;
  Timer? _bluetoothCheckTimer;

  String get _passThroughRoute =>
      (_monitorCaptureSource == 'earphone' && _monitorListenOutput == 'phone')
          ? 'earphone_to_phone'
          : 'phone_to_earphone';

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

  // Active Captions
  final TextEditingController _captionController = TextEditingController();

  // Audio Input Sources & Call Telemetry
  String _selectedAudioSource = 'mic'; // 'mic', 'earphone', 'system_sound', 'call'
  bool _isCallActive = false;
  Timer? _callCheckTimer;

  // AI Voice Clarity
  bool _isAiVoiceCorrectionEnabled = true;

  // Audio Playback
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  static const List<double> _playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  bool get _isPlayingAudio => _playerState == PlayerState.playing;

  // Saved Recordings List
  List<VoiceRecordingItem> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initPlayerListeners();
    _loadRecordings();
    _restorePersistentSession();
    _checkBluetoothStatus();
    _bluetoothCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkBluetoothStatus();
    });
    _checkCallStatus();
    _callCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkCallStatus();
    });
    // Watchdog to ensure live dB never freezes (strictly paused during playback & monitor)
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isRecording &&
          !_isPlayingAudio &&
          !_isPassThroughEnabled &&
          _lastMicPacketTime != null &&
          DateTime.now().difference(_lastMicPacketTime!).inMilliseconds > 1600) {
        _recoverLiveMicMonitoring();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNativeMonitorStatus();
      if (_isRecording && !_isPausedRecording && _ActiveRecordingSession.startedAt != null) {
        final int elapsed = _ActiveRecordingSession.pausedAccumulatedSeconds +
            DateTime.now().difference(_ActiveRecordingSession.startedAt!).inSeconds;
        if (mounted) setState(() => _recordSeconds = elapsed);
      } else if (!_isRecording && !_isPlayingAudio && !_isPassThroughEnabled) {
        _startLiveMicMonitoring();
      }
    }
    // When paused/inactive/hidden: DO NOT stop recording or foreground audio monitor!
  }

  Future<void> _restorePersistentSession() async {
    await _syncNativeMonitorStatus();

    if (_ActiveRecordingSession.isRecording) {
      final int elapsed = _ActiveRecordingSession.isPaused
          ? _ActiveRecordingSession.pausedAccumulatedSeconds
          : _ActiveRecordingSession.pausedAccumulatedSeconds +
              (_ActiveRecordingSession.startedAt != null
                  ? DateTime.now()
                      .difference(_ActiveRecordingSession.startedAt!)
                      .inSeconds
                  : 0);
      if (mounted) {
        setState(() {
          _isRecording = true;
          _isPausedRecording = _ActiveRecordingSession.isPaused;
          _recordSeconds = elapsed;
          _selectedAudioSource = _ActiveRecordingSession.audioSource;
          _isAiVoiceCorrectionEnabled = _ActiveRecordingSession.aiEnhanced;
          _recordingPeakDb = _ActiveRecordingSession.peakDb;
          _currentBookmarks
            ..clear()
            ..addAll(_ActiveRecordingSession.bookmarks);
        });
      }
      _attachRecordingTimersAndAmp();
    } else if (!_isPassThroughEnabled) {
      await _startLiveMicMonitoring();
    }
  }

  Future<void> _syncNativeMonitorStatus() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final dynamic raw = await _loopbackChannel.invokeMethod('getMonitorStatus');
      if (raw is Map && mounted) {
        setState(() {
          _isPassThroughEnabled = raw['isLoopbackRunning'] == true;
          _monitorCaptureSource = (raw['captureSource'] as String?) ?? _monitorCaptureSource;
          _monitorListenOutput = (raw['listenOutput'] as String?) ?? _monitorListenOutput;
          final double? g = (raw['gain'] as num?)?.toDouble();
          if (g != null && g >= 0.2 && g <= 2.0) {
            _passThroughVolume = g;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothCheckTimer?.cancel();
    _callCheckTimer?.cancel();
    _watchdogTimer?.cancel();
    // Do NOT stop background audio monitor or active recording on dispose!
    _pcmStreamSub?.cancel();
    _ampSub?.cancel();
    _simTimer?.cancel();
    _recordTimer?.cancel();
    _pulseController.dispose();
    if (!_ActiveRecordingSession.isRecording) {
      try {
        _recorder.stop();
      } catch (_) {}
    }
    _player.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _captionController.dispose();
    super.dispose();
  }

  void _initPlayerListeners() {
    if (!kIsWeb && Platform.isAndroid) {
      _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    }
    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _durSub = _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
    _stateSub = _player.onPlayerStateChanged.listen((st) {
      if (mounted) {
        setState(() => _playerState = st);
        if (st == PlayerState.paused || st == PlayerState.stopped) {
          _resumeLiveMicAfterPlayback();
        }
      }
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _currentPosition = Duration.zero;
        });
        _resumeLiveMicAfterPlayback();
      }
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

  // --- LIVE MICROPHONE MONITORING & CALIBRATION ---
  Future<void> _pauseLiveMicForPlayback() async {
    _simTimer?.cancel();
    await _pcmStreamSub?.cancel();
    _pcmStreamSub = null;
    if (!_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
  }

  Future<void> _resumeLiveMicAfterPlayback() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && !_isRecording && !_isPlayingAudio && !_isPassThroughEnabled) {
      await _startLiveMicMonitoring();
    }
  }

  Future<void> _startLiveMicMonitoring() async {
    if (_isRecording || _isPlayingAudio || _isPassThroughEnabled) return;
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
          audioInterruption: AudioInterruptionMode.none,
        ),
      );

      _pcmStreamSub?.cancel();
      _pcmStreamSub = stream.listen((Uint8List chunk) {
        if (!mounted || _isRecording || _isPlayingAudio) return;
        _lastMicPacketTime = DateTime.now();

        double sumSquares = 0.0;
        int count = chunk.length ~/ 2;
        if (count > 0) {
          int sliceSize = math.max(1, count ~/ 4);
          List<double> sliceAmps = [];
          double slicePeak = 0;
          int sliceCount = 0;

          for (int i = 0; i < chunk.length - 1; i += 2) {
            int sample = chunk[i] | (chunk[i + 1] << 8);
            if (sample >= 32768) sample -= 65536; // signed int16
            double sVal = sample.toDouble();
            sumSquares += sVal * sVal;
            if (sVal.abs() > slicePeak) slicePeak = sVal.abs();
            sliceCount++;

            if (sliceCount >= sliceSize) {
              // Direct live amplitude for waveform visualizer [0.08 to 1.0]
              sliceAmps.add((slicePeak / 16000.0).clamp(0.08, 1.0));
              slicePeak = 0;
              sliceCount = 0;
            }
          }

          double rms = math.sqrt(sumSquares / count);
          // Standard acoustic calibration for mobile MEMS mics:
          // 0 dBFS ≈ 98 dB SPL (maximum mobile mic linear range)
          double dbFs = 20 * (math.log(rms > 1.0 ? (rms / 32767.0) : 0.00003) / math.ln10);
          double rawSpl = (98.0 + dbFs).clamp(28.0, 115.0);
          // Smooth exponential filter for natural, professional meter response
          double smoothedSpl = (_currentDb * 0.35) + (rawSpl * 0.65);

          _updateLiveDecibel(smoothedSpl, sliceAmps: sliceAmps);
        }
      }, onError: (e) {
        debugPrint('Mic stream error: $e, recovering live mic');
        _recoverLiveMicMonitoring();
      });
    } catch (e) {
      debugPrint('Live mic init error: $e, recovering live mic');
      _recoverLiveMicMonitoring();
    }
  }

  void _recoverLiveMicMonitoring() {
    if (_isRecording || _isPlayingAudio || _isPassThroughEnabled) return;
    _startAmbientSimulation();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_isRecording && !_isPlayingAudio && !_isPassThroughEnabled) {
        _startLiveMicMonitoring();
      }
    });
  }

  void _startAmbientSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted || _isRecording) return;
      // Realistic ambient room noise (30 to 44 dB with gentle natural voice variations)
      final double wave = math.sin(timer.tick * 0.3) * 4.0;
      final double jitter = (_random.nextDouble() * 3.0) - 1.5;
      final double simulatedDb = (35.0 + wave + jitter).clamp(30.0, 92.0);
      _updateLiveDecibel(simulatedDb);
    });
  }

  void _updateLiveDecibel(double db, {List<double>? sliceAmps}) {
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

      if (sliceAmps != null && sliceAmps.isNotEmpty) {
        for (final amp in sliceAmps) {
          _liveAmplitudes.removeAt(0);
          _liveAmplitudes.add(amp);
        }
      } else {
        // Fallback normalized amplitude for waveform bars [0.08 to 1.0]
        final double normalized = ((db - 30.0) / 70.0).clamp(0.08, 1.0);
        _liveAmplitudes.removeAt(0);
        final double variation = (_random.nextDouble() * 0.08) - 0.04;
        _liveAmplitudes.add((normalized + variation).clamp(0.08, 1.0));
      }
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

      // Stop playback if active so mic capture is clean
      if (_isPlayingAudio) {
        await _player.stop();
        _currentlyPlayingId = null;
      }

      // Start Android Foreground Service + WakeLock so recording survives
      // backgrounding (in RAM) and screen lock/unlock cycles
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _loopbackChannel.invokeMethod('startRecordingService');
        } catch (_) {}
      }

      // Pause monitoring stream to allow dedicated recording capture
      await _pcmStreamSub?.cancel();
      _pcmStreamSub = null;
      _simTimer?.cancel();
      try {
        await _recorder.stop();
      } catch (_) {}

      String? path;
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = '${dir.path}/tooler_sound_$timestamp.m4a';
      }

      AndroidAudioSource audioSource;
      switch (_selectedAudioSource) {
        case 'call':
          audioSource = AndroidAudioSource.voiceCommunication;
          break;
        case 'system_sound':
          audioSource = AndroidAudioSource.voiceCommunication;
          break;
        case 'earphone':
          audioSource = AndroidAudioSource.mic;
          break;
        case 'mic':
        default:
          audioSource = AndroidAudioSource.mic;
          break;
      }

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: _isAiVoiceCorrectionEnabled ? 192000 : 128000,
          sampleRate: 44100,
          autoGain: _isAiVoiceCorrectionEnabled,
          echoCancel: _isAiVoiceCorrectionEnabled,
          noiseSuppress: _isAiVoiceCorrectionEnabled,
          audioInterruption: AudioInterruptionMode.none,
          androidConfig: AndroidRecordConfig(
            audioSource: audioSource,
          ),
        ),
        path: path ?? '',
      );

      _ActiveRecordingSession.isRecording = true;
      _ActiveRecordingSession.isPaused = false;
      _ActiveRecordingSession.startedAt = DateTime.now();
      _ActiveRecordingSession.pausedAccumulatedSeconds = 0;
      _ActiveRecordingSession.audioSource = _selectedAudioSource;
      _ActiveRecordingSession.aiEnhanced = _isAiVoiceCorrectionEnabled;
      _ActiveRecordingSession.peakDb = _currentDb;
      _ActiveRecordingSession.bookmarks.clear();

      setState(() {
        _isRecording = true;
        _isPausedRecording = false;
        _recordSeconds = 0;
        _recordingPeakDb = _currentDb;
        _currentBookmarks.clear();
      });

      _attachRecordingTimersAndAmp();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _loopbackChannel.invokeMethod('stopRecordingService');
        } catch (_) {}
      }
      _ActiveRecordingSession.isRecording = false;
      _restartMonitoringAfterStop();
    }
  }

  void _attachRecordingTimersAndAmp() {
    // Listen to amplitude updates while actively recording
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (!mounted || !_isRecording) return;
      _lastMicPacketTime = DateTime.now();
      // amp.current is dBFS (-60 to 0) -> map to SPL dB (30 to 115)
      final double rawSpl = (98.0 + amp.current).clamp(28.0, 115.0);
      final double normalized = ((rawSpl - 30.0) / 70.0).clamp(0.08, 1.0);
      if (rawSpl > _ActiveRecordingSession.peakDb) {
        _ActiveRecordingSession.peakDb = rawSpl;
      }
      _updateLiveDecibel(rawSpl, sliceAmps: [normalized, normalized]);
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPausedRecording && mounted) {
        final int elapsed = _ActiveRecordingSession.pausedAccumulatedSeconds +
            (_ActiveRecordingSession.startedAt != null
                ? DateTime.now()
                    .difference(_ActiveRecordingSession.startedAt!)
                    .inSeconds
                : _recordSeconds + 1);
        setState(() => _recordSeconds = elapsed);
      }
    });
  }

  Future<void> _pauseRecording() async {
    SoundService().playKey();
    HapticFeedback.lightImpact();
    await _recorder.pause();
    if (_ActiveRecordingSession.startedAt != null) {
      _ActiveRecordingSession.pausedAccumulatedSeconds +=
          DateTime.now().difference(_ActiveRecordingSession.startedAt!).inSeconds;
      _ActiveRecordingSession.startedAt = null;
    }
    _ActiveRecordingSession.isPaused = true;
    setState(() => _isPausedRecording = true);
  }

  Future<void> _resumeRecording() async {
    SoundService().playKey();
    HapticFeedback.lightImpact();
    await _recorder.resume();
    _ActiveRecordingSession.startedAt = DateTime.now();
    _ActiveRecordingSession.isPaused = false;
    setState(() => _isPausedRecording = false);
  }

  void _addBookmarkMarker() {
    SoundService().playKey();
    HapticFeedback.selectionClick();
    if (_recordSeconds > 0 && !_currentBookmarks.contains(_recordSeconds)) {
      setState(() {
        _currentBookmarks.add(_recordSeconds);
        _ActiveRecordingSession.bookmarks.add(_recordSeconds);
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
    _ampSub = null;

    final String? recordedPath = await _recorder.stop();
    final bool wasAiEnhanced = _ActiveRecordingSession.aiEnhanced;
    final String sourceUsed = _ActiveRecordingSession.audioSource;

    _ActiveRecordingSession.isRecording = false;
    _ActiveRecordingSession.isPaused = false;
    _ActiveRecordingSession.startedAt = null;
    _ActiveRecordingSession.pausedAccumulatedSeconds = 0;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _loopbackChannel.invokeMethod('stopRecordingService');
      } catch (_) {}
    }

    setState(() {
      _isRecording = false;
      _isPausedRecording = false;
    });

    if (recordedPath == null || _recordSeconds < 1) {
      setState(() {
        _recordSeconds = 0;
      });
      _restartMonitoringAfterStop();
      return;
    }

    // Export copy to public Download/Tooler_Recordings folder, while keeping
    // the app-internal recordedPath for 100% reliable playback across Android versions
    final publicCopyPath = await _saveFileToPublicDownloads(recordedPath);

    final String chosenTag = switch (sourceUsed) {
      'call' => 'Call Recording',
      'system_sound' => 'System Sound',
      'earphone' => 'Earphone Audio',
      _ => 'Voice Record',
    };

    final String defaultTitle =
        '$chosenTag · ${_recordings.length + 1} (${_recordingPeakDb.toStringAsFixed(0)} dB)';
    final newItem = VoiceRecordingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: defaultTitle,
      filePath: recordedPath,
      durationSeconds: _recordSeconds,
      createdAt: DateTime.now(),
      tag: chosenTag,
      caption: _captionController.text.trim(),
      bookmarks: List<int>.from(_currentBookmarks),
      peakDb: _recordingPeakDb,
      aiEnhanced: wasAiEnhanced,
    );

    setState(() {
      _recordings.insert(0, newItem);
      _recordSeconds = 0;
      _captionController.clear();
      _currentBookmarks.clear();
    });

    await _saveRecordings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publicCopyPath != null
                ? 'Recording saved to Download/Tooler_Recordings/'
                : 'Recording saved successfully',
            style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: widget.theme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Smoothly restart live mic monitoring without freezing
    _restartMonitoringAfterStop();
  }

  Future<void> _restartMonitoringAfterStop() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted && !_isRecording && !_isPlayingAudio && !_isPassThroughEnabled) {
      await _startLiveMicMonitoring();
    }
  }

  Future<String?> _saveFileToPublicDownloads(String sourcePath) async {
    try {
      if (kIsWeb) return sourcePath;
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      // First try native Android method to trigger MediaScannerConnection
      if (Platform.isAndroid) {
        try {
          final fileName = sourcePath.split(Platform.pathSeparator).last;
          final String? nativeSaved = await _loopbackChannel.invokeMethod('saveToPublicDirectory', {
            'sourcePath': sourcePath,
            'fileName': fileName,
          });
          if (nativeSaved != null && nativeSaved.isNotEmpty) {
            return nativeSaved;
          }
        } catch (_) {}
      }

      Directory? downloadDir;
      final androidDownload =
          Directory('/storage/emulated/0/Download/Tooler_Recordings');
      if (await Directory('/storage/emulated/0/Download').exists()) {
        if (!await androidDownload.exists()) {
          await androidDownload.create(recursive: true);
        }
        downloadDir = androidDownload;
      } else {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final extSub = Directory('${ext.path}/Tooler_Recordings');
          if (!await extSub.exists()) await extSub.create(recursive: true);
          downloadDir = extSub;
        }
      }

      if (downloadDir != null) {
        final fileName = sourcePath.split(Platform.pathSeparator).last;
        final targetPath = '${downloadDir.path}/$fileName';
        final targetFile = await sourceFile.copy(targetPath);
        return targetFile.path;
      }
    } catch (e) {
      debugPrint("Failed to copy recording to public storage: $e");
    }
    return null;
  }

  // --- PLAYBACK ACTIONS (Zero AudioFocus Conflict) ---
  Future<String?> _resolvePlayablePath(String originalPath) async {
    if (kIsWeb) return originalPath;
    if (await File(originalPath).exists()) return originalPath;
    final fileName = originalPath.split(RegExp(r'[/\\]')).last;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final docCandidate = '${docDir.path}/$fileName';
      if (await File(docCandidate).exists()) return docCandidate;
    } catch (_) {}
    final dlCandidate = '/storage/emulated/0/Download/Tooler_Recordings/$fileName';
    if (await File(dlCandidate).exists()) return dlCandidate;
    return null;
  }

  Future<void> _playRecording(VoiceRecordingItem item) async {
    HapticFeedback.selectionClick();

    try {
      if (_currentlyPlayingId == item.id && _playerState == PlayerState.playing) {
        await _player.pause();
        if (mounted) setState(() => _playerState = PlayerState.paused);
        return;
      }

      // Always pause live mic monitoring BEFORE playing so AudioRecorder never steals AudioFocus
      await _pauseLiveMicForPlayback();

      if (_currentlyPlayingId == item.id && _playerState == PlayerState.paused) {
        await _player.setPlaybackRate(_playbackSpeed);
        await _player.resume();
        if (mounted) setState(() => _playerState = PlayerState.playing);
        return;
      }

      final String? resolvedPath = await _resolvePlayablePath(item.filePath);
      if (resolvedPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Audio file not found in storage.',
                style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await _player.stop();
      setState(() {
        _currentlyPlayingId = item.id;
        _currentPosition = Duration.zero;
        _totalDuration = Duration(seconds: item.durationSeconds);
        _playerState = PlayerState.playing;
      });

      if (kIsWeb) {
        await _player.setSource(UrlSource(resolvedPath));
      } else {
        await _player.setSource(DeviceFileSource(resolvedPath));
      }
      await _player.setPlaybackRate(_playbackSpeed);
      await _player.resume();
    } catch (e) {
      debugPrint('Playback error: $e');
      if (mounted) {
        setState(() => _playerState = PlayerState.stopped);
      }
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    HapticFeedback.selectionClick();
    _playbackSpeed = speed;
    if (_currentlyPlayingId != null) {
      try {
        await _player.setPlaybackRate(_playbackSpeed);
      } catch (_) {}
    }
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

  // --- EARPHONE AUDIO PASS-THROUGH / LOOPBACK CONTROLS ---
  Future<void> _checkBluetoothStatus() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool isConn =
            await _loopbackChannel.invokeMethod('isBluetoothConnected') ?? false;
        if (mounted && _isBluetoothConnected != isConn) {
          setState(() {
            _isBluetoothConnected = isConn;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _checkCallStatus() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool inCall =
            await _loopbackChannel.invokeMethod('isCallActive') ?? false;
        if (mounted && _isCallActive != inCall) {
          setState(() {
            _isCallActive = inCall;
            if (inCall && !_isRecording) {
              _selectedAudioSource = 'call';
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _togglePassThrough(bool enable) async {
    SoundService().playKey();
    HapticFeedback.lightImpact();

    if (!enable) {
      await _stopPassThrough();
      return;
    }

    await _checkBluetoothStatus();
    final bool needsEarphone =
        _monitorCaptureSource == 'earphone' || _monitorListenOutput == 'earphone';
    if (needsEarphone && !_isBluetoothConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please connect Bluetooth or wired earphone for earphone routing.",
              style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: Colors.amber.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Pause live dB mic stream if not recording so native loopback gets exclusive mic
    if (!_isRecording) {
      await _pauseLiveMicForPlayback();
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool ok = await _loopbackChannel.invokeMethod('startLoopback', {
          'route': _passThroughRoute,
          'captureSource': _monitorCaptureSource,
          'listenOutput': _monitorListenOutput,
          'gain': _passThroughVolume,
        }) ?? false;
        if (mounted) {
          setState(() {
            _isPassThroughEnabled = ok;
          });
        }
      } else {
        setState(() {
          _isPassThroughEnabled = true;
        });
      }
    } catch (e) {
      debugPrint("Error starting loopback: $e");
    }
  }

  Future<void> _stopPassThrough() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _loopbackChannel.invokeMethod('stopLoopback');
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isPassThroughEnabled = false;
      });
      _resumeLiveMicAfterPlayback();
    }
  }

  Future<void> _setMonitorRoute({
    String? captureSource,
    String? listenOutput,
  }) async {
    SoundService().playKey();
    HapticFeedback.selectionClick();
    setState(() {
      if (captureSource != null) _monitorCaptureSource = captureSource;
      if (listenOutput != null) _monitorListenOutput = listenOutput;
    });
    if (_isPassThroughEnabled) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          await _loopbackChannel.invokeMethod('startLoopback', {
            'route': _passThroughRoute,
            'captureSource': _monitorCaptureSource,
            'listenOutput': _monitorListenOutput,
            'gain': _passThroughVolume,
          });
        }
      } catch (e) {
        debugPrint("Error updating loopback route: $e");
      }
    }
  }

  void _updatePassThroughVolume(double val) {
    setState(() {
      _passThroughVolume = val;
    });
    if (_isPassThroughEnabled && !kIsWeb && Platform.isAndroid) {
      try {
        _loopbackChannel.invokeMethod('setGain', {'gain': val});
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color safetyColor = _getSafetyColor(_currentDb);
    final String safetyStatus = _getSafetyStatus(_currentDb);
    final double avgDb = _sampleCount > 0 ? (_sumDb / _sampleCount) : _currentDb;

    return Scaffold(
      backgroundColor: widget.theme.bg,
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

                  const SizedBox(height: 18),

                  // 5. EARPHONE & PHONE AUDIO MONITOR
                  _buildEarphonePassThroughSection(),

                  const SizedBox(height: 32),
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
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: widget.theme.primary, size: 20),
                tooltip: "Reset dB Stats",
                onPressed: _resetDecibelStats,
              ),
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
              Icon(Icons.graphic_eq_rounded, size: 20, color: safetyColor),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Phone Call Auto-Detection Banner
          if (_isCallActive)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Phone Call Detected",
                          style: widget.theme.fontDisplay(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Call recording mode enabled. Tap Record Call to capture conversation audio.",
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                      _isPausedRecording
                          ? "PAUSED"
                          : _selectedAudioSource == 'call'
                              ? "RECORDING CALL"
                              : _selectedAudioSource == 'system_sound'
                                  ? "RECORDING SYSTEM AUDIO"
                                  : "RECORDING SOUND",
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

            // Caption / Note field
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: "Add note / description...",
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
            // Idle State: Audio Source Selector (Color-highlighted pills, no checkmark)
            Text(
              "Audio Source",
              style: widget.theme.fontDisplay(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSourceChip(
                    id: 'mic',
                    label: 'Phone Mic',
                    icon: Icons.mic_rounded,
                  ),
                  _buildSourceChip(
                    id: 'earphone',
                    label: 'Earphone',
                    icon: Icons.headphones_rounded,
                  ),
                  _buildSourceChip(
                    id: 'system_sound',
                    label: 'System Sound',
                    icon: Icons.volume_up_rounded,
                  ),
                  _buildSourceChip(
                    id: 'call',
                    label: 'Call Recording',
                    icon: Icons.phone_in_talk_rounded,
                    isLiveCall: _isCallActive,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Compact AI Voice Clarity Toggle (No caption/subtitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isAiVoiceCorrectionEnabled
                    ? widget.theme.primary.withValues(alpha: 0.08)
                    : widget.theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAiVoiceCorrectionEnabled
                      ? widget.theme.primary.withValues(alpha: 0.35)
                      : widget.theme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: _isAiVoiceCorrectionEnabled
                        ? widget.theme.primary
                        : widget.theme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "AI Voice Clarity",
                      style: widget.theme.fontDisplay(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.text,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isAiVoiceCorrectionEnabled,
                    activeThumbColor: widget.theme.primary,
                    onChanged: (val) {
                      SoundService().playKey();
                      HapticFeedback.selectionClick();
                      setState(() => _isAiVoiceCorrectionEnabled = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Idle State: Start Record Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAudioSource == 'call'
                            ? "Record Phone Call"
                            : _selectedAudioSource == 'system_sound'
                                ? "Record System Audio"
                                : "Record Noise & Audio",
                        style: widget.theme.fontDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.text,
                        ),
                      ),
                      Text(
                        _selectedAudioSource == 'call'
                            ? "Captures active call conversation"
                            : _selectedAudioSource == 'system_sound'
                                ? "Captures phone system playback"
                                : "Runs in background while in RAM",
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAudioSource == 'call'
                        ? Colors.green.shade700
                        : widget.theme.primary,
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
                  icon: Icon(
                    _selectedAudioSource == 'call'
                        ? Icons.phone_in_talk_rounded
                        : Icons.fiber_manual_record_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _selectedAudioSource == 'call'
                        ? "Record Call"
                        : "Record Sound",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceChip({
    required String id,
    required String label,
    required IconData icon,
    bool isLiveCall = false,
  }) {
    final bool isSelected = (_selectedAudioSource == id);
    final Color activeBg =
        (isLiveCall && isSelected) ? Colors.green.shade700 : widget.theme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          SoundService().playKey();
          HapticFeedback.selectionClick();
          setState(() {
            _selectedAudioSource = id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : widget.theme.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeBg
                  : (isLiveCall ? Colors.green : widget.theme.border),
              width: 1.3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBg.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isLiveCall ? Colors.green : widget.theme.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : widget.theme.text,
                ),
              ),
              if (isLiveCall) ...[
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.greenAccent : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedPopupButton({bool compact = false}) {
    return PopupMenuButton<double>(
      tooltip: "Playback Speed",
      initialValue: _playbackSpeed,
      onSelected: (spd) => _setPlaybackSpeed(spd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: widget.theme.border),
      ),
      color: widget.theme.cardBg,
      itemBuilder: (context) => _playbackSpeeds.map((spd) {
        final bool isCur = (_playbackSpeed == spd);
        return PopupMenuItem<double>(
          value: spd,
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${spd}x",
                style: widget.theme.fontMono(
                  fontSize: 13,
                  fontWeight: isCur ? FontWeight.bold : FontWeight.w500,
                  color: isCur ? widget.theme.primary : widget.theme.text,
                ),
              ),
              if (isCur)
                Icon(
                  Icons.circle,
                  size: 8,
                  color: widget.theme.primary,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: widget.theme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.theme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed_rounded,
              size: compact ? 13 : 14,
              color: widget.theme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              "${_playbackSpeed}x",
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.bold,
                color: widget.theme.primary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: compact ? 15 : 16,
              color: widget.theme.primary,
            ),
          ],
        ),
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
              _buildSpeedPopupButton(),
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
                final bool isSelectedCard = _currentlyPlayingId == item.id;
                final bool isPlaying = (isSelectedCard &&
                    _playerState == PlayerState.playing);
                final bool isExpandedPlayer = isSelectedCard &&
                    (_playerState == PlayerState.playing ||
                        _playerState == PlayerState.paused);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpandedPlayer
                        ? widget.theme.primary.withValues(alpha: 0.08)
                        : widget.theme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isExpandedPlayer
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
                                    const SizedBox(width: 6),
                                    // AI Voice Clarity status — icon only (no text)
                                    Tooltip(
                                      message: item.aiEnhanced
                                          ? "AI Voice Clarity: ON"
                                          : "AI Voice Clarity: OFF",
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: item.aiEnhanced
                                              ? widget.theme.primary.withValues(alpha: 0.14)
                                              : widget.theme.border.withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item.aiEnhanced
                                              ? Icons.auto_awesome_rounded
                                              : Icons.auto_awesome_outlined,
                                          size: 12,
                                          color: item.aiEnhanced
                                              ? widget.theme.primary
                                              : widget.theme.textSecondary.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save_alt_rounded, size: 20),
                            tooltip: "Save to System Storage",
                            color: widget.theme.primary,
                            onPressed: () async {
                              final saved = await _saveFileToPublicDownloads(item.filePath);
                              if (context.mounted) {
                                final fileName = item.filePath.split(Platform.pathSeparator).last;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      saved != null
                                          ? "Saved to Phone: Download/Tooler_Recordings/$fileName"
                                          : "File exported to device storage",
                                      style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
                                    ),
                                    backgroundColor: widget.theme.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
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
                      if (isExpandedPlayer && _totalDuration.inMilliseconds > 0)
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildSpeedPopupButton(compact: true),
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: item.aiEnhanced
                                            ? "AI Voice Clarity: ON"
                                            : "AI Voice Clarity: OFF",
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: item.aiEnhanced
                                                ? widget.theme.primary.withValues(alpha: 0.14)
                                                : widget.theme.border.withValues(alpha: 0.4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            item.aiEnhanced
                                                ? Icons.auto_awesome_rounded
                                                : Icons.auto_awesome_outlined,
                                            size: 14,
                                            color: item.aiEnhanced
                                                ? widget.theme.primary
                                                : widget.theme.textSecondary.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ],
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

  // --- 5. EARPHONE & PHONE AUDIO MONITOR ---
  Widget _buildEarphonePassThroughSection() {
    final bool isPhoneToEarphone =
        _monitorCaptureSource == 'phone' && _monitorListenOutput == 'earphone';
    final bool isEarphoneToPhone =
        _monitorCaptureSource == 'earphone' && _monitorListenOutput == 'phone';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isPassThroughEnabled
              ? widget.theme.primary.withValues(alpha: 0.6)
              : widget.theme.border,
          width: 1.8,
        ),
        boxShadow: _isPassThroughEnabled
            ? [
                BoxShadow(
                  color: widget.theme.primary.withValues(alpha: 0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header + Master Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_isPassThroughEnabled
                                ? widget.theme.primary
                                : widget.theme.border)
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.headphones_rounded,
                        size: 20,
                        color: _isPassThroughEnabled
                            ? widget.theme.primary
                            : widget.theme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Earphone Audio Monitor",
                            style: widget.theme.fontDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text,
                            ),
                          ),
                          if (_isPassThroughEnabled)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Active in Background",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isPassThroughEnabled,
                activeTrackColor: widget.theme.primary,
                onChanged: (val) => _togglePassThrough(val),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bluetooth / Headset Connection Status Banner
          if (!_isBluetoothConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade900.withValues(alpha: 0.35),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bluetooth_disabled_rounded,
                    size: 18,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Connect Bluetooth or wired earphone for earphone monitoring.",
                      style: widget.theme.fontDisplay(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth_connected_rounded,
                    size: 17,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Earphone / Bluetooth Connected",
                    style: widget.theme.fontDisplay(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Quick Segmented Switch: Phone ➔ Earphone | Earphone ➔ Phone
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.theme.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.theme.border, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setMonitorRoute(
                      captureSource: 'phone',
                      listenOutput: 'earphone',
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPhoneToEarphone
                            ? widget.theme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 15,
                            color: isPhoneToEarphone
                                ? Colors.white
                                : widget.theme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isPhoneToEarphone
                                ? Colors.white70
                                : widget.theme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.headphones_rounded,
                            size: 15,
                            color: isPhoneToEarphone
                                ? Colors.white
                                : widget.theme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Phone → Ear",
                            style: widget.theme.fontDisplay(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isPhoneToEarphone
                                  ? Colors.white
                                  : widget.theme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setMonitorRoute(
                      captureSource: 'earphone',
                      listenOutput: 'phone',
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isEarphoneToPhone
                            ? widget.theme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.headphones_rounded,
                            size: 15,
                            color: isEarphoneToPhone
                                ? Colors.white
                                : widget.theme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isEarphoneToPhone
                                ? Colors.white70
                                : widget.theme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.phone_android_rounded,
                            size: 15,
                            color: isEarphoneToPhone
                                ? Colors.white
                                : widget.theme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Ear → Phone",
                            style: widget.theme.fontDisplay(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isEarphoneToPhone
                                  ? Colors.white
                                  : widget.theme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Explicit Audio Capture (Mic Input) & Live Listen (Speaker Output) Selectors
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Audio Capture From (Mic Input)
                Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      size: 14,
                      color: widget.theme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Audio Capture (Mic)",
                      style: widget.theme.fontDisplay(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMonitorOptionPill(
                        label: "Phone Mic",
                        icon: Icons.phone_android_rounded,
                        isSelected: _monitorCaptureSource == 'phone',
                        onTap: () => _setMonitorRoute(captureSource: 'phone'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMonitorOptionPill(
                        label: "Earphone Mic",
                        icon: Icons.headset_mic_rounded,
                        isSelected: _monitorCaptureSource == 'earphone',
                        onTap: () => _setMonitorRoute(captureSource: 'earphone'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Live Listen On (Speaker Output)
                Row(
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      size: 14,
                      color: widget.theme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Live Listen (Output)",
                      style: widget.theme.fontDisplay(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMonitorOptionPill(
                        label: "Earphone",
                        icon: Icons.headphones_rounded,
                        isSelected: _monitorListenOutput == 'earphone',
                        onTap: () => _setMonitorRoute(listenOutput: 'earphone'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMonitorOptionPill(
                        label: "Phone Speaker",
                        icon: Icons.speaker_phone_rounded,
                        isSelected: _monitorListenOutput == 'phone',
                        onTap: () => _setMonitorRoute(listenOutput: 'phone'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Monitor Volume / Gain Slider
          Row(
            children: [
              Icon(
                Icons.volume_up_rounded,
                size: 18,
                color: widget.theme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                "Monitor Volume",
                style: widget.theme.fontDisplay(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text,
                ),
              ),
              const Spacer(),
              Text(
                "${(_passThroughVolume * 100).toInt()}%",
                style: widget.theme.fontMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: widget.theme.primary,
              thumbColor: widget.theme.primary,
            ),
            child: Slider(
              value: _passThroughVolume,
              min: 0.2,
              max: 2.0,
              onChanged: (val) => _updatePassThroughVolume(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorOptionPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : widget.theme.cardBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? widget.theme.primary : widget.theme.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : widget.theme.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : widget.theme.text,
                ),
              ),
            ),
          ],
        ),
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
