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
/// TOOLER RETRO FM & GLOBAL 3D RADIO STUDIO
/// - Retro 2D Vector Radio Deck with telescopic antenna, analog 87.5-108 MHz
///   illuminated dial, glowing tuning needle & stereo spectrum bars
/// - Real hardware wired-antenna / Bluetooth / Speaker output telemetry & toggle
/// - 1-Tap Auto-Scan Area Stations + Direct Station Switch + Manual Add Station
/// - Favorite Stations (♥) with persistent storage & station naming
/// - Real Live Radio Stream Recorder (captures digital radio stream to MP3)
/// - Live Global Radio Browser API (30,000+ worldwide HTTPS stations) +
///   Interactive Rotating 3D Globe with Real Vector Continent Map!
/// ---------------------------------------------------------------------------

class RadioStationItem {
  final String id;
  final String name;
  final double frequencyMhz;
  final String streamUrl;
  final String country;
  final String countryCode;
  final String genre;
  final bool isCustom;

  const RadioStationItem({
    required this.id,
    required this.name,
    required this.frequencyMhz,
    required this.streamUrl,
    this.country = 'India',
    this.countryCode = 'IN',
    this.genre = 'FM',
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
  static const String _favKey = 'tooler_fm_favorites_v1';
  static const String _customKey = 'tooler_fm_custom_stations_v1';
  static const String _clipsKey = 'tooler_fm_recorded_clips_v1';

  // Radio Browser open global API mirrors (HTTPS, zero API key required)
  static const List<String> _apiMirrors = [
    'https://de1.api.radio-browser.info',
    'https://fr1.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
  ];

  // Curated verified high-reliability Indian FM presets (used as instant seed + fallback)
  static const List<RadioStationItem> _seedAreaStations = [
    RadioStationItem(
      id: 'seed_mirchi_983',
      name: 'Radio Mirchi 98.3 FM',
      frequencyMhz: 98.3,
      streamUrl: 'https://eu8.fastcast4u.com/proxy/clyedupq?mp=/1',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Hits',
    ),
    RadioStationItem(
      id: 'seed_vividh_1028',
      name: 'AIR Vividh Bharati',
      frequencyMhz: 102.8,
      streamUrl: 'https://air.pc.cdn.bitgravity.com/air/live/pbaudio001/playlist.m3u8',
      country: 'India',
      countryCode: 'IN',
      genre: 'Classic · AIR',
    ),
    RadioStationItem(
      id: 'seed_fmgold_1064',
      name: 'AIR FM Gold',
      frequencyMhz: 106.4,
      streamUrl: 'https://airhlspush.pc.cdn.bitgravity.com/httppush/hlspbaudio005/hlspbaudio00564kbps.m3u8',
      country: 'India',
      countryCode: 'IN',
      genre: 'News · Retro',
    ),
    RadioStationItem(
      id: 'seed_rainbow_1013',
      name: 'AIR FM Rainbow',
      frequencyMhz: 101.3,
      streamUrl: 'https://airhlspush.pc.cdn.bitgravity.com/httppush/hlspbaudio004/hlspbaudio00464kbps.m3u8',
      country: 'India',
      countryCode: 'IN',
      genre: 'Pop · Hindi',
    ),
    RadioStationItem(
      id: 'seed_city_911',
      name: 'Radio City Hindi',
      frequencyMhz: 91.1,
      streamUrl: 'https://stream.zeno.fm/pxc55r5uyc9uv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Hindi · Hits',
    ),
    RadioStationItem(
      id: 'seed_lofi_943',
      name: 'Nightride FM Chill',
      frequencyMhz: 94.3,
      streamUrl: 'https://stream.nightride.fm/chillsynth.m4a',
      country: 'Global',
      countryCode: 'US',
      genre: 'Synth · Chill',
    ),
  ];

  // Audio Playback
  final AudioPlayer _radioPlayer = AudioPlayer();
  final AudioPlayer _clipPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _playingClipId;

  // Tuner State
  double _tunedFreqMhz = 98.3;
  RadioStationItem? _activeStation;
  int _activeTab = 0; // 0=Area FM, 1=Global 3D, 2=Favorites, 3=Recordings

  // Station Collections
  List<RadioStationItem> _areaStations = List.from(_seedAreaStations);
  List<RadioStationItem> _customStations = [];
  List<RadioStationItem> _favoriteStations = [];
  List<RadioStationItem> _globalStations = [];
  bool _isScanningArea = false;
  bool _isLoadingGlobal = false;
  String _selectedCountryCode = 'IN';
  String _selectedCountryName = 'India';
  final TextEditingController _globalSearchCtrl = TextEditingController();

  // Hardware Antenna & Output State
  bool _hasWiredAntenna = false;
  bool _hasBluetoothAudio = false;
  bool _hasFmChip = false;
  String _activeOutputName = 'Phone Speaker';
  String _outputRoute = 'headset'; // 'headset' (wired/BT) or 'speaker'
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

  @override
  void initState() {
    super.initState();
    _activeStation = _areaStations.first;
    _tunedFreqMhz = _activeStation!.frequencyMhz;

    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _initPlayers();
    _loadPersistedData();
    _pollHardwareStatus();
    _hwPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollHardwareStatus();
    });

    // Silently enrich area stations from Radio Browser API right away
    _scanAreaStations(silent: true);
  }

  @override
  void dispose() {
    _hwPollTimer?.cancel();
    _recTimer?.cancel();
    _stopRadioRecording(save: false);
    _radioPlayer.dispose();
    _clipPlayer.dispose();
    _eqController.dispose();
    _globalSearchCtrl.dispose();
    super.dispose();
  }

  void _initPlayers() {
    _radioPlayer.onPlayerStateChanged.listen((st) {
      if (!mounted) return;
      setState(() {
        _isPlaying = st == PlayerState.playing;
        if (st == PlayerState.playing || st == PlayerState.stopped) {
          _isBuffering = false;
        }
      });
    });

    _clipPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingClipId = null);
    });
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
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final dynamic raw = await _radioChannel.invokeMethod('getRadioHardwareStatus');
      if (raw is Map && mounted) {
        setState(() {
          _hasWiredAntenna = raw['hasWiredAntenna'] == true;
          _hasBluetoothAudio = raw['hasBluetoothAudio'] == true;
          _hasFmChip = raw['hasFmChip'] == true;
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

  // ===========================================================================
  // GLOBAL RADIO BROWSER API (MULTI-MIRROR HTTPS)
  // ===========================================================================
  Future<List<RadioStationItem>> _queryRadioApi(String endpointPath) async {
    for (final host in _apiMirrors) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
      try {
        final req = await client.getUrl(Uri.parse('$host$endpointPath'));
        req.headers.set('User-Agent', 'ToolerFMRadio/1.0');
        req.headers.set('Accept', 'application/json');
        final resp = await req.close().timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final List rawList = jsonDecode(body) as List;
          final parsed = <RadioStationItem>[];
          final seenUrls = <String>{};

          int freqIdx = 0;
          for (final item in rawList) {
            if (item is! Map) continue;
            final stream = (item['url_resolved'] as String? ?? item['url'] as String? ?? '').trim();
            // Strictly HTTPS so Android cleartext policy never blocks playback
            if (!stream.startsWith('https://') || !seenUrls.add(stream)) continue;
            final name = (item['name'] as String? ?? '').trim();
            if (name.isEmpty) continue;

            // Extract real FM MHz if present in station name (e.g. "98.3 Mirchi" -> 98.3)
            double freq = _extractFreqFromName(name) ??
                double.parse((88.1 + ((freqIdx * 1.4) % 19.2)).toStringAsFixed(1));
            freqIdx++;

            parsed.add(
              RadioStationItem(
                id: item['stationuuid'] as String? ?? 'api_${stream.hashCode}',
                name: name.length > 42 ? '${name.substring(0, 42)}…' : name,
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
              ),
            );
            if (parsed.length >= 24) break;
          }
          client.close();
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {
      } finally {
        client.close();
      }
    }
    return [];
  }

  double? _extractFreqFromName(String name) {
    final m = RegExp(r'\b(8[7-9]|9\d|10[0-8])\.\d\b').firstMatch(name);
    if (m != null) {
      return double.tryParse(m.group(0)!);
    }
    return null;
  }

  /// Auto-Scans local / regional FM stations in 1 tap so user never has to sweep dead static!
  Future<void> _scanAreaStations({bool silent = false}) async {
    if (_isScanningArea) return;
    if (!silent) {
      SoundService().playClick();
      HapticFeedback.mediumImpact();
    }
    setState(() => _isScanningArea = true);

    final liveFound = await _queryRadioApi(
      '/json/stations/search?countrycode=IN&hidebroken=true&order=clickcount&reverse=true&limit=35',
    );

    if (!mounted) return;
    setState(() {
      final merged = <RadioStationItem>[..._customStations];
      final seenIds = merged.map((e) => e.id).toSet();
      for (final s in liveFound) {
        if (seenIds.add(s.id)) merged.add(s);
      }
      for (final seed in _seedAreaStations) {
        if (seenIds.add(seed.id)) merged.add(seed);
      }
      _areaStations = merged;
      _isScanningArea = false;
    });

    if (!silent) {
      SoundService().playSuccess();
      _showToast(
        'Area Scan complete · ${_areaStations.length} active stations ready!',
        color: const Color(0xFF10B981),
      );
    }
  }

  /// Fetches live global stations for a selected country on the 3D Globe or search query
  Future<void> _fetchGlobalStations({String? countryCode, String? query}) async {
    setState(() => _isLoadingGlobal = true);
    final String path;
    if (query != null && query.trim().isNotEmpty) {
      final q = Uri.encodeQueryComponent(query.trim());
      path = '/json/stations/search?name=$q&hidebroken=true&order=clickcount&reverse=true&limit=35';
    } else {
      final cc = (countryCode ?? _selectedCountryCode).toUpperCase();
      path = '/json/stations/search?countrycode=$cc&hidebroken=true&order=clickcount&reverse=true&limit=35';
    }

    final results = await _queryRadioApi(path);
    if (!mounted) return;
    setState(() {
      _globalStations = results;
      _isLoadingGlobal = false;
    });
  }

  // ===========================================================================
  // PLAYBACK, DIRECT STATION SWITCH & TUNING CONTROLS
  // ===========================================================================
  Future<void> _tuneAndPlayStation(RadioStationItem station) async {
    SoundService().playClick();
    HapticFeedback.selectionClick();

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
    });

    try {
      await _radioPlayer.stop();
      await _radioPlayer.play(UrlSource(station.streamUrl));
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
        });
        _showToast('Stream temporarily unavailable — try another station', color: Colors.amber.shade800);
      }
    }
  }

  Future<void> _togglePlayStop() async {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    if (_isPlaying || _isBuffering) {
      if (_isRecordingRadio) await _stopRadioRecording(save: true);
      await _radioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _isBuffering = false;
      });
    } else {
      final target = _activeStation ?? _areaStations.first;
      await _tuneAndPlayStation(target);
    }
  }

  void _stepStation(int delta) {
    final pool = _currentStationPool();
    if (pool.isEmpty) return;
    final curIdx = pool.indexWhere((s) => s.id == _activeStation?.id);
    final nextIdx = curIdx == -1
        ? 0
        : (curIdx + delta + pool.length) % pool.length;
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
    final next = double.parse((_tunedFreqMhz + deltaMhz).clamp(87.5, 108.0).toStringAsFixed(1));
    setState(() => _tunedFreqMhz = next);

    // Auto-snap if a known station sits right on this frequency
    final match = _areaStations.where((s) => (s.frequencyMhz - next).abs() <= 0.15).firstOrNull;
    if (match != null && match.id != _activeStation?.id) {
      _tuneAndPlayStation(match);
    }
  }

  bool _isFavorite(RadioStationItem? station) {
    if (station == null) return false;
    return _favoriteStations.any((f) => f.id == station.id || f.streamUrl == station.streamUrl);
  }

  Future<void> _toggleFavorite(RadioStationItem station) async {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    setState(() {
      if (_isFavorite(station)) {
        _favoriteStations.removeWhere((f) => f.id == station.id || f.streamUrl == station.streamUrl);
      } else {
        _favoriteStations.insert(0, station);
      }
    });
    await _persistStations();
  }

  // ===========================================================================
  // MANUAL ADD STATION DIALOG (NAME + FREQUENCY + OPTIONAL URL)
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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.border, width: 1.2),
        ),
        title: Text(
          'Add Radio Station',
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
              decoration: InputDecoration(
                labelText: 'Station Name (e.g. Nagpur Red FM)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: freqCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Frequency MHz (87.5 – 108.0)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final freq = (double.tryParse(freqCtrl.text.trim()) ?? _tunedFreqMhz).clamp(87.5, 108.0);
              String streamUrl = urlCtrl.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(ctx);

              // Auto-resolve live stream from Radio Browser API if user didn't paste a URL
              if (streamUrl.isEmpty) {
                final found = await _queryRadioApi(
                  '/json/stations/search?name=${Uri.encodeQueryComponent(name)}&hidebroken=true&limit=5',
                );
                if (found.isNotEmpty) {
                  streamUrl = found.first.streamUrl;
                } else {
                  streamUrl = _seedAreaStations.first.streamUrl;
                }
              }

              final custom = RadioStationItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                frequencyMhz: double.parse(freq.toStringAsFixed(1)),
                streamUrl: streamUrl,
                country: 'Custom',
                countryCode: 'IN',
                genre: 'Manual FM',
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
            child: const Text('Add & Tune'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LIVE RADIO STREAM RECORDER (RECORDS CLEAN DIGITAL AUDIO DIRECTLY)
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
      _showToast('Play a radio station first to record live audio', color: Colors.amber.shade800);
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/tooler_radio_$ts.mp3';
      final file = File(filePath);
      final sink = file.openWrite();

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(station.streamUrl));
      req.headers.set('User-Agent', 'ToolerFMRadio/1.0');
      final resp = await req.close();

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        await sink.close();
        client.close();
        _showToast('This stream format cannot be captured directly', color: Colors.amber.shade800);
        return;
      }

      _recHttpClient = client;
      _recFileSink = sink;
      _recFilePath = filePath;

      setState(() {
        _isRecordingRadio = true;
        _recSeconds = 0;
        _recBytes = 0;
      });

      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isRecordingRadio) {
          setState(() => _recSeconds++);
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
      _showToast('Unable to start live stream capture', color: const Color(0xFFF43F5E));
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
      });
    }

    if (save && path != null && bytes > 1024 && station != null) {
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
        _showToast('Radio clip recorded (${_formatBytes(bytes)})', color: const Color(0xFF10B981));
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
    if (_isPlaying) {
      await _radioPlayer.stop();
    }
    try {
      await _clipPlayer.stop();
      await _clipPlayer.play(DeviceFileSource(clip.filePath));
      setState(() => _playingClipId = clip.id);
    } catch (_) {}
  }

  Future<void> _deleteRecordedClip(RadioRecordingClip clip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Radio Clip?', style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Delete "${clip.stationName}" recording permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white),
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
        content: Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
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
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. COOL 2D VECTOR RETRO RADIO DECK (Theme-matched with Telescopic Antenna & Analog Dial)
              _buildRetroRadioDeck(theme),

              const SizedBox(height: 12),

              // 2. HARDWARE ANTENNA & WIRED/BLUETOOTH/SPEAKER AUDIO OUTPUT BAR
              _buildHardwareOutputStrip(theme),

              const SizedBox(height: 12),

              // 3. QUICK ACTION BAR: Auto-Scan Area + Manual Add Station
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
                              color: theme.primary.withValues(alpha: 0.28),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 7),
                            Text(
                              _isScanningArea ? 'SCANNING AREA...' : 'FIND AREA STATIONS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
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
                          Icon(Icons.add_rounded, color: theme.primary, size: 19),
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

              // 4. SECTION TABS: Area FM | Global 3D Globe | Favorites | Recordings
              _buildTabsStrip(theme),

              const SizedBox(height: 12),

              // 5. ACTIVE TAB CONTENT
              if (_activeTab == 0) _buildStationsList(_areaStations, theme, emptyHint: 'Tap FIND AREA STATIONS to scan FM channels'),
              if (_activeTab == 1) _buildGlobal3DRadioTab(theme),
              if (_activeTab == 2) _buildStationsList(_favoriteStations, theme, emptyHint: 'Tap ♥ on any radio station to add it to Favorites'),
              if (_activeTab == 3) _buildRecordingsTab(theme),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. COOL 2D VECTOR RETRO RADIO DECK + ANALOG FREQUENCY TUNER + CONTROLS
  // ===========================================================================
  Widget _buildRetroRadioDeck(StationeryTheme theme) {
    final station = _activeStation;
    final isFav = _isFavorite(station);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isPlaying ? theme.primary.withValues(alpha: 0.55) : theme.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isPlaying ? theme.primary : Colors.black).withValues(alpha: theme.isDark ? 0.22 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 2D Retro Vector Radio Illustration (Telescopic Antenna, Speaker Grille, Analog Dial + Live Needle)
          SizedBox(
            height: 146,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _eqController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _RetroRadio2DPainter(
                    frequencyMhz: _tunedFreqMhz,
                    stationName: station?.name ?? 'FM Tuner',
                    isPlaying: _isPlaying,
                    isBuffering: _isBuffering,
                    hasAntenna: _hasWiredAntenna || _hasBluetoothAudio,
                    animT: _eqController.value,
                    theme: theme,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Direct Analog Frequency Band Scrubber (87.5 - 108.0 MHz)
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
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                          .where((s) => (s.frequencyMhz - rounded).abs() <= 0.6)
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

          const SizedBox(height: 8),

          // Retro Tactile Channel Switch Deck: [Fav] [Prev] [PLAY/STOP] [Next] [REC]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Favorite Toggle
              BouncyTap(
                onTap: station != null ? () => _toggleFavorite(station) : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFav ? const Color(0xFFF43F5E).withValues(alpha: 0.14) : theme.bg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isFav ? const Color(0xFFF43F5E).withValues(alpha: 0.45) : theme.border,
                    ),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? const Color(0xFFF43F5E) : theme.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              // Prev Station
              BouncyTap(
                onTap: () => _stepStation(-1),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: theme.border),
                  ),
                  child: Icon(Icons.skip_previous_rounded, color: theme.text, size: 22),
                ),
              ),

              // Big Tactile Retro Power / Play Button
              BouncyTap(
                onTap: _togglePlayStop,
                scaleFraction: 0.90,
                child: Container(
                  width: 62,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isPlaying ? const Color(0xFFF43F5E) : theme.primary,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying ? const Color(0xFFF43F5E) : theme.primary)
                            .withValues(alpha: 0.36),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isBuffering
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Icon(
                            _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ),

              // Next Station
              BouncyTap(
                onTap: () => _stepStation(1),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: theme.border),
                  ),
                  child: Icon(Icons.skip_next_rounded, color: theme.text, size: 22),
                ),
              ),

              // Record Live Radio Button
              BouncyTap(
                onTap: _toggleRadioRecording,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isRecordingRadio
                        ? const Color(0xFFF43F5E)
                        : theme.bg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _isRecordingRadio ? const Color(0xFFF43F5E) : theme.border,
                    ),
                  ),
                  child: Icon(
                    _isRecordingRadio ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded,
                    color: _isRecordingRadio ? Colors.white : const Color(0xFFF43F5E),
                    size: 20,
                  ),
                ),
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
                border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fiber_manual_record_rounded, color: Color(0xFFF43F5E), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'RECORDING LIVE RADIO · ${_formatSec(_recSeconds)} · ${_formatBytes(_recBytes)}',
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
  // 2. HARDWARE ANTENNA & WIRED / BLUETOOTH / SPEAKER OUTPUT SWITCH STRIP
  // ===========================================================================
  Widget _buildHardwareOutputStrip(StationeryTheme theme) {
    final bool hasExternal = _hasWiredAntenna || _hasBluetoothAudio;
    final String antennaLabel = _hasWiredAntenna
        ? 'Wired Antenna Active'
        : (_hasBluetoothAudio
            ? 'Bluetooth Audio Active'
            : (_hasFmChip ? 'Plug Wired Earphones for Antenna' : 'Hybrid FM · Live Digital Tuner'));
    final Color statusColor = _hasWiredAntenna || _hasBluetoothAudio
        ? const Color(0xFF10B981)
        : theme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1.1),
      ),
      child: Row(
        children: [
          Icon(
            _hasWiredAntenna
                ? Icons.headset_rounded
                : (_hasBluetoothAudio ? Icons.bluetooth_connected_rounded : Icons.settings_input_antenna_rounded),
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  antennaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
                Text(
                  'Output: $_activeOutputName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Output Switch: Headset (Wired/BT) <-> Phone Speaker
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
                  onTap: () => _setOutputRoute('headset'),
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
                  : (dimmed ? theme.textSecondary.withValues(alpha: 0.4) : theme.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: active
                    ? Colors.white
                    : (dimmed ? theme.textSecondary.withValues(alpha: 0.4) : theme.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. TABS STRIP
  // ===========================================================================
  Widget _buildTabsStrip(StationeryTheme theme) {
    final tabs = [
      ('Area FM', _areaStations.length, Icons.radio_rounded),
      ('Global 3D', _globalStations.length, Icons.public_rounded),
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
                          color: sel ? Colors.white.withValues(alpha: 0.9) : theme.textSecondary,
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
  // 5A. GLOBAL 3D GLOBE + GLOBAL RADIO API SEARCH TAB
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
              // Interactive Rotating 3D Globe with Real Vector World Map!
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

              const SizedBox(height: 12),

              // Country Quick Select Pills
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

              const SizedBox(height: 12),

              // Global Station Search Input (search ANY radio worldwide!)
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
                          hintText: 'Search any global station, city or genre...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
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
                    'Tuning $_selectedCountryName global stations...',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          _buildStationsList(
            _globalStations,
            theme,
            emptyHint: 'Tap any beacon on the 3D Globe or search a radio name above',
          ),
      ],
    );
  }

  // ===========================================================================
  // 5B. STATIONS LIST (DIRECT SWITCH + FAVORITE HEART)
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
            scaleFraction: 0.98,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: isActive ? theme.primary.withValues(alpha: 0.11) : theme.cardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive ? theme.primary : theme.border,
                  width: isActive ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Retro Frequency Badge
                  Container(
                    width: 60,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : theme.text,
                          ),
                        ),
                        Text(
                          'MHz',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
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
                          '${st.country}${st.genre.isNotEmpty ? " · ${st.genre}" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: isActive ? theme.primary : theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive && _isPlaying)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.graphic_eq_rounded, color: theme.primary, size: 20),
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
  // 5C. RECORDED RADIO CLIPS TAB
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
            'No recorded radio clips yet.\nPlay any station and tap the red ● REC button to capture live audio.',
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: playing ? theme.primary : theme.border),
          ),
          child: Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: theme.text),
                    ),
                    Text(
                      '${clip.frequencyMhz.toStringAsFixed(1)} MHz · ${_formatSec(clip.durationSeconds)} · ${_formatBytes(clip.sizeBytes)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: theme.textSecondary),
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
                    color: saved != null ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFF43F5E)),
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
// COOL 2D VECTOR RETRO RADIO DECK PAINTER
// Telescopic antenna + perforated speaker grille + illuminated analog FM scale
// + glowing sliding needle + live animated stereo equalizer bars!
// =============================================================================
class _RetroRadio2DPainter extends CustomPainter {
  final double frequencyMhz;
  final String stationName;
  final bool isPlaying;
  final bool isBuffering;
  final bool hasAntenna;
  final double animT;
  final StationeryTheme theme;

  _RetroRadio2DPainter({
    required this.frequencyMhz,
    required this.stationName,
    required this.isPlaying,
    required this.isBuffering,
    required this.hasAntenna,
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
      ..color = ink.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Telescopic FM Antenna rod rising cleanly at top-left
    final antBase = Offset(w * 0.14, h * 0.24);
    final antTip = Offset(w * 0.42, h * 0.04);
    canvas.drawLine(antBase, antTip, stroke..strokeWidth = 2.0);
    canvas.drawCircle(antTip, 3.6, Paint()..color = isPlaying ? const Color(0xFFF43F5E) : accent);

    // Subtle live RF signal waves radiating from antenna tip when playing
    if (isPlaying || isBuffering) {
      for (int i = 0; i < 3; i++) {
        final p = (animT + i / 3.0) % 1.0;
        canvas.drawArc(
          Rect.fromCircle(center: antTip, radius: 6.0 + p * 16.0),
          -0.95,
          1.4,
          false,
          Paint()
            ..color = accent.withValues(alpha: (1.0 - p) * 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }

    // 2. Retro Radio Chassis Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, h * 0.22, w - 4, h * 0.76),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = isDark
            ? const Color(0xFF1A1A22)
            : Color.lerp(theme.bg, accent, 0.05)!,
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = ink.withValues(alpha: isDark ? 0.28 : 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Left Retro Speaker Grille (Clean dot matrix circle!)
    final spkCenter = Offset(w * 0.17, h * 0.60);
    final spkR = math.min(w * 0.115, h * 0.26);
    canvas.drawCircle(
      spkCenter,
      spkR + 3,
      Paint()
        ..color = accent.withValues(alpha: isDark ? 0.14 : 0.10)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(spkCenter, spkR + 3, stroke..strokeWidth = 1.4);

    final dotPaint = Paint()..color = ink.withValues(alpha: isDark ? 0.50 : 0.35);
    for (int gy = -3; gy <= 3; gy++) {
      for (int gx = -3; gx <= 3; gx++) {
        final dx = gx * (spkR * 0.28);
        final dy = gy * (spkR * 0.28);
        if (dx * dx + dy * dy <= (spkR - 2) * (spkR - 2)) {
          canvas.drawCircle(Offset(spkCenter.dx + dx, spkCenter.dy + dy), 1.4, dotPaint);
        }
      }
    }

    // 4. Right Illuminated Retro Frequency Display & Analog Tuning Window
    final dialLeft = w * 0.33;
    final dialWidth = w * 0.63;
    final dialRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dialLeft, h * 0.30, dialWidth, h * 0.58),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      dialRect,
      Paint()
        ..color = isDark ? const Color(0xFF0E1016) : Colors.white,
    );
    canvas.drawRRect(
      dialRect,
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Digital Frequency Readout (e.g. "98.3 MHz")
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
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    freqSpan.paint(canvas, Offset(dialLeft + 10, h * 0.33));

    // Station Name Sub-Readout
    final namePainter = TextPainter(
      text: TextSpan(
        text: stationName,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: theme.textSecondary,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: dialWidth - 68);
    namePainter.paint(canvas, Offset(dialLeft + 10, h * 0.53));

    // Animated Stereo Equalizer Bars (top-right inside dial)
    for (int b = 0; b < 5; b++) {
      final level = isPlaying
          ? (0.25 + 0.75 * ((math.sin(animT * math.pi * 2 + b * 1.3) + 1) / 2))
          : 0.18;
      final bh = 18.0 * level;
      final bx = dialLeft + dialWidth - 36 + b * 5.2;
      final by = h * 0.56 - bh;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, 3.2, bh), const Radius.circular(2)),
        Paint()..color = isPlaying ? accent : theme.border,
      );
    }

    // 5. Analog FM Scale Track (88 .. 108) + Glowing Red Retro Tuning Needle
    final scaleY = h * 0.74;
    final scaleStart = dialLeft + 10;
    final scaleEnd = dialLeft + dialWidth - 10;
    final scaleSpan = scaleEnd - scaleStart;

    canvas.drawLine(
      Offset(scaleStart, scaleY),
      Offset(scaleEnd, scaleY),
      Paint()
        ..color = theme.border
        ..strokeWidth = 1.6,
    );

    const ticks = 20;
    for (int i = 0; i <= ticks; i++) {
      final tx = scaleStart + (i / ticks) * scaleSpan;
      final isMajor = i % 5 == 0;
      canvas.drawLine(
        Offset(tx, scaleY - (isMajor ? 5.5 : 3.0)),
        Offset(tx, scaleY + (isMajor ? 5.5 : 3.0)),
        Paint()
          ..color = ink.withValues(alpha: isMajor ? 0.55 : 0.25)
          ..strokeWidth = isMajor ? 1.4 : 0.9,
      );
    }

    // Glowing Red Sliding Needle positioned at exact tuned MHz
    final frac = ((frequencyMhz - 87.5) / 20.5).clamp(0.0, 1.0);
    final needleX = scaleStart + frac * scaleSpan;
    canvas.drawLine(
      Offset(needleX, scaleY - 10),
      Offset(needleX, scaleY + 9),
      Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.35)
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
