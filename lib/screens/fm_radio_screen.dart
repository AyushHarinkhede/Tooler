import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/globe_3d_radio_widget.dart';

/// ---------------------------------------------------------------------------
/// TOOLER RETRO FM & GLOBAL 3D RADIO STUDIO (REFINED EDITION)
/// - Real Android Hardware FM Receiver & Wired Antenna detection with honest
///   warning card & dialog if the phone has no FM receiver chip (or direct
///   hardware play trigger when present!)
/// - Tactile Retro 2D Vector Radio Deck with telescopic antenna, speaker grille,
///   station lock markers on the 88–108 MHz analog scale & glowing needle
/// - 6 Retro Preset Memory Keys (CH1–CH6) + Prev/Next + Slider + ±0.1 MHz step
/// - Location-aware 1-Tap Area Auto-Scan with animated dial sweep
/// - Reliable Direct HTTPS MP3/AAC playback with playlist resolution & 10s watchdog
/// - Live Digital Radio Stream Recorder (MP3/AAC/OGG) with playback & Downloads export
/// - Global Radio Browser API (6 HTTPS mirrors) + Interactive Rotating 3D Globe Map
/// ---------------------------------------------------------------------------

class RadioStationItem {
  final String id;
  final String name;
  final double frequencyMhz;
  final String streamUrl;
  final String country;
  final String countryCode;
  final String genre;
  final String codec;
  final int bitrate;
  final bool isCustom;

  const RadioStationItem({
    required this.id,
    required this.name,
    required this.frequencyMhz,
    required this.streamUrl,
    this.country = 'India',
    this.countryCode = 'IN',
    this.genre = 'FM',
    this.codec = 'MP3',
    this.bitrate = 128,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frequencyMhz': frequencyMhz,
        'streamUrl': streamUrl,
        'country': country,
        'countryCode': countryCode,
        'genre': genre,
        'codec': codec,
        'bitrate': bitrate,
        'isCustom': isCustom,
      };

  factory RadioStationItem.fromJson(Map<String, dynamic> j) => RadioStationItem(
        id: j['id'] as String? ?? '${DateTime.now().millisecondsSinceEpoch}',
        name: j['name'] as String? ?? 'FM Station',
        frequencyMhz: (j['frequencyMhz'] as num?)?.toDouble() ?? 93.5,
        streamUrl: j['streamUrl'] as String? ?? '',
        country: j['country'] as String? ?? 'India',
        countryCode: j['countryCode'] as String? ?? 'IN',
        genre: j['genre'] as String? ?? 'FM',
        codec: j['codec'] as String? ?? 'MP3',
        bitrate: (j['bitrate'] as num?)?.toInt() ?? 128,
        isCustom: j['isCustom'] as bool? ?? false,
      );
}

class RadioRecordingClip {
  final String id;
  final String stationName;
  final double frequencyMhz;
  final String filePath;
  final int durationSeconds;
  final int sizeBytes;
  final DateTime createdAt;

  const RadioRecordingClip({
    required this.id,
    required this.stationName,
    required this.frequencyMhz,
    required this.filePath,
    required this.durationSeconds,
    required this.sizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationName': stationName,
        'frequencyMhz': frequencyMhz,
        'filePath': filePath,
        'durationSeconds': durationSeconds,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RadioRecordingClip.fromJson(Map<String, dynamic> j) =>
      RadioRecordingClip(
        id: j['id'] as String? ?? '',
        stationName: j['stationName'] as String? ?? 'FM Clip',
        frequencyMhz: (j['frequencyMhz'] as num?)?.toDouble() ?? 93.5,
        filePath: j['filePath'] as String? ?? '',
        durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class FmRadioScreen extends StatefulWidget {
  final StationeryTheme theme;
  const FmRadioScreen({super.key, required this.theme});

  @override
  State<FmRadioScreen> createState() => _FmRadioScreenState();
}

class _FmRadioScreenState extends State<FmRadioScreen>
    with TickerProviderStateMixin {
  static const MethodChannel _radioChannel =
      MethodChannel('com.tooler.tooler/fm_radio');
  static const String _favKey = 'tooler_fm_favorites_v2';
  static const String _customKey = 'tooler_fm_custom_stations_v2';
  static const String _clipsKey = 'tooler_fm_recorded_clips_v2';

  // 6 Geographically distributed Radio Browser open HTTPS mirrors (zero API key)
  static const List<String> _apiMirrors = [
    'https://de1.api.radio-browser.info',
    'https://de2.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
    'https://fr1.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
    'https://fi1.api.radio-browser.info',
  ];

  // 100% Verified high-uptime direct HTTPS MP3/AAC streams (instant backup if offline/before scan)
  static const List<RadioStationItem> _fallbackStations = [
    RadioStationItem(
      id: 'seed_bolly_983',
      name: 'Hindi Retro · Radio Mirchi Mix',
      frequencyMhz: 98.3,
      streamUrl: 'https://stream.zeno.fm/0r0xa792kwzuv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Hindi',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_soma_groove',
      name: 'SomaFM Groove Salad',
      frequencyMhz: 91.1,
      streamUrl: 'https://ice2.somafm.com/groovesalad-128-mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'Ambient · Chill',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_nightride',
      name: 'Nightride FM Synth',
      frequencyMhz: 94.3,
      streamUrl: 'https://stream.nightride.fm/chillsynth.mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'Synthwave · Chill',
      codec: 'MP3',
      bitrate: 192,
    ),
    RadioStationItem(
      id: 'seed_paradise',
      name: 'Radio Paradise Main',
      frequencyMhz: 101.3,
      streamUrl: 'https://stream.radioparadise.com/mp3-128',
      country: 'Global',
      countryCode: 'US',
      genre: 'Eclectic · Rock',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_soma_lush',
      name: 'SomaFM Lush Radio',
      frequencyMhz: 104.8,
      streamUrl: 'https://ice4.somafm.com/lush-128-mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'Dreamy · Vocal',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_soma_beats',
      name: 'SomaFM Beat Blender',
      frequencyMhz: 106.4,
      streamUrl: 'https://ice2.somafm.com/beatblender-128-mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'Deep House · Chill',
      codec: 'MP3',
      bitrate: 128,
    ),
  ];

  // Audio Playback
  final AudioPlayer _radioPlayer = AudioPlayer();
  final AudioPlayer _clipPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _playingClipId;
  String _statusBannerText = 'STANDBY';
  Timer? _bufferWatchdog;
  int _playRequestSeq = 0;

  // Tuner & Navigation State
  double _tunedFreqMhz = 98.3;
  RadioStationItem? _activeStation;
  int _activeTab = 0; // 0=Area FM, 1=3D Globe, 2=Favorites, 3=Recorded
  bool _showWarningExpanded = true;

  // Area & Global Collections
  String _detectedAreaCountryCode = 'IN';
  String _detectedAreaLabel = 'India';
  List<RadioStationItem> _areaStations = List.from(_fallbackStations);
  List<RadioStationItem> _customStations = [];
  List<RadioStationItem> _favoriteStations = [];
  List<RadioStationItem> _globalStations = [];
  bool _isScanningArea = false;
  bool _isLoadingGlobal = false;
  String _selectedCountryCode = 'IN';
  String _selectedCountryName = 'India';
  final TextEditingController _globalSearchCtrl = TextEditingController();

  // Real Hardware FM Receiver & Audio Output State
  bool _hwChecked = false;
  bool _hasFmReceiver = false;
  String _fmReceiverDetail = 'Checking hardware receiver...';
  String _oemFmPackage = '';
  bool _hasWiredAntenna = false;
  bool _hasBluetoothAudio = false;
  String _activeOutputName = 'Phone Speaker';
  String _outputRoute = 'headset'; // 'headset' or 'speaker'
  Timer? _hwPollTimer;

  // Live Radio Stream Recording State
  bool _isRecordingRadio = false;
  int _recSeconds = 0;
  int _recBytes = 0;
  Timer? _recTimer;
  HttpClient? _recHttpClient;
  IOSink? _recFileSink;
  StreamSubscription<List<int>>? _recStreamSub;
  String? _recFilePath;
  List<RadioRecordingClip> _recordedClips = [];

  // Visual Retro Animations
  late final AnimationController _eqController;
  late final AnimationController _scanSweepController;

  @override
  void initState() {
    super.initState();
    _activeStation = _areaStations.first;
    _tunedFreqMhz = _activeStation!.frequencyMhz;

    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();

    _scanSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        if (_isScanningArea && mounted) {
          setState(() {
            _tunedFreqMhz = double.parse(
              (87.5 + _scanSweepController.value * 20.5).toStringAsFixed(1),
            );
          });
        }
      });

    _initPlayers();
    _loadPersistedData();
    _pollHardwareStatus();
    _hwPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollHardwareStatus();
    });

    // Detect area + fetch live verified local FM streams right away
    _bootstrapAreaRadio();
  }

  @override
  void dispose() {
    _bufferWatchdog?.cancel();
    _hwPollTimer?.cancel();
    _recTimer?.cancel();
    _stopRadioRecording(save: false);
    if (!kIsWeb && Platform.isAndroid) {
      _radioChannel.invokeMethod('resetAudioRoute').catchError((_) {});
    }
    _radioPlayer.dispose();
    _clipPlayer.dispose();
    _eqController.dispose();
    _scanSweepController.dispose();
    _globalSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPlayers() async {
    try {
      await _radioPlayer.setAudioContext(
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
      await _radioPlayer.setVolume(1.0);
    } catch (_) {}

    _radioPlayer.onPlayerStateChanged.listen((st) {
      if (!mounted) return;
      if (st == PlayerState.playing) {
        _bufferWatchdog?.cancel();
        setState(() {
          _isPlaying = true;
          _isBuffering = false;
          _statusBannerText = 'ON AIR';
        });
      } else if (st == PlayerState.stopped || st == PlayerState.completed) {
        _bufferWatchdog?.cancel();
        setState(() {
          _isPlaying = false;
          _isBuffering = false;
          if (!_isScanningArea) _statusBannerText = 'STANDBY';
        });
      } else if (st == PlayerState.paused) {
        setState(() {
          _isPlaying = false;
          _isBuffering = false;
          _statusBannerText = 'PAUSED';
        });
      }
    });

    _clipPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingClipId = null);
    });
  }

  Future<void> _bootstrapAreaRadio() async {
    await _detectUserArea();
    await _scanAreaStations(silent: true);
  }

  Future<void> _detectUserArea() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.getUrl(Uri.parse('https://ipwho.is/?fields=country,country_code,city'));
      final resp = await req.close().timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data is Map) {
          final cc = (data['country_code'] as String? ?? '').trim().toUpperCase();
          final country = (data['country'] as String? ?? '').trim();
          final city = (data['city'] as String? ?? '').trim();
          if (cc.length == 2 && mounted) {
            setState(() {
              _detectedAreaCountryCode = cc;
              _selectedCountryCode = cc;
              _selectedCountryName = country.isNotEmpty ? country : cc;
              _detectedAreaLabel = city.isNotEmpty && country.isNotEmpty
                  ? '$city · $country'
                  : (country.isNotEmpty ? country : 'India');
            });
          }
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favRaw = prefs.getString(_favKey);
      final customRaw = prefs.getString(_customKey);
      final clipsRaw = prefs.getString(_clipsKey);

      if (mounted) {
        setState(() {
          if (favRaw != null && favRaw.isNotEmpty) {
            _favoriteStations = (jsonDecode(favRaw) as List)
                .map((e) => RadioStationItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
          if (customRaw != null && customRaw.isNotEmpty) {
            _customStations = (jsonDecode(customRaw) as List)
                .map((e) => RadioStationItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
          if (clipsRaw != null && clipsRaw.isNotEmpty) {
            _recordedClips = (jsonDecode(clipsRaw) as List)
                .map((e) => RadioRecordingClip.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _persistStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _favKey,
        jsonEncode(_favoriteStations.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        _customKey,
        jsonEncode(_customStations.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        _clipsKey,
        jsonEncode(_recordedClips.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _pollHardwareStatus() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (!_hwChecked && mounted) {
        setState(() {
          _hwChecked = true;
          _hasFmReceiver = false;
          _fmReceiverDetail = 'No Hardware FM Receiver Chip';
        });
      }
      return;
    }
    try {
      final dynamic raw = await _radioChannel.invokeMethod('getRadioHardwareStatus');
      if (raw is Map && mounted) {
        setState(() {
          _hwChecked = true;
          _hasFmReceiver = raw['hasFmReceiver'] == true || raw['hasFmChip'] == true;
          _fmReceiverDetail = raw['fmReceiverDetail'] as String? ?? 'No Hardware FM Receiver Chip';
          _oemFmPackage = raw['oemFmPackage'] as String? ?? '';
          _hasWiredAntenna = raw['hasWiredAntenna'] == true;
          _hasBluetoothAudio = raw['hasBluetoothAudio'] == true;
          _activeOutputName = raw['activeOutputName'] as String? ?? 'Phone Speaker';
          _outputRoute = raw['outputRoute'] as String? ?? 'headset';
        });
      }
    } catch (_) {}
  }

  Future<void> _setOutputRoute(String route) async {
    SoundService().playTap();
    HapticFeedback.selectionClick();
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _radioChannel.invokeMethod('setAudioOutputRoute', {'route': route});
      } catch (_) {}
    }
    await _pollHardwareStatus();
  }

  Future<void> _handleAntennaReceiverAction() async {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    await _pollHardwareStatus();

    if (!_hasFmReceiver) {
      if (!mounted) return;
      _showNoHardwareReceiverDialog();
      return;
    }

    if (!_hasWiredAntenna) {
      _showToast(
        'Plug in wired earphones (3.5mm) — wire acts as the offline FM antenna!',
        color: Colors.amber.shade800,
      );
      return;
    }

    if (_oemFmPackage.isNotEmpty) {
      final launched = await _radioChannel.invokeMethod<bool>('launchHardwareFm', {
        'packageName': _oemFmPackage,
      });
      if (launched == true) return;
    }

    // Play right inside Tooler's tuned station if OEM app isn't separate
    final target = _activeStation ?? _areaStations.first;
    await _tuneAndPlayStation(target);
  }

  void _showNoHardwareReceiverDialog() {
    final theme = widget.theme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: theme.border, width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No FM Receiver Found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Is phone me built-in offline FM receiver hardware chip nahi hai (modern smartphones me FM tuner chip disabled/absent hota hai).\n\nOffline antenna FM play nahi ho sakta, lekin aap Tooler ke Live Area FM aur Global 3D Radio se bina antenna ke local + worldwide stations play aur record kar sakte ho!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.48,
            color: theme.textSecondary,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (!_isPlaying && _areaStations.isNotEmpty) {
                _tuneAndPlayStation(_activeStation ?? _areaStations.first);
              }
            },
            child: const Text('Play Live FM Instead'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GLOBAL RADIO BROWSER API (6 HTTPS MIRRORS + DIRECT PLAYABLE STREAM FILTER)
  // ===========================================================================
  Future<List<RadioStationItem>> _queryRadioApi(String endpointPath) async {
    for (final host in _apiMirrors) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      try {
        final req = await client.getUrl(Uri.parse('$host$endpointPath'));
        req.headers.set('User-Agent', 'ToolerFMRadio/2.0');
        req.headers.set('Accept', 'application/json');
        final resp = await req.close().timeout(const Duration(seconds: 7));
        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final List rawList = jsonDecode(body) as List;
          final directStreams = <RadioStationItem>[];
          final secondaryStreams = <RadioStationItem>[];
          final seenUrls = <String>{};

          int freqIdx = 0;
          for (final item in rawList) {
            if (item is! Map) continue;
            if ((item['lastcheckok'] as num?)?.toInt() == 0) continue;

            final stream =
                (item['url_resolved'] as String? ?? item['url'] as String? ?? '')
                    .trim();
            if (!stream.startsWith('https://') || !seenUrls.add(stream)) continue;

            final lowerUrl = stream.toLowerCase();
            // Skip HLS .m3u8 & ASX streams that commonly hang Android MediaPlayer
            if (lowerUrl.contains('.m3u8') || lowerUrl.endsWith('.asx')) continue;

            final name = (item['name'] as String? ?? '').trim();
            if (name.isEmpty) continue;

            final codec = (item['codec'] as String? ?? 'MP3').toUpperCase();
            final bitrate = (item['bitrate'] as num?)?.toInt() ?? 128;

            double freq = _extractFreqFromName(name) ??
                double.parse((88.1 + ((freqIdx * 1.1) % 19.4)).toStringAsFixed(1));
            freqIdx++;

            final st = RadioStationItem(
              id: item['stationuuid'] as String? ?? 'api_${stream.hashCode}',
              name: name.length > 40 ? '${name.substring(0, 40)}…' : name,
              frequencyMhz: freq.clamp(87.5, 108.0),
              streamUrl: stream,
              country: (item['country'] as String? ?? 'Global').trim(),
              countryCode: (item['countrycode'] as String? ?? 'GL').toUpperCase(),
              genre: (item['tags'] as String? ?? 'FM Radio')
                  .split(',')
                  .take(2)
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              codec: codec.isEmpty ? 'MP3' : codec,
              bitrate: bitrate,
            );

            // Strongly prioritize direct MP3/AAC streams (instant play + direct live recording!)
            final isDirect = !lowerUrl.endsWith('.pls') &&
                !lowerUrl.endsWith('.m3u') &&
                (codec.contains('MP3') || codec.contains('AAC') || codec.contains('OGG'));
            if (isDirect) {
              directStreams.add(st);
            } else {
              secondaryStreams.add(st);
            }
            if (directStreams.length >= 24) break;
          }

          final combined = [...directStreams, ...secondaryStreams].take(26).toList();
          client.close();
          if (combined.isNotEmpty) return combined;
        }
      } catch (_) {
      } finally {
        client.close();
      }
    }
    return [];
  }

  /// Resolves .pls / .m3u playlist links into a direct playable HTTPS audio stream URL
  Future<String> _resolveDirectStreamUrl(String rawUrl) async {
    final lower = rawUrl.toLowerCase();
    if (!lower.endsWith('.m3u') && !lower.endsWith('.pls')) {
      return rawUrl;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(Uri.parse(rawUrl));
      req.headers.set('User-Agent', 'ToolerFMRadio/2.0');
      final resp = await req.close().timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final text = await resp.transform(utf8.decoder).join();
        for (final line in text.split('\n')) {
          final t = line.trim();
          if (t.startsWith('https://')) return t;
          if (t.toLowerCase().startsWith('file1=https://')) {
            return t.substring(6).trim();
          }
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return rawUrl;
  }

  double? _extractFreqFromName(String name) {
    final m = RegExp(r'\b(8[7-9]|9\d|10[0-8])\.\d\b').firstMatch(name);
    if (m != null) {
      return double.tryParse(m.group(0)!);
    }
    return null;
  }

  /// Auto-Scans local/area FM stations with an animated analog needle sweep!
  Future<void> _scanAreaStations({bool silent = false}) async {
    if (_isScanningArea) return;
    if (!silent) {
      SoundService().playClick();
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _isScanningArea = true;
      if (!silent) _statusBannerText = 'SCANNING AREA...';
    });
    if (!silent) {
      _scanSweepController.repeat();
    }

    final cc = _detectedAreaCountryCode;
    final liveFound = await _queryRadioApi(
      '/json/stations/search?countrycode=$cc&hidebroken=true&lastcheckok=1&order=clickcount&reverse=true&limit=45',
    );

    if (!mounted) return;
    _scanSweepController.stop();

    setState(() {
      final merged = <RadioStationItem>[..._customStations];
      final seenIds = merged.map((e) => e.id).toSet();
      for (final s in liveFound) {
        if (seenIds.add(s.id)) merged.add(s);
      }
      for (final seed in _fallbackStations) {
        if (seenIds.add(seed.id)) merged.add(seed);
      }
      _areaStations = merged;
      _isScanningArea = false;

      if (_activeStation == null && _areaStations.isNotEmpty) {
        _activeStation = _areaStations.first;
      }
      if (_activeStation != null) {
        _tunedFreqMhz = _activeStation!.frequencyMhz;
      }
      if (!_isPlaying && !_isBuffering) {
        _statusBannerText = 'READY';
      }
    });

    if (!silent) {
      SoundService().playSuccess();
      _showToast(
        'Area Scan locked ${_areaStations.length} active stations ($_detectedAreaLabel)',
        color: const Color(0xFF10B981),
      );
    }
  }

  /// Fetches live global stations for a country clicked on the 3D Globe or search query
  Future<void> _fetchGlobalStations({String? countryCode, String? query}) async {
    setState(() => _isLoadingGlobal = true);
    final String path;
    if (query != null && query.trim().isNotEmpty) {
      final q = Uri.encodeQueryComponent(query.trim());
      path =
          '/json/stations/search?name=$q&hidebroken=true&lastcheckok=1&order=clickcount&reverse=true&limit=40';
    } else {
      final cc = (countryCode ?? _selectedCountryCode).toUpperCase();
      path =
          '/json/stations/search?countrycode=$cc&hidebroken=true&lastcheckok=1&order=clickcount&reverse=true&limit=40';
    }

    final results = await _queryRadioApi(path);
    if (!mounted) return;
    setState(() {
      _globalStations = results;
      _isLoadingGlobal = false;
    });
  }

  // ===========================================================================
  // RELIABLE PLAYBACK, WATCHDOG, DIRECT SWITCH & FREQUENCY TUNING
  // ===========================================================================
  Future<void> _tuneAndPlayStation(RadioStationItem station) async {
    SoundService().playClick();
    HapticFeedback.selectionClick();

    final seq = ++_playRequestSeq;
    _bufferWatchdog?.cancel();

    if (_playingClipId != null) {
      await _clipPlayer.stop();
      setState(() => _playingClipId = null);
    }

    if (_isRecordingRadio) {
      await _stopRadioRecording(save: true);
    }

    setState(() {
      _activeStation = station;
      _tunedFreqMhz = station.frequencyMhz;
      _isBuffering = true;
      _isPlaying = false;
      _statusBannerText = 'TUNING...';
    });

    // 10-second buffering watchdog so UI NEVER hangs indefinitely on a slow/dead server
    _bufferWatchdog = Timer(const Duration(seconds: 10), () {
      if (!mounted || seq != _playRequestSeq) return;
      if (_isBuffering && !_isPlaying) {
        _radioPlayer.stop().catchError((_) {});
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _statusBannerText = 'WEAK SIGNAL';
        });
        _showToast(
          'Station took too long to respond — tap Next ⏭ for another station',
          color: Colors.amber.shade800,
        );
      }
    });

    try {
      final directUrl = await _resolveDirectStreamUrl(station.streamUrl);
      if (!mounted || seq != _playRequestSeq) return;

      await _radioPlayer.stop();
      await _radioPlayer.play(UrlSource(directUrl));
    } catch (_) {
      _bufferWatchdog?.cancel();
      if (mounted && seq == _playRequestSeq) {
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _statusBannerText = 'OFFLINE';
        });
        _showToast(
          'Stream offline — tap Next ⏭ or try another station',
          color: Colors.amber.shade800,
        );
      }
    }
  }

  Future<void> _togglePlayStop() async {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    _bufferWatchdog?.cancel();

    if (_isPlaying || _isBuffering) {
      _playRequestSeq++;
      if (_isRecordingRadio) await _stopRadioRecording(save: true);
      await _radioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _isBuffering = false;
        _statusBannerText = 'STANDBY';
      });
    } else {
      final pool = _currentStationPool();
      final target = _activeStation ?? (pool.isNotEmpty ? pool.first : _fallbackStations.first);
      await _tuneAndPlayStation(target);
    }
  }

  void _stepStation(int delta) {
    final pool = _currentStationPool();
    if (pool.isEmpty) return;
    final curIdx = pool.indexWhere((s) => s.id == _activeStation?.id);
    final nextIdx = curIdx == -1 ? 0 : (curIdx + delta + pool.length) % pool.length;
    _tuneAndPlayStation(pool[nextIdx]);
  }

  List<RadioStationItem> _currentStationPool() {
    if (_activeTab == 1 && _globalStations.isNotEmpty) return _globalStations;
    if (_activeTab == 2 && _favoriteStations.isNotEmpty) return _favoriteStations;
    return _areaStations;
  }

  void _nudgeFrequency(double deltaMhz) {
    SoundService().playTap();
    HapticFeedback.selectionClick();
    final next = double.parse(
      (_tunedFreqMhz + deltaMhz).clamp(87.5, 108.0).toStringAsFixed(1),
    );
    setState(() => _tunedFreqMhz = next);

    final match = _areaStations
        .where((s) => (s.frequencyMhz - next).abs() <= 0.15)
        .firstOrNull;
    if (match != null && match.id != _activeStation?.id) {
      _tuneAndPlayStation(match);
    }
  }

  bool _isFavorite(RadioStationItem? station) {
    if (station == null) return false;
    return _favoriteStations
        .any((f) => f.id == station.id || f.streamUrl == station.streamUrl);
  }

  Future<void> _toggleFavorite(RadioStationItem station) async {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    setState(() {
      if (_isFavorite(station)) {
        _favoriteStations
            .removeWhere((f) => f.id == station.id || f.streamUrl == station.streamUrl);
      } else {
        _favoriteStations.insert(0, station);
      }
    });
    await _persistStations();
  }

  Future<void> _deleteCustomStation(RadioStationItem station) async {
    SoundService().playTap();
    setState(() {
      _customStations.removeWhere((s) => s.id == station.id);
      _areaStations.removeWhere((s) => s.id == station.id);
      _favoriteStations.removeWhere((s) => s.id == station.id);
    });
    await _persistStations();
    _showToast('Removed "${station.name}"', color: Colors.blueGrey.shade700);
  }

  // ===========================================================================
  // MANUAL ADD STATION DIALOG (NAME + FREQUENCY + OPTIONAL HTTPS STREAM)
  // ===========================================================================
  void _showManualAddStationDialog() {
    SoundService().playClick();
    final nameCtrl = TextEditingController();
    final freqCtrl = TextEditingController(text: _tunedFreqMhz.toStringAsFixed(1));
    final urlCtrl = TextEditingController();
    final theme = widget.theme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: theme.border, width: 1.2),
        ),
        title: Text(
          'Add Manual Station',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: theme.text, fontSize: 13.5),
              decoration: InputDecoration(
                labelText: 'Station Name (e.g. Red FM 93.5)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: freqCtrl,
              style: TextStyle(color: theme.text, fontSize: 13.5),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Frequency MHz (87.5 – 108.0)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              style: TextStyle(color: theme.text, fontSize: 13.5),
              decoration: InputDecoration(
                labelText: 'Stream HTTPS URL (optional — auto-finds)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final freq =
                  (double.tryParse(freqCtrl.text.trim()) ?? _tunedFreqMhz).clamp(87.5, 108.0);
              String streamUrl = urlCtrl.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(ctx);

              if (streamUrl.isEmpty) {
                _showToast('Finding live stream for "$name"...', color: theme.primary);
                final found = await _queryRadioApi(
                  '/json/stations/search?name=${Uri.encodeQueryComponent(name)}&hidebroken=true&lastcheckok=1&limit=8',
                );
                if (found.isNotEmpty) {
                  streamUrl = found.first.streamUrl;
                } else {
                  streamUrl = _fallbackStations.first.streamUrl;
                }
              }

              final custom = RadioStationItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                frequencyMhz: double.parse(freq.toStringAsFixed(1)),
                streamUrl: streamUrl,
                country: _detectedAreaLabel,
                countryCode: _detectedAreaCountryCode,
                genre: 'Custom FM',
                isCustom: true,
              );

              if (mounted) {
                setState(() {
                  _customStations.insert(0, custom);
                  _areaStations.insert(0, custom);
                });
                await _persistStations();
                _tuneAndPlayStation(custom);
              }
            },
            child: const Text('Save & Tune'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LIVE RADIO STREAM RECORDER (MP3 / AAC / OGG DIRECT CAPTURE)
  // ===========================================================================
  Future<void> _toggleRadioRecording() async {
    SoundService().playClick();
    HapticFeedback.mediumImpact();

    if (_isRecordingRadio) {
      await _stopRadioRecording(save: true);
      return;
    }

    final station = _activeStation;
    if (station == null || station.streamUrl.isEmpty || (!_isPlaying && !_isBuffering)) {
      _showToast(
        'Play a radio station first, then tap ● REC to record!',
        color: Colors.amber.shade800,
      );
      return;
    }

    try {
      final resolvedUrl = await _resolveDirectStreamUrl(station.streamUrl);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(resolvedUrl));
      req.headers.set('User-Agent', 'ToolerFMRadio/2.0');
      final resp = await req.close().timeout(const Duration(seconds: 8));

      final ct = (resp.headers.contentType?.mimeType ?? '').toLowerCase();
      if (resp.statusCode < 200 || resp.statusCode >= 300 || ct.contains('mpegurl') || ct.contains('text/')) {
        client.close(force: true);
        _showToast(
          'This station uses a protected playlist format — switch station to record',
          color: Colors.amber.shade800,
        );
        return;
      }

      String ext = 'mp3';
      if (ct.contains('aac')) {
        ext = 'aac';
      } else if (ct.contains('ogg')) {
        ext = 'ogg';
      } else if (ct.contains('mp4') || ct.contains('m4a')) {
        ext = 'm4a';
      }

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/tooler_radio_$ts.$ext';
      final sink = File(filePath).openWrite();

      _recHttpClient = client;
      _recFileSink = sink;
      _recFilePath = filePath;

      setState(() {
        _isRecordingRadio = true;
        _recSeconds = 0;
        _recBytes = 0;
        _statusBannerText = 'REC LIVE';
      });

      final startedAt = DateTime.now();
      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted && _isRecordingRadio) {
          setState(() {
            _recSeconds = DateTime.now().difference(startedAt).inSeconds;
          });
        }
      });

      _recStreamSub = resp.listen(
        (chunk) {
          _recFileSink?.add(chunk);
          _recBytes += chunk.length;
        },
        onDone: () {
          if (_isRecordingRadio) _stopRadioRecording(save: true);
        },
        onError: (_) {
          if (_isRecordingRadio) _stopRadioRecording(save: true);
        },
      );
    } catch (_) {
      _showToast('Could not start live capture on this station', color: const Color(0xFFF43F5E));
    }
  }

  Future<void> _stopRadioRecording({required bool save}) async {
    _recTimer?.cancel();
    _recTimer = null;
    await _recStreamSub?.cancel();
    _recStreamSub = null;
    try {
      await _recFileSink?.flush();
      await _recFileSink?.close();
    } catch (_) {}
    _recFileSink = null;
    _recHttpClient?.close(force: true);
    _recHttpClient = null;

    final path = _recFilePath;
    final dur = _recSeconds;
    final bytes = _recBytes;
    final station = _activeStation;
    _recFilePath = null;

    if (mounted) {
      setState(() {
        _isRecordingRadio = false;
        _recSeconds = 0;
        _recBytes = 0;
        _statusBannerText = _isPlaying ? 'ON AIR' : 'STANDBY';
      });
    }

    if (save && path != null && station != null) {
      if (bytes > 1024) {
        final clip = RadioRecordingClip(
          id: 'clip_${DateTime.now().millisecondsSinceEpoch}',
          stationName: station.name,
          frequencyMhz: station.frequencyMhz,
          filePath: path,
          durationSeconds: dur.clamp(1, 99999),
          sizeBytes: bytes,
          createdAt: DateTime.now(),
        );
        if (mounted) {
          setState(() => _recordedClips.insert(0, clip));
          await _persistStations();
          SoundService().playSuccess();
          _showToast(
            'Saved radio clip (${_formatSec(clip.durationSeconds)} · ${_formatBytes(bytes)})',
            color: const Color(0xFF10B981),
          );
        }
      } else {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
        if (mounted) {
          _showToast('Recording was too short to save', color: Colors.amber.shade800);
        }
      }
    }
  }

  Future<void> _playRecordedClip(RadioRecordingClip clip) async {
    SoundService().playTap();
    if (_playingClipId == clip.id) {
      await _clipPlayer.stop();
      setState(() => _playingClipId = null);
      return;
    }
    if (_isPlaying || _isBuffering) {
      await _radioPlayer.stop();
    }
    try {
      await _clipPlayer.stop();
      await _clipPlayer.play(DeviceFileSource(clip.filePath));
      setState(() => _playingClipId = clip.id);
    } catch (_) {
      _showToast('Unable to play this clip', color: const Color(0xFFF43F5E));
    }
  }

  Future<void> _deleteRecordedClip(RadioRecordingClip clip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Recording?',
          style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text('Delete "${clip.stationName}" clip permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_playingClipId == clip.id) {
      await _clipPlayer.stop();
      _playingClipId = null;
    }
    try {
      final f = File(clip.filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (mounted) {
      setState(() => _recordedClips.removeWhere((c) => c.id == clip.id));
      await _persistStations();
    }
  }

  void _showToast(String msg, {required Color color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatSec(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ===========================================================================
  // MAIN BUILD — CLEAN, REFINED RETRO STUDIO LAYOUT
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HARDWARE FM RECEIVER WARNING / STATUS CARD (Clear & Honest!)
              if (_hwChecked) _buildHardwareReceiverBanner(theme),
              if (_hwChecked) const SizedBox(height: 10),

              // 2. REFINED 2D VECTOR RETRO RADIO UNIT + TACTILE CONTROLS + PRESETS
              _buildRetroRadioDeck(theme),

              const SizedBox(height: 10),

              // 3. SLIM AUDIO OUTPUT BAR (Wired / Bluetooth <-> Phone Speaker)
              _buildAudioOutputBar(theme),

              const SizedBox(height: 10),

              // 4. AREA AUTO-SCAN + MANUAL ADD ROW
              Row(
                children: [
                  Expanded(
                    child: BouncyTap(
                      onTap: _isScanningArea ? null : () => _scanAreaStations(),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isScanningArea)
                              const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(Icons.radar_rounded, color: Colors.white, size: 17),
                            const SizedBox(width: 7),
                            Text(
                              _isScanningArea ? 'SCANNING AREA...' : 'FIND AREA STATIONS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  BouncyTap(
                    onTap: _showManualAddStationDialog,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, color: theme.primary, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'ADD',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 5. SECTION TABS: Area FM | 3D Globe | Favorites | Recorded
              _buildTabsStrip(theme),

              const SizedBox(height: 12),

              // 6. ACTIVE TAB VIEW
              if (_activeTab == 0)
                _buildStationsList(
                  _areaStations,
                  theme,
                  emptyHint: 'Tap FIND AREA STATIONS to scan active FM channels',
                ),
              if (_activeTab == 1) _buildGlobal3DRadioTab(theme),
              if (_activeTab == 2)
                _buildStationsList(
                  _favoriteStations,
                  theme,
                  emptyHint: 'Tap ♥ on any station to save it in Favorites',
                ),
              if (_activeTab == 3) _buildRecordingsTab(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. REAL HARDWARE FM RECEIVER WARNING / READY BANNER
  // ===========================================================================
  Widget _buildHardwareReceiverBanner(StationeryTheme theme) {
    if (_hasFmReceiver) {
      final ready = _hasWiredAntenna;
      final accent = ready ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: theme.isDark ? 0.14 : 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.1),
        ),
        child: Row(
          children: [
            Icon(
              ready ? Icons.settings_input_antenna_rounded : Icons.headset_off_rounded,
              color: accent,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ready
                        ? 'FM Receiver & Wired Antenna Active'
                        : 'FM Receiver Found · Plug Wired Earphones',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    ready
                        ? '$_fmReceiverDetail · Ready to play offline FM'
                        : 'Connect 3.5mm wired earphones to act as the FM antenna',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            BouncyTap(
              onTap: _handleAntennaReceiverAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ready ? 'PLAY FM' : 'CHECK',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Device has NO hardware FM receiver chip — show crisp, honest warning card!
    const warnColor = Color(0xFFF59E0B);
    return GestureDetector(
      onTap: () => setState(() => _showWarningExpanded = !_showWarningExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: warnColor.withValues(alpha: theme.isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: warnColor.withValues(alpha: 0.48), width: 1.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: warnColor, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No Hardware FM Receiver on This Device',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ),
                Icon(
                  _showWarningExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.textSecondary,
                ),
              ],
            ),
            if (_showWarningExpanded) ...[
              const SizedBox(height: 5),
              Text(
                'Is phone me built-in antenna FM receiver chip nahi hai — offline antenna FM play nahi ho sakta. Live Area FM & Global 3D Radio mode se aap local + worldwide stations play aur record kar sakte ho!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 1.38,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. REFINED 2D VECTOR RETRO RADIO DECK + PRESET MEMORY KEYS + CONTROLS
  // ===========================================================================
  Widget _buildRetroRadioDeck(StationeryTheme theme) {
    final station = _activeStation;
    final isFav = _isFavorite(station);
    final presetPool = _areaStations.take(6).toList();
    final stationFreqs = _areaStations.map((s) => s.frequencyMhz).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isPlaying
              ? theme.primary.withValues(alpha: 0.50)
              : theme.border,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isPlaying ? theme.primary : Colors.black)
                .withValues(alpha: theme.isDark ? 0.20 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 2D Retro Vector Radio Illustration
          SizedBox(
            height: 162,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _eqController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _RetroRadio2DPainter(
                    frequencyMhz: _tunedFreqMhz,
                    stationName: station?.name ?? 'FM Tuner',
                    statusLabel: _statusBannerText,
                    codecBadge: station != null
                        ? '${station.codec}${station.bitrate > 0 ? " ${station.bitrate}k" : ""}'
                        : 'FM STEREO',
                    isPlaying: _isPlaying,
                    isBuffering: _isBuffering || _isScanningArea,
                    isRecording: _isRecordingRadio,
                    stationFrequencies: stationFreqs,
                    animT: _eqController.value,
                    theme: theme,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Analog Frequency Scrubber + Fine ±0.1 MHz Steps
          Row(
            children: [
              _miniStepBtn('-0.1', () => _nudgeFrequency(-0.1), theme),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: theme.primary,
                    inactiveTrackColor: theme.border,
                    thumbColor: const Color(0xFFF43F5E),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
                  ),
                  child: Slider(
                    value: _tunedFreqMhz.clamp(87.5, 108.0),
                    min: 87.5,
                    max: 108.0,
                    onChanged: (v) {
                      setState(() => _tunedFreqMhz = double.parse(v.toStringAsFixed(1)));
                    },
                    onChangeEnd: (v) {
                      final rounded = double.parse(v.toStringAsFixed(1));
                      final nearest = _areaStations
                          .where((s) => (s.frequencyMhz - rounded).abs() <= 0.7)
                          .firstOrNull;
                      if (nearest != null) {
                        _tuneAndPlayStation(nearest);
                      }
                    },
                  ),
                ),
              ),
              _miniStepBtn('+0.1', () => _nudgeFrequency(0.1), theme),
            ],
          ),

          const SizedBox(height: 6),

          // Retro Tactile 6-Channel Preset Push-Buttons (CH1..CH6) for Instant Direct Switch!
          if (presetPool.isNotEmpty) ...[
            Row(
              children: List.generate(presetPool.length, (idx) {
                final st = presetPool[idx];
                final selected = _activeStation?.id == st.id;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: idx < presetPool.length - 1 ? 5 : 0),
                    child: BouncyTap(
                      onTap: () => _tuneAndPlayStation(st),
                      scaleFraction: 0.93,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? theme.primary : theme.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? theme.primary : theme.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'CH ${idx + 1}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.2,
                                fontWeight: FontWeight.w800,
                                color: selected ? Colors.white70 : theme.textSecondary,
                              ),
                            ),
                            Text(
                              st.frequencyMhz.toStringAsFixed(1),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: selected ? Colors.white : theme.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 11),
          ],

          // Retro Main Deck Switch Row: [Fav] [Prev] [PLAY/STOP] [Next] [REC]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _deckActionBtn(
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isFav ? const Color(0xFFF43F5E) : theme.textSecondary,
                bg: isFav
                    ? const Color(0xFFF43F5E).withValues(alpha: 0.13)
                    : theme.bg,
                border: isFav
                    ? const Color(0xFFF43F5E).withValues(alpha: 0.45)
                    : theme.border,
                onTap: station != null ? () => _toggleFavorite(station) : null,
              ),
              _deckActionBtn(
                icon: Icons.skip_previous_rounded,
                iconColor: theme.text,
                bg: theme.bg,
                border: theme.border,
                onTap: () => _stepStation(-1),
              ),
              // Primary Play/Stop Retro Power Key
              BouncyTap(
                onTap: _togglePlayStop,
                scaleFraction: 0.90,
                child: Container(
                  width: 66,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isPlaying ? const Color(0xFFF43F5E) : theme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying ? const Color(0xFFF43F5E) : theme.primary)
                            .withValues(alpha: 0.34),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isBuffering
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ),
              _deckActionBtn(
                icon: Icons.skip_next_rounded,
                iconColor: theme.text,
                bg: theme.bg,
                border: theme.border,
                onTap: () => _stepStation(1),
              ),
              _deckActionBtn(
                icon: _isRecordingRadio
                    ? Icons.stop_circle_rounded
                    : Icons.fiber_manual_record_rounded,
                iconColor: _isRecordingRadio ? Colors.white : const Color(0xFFF43F5E),
                bg: _isRecordingRadio ? const Color(0xFFF43F5E) : theme.bg,
                border: _isRecordingRadio ? const Color(0xFFF43F5E) : theme.border,
                onTap: _toggleRadioRecording,
              ),
            ],
          ),

          if (_isRecordingRadio) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fiber_manual_record_rounded,
                    color: Color(0xFFF43F5E),
                    size: 11,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'RECORDING · ${_formatSec(_recSeconds)} · ${_formatBytes(_recBytes)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _deckActionBtn({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required Color border,
    VoidCallback? onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
    );
  }

  Widget _miniStepBtn(String label, VoidCallback onTap, StationeryTheme theme) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: theme.text,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SLIM AUDIO OUTPUT ROUTING BAR (WIRED / BLUETOOTH <-> PHONE SPEAKER)
  // ===========================================================================
  Widget _buildAudioOutputBar(StationeryTheme theme) {
    final bool hasExternal = _hasWiredAntenna || _hasBluetoothAudio;
    final Color activeColor = hasExternal ? const Color(0xFF10B981) : theme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _hasWiredAntenna
                  ? Icons.headset_rounded
                  : (_hasBluetoothAudio
                      ? Icons.bluetooth_connected_rounded
                      : Icons.volume_up_rounded),
              size: 17,
              color: activeColor,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeOutputName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
                Text(
                  _hasWiredAntenna
                      ? 'Wired connected · Audio routed'
                      : (_hasBluetoothAudio
                          ? 'Bluetooth connected · Audio routed'
                          : 'Area: $_detectedAreaLabel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _outputSwitchChip(
                  icon: Icons.headphones_rounded,
                  label: 'Wired/BT',
                  active: hasExternal && _outputRoute == 'headset',
                  dimmed: !hasExternal,
                  onTap: () {
                    if (!hasExternal) {
                      _showToast(
                        'Connect wired earphones or Bluetooth to route audio there',
                        color: Colors.blueGrey.shade700,
                      );
                    } else {
                      _setOutputRoute('headset');
                    }
                  },
                  theme: theme,
                ),
                const SizedBox(width: 3),
                _outputSwitchChip(
                  icon: Icons.volume_up_rounded,
                  label: 'Speaker',
                  active: !hasExternal || _outputRoute == 'speaker',
                  dimmed: false,
                  onTap: () => _setOutputRoute('speaker'),
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputSwitchChip({
    required IconData icon,
    required String label,
    required bool active,
    required bool dimmed,
    required VoidCallback onTap,
    required StationeryTheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? Colors.white
                  : (dimmed
                      ? theme.textSecondary.withValues(alpha: 0.4)
                      : theme.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: active
                    ? Colors.white
                    : (dimmed
                        ? theme.textSecondary.withValues(alpha: 0.4)
                        : theme.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. SECTION TABS STRIP
  // ===========================================================================
  Widget _buildTabsStrip(StationeryTheme theme) {
    final tabs = [
      ('Area FM', _areaStations.length, Icons.radio_rounded),
      ('3D Globe', _globalStations.length, Icons.public_rounded),
      ('Favorites', _favoriteStations.length, Icons.favorite_rounded),
      ('Recorded', _recordedClips.length, Icons.mic_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final (label, count, icon) = tabs[i];
          final sel = _activeTab == i;
          return Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
            child: BouncyTap(
              onTap: () {
                SoundService().playTap();
                setState(() => _activeTab = i);
                if (i == 1 && _globalStations.isEmpty) {
                  _fetchGlobalStations(countryCode: _selectedCountryCode);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? theme.primary : theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? theme.primary : theme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: sel ? Colors.white : theme.primary),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : theme.text,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$count',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? Colors.white.withValues(alpha: 0.9)
                              : theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // 6A. GLOBAL 3D GLOBE + GLOBAL RADIO API SEARCH TAB
  // ===========================================================================
  Widget _buildGlobal3DRadioTab(StationeryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.border, width: 1.2),
          ),
          child: Column(
            children: [
              // Interactive Horizon-Clipped 3D Rotating Globe with World Map!
              Globe3DRadioWidget(
                theme: theme,
                selectedCountryCode: _selectedCountryCode,
                isPlaying: _isPlaying,
                onHubSelected: (hub) {
                  setState(() {
                    _selectedCountryCode = hub.code;
                    _selectedCountryName = hub.name;
                  });
                  _fetchGlobalStations(countryCode: hub.code);
                },
              ),

              const SizedBox(height: 10),

              // Country Quick-Select Chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kGlobalRadioHubs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, idx) {
                    final hub = kGlobalRadioHubs[idx];
                    final sel = hub.code == _selectedCountryCode;
                    return GestureDetector(
                      onTap: () {
                        SoundService().playTap();
                        setState(() {
                          _selectedCountryCode = hub.code;
                          _selectedCountryName = hub.name;
                        });
                        _fetchGlobalStations(countryCode: hub.code);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? theme.primary : theme.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? theme.primary : theme.border),
                        ),
                        child: Text(
                          hub.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : theme.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Global Station Search Input
              Container(
                padding: const EdgeInsets.fromLTRB(12, 3, 4, 3),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, size: 17, color: theme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _globalSearchCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.text),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search any worldwide station, city or genre...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: theme.textSecondary.withValues(alpha: 0.65),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (q) => _fetchGlobalStations(query: q),
                      ),
                    ),
                    BouncyTap(
                      onTap: () => _fetchGlobalStations(query: _globalSearchCtrl.text),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (_isLoadingGlobal)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2.4, color: theme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Finding live stations in $_selectedCountryName...',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildStationsList(
            _globalStations,
            theme,
            emptyHint: 'Spin the 3D Globe & tap any beacon or search a station above',
          ),
      ],
    );
  }

  // ===========================================================================
  // 6B. STATIONS LIST (DIRECT SWITCH + FAVORITE + CUSTOM DELETE)
  // ===========================================================================
  Widget _buildStationsList(
    List<RadioStationItem> stations,
    StationeryTheme theme, {
    required String emptyHint,
  }) {
    if (stations.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.border),
        ),
        child: Center(
          child: Text(
            emptyHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: stations.map((st) {
        final isActive = _activeStation?.id == st.id;
        final isFav = _isFavorite(st);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BouncyTap(
            onTap: () => _tuneAndPlayStation(st),
            scaleFraction: 0.985,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? theme.primary.withValues(alpha: 0.11) : theme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? theme.primary : theme.border,
                  width: isActive ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? theme.primary : theme.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? theme.primary : theme.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          st.frequencyMhz.toStringAsFixed(1),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : theme.text,
                          ),
                        ),
                        Text(
                          'MHz',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7.8,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white70 : theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${st.country}${st.genre.isNotEmpty ? " · ${st.genre}" : ""} · ${st.codec}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.8,
                            color: isActive ? theme.primary : theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive && _isPlaying)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.graphic_eq_rounded, color: theme.primary, size: 19),
                    ),
                  if (st.isCustom)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: theme.textSecondary,
                      ),
                      onPressed: () => _deleteCustomStation(st),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 19,
                      color: isFav ? const Color(0xFFF43F5E) : theme.textSecondary,
                    ),
                    onPressed: () => _toggleFavorite(st),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // 6C. RECORDED RADIO CLIPS TAB
  // ===========================================================================
  Widget _buildRecordingsTab(StationeryTheme theme) {
    if (_recordedClips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.border),
        ),
        child: Center(
          child: Text(
            'No recorded radio clips yet.\nPlay any station and tap the red ● REC button to record live audio.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: theme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _recordedClips.map((clip) {
        final playing = _playingClipId == clip.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: playing ? theme.primary : theme.border),
          ),
          child: Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 19),
                onPressed: () => _playRecordedClip(clip),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.stationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      '${clip.frequencyMhz.toStringAsFixed(1)} MHz · ${_formatSec(clip.durationSeconds)} · ${_formatBytes(clip.sizeBytes)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.save_alt_rounded, size: 19, color: theme.primary),
                tooltip: 'Save to Device Downloads',
                onPressed: () async {
                  final fn = clip.filePath.split(Platform.pathSeparator).last;
                  final saved = await _radioChannel.invokeMethod<String>('saveRadioRecording', {
                    'sourcePath': clip.filePath,
                    'fileName': fn,
                  });
                  _showToast(
                    saved != null ? 'Saved to $saved' : 'Unable to save recording',
                    color: saved != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF43F5E),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: Color(0xFFF43F5E),
                ),
                onPressed: () => _deleteRecordedClip(clip),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// REFINED 2D VECTOR RETRO RADIO DECK PAINTER
// Telescopic antenna + acoustic speaker grille + recessed illuminated tuning
// window + labeled 88–108 MHz analog scale + station lock dots + glowing needle!
// =============================================================================
class _RetroRadio2DPainter extends CustomPainter {
  final double frequencyMhz;
  final String stationName;
  final String statusLabel;
  final String codecBadge;
  final bool isPlaying;
  final bool isBuffering;
  final bool isRecording;
  final List<double> stationFrequencies;
  final double animT;
  final StationeryTheme theme;

  _RetroRadio2DPainter({
    required this.frequencyMhz,
    required this.stationName,
    required this.statusLabel,
    required this.codecBadge,
    required this.isPlaying,
    required this.isBuffering,
    required this.isRecording,
    required this.stationFrequencies,
    required this.animT,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final isDark = theme.isDark;
    final accent = theme.primary;
    final ink = theme.text;

    final stroke = Paint()
      ..color = ink.withValues(alpha: isDark ? 0.72 : 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Telescopic FM Antenna rising cleanly at top-left
    final antBase = Offset(w * 0.13, h * 0.19);
    final antTip = Offset(w * 0.42, h * 0.035);
    canvas.drawLine(antBase, antTip, stroke..strokeWidth = 2.0);
    // Telescopic collar joint
    final antMid = Offset.lerp(antBase, antTip, 0.48)!;
    canvas.drawCircle(antMid, 2.1, Paint()..color = ink.withValues(alpha: 0.65));
    canvas.drawCircle(
      antTip,
      3.6,
      Paint()
        ..color = isRecording
            ? const Color(0xFFF43F5E)
            : (isPlaying ? const Color(0xFF10B981) : accent),
    );

    // Radiating live RF waves from antenna tip when live/tuning
    if (isPlaying || isBuffering) {
      for (int i = 0; i < 3; i++) {
        final p = (animT + i / 3.0) % 1.0;
        canvas.drawArc(
          Rect.fromCircle(center: antTip, radius: 6.0 + p * 17.0),
          -0.95,
          1.45,
          false,
          Paint()
            ..color = accent.withValues(alpha: (1.0 - p) * 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.35,
        );
      }
    }

    // 2. Retro Radio Chassis Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, h * 0.17, w - 2, h * 0.82),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = isDark
            ? const Color(0xFF171922)
            : Color.lerp(theme.bg, accent, 0.045)!,
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = ink.withValues(alpha: isDark ? 0.24 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 3. Left Retro Perforated Speaker Grille + Subtle Live Acoustic Pulse
    final spkCenter = Offset(w * 0.155, h * 0.58);
    final spkR = math.min(w * 0.11, h * 0.25);
    if (isPlaying) {
      final pulse = (math.sin(animT * math.pi * 2) + 1) * 0.5;
      canvas.drawCircle(
        spkCenter,
        spkR + 3 + pulse * 4,
        Paint()
          ..color = accent.withValues(alpha: 0.14 * (1 - pulse * 0.4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    canvas.drawCircle(
      spkCenter,
      spkR + 2.5,
      Paint()..color = accent.withValues(alpha: isDark ? 0.14 : 0.09),
    );
    canvas.drawCircle(
      spkCenter,
      spkR + 2.5,
      Paint()
        ..color = ink.withValues(alpha: isDark ? 0.35 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final dotPaint = Paint()..color = ink.withValues(alpha: isDark ? 0.52 : 0.38);
    for (int gy = -3; gy <= 3; gy++) {
      for (int gx = -3; gx <= 3; gx++) {
        final dx = gx * (spkR * 0.28);
        final dy = gy * (spkR * 0.28);
        if (dx * dx + dy * dy <= (spkR - 2) * (spkR - 2)) {
          canvas.drawCircle(Offset(spkCenter.dx + dx, spkCenter.dy + dy), 1.35, dotPaint);
        }
      }
    }

    // 4. Recessed Illuminated Retro Tuning Glass Window
    final dialLeft = w * 0.305;
    final dialWidth = w * 0.665;
    final dialTop = h * 0.23;
    final dialH = h * 0.70;
    final dialRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dialLeft, dialTop, dialWidth, dialH),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      dialRect,
      Paint()..color = isDark ? const Color(0xFF0C0E14) : Colors.white,
    );
    canvas.drawRRect(
      dialRect,
      Paint()
        ..color = accent.withValues(alpha: isPlaying ? 0.48 : 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Top Status Row inside Dial: [● ON AIR] ............ [MP3 128k]
    final statusColor = isRecording
        ? const Color(0xFFF43F5E)
        : (isPlaying
            ? const Color(0xFF10B981)
            : (isBuffering ? const Color(0xFFF59E0B) : theme.textSecondary));

    canvas.drawCircle(
      Offset(dialLeft + 14, dialTop + 13),
      3.1,
      Paint()..color = statusColor,
    );
    final stPainter = TextPainter(
      text: TextSpan(
        text: statusLabel,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: statusColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stPainter.paint(canvas, Offset(dialLeft + 21, dialTop + 7.5));

    final codecPainter = TextPainter(
      text: TextSpan(
        text: codecBadge,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8.2,
          fontWeight: FontWeight.w700,
          color: theme.textSecondary.withValues(alpha: 0.75),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    codecPainter.paint(
      canvas,
      Offset(dialLeft + dialWidth - codecPainter.width - 10, dialTop + 7.5),
    );

    // Big Crisp Frequency Readout ("98.3 MHz")
    final freqSpan = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: frequencyMhz.toStringAsFixed(1),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: ink,
              letterSpacing: -0.8,
            ),
          ),
          TextSpan(
            text: ' MHz',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    freqSpan.paint(canvas, Offset(dialLeft + 10, dialTop + 21));

    // Stereo Equalizer Bars (cleanly anchored right beside MHz readout, zero overlap!)
    for (int b = 0; b < 5; b++) {
      final level = isPlaying
          ? (0.25 + 0.75 * ((math.sin(animT * math.pi * 2 + b * 1.25) + 1) / 2))
          : 0.16;
      final bh = 18.0 * level;
      final bx = dialLeft + dialWidth - 36 + b * 5.2;
      final by = dialTop + 45 - bh;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, 3.2, bh), const Radius.circular(2)),
        Paint()..color = isPlaying ? accent : theme.border,
      );
    }

    // Station Name Readout (full width, clean spacing above analog scale)
    final namePainter = TextPainter(
      text: TextSpan(
        text: stationName,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.textSecondary,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: dialWidth - 20);
    namePainter.paint(canvas, Offset(dialLeft + 10, dialTop + 50));

    // 5. Analog FM Scale (88 .. 108) with Station Lock Dots + Glowing Sliding Needle
    final scaleY = dialTop + dialH - 25;
    final scaleStart = dialLeft + 10;
    final scaleEnd = dialLeft + dialWidth - 10;
    final scaleSpan = scaleEnd - scaleStart;

    canvas.drawLine(
      Offset(scaleStart, scaleY),
      Offset(scaleEnd, scaleY),
      Paint()
        ..color = theme.border
        ..strokeWidth = 1.5,
    );

    // Tick marks + numeric band markers (88, 92, 96, 100, 104, 108)
    const ticks = 20;
    for (int i = 0; i <= ticks; i++) {
      final tx = scaleStart + (i / ticks) * scaleSpan;
      final isMajor = i % 4 == 0;
      canvas.drawLine(
        Offset(tx, scaleY - (isMajor ? 5.5 : 2.8)),
        Offset(tx, scaleY + (isMajor ? 5.5 : 2.8)),
        Paint()
          ..color = ink.withValues(alpha: isMajor ? 0.55 : 0.22)
          ..strokeWidth = isMajor ? 1.3 : 0.85,
      );
      if (isMajor) {
        final labelMhz = 88 + i;
        final lp = TextPainter(
          text: TextSpan(
            text: '$labelMhz',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 7.4,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lp.paint(canvas, Offset(tx - lp.width / 2, scaleY + 7.5));
      }
    }

    // Active Station Lock Dots along the analog dial!
    for (final sf in stationFrequencies.take(18)) {
      final sfFrac = ((sf - 87.5) / 20.5).clamp(0.0, 1.0);
      final sx = scaleStart + sfFrac * scaleSpan;
      canvas.drawCircle(
        Offset(sx, scaleY),
        2.0,
        Paint()..color = accent.withValues(alpha: 0.72),
      );
    }

    // Glowing Red Retro Tuning Needle
    final frac = ((frequencyMhz - 87.5) / 20.5).clamp(0.0, 1.0);
    final needleX = scaleStart + frac * scaleSpan;
    canvas.drawLine(
      Offset(needleX, scaleY - 10),
      Offset(needleX, scaleY + 9),
      Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.36)
        ..strokeWidth = 5.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );
    canvas.drawLine(
      Offset(needleX, scaleY - 10),
      Offset(needleX, scaleY + 9),
      Paint()
        ..color = const Color(0xFFF43F5E)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RetroRadio2DPainter old) => true;
}
