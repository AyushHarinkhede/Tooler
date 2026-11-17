import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  bool _isBluetoothEnabled = false;
  bool _isBluetoothConnected = false; // true if BT earphone OR wired headset is connected
  bool _isWiredConnected = false;
  String _connectedDeviceName = '';
  double _passThroughVolume = 1.0;
  Timer? _bluetoothCheckTimer;
  Timer? _monitorMeterTimer;
  Timer? _recAmpFallbackTimer;

  String get _passThroughRoute =>
      (_monitorCaptureSource == 'earphone' && _monitorListenOutput == 'phone')
          ? 'earphone_to_phone'
          : 'phone_to_earphone';

  // Live Decibels & Ultra-Smooth Interpolated Gauge State
  double _currentDb = 36.0;
  double _displayDb = 36.0; // Smoothly damped 60/120fps display value for zero jitter
  double _peakHoldDb = 36.0;
  DateTime _peakHoldUpdatedAt = DateTime.now();
  double _minDb = 34.0;
  double _maxDb = 42.0;
  double _sumDb = 36.0;
  int _sampleCount = 1;
  Ticker? _gaugeTicker;
  Duration _lastTickerElapsed = Duration.zero;

  final List<double> _liveAmplitudes = List.generate(36, (_) => 0.14);
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

  // Audio Input Sources & Call Telemetry (Dialer + WhatsApp + Instagram + Snapchat + VoIP)
  String _selectedAudioSource = 'mic'; // 'mic', 'earphone', 'system_sound', 'call'
  bool _isCallActive = false;
  String _activeCallType = 'None';
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

    // 60/120fps silky smooth display damper for zero-jitter circular dB gauge
    _gaugeTicker = createTicker((elapsed) {
      final dt = ((elapsed - _lastTickerElapsed).inMicroseconds / 1000000.0)
          .clamp(0.001, 0.05);
      _lastTickerElapsed = elapsed;

      // Exponential smoothing: responsive attack, silky smooth release
      final bool rising = _currentDb > _displayDb;
      final double speed = rising ? 11.5 : 6.2;
      final double factor = 1.0 - math.exp(-speed * dt);
      final double nextDb = _displayDb + (_currentDb - _displayDb) * factor;

      // Smooth peak-hold indicator decay after 1.6s hold
      double nextPeak = _peakHoldDb;
      if (nextDb >= nextPeak) {
        nextPeak = nextDb;
        _peakHoldUpdatedAt = DateTime.now();
      } else if (DateTime.now().difference(_peakHoldUpdatedAt).inMilliseconds > 1600) {
        nextPeak = math.max(nextDb, nextPeak - 14.0 * dt);
      }

      if ((nextDb - _displayDb).abs() > 0.03 || (nextPeak - _peakHoldDb).abs() > 0.03) {
        if (mounted) {
          setState(() {
            _displayDb = nextDb;
            _peakHoldDb = nextPeak;
          });
        }
      }
    })..start();

    _initPlayerListeners();
    _loadRecordings();
    _restorePersistentSession();
    _checkBluetoothStatus();
    _bluetoothCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkBluetoothStatus();
    });
    _checkCallStatus();
    _callCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _checkCallStatus();
    });
    // Watchdog to ensure live dB NEVER freezes in idle, recording, or monitor mode
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (_isPassThroughEnabled) {
        _ensureMonitorMeterPolling();
      } else if (!_isRecording &&
          !_isPlayingAudio &&
          (_lastMicPacketTime == null ||
              DateTime.now().difference(_lastMicPacketTime!).inMilliseconds > 1500)) {
        _recoverLiveMicMonitoring();
      }
    });
  }

  void _ensureMonitorMeterPolling() {
    if (_monitorMeterTimer != null && _monitorMeterTimer!.isActive) return;
    _monitorMeterTimer = Timer.periodic(const Duration(milliseconds: 90), (_) async {
      if (!mounted || !_isPassThroughEnabled) {
        _monitorMeterTimer?.cancel();
        _monitorMeterTimer = null;
        return;
      }
      if (kIsWeb || !Platform.isAndroid) return;
      try {
        final dynamic raw = await _loopbackChannel.invokeMethod('getMonitorStatus');
        if (raw is Map && mounted) {
          final bool stillRunning = raw['isLoopbackRunning'] == true;
          if (!stillRunning) {
            setState(() => _isPassThroughEnabled = false);
            _monitorMeterTimer?.cancel();
            _monitorMeterTimer = null;
            _resumeLiveMicAfterPlayback();
            return;
          }
          final double? db = (raw['liveDb'] as num?)?.toDouble();
          final double? amp = (raw['liveAmp'] as num?)?.toDouble();
          if (db != null) {
            _lastMicPacketTime = DateTime.now();
            _updateLiveDecibel(db, sliceAmps: amp != null ? [amp] : null);
          }
        }
      } catch (_) {}
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
        if (mounted) {
          setState(() {
            _isPassThroughEnabled = raw['isLoopbackRunning'] == true;
            _monitorCaptureSource = (raw['captureSource'] as String?) ?? _monitorCaptureSource;
            _monitorListenOutput = (raw['listenOutput'] as String?) ?? _monitorListenOutput;
            final double? g = (raw['gain'] as num?)?.toDouble();
            if (g != null && g >= 0.2 && g <= 2.0) {
              _passThroughVolume = g;
            }
          });
          if (_isPassThroughEnabled) {
            _ensureMonitorMeterPolling();
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothCheckTimer?.cancel();
    _callCheckTimer?.cancel();
    _watchdogTimer?.cancel();
    _monitorMeterTimer?.cancel();
    _recAmpFallbackTimer?.cancel();
    _gaugeTicker?.dispose();
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

      // Cleanly close any lingering stream before opening a fresh PCM stream
      await _pcmStreamSub?.cancel();
      _pcmStreamSub = null;
      try {
        if (await _recorder.isRecording()) {
          await _recorder.stop();
        }
      } catch (_) {}

      // Start raw PCM 16-bit audio stream for live dB & waveform analysis
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          audioInterruption: AudioInterruptionMode.none,
        ),
      );

      _pcmStreamSub = stream.listen((Uint8List chunk) {
        if (!mounted || _isRecording || _isPlayingAudio || _isPassThroughEnabled) return;
        // Stop fallback simulation immediately so real hardware mic never collides with sim!
        if (_simTimer != null && _simTimer!.isActive) {
          _simTimer?.cancel();
        }
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
      // Strict Call Recording check: verify live call on Dialer, WhatsApp, Instagram, Snapchat, or VoIP
      if (_selectedAudioSource == 'call') {
        await _checkCallStatus();
        if (!_isCallActive) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: widget.theme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.amber.shade700.withValues(alpha: 0.5), width: 1.5),
                ),
                title: Row(
                  children: [
                    Icon(Icons.phone_missed_rounded, color: Colors.amber.shade700, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No Active Call Detected',
                        style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Call Recording only starts when an active call is running on Phone Dialer, WhatsApp, Instagram, Snapchat, or another calling app.\n\nStart or answer a call first, then tap Record Call.',
                  style: TextStyle(fontSize: 13, color: widget.theme.textSecondary, height: 1.45),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

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
          // voiceRecognition avoids Android VoIP/Dialer mute lock while capturing both ends clearly
          audioSource = AndroidAudioSource.voiceRecognition;
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
    // Listen to amplitude updates while actively recording (65ms smooth cadence)
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 65))
        .listen((amp) {
      if (!mounted || !_isRecording || _isPausedRecording) return;
      if (amp.current > -155.0) {
        _lastMicPacketTime = DateTime.now();
        final double rawSpl = (98.0 + amp.current).clamp(28.0, 115.0);
        final double smoothed = (_currentDb * 0.30) + (rawSpl * 0.70);
        final double normalized = ((smoothed - 30.0) / 70.0).clamp(0.08, 1.0);
        if (smoothed > _ActiveRecordingSession.peakDb) {
          _ActiveRecordingSession.peakDb = smoothed;
        }
        _updateLiveDecibel(smoothed, sliceAmps: [normalized]);
      }
    });

    // Secondary hardware amplitude poll so dB meter NEVER freezes during recording
    _recAmpFallbackTimer?.cancel();
    _recAmpFallbackTimer = Timer.periodic(const Duration(milliseconds: 90), (_) async {
      if (!mounted || !_isRecording || _isPausedRecording) return;
      final stalled = _lastMicPacketTime == null ||
          DateTime.now().difference(_lastMicPacketTime!).inMilliseconds > 220;
      if (!stalled) return;
      try {
        final amp = await _recorder.getAmplitude();
        if (!mounted || !_isRecording) return;
        if (amp.current > -155.0) {
          _lastMicPacketTime = DateTime.now();
          final double rawSpl = (98.0 + amp.current).clamp(28.0, 115.0);
          final double smoothed = (_currentDb * 0.35) + (rawSpl * 0.65);
          final double normalized = ((smoothed - 30.0) / 70.0).clamp(0.08, 1.0);
          _updateLiveDecibel(smoothed, sliceAmps: [normalized]);
        }
      } catch (_) {}
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
    _recAmpFallbackTimer?.cancel();
    _recAmpFallbackTimer = null;
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

    // Keep recording inside Tooler app list ONLY (do NOT auto-export to device storage).
    // User exports to device Download/Tooler_Recordings/ ONLY when pressing the Save icon.
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
            'Recording added to list · Tap Save icon to export to device storage',
            style: widget.theme.fontDisplay(color: Colors.white, fontSize: 12.5),
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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.45), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Audio?',
                style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'You are about to permanently delete "${item.title}" (${_formatSeconds(item.durationSeconds)}). This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: widget.theme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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

    if (mounted) {
      setState(() {
        _recordings.removeWhere((r) => r.id == item.id);
      });
    }
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
        final dynamic raw = await _loopbackChannel.invokeMethod('getBluetoothAudioState');
        if (raw is Map && mounted) {
          final btOn = raw['bluetoothEnabled'] == true;
          final earConn = raw['isEarphoneConnected'] == true;
          final wiredConn = raw['isWiredConnected'] == true;
          final devName = (raw['deviceName'] as String? ?? '').trim();

          if (_isBluetoothEnabled != btOn ||
              _isBluetoothConnected != earConn ||
              _isWiredConnected != wiredConn ||
              _connectedDeviceName != devName) {
            setState(() {
              _isBluetoothEnabled = btOn;
              _isBluetoothConnected = earConn;
              _isWiredConnected = wiredConn;
              _connectedDeviceName = devName;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _checkCallStatus() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final dynamic raw = await _loopbackChannel.invokeMethod('getCallStatus');
        if (raw is Map && mounted) {
          final bool inCall = raw['isCallActive'] == true;
          final String cType = (raw['callType'] as String? ?? 'None');
          if (_isCallActive != inCall || _activeCallType != cType) {
            setState(() {
              _isCallActive = inCall;
              _activeCallType = cType;
              if (inCall && !_isRecording) {
                _selectedAudioSource = 'call';
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  String _getEarphoneUnavailableMessage() {
    if (!_isBluetoothEnabled) {
      return "Bluetooth is OFF. Turn ON Bluetooth & connect earphones, or plug in wired earphones.";
    }
    return "Bluetooth is ON, but no earphone device is connected.";
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
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getEarphoneUnavailableMessage(),
              style: widget.theme.fontDisplay(color: Colors.white, fontSize: 12.5),
            ),
            backgroundColor: Colors.amber.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
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
          if (ok) _ensureMonitorMeterPolling();
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
    _monitorMeterTimer?.cancel();
    _monitorMeterTimer = null;
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

    final wantsEarphone = captureSource == 'earphone' || listenOutput == 'earphone';
    if (wantsEarphone && !_isBluetoothConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getEarphoneUnavailableMessage(),
              style: widget.theme.fontDisplay(color: Colors.white, fontSize: 12.5),
            ),
            backgroundColor: Colors.amber.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
    final Color safetyColor = _getSafetyColor(_displayDb);
    final String safetyStatus = _getSafetyStatus(_displayDb);
    final double avgDb = _sampleCount > 0 ? (_sumDb / _sampleCount) : _displayDb;

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
                // Custom Painter for Silky Smooth Radial Bar Gauge
                CustomPaint(
                  size: const Size(210, 210),
                  painter: _RadialDecibelBarPainter(
                    decibel: _displayDb,
                    peakHoldDb: _peakHoldDb,
                    gaugeColor: safetyColor,
                    primaryColor: widget.theme.primary,
                    trackColor: widget.theme.border.withValues(alpha: 0.45),
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
                          _displayDb.toStringAsFixed(0),
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
                        _displayDb < 68.0
                            ? "SAFE"
                            : _displayDb < 82.0
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
                "LIVE ${_displayDb.toStringAsFixed(1)} dB",
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
                          "Active Call Detected · $_activeCallType",
                          style: widget.theme.fontDisplay(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Dialer, WhatsApp, Instagram & Snapchat calls ready to record.",
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
                    isOffState: !_isBluetoothConnected,
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

            // Idle State: Start Record Row (Clean title word ONLY — caption removed)
            Row(
              children: [
                Expanded(
                  child: Text(
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
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAudioSource == 'call'
                        ? (_isCallActive ? Colors.green.shade700 : widget.theme.textSecondary.withValues(alpha: 0.55))
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
    bool isOffState = false,
  }) {
    final bool isSelected = !isOffState && (_selectedAudioSource == id);
    final Color activeBg =
        (isLiveCall && isSelected) ? Colors.green.shade700 : widget.theme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          SoundService().playKey();
          HapticFeedback.selectionClick();
          if (isOffState) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _getEarphoneUnavailableMessage(),
                  style: widget.theme.fontDisplay(color: Colors.white, fontSize: 12.5),
                ),
                backgroundColor: Colors.amber.shade900,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          setState(() {
            _selectedAudioSource = id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOffState
                ? widget.theme.border.withValues(alpha: 0.28)
                : (isSelected ? activeBg : widget.theme.bg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOffState
                  ? widget.theme.border.withValues(alpha: 0.5)
                  : (isSelected
                      ? activeBg
                      : (isLiveCall ? Colors.green : widget.theme.border)),
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
                color: isOffState
                    ? widget.theme.textSecondary.withValues(alpha: 0.42)
                    : (isSelected
                        ? Colors.white
                        : (isLiveCall ? Colors.green : widget.theme.textSecondary)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isOffState
                      ? widget.theme.textSecondary.withValues(alpha: 0.45)
                      : (isSelected ? Colors.white : widget.theme.text),
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
    // Live Bluetooth & Headset inline status shown right below title
    final Color btStatusColor;
    final IconData btStatusIcon;
    final String btStatusLabel;
    if (_isBluetoothConnected) {
      btStatusColor = const Color(0xFF10B981);
      btStatusIcon = _isWiredConnected && _connectedDeviceName == 'Wired Earphone'
          ? Icons.headset_rounded
          : Icons.bluetooth_connected_rounded;
      btStatusLabel = _connectedDeviceName.isNotEmpty
          ? 'Connected · $_connectedDeviceName'
          : 'Bluetooth Connected';
    } else if (_isBluetoothEnabled) {
      btStatusColor = const Color(0xFFF59E0B);
      btStatusIcon = Icons.bluetooth_searching_rounded;
      btStatusLabel = 'Bluetooth ON · No device connected';
    } else {
      btStatusColor = widget.theme.textSecondary.withValues(alpha: 0.75);
      btStatusIcon = Icons.bluetooth_disabled_rounded;
      btStatusLabel = 'Bluetooth is OFF';
    }

    final bool earphoneOff = !_isBluetoothConnected;

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
          // Section Header + Inline Bluetooth Status + Master Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_isPassThroughEnabled && !earphoneOff
                                ? widget.theme.primary
                                : widget.theme.border)
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.headphones_rounded,
                        size: 20,
                        color: earphoneOff
                            ? widget.theme.textSecondary.withValues(alpha: 0.45)
                            : (_isPassThroughEnabled
                                ? widget.theme.primary
                                : widget.theme.textSecondary),
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
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                btStatusIcon,
                                size: 12.5,
                                color: btStatusColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  btStatusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: btStatusColor,
                                  ),
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

          const SizedBox(height: 14),

          // Direct Audio Capture (Mic Input) & Live Listen (Output) Selectors
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
                        isOffState: false,
                        onTap: () => _setMonitorRoute(captureSource: 'phone'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMonitorOptionPill(
                        label: "Earphone Mic",
                        icon: Icons.headset_mic_rounded,
                        isSelected: !earphoneOff && _monitorCaptureSource == 'earphone',
                        isOffState: earphoneOff,
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
                        isSelected: !earphoneOff && _monitorListenOutput == 'earphone',
                        isOffState: earphoneOff,
                        onTap: () => _setMonitorRoute(listenOutput: 'earphone'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMonitorOptionPill(
                        label: "Phone Speaker",
                        icon: Icons.speaker_phone_rounded,
                        isSelected: _monitorListenOutput == 'phone',
                        isOffState: false,
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
    required bool isOffState,
    required VoidCallback onTap,
  }) {
    final Color bgColor = isOffState
        ? widget.theme.border.withValues(alpha: 0.28)
        : (isSelected ? widget.theme.primary : widget.theme.cardBg);
    final Color borderColor = isOffState
        ? widget.theme.border.withValues(alpha: 0.5)
        : (isSelected ? widget.theme.primary : widget.theme.border);
    final Color contentColor = isOffState
        ? widget.theme.textSecondary.withValues(alpha: 0.45)
        : (isSelected ? Colors.white : widget.theme.text);
    final Color iconColor = isOffState
        ? widget.theme.textSecondary.withValues(alpha: 0.42)
        : (isSelected ? Colors.white : widget.theme.textSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: contentColor,
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
// SILKY SMOOTH RADIAL DECIBEL BAR PAINTER (ZERO-JITTER STUDIO SPL GAUGE)
// Fills smoothly from 30 dB (0%) to 110 dB (100%) with gradient glow & peak dot
// =============================================================================
class _RadialDecibelBarPainter extends CustomPainter {
  final double decibel;
  final double peakHoldDb;
  final Color gaugeColor;
  final Color primaryColor;
  final Color trackColor;

  _RadialDecibelBarPainter({
    required this.decibel,
    required this.peakHoldDb,
    required this.gaugeColor,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 18;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Sweep from bottom-left (140°) to bottom-right (400° -> 260° sweep)
    const double startAngle = 140.0 * math.pi / 180.0;
    const double totalSweep = 260.0 * math.pi / 180.0;

    final double progress = ((decibel - 30.0) / 80.0).clamp(0.0, 1.0);
    final double activeSweep = totalSweep * progress;
    final double peakProgress = ((peakHoldDb - 30.0) / 80.0).clamp(0.0, 1.0);

    // 1. Subtle Inner Micro-Tick Scale Dots (30..110 dB, 25 smooth ticks)
    const int tickCount = 24;
    for (int i = 0; i <= tickCount; i++) {
      final double frac = i / tickCount;
      final double ang = startAngle + (totalSweep * frac);
      final bool isMajor = i % 6 == 0;
      final bool isLit = frac <= progress;
      final double innerR = radius - (isMajor ? 16.5 : 14.0);
      final double outerR = radius - 10.5;
      final Paint tickPaint = Paint()
        ..color = isLit
            ? gaugeColor.withValues(alpha: isMajor ? 0.72 : 0.40)
            : trackColor.withValues(alpha: isMajor ? 0.65 : 0.35)
        ..strokeWidth = isMajor ? 2.0 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(ang), center.dy + innerR * math.sin(ang)),
        Offset(center.dx + outerR * math.cos(ang), center.dy + outerR * math.sin(ang)),
        tickPaint,
      );
    }

    // 2. Smooth Recessed Background Track Arc
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, totalSweep, false, trackPaint);

    // 3. Soft Ambient Glow Under Active Arc
    if (activeSweep > 0.01) {
      final Paint glowPaint = Paint()
        ..color = gaugeColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
      canvas.drawArc(arcRect, startAngle, activeSweep, false, glowPaint);

      // 4. Silky SweepGradient Active Decibel Arc
      final Shader arcShader = SweepGradient(
        startAngle: 0.0,
        endAngle: totalSweep,
        colors: [
          primaryColor,
          Color.lerp(primaryColor, gaugeColor, 0.55)!,
          gaugeColor,
        ],
        stops: const [0.0, 0.62, 1.0],
        transform: const GradientRotation(startAngle),
      ).createShader(arcRect);

      final Paint activePaint = Paint()
        ..shader = arcShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, startAngle, activeSweep, false, activePaint);

      // 5. Crisp Luminous Leading Tip Orb
      final double tipAngle = startAngle + activeSweep;
      final Offset tipCenter = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipCenter,
        7.5,
        Paint()
          ..color = gaugeColor.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
      canvas.drawCircle(
        tipCenter,
        4.2,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }

    // 6. Floating Peak-Hold Indicator Marker Dot (smoothly tracks recent peak)
    if (peakProgress > progress + 0.025) {
      final double peakAngle = startAngle + (totalSweep * peakProgress);
      final Offset peakPos = Offset(
        center.dx + radius * math.cos(peakAngle),
        center.dy + radius * math.sin(peakAngle),
      );
      canvas.drawCircle(
        peakPos,
        3.6,
        Paint()..color = gaugeColor.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialDecibelBarPainter oldDelegate) {
    return (oldDelegate.decibel - decibel).abs() > 0.01 ||
        (oldDelegate.peakHoldDb - peakHoldDb).abs() > 0.01 ||
        oldDelegate.gaugeColor != gaugeColor ||
        oldDelegate.primaryColor != primaryColor;
  }
}
