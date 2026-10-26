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
/// TOOLER PRO FM & GLOBAL 3D RADIO STUDIO (STREAMLINED ULTRA-EDITION)
/// - Ultra-realistic tactile vector FM Radio Console with dynamic speaker cone
///   bass pulsation, 8-band audio spectrum analyzer, 5-bar RSSI signal meter,
///   luminous 88–108 MHz scale, glowing neon needle & rotary tuning dial
/// - Decluttered, high-efficiency modern Studio layout: compact top-bar pills
///   for Hardware FM & Audio routing (Speaker/Headset), integrated deck controls,
///   compact 6-channel preset ribbon, instant genre chips & live search
/// - Multi-server resilient Radio Browser API (6 fast HTTPS mirrors) with
///   real-time station sync, instant zero-lag offline caching & stream recovery
/// - Live Digital Stream Recorder (MP3/AAC/OGG) + Device Downloads export
/// - Interactive Rotating 3D Globe with 36 world hubs & live satellite relay
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

  static const String _favKey = 'tooler_fm_favorites_v3';
  static const String _customKey = 'tooler_fm_custom_stations_v3';
  static const String _clipsKey = 'tooler_fm_recorded_clips_v3';
  static const String _cachedAreaStationsKey = 'tooler_fm_cached_area_v3';

  // 6 Geographically distributed open Radio Browser mirrors
  static const List<String> _apiMirrors = [
    'https://de1.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
    'https://fr1.api.radio-browser.info',
    'https://fi1.api.radio-browser.info',
    'https://de2.api.radio-browser.info',
  ];

  // High-uptime curated verified HD radio streams (instant playback fallback)
  static const List<RadioStationItem> _fallbackStations = [
    RadioStationItem(
      id: 'seed_bolly_983',
      name: 'Hindi Retro · Mirchi Classics',
      frequencyMhz: 98.3,
      streamUrl: 'https://stream.zeno.fm/0r0xa792kwzuv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Hindi',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_red_935',
      name: 'Superhits 93.5 Red FM Mix',
      frequencyMhz: 93.5,
      streamUrl: 'https://stream.zeno.fm/f3wvbbqmdg8uv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Pop',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_vividh_air',
      name: 'AIR Vividh Bharati National Live',
      frequencyMhz: 102.8,
      streamUrl: 'https://stream.zeno.fm/k2k5p681y0quv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Akashvani · Retro',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_radiocity_911',
      name: 'Radio City 91.1 Hindi Hits',
      frequencyMhz: 91.1,
      streamUrl: 'https://stream.zeno.fm/v2ps85wqefhvv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Pop',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_bigfm_927',
      name: 'Big FM 92.7 Dhun Badal Ke Dekho',
      frequencyMhz: 92.7,
      streamUrl: 'https://stream.zeno.fm/c3w2n7f1k6quv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Retro',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_fever_104',
      name: 'Fever 104 Delhi Baap of Bollywood',
      frequencyMhz: 104.0,
      streamUrl: 'https://stream.zeno.fm/4v709d2k84zuv',
      country: 'India',
      countryCode: 'IN',
      genre: 'Bollywood · Youth Hits',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_soma_groove',
      name: 'SomaFM Groove Salad (Chill)',
      frequencyMhz: 89.9,
      streamUrl: 'https://ice2.somafm.com/groovesalad-128-mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'Ambient · Chill',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_nightride',
      name: 'Nightride FM Synthwave',
      frequencyMhz: 94.3,
      streamUrl: 'https://stream.nightride.fm/chillsynth.mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'Synthwave · Lo-Fi',
      codec: 'MP3',
      bitrate: 192,
    ),
    RadioStationItem(
      id: 'seed_paradise',
      name: 'Radio Paradise Eclectic Rock',
      frequencyMhz: 101.3,
      streamUrl: 'https://stream.radioparadise.com/mp3-128',
      country: 'Global',
      countryCode: 'US',
      genre: 'Rock · Eclectic',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_bbc_ws',
      name: 'BBC World Service News',
      frequencyMhz: 104.8,
      streamUrl: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
      country: 'United Kingdom',
      countryCode: 'GB',
      genre: 'News · Talk',
      codec: 'AAC',
      bitrate: 96,
    ),
    RadioStationItem(
      id: 'seed_capital_uk',
      name: 'Capital FM London Hits',
      frequencyMhz: 95.8,
      streamUrl: 'https://media-ice.musicradio.com/CapitalMP3',
      country: 'United Kingdom',
      countryCode: 'GB',
      genre: 'Top 40 · Pop',
      codec: 'MP3',
      bitrate: 128,
    ),
    RadioStationItem(
      id: 'seed_soma_beats',
      name: 'SomaFM Beat Blender EDM',
      frequencyMhz: 106.4,
      streamUrl: 'https://ice2.somafm.com/beatblender-128-mp3',
      country: 'Global',
      countryCode: 'US',
      genre: 'EDM · Dance',
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

  // Resolved direct stream URL cache
  final Map<String, String> _resolvedStreamCache = {};

  // Tuner & Navigation State
  double _tunedFreqMhz = 98.3;
  RadioStationItem? _activeStation;
  int _activeTab = 0; // 0 = Local FM, 1 = 3D Globe, 2 = Favorites, 3 = Recorded

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

  // Instant Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

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
  late final AnimationController _livePulseController;
  late final AnimationController _syncController;

  @override
  void initState() {
    super.initState();
    _activeStation = _areaStations.first;
    _tunedFreqMhz = _activeStation!.frequencyMhz;

    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _scanSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    _bootstrapAreaRadio();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _bufferWatchdog?.cancel();
    _recTimer?.cancel();
    _stopRadioRecording(save: false);
    if (!kIsWeb && Platform.isAndroid) {
      _radioChannel.invokeMethod('resetAudioRoute').catchError((_) {});
    }
    _radioPlayer.dispose();
    _clipPlayer.dispose();
    _eqController.dispose();
    _scanSweepController.dispose();
    _livePulseController.dispose();
    _syncController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPlayers() async {
    try {
      await _radioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
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
    _detectUserAreaSync(); // Instant 0ms local sync!
    await _detectUserArea(); // Network precision refinement
    await _scanAreaStations(silent: true);
  }

  void _detectUserAreaSync() {
    try {
      final loc = Platform.localeName;
      final parts = loc.split('_');
      String cc = 'IN';
      if (parts.length >= 2 && parts[1].length == 2) {
        cc = parts[1].toUpperCase();
      }
      final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
      if (tzOffset == 330) {
        cc = 'IN';
      }

      final label = cc == 'IN' ? 'India' : (cc == 'US' ? 'United States' : (cc == 'GB' ? 'United Kingdom' : cc));
      _detectedAreaCountryCode = cc;
      _selectedCountryCode = cc;
      _selectedCountryName = label;
      _detectedAreaLabel = 'Live Airwaves · $label';
    } catch (_) {}
  }

  Future<void> _detectUserArea() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client
          .getUrl(Uri.parse('https://ipwho.is/?fields=country,country_code,city,region'));
      final resp = await req.close().timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data is Map) {
          final cc = (data['country_code'] as String? ?? '').trim().toUpperCase();
          final country = (data['country'] as String? ?? '').trim();
          final city = (data['city'] as String? ?? '').trim();
          final region = (data['region'] as String? ?? '').trim();
          if (cc.length == 2 && mounted) {
            setState(() {
              _detectedAreaCountryCode = cc;
              _selectedCountryCode = cc;
              _selectedCountryName = country.isNotEmpty ? country : cc;
              final locName = city.isNotEmpty
                  ? (country.isNotEmpty ? '$city, $country' : city)
                  : (region.isNotEmpty ? '$region, $country' : country);
              _detectedAreaLabel = locName.isNotEmpty ? locName : 'India';
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
      final cachedAreaRaw = prefs.getString(_cachedAreaStationsKey);

      if (mounted) {
        setState(() {
          if (favRaw != null && favRaw.isNotEmpty) {
            _favoriteStations = (jsonDecode(favRaw) as List)
                .map((e) =>
                    RadioStationItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
          if (customRaw != null && customRaw.isNotEmpty) {
            _customStations = (jsonDecode(customRaw) as List)
                .map((e) =>
                    RadioStationItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
          if (clipsRaw != null && clipsRaw.isNotEmpty) {
            _recordedClips = (jsonDecode(clipsRaw) as List)
                .map((e) => RadioRecordingClip.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList();
          }
          if (cachedAreaRaw != null && cachedAreaRaw.isNotEmpty) {
            final loaded = (jsonDecode(cachedAreaRaw) as List)
                .map((e) =>
                    RadioStationItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            if (loaded.isNotEmpty) {
              _areaStations = loaded;
              _activeStation = _areaStations.first;
              _tunedFreqMhz = _activeStation!.frequencyMhz;
            }
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
      await prefs.setString(
        _cachedAreaStationsKey,
        jsonEncode(_areaStations.take(50).map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ===========================================================================
  // RESILIENT MULTI-MIRROR RADIO BROWSER API & REAL-TIME SYNC
  // ===========================================================================
  Future<List<RadioStationItem>> _queryRadioApi(String endpointPath) async {
    for (final host in _apiMirrors) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      try {
        final req = await client.getUrl(Uri.parse('$host$endpointPath'));
        req.headers.set('User-Agent', 'ToolerFMRadioStudio/3.0');
        req.headers.set('Accept', 'application/json');
        final resp = await req.close().timeout(const Duration(seconds: 5));
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
            if (lowerUrl.contains('.m3u8') || lowerUrl.endsWith('.asx')) continue;

            final name = (item['name'] as String? ?? '').trim();
            if (name.isEmpty) continue;

            final codec = (item['codec'] as String? ?? 'MP3').toUpperCase();
            final bitrate = (item['bitrate'] as num?)?.toInt() ?? 128;

            double freq = _extractFreqFromName(name) ??
                double.parse(
                    (88.1 + ((freqIdx * 1.1) % 19.4)).toStringAsFixed(1));
            freqIdx++;

            final tags = (item['tags'] as String? ?? 'FM')
                .split(',')
                .take(2)
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .join(' · ');

            final st = RadioStationItem(
              id: item['stationuuid'] as String? ?? 'api_${stream.hashCode}',
              name: name.length > 38 ? '${name.substring(0, 38)}…' : name,
              frequencyMhz: freq.clamp(87.5, 108.0),
              streamUrl: stream,
              country: (item['country'] as String? ?? 'Global').trim(),
              countryCode:
                  (item['countrycode'] as String? ?? 'GL').toUpperCase(),
              genre: tags.isNotEmpty ? tags : 'FM Radio',
              codec: codec.isEmpty ? 'MP3' : codec,
              bitrate: bitrate,
            );

            final isDirect = !lowerUrl.endsWith('.pls') &&
                !lowerUrl.endsWith('.m3u') &&
                (codec.contains('MP3') ||
                    codec.contains('AAC') ||
                    codec.contains('OGG'));
            if (isDirect) {
              directStreams.add(st);
            } else {
              secondaryStreams.add(st);
            }
            if (directStreams.length >= 35) break;
          }

          final combined =
              [...directStreams, ...secondaryStreams].take(36).toList();
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

  Future<String> _resolveDirectStreamUrl(String rawUrl) async {
    if (_resolvedStreamCache.containsKey(rawUrl)) {
      return _resolvedStreamCache[rawUrl]!;
    }
    final lower = rawUrl.toLowerCase();
    if (!lower.endsWith('.m3u') && !lower.endsWith('.pls')) {
      _resolvedStreamCache[rawUrl] = rawUrl;
      return rawUrl;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(Uri.parse(rawUrl));
      req.headers.set('User-Agent', 'ToolerFMRadioStudio/3.0');
      final resp = await req.close().timeout(const Duration(seconds: 4));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final text = await resp.transform(utf8.decoder).join();
        for (final line in text.split('\n')) {
          final t = line.trim();
          if (t.startsWith('https://')) {
            _resolvedStreamCache[rawUrl] = t;
            return t;
          }
          if (t.toLowerCase().startsWith('file1=https://')) {
            final res = t.substring(6).trim();
            _resolvedStreamCache[rawUrl] = res;
            return res;
          }
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    _resolvedStreamCache[rawUrl] = rawUrl;
    return rawUrl;
  }

  void _syncStationClick(String stationId) {
    if (stationId.startsWith('api_') || stationId.startsWith('seed_')) return;
    for (final host in _apiMirrors.take(2)) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      client
          .getUrl(Uri.parse('$host/json/url/$stationId'))
          .then((req) => req.close())
          .catchError((_) => null as dynamic)
          .whenComplete(() => client.close());
    }
  }

  double? _extractFreqFromName(String name) {
    final m = RegExp(r'\b(8[7-9]|9\d|10[0-8])\.\d\b').firstMatch(name);
    if (m != null) {
      return double.tryParse(m.group(0)!);
    }
    return null;
  }

  Future<void> _scanAreaStations({bool silent = false}) async {
    if (_isScanningArea) return;
    if (!silent) {
      SoundService().playClick();
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _isScanningArea = true;
      if (!silent) _statusBannerText = 'SCANNING...';
    });
    if (!silent) {
      _scanSweepController.repeat();
    }

    final cc = _detectedAreaCountryCode;
    final liveFound = await _queryRadioApi(
      '/json/stations/search?countrycode=$cc&hidebroken=true&lastcheckok=1&order=clickcount&reverse=true&limit=48',
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

    _persistStations();

    if (!silent) {
      SoundService().playSuccess();
      _showToast(
        'Locked ${_areaStations.length} live stations ($_detectedAreaLabel)',
        color: const Color(0xFF10B981),
      );
    }
  }

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
      _globalStations = results.isNotEmpty ? results : _fallbackStations;
      _isLoadingGlobal = false;
    });
  }

  // ===========================================================================
  // PLAYBACK, BUFFER WATCHDOG, DIRECT SWITCH & TUNING
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
      _statusBannerText = 'SYNCING LIVE FEED...';
    });

    // 6-second responsive watchdog
    _bufferWatchdog = Timer(const Duration(seconds: 6), () {
      if (!mounted || seq != _playRequestSeq) return;
      if (_isBuffering && !_isPlaying) {
        _radioPlayer.stop().catchError((_) {});
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _statusBannerText = 'WEAK SIGNAL';
        });
        _showToast(
          'Station taking long to buffer — tap Next ⏭ for another station',
          color: Colors.amber.shade800,
        );
      }
    });

    try {
      final isPlaylist = station.streamUrl.toLowerCase().endsWith('.m3u') ||
          station.streamUrl.toLowerCase().endsWith('.pls');
      final String directUrl;
      if (_resolvedStreamCache.containsKey(station.streamUrl)) {
        directUrl = _resolvedStreamCache[station.streamUrl]!;
      } else if (!isPlaylist) {
        directUrl = station.streamUrl;
        _resolvedStreamCache[station.streamUrl] = directUrl;
      } else {
        directUrl = await _resolveDirectStreamUrl(station.streamUrl);
      }

      if (!mounted || seq != _playRequestSeq) return;

      if (_isPlaying) {
        await _radioPlayer.stop();
      }
      await _radioPlayer.play(UrlSource(directUrl), mode: PlayerMode.mediaPlayer);
      _syncStationClick(station.id);
    } catch (_) {
      _bufferWatchdog?.cancel();
      if (mounted && seq == _playRequestSeq) {
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _statusBannerText = 'OFFLINE';
        });
        _showToast(
          'Stream offline — tap Next ⏭ for another station',
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
      final pool = _getFilteredStations();
      final target = _activeStation ??
          (pool.isNotEmpty ? pool.first : _fallbackStations.first);
      await _tuneAndPlayStation(target);
    }
  }

  void _stepStation(int delta) {
    final pool = _getFilteredStations();
    if (pool.isEmpty) return;
    final curIdx = pool.indexWhere((s) => s.id == _activeStation?.id);
    final nextIdx =
        curIdx == -1 ? 0 : (curIdx + delta + pool.length) % pool.length;
    _tuneAndPlayStation(pool[nextIdx]);
  }

  List<RadioStationItem> _getFilteredStations() {
    List<RadioStationItem> base;
    if (_activeTab == 1) {
      base = _globalStations.isNotEmpty ? _globalStations : _fallbackStations;
    } else if (_activeTab == 2) {
      base = _favoriteStations;
    } else {
      base = _areaStations;
    }

    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.toLowerCase().trim();
    return base.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.country.toLowerCase().contains(q) ||
          s.genre.toLowerCase().contains(q) ||
          s.frequencyMhz.toStringAsFixed(1).contains(q);
    }).toList();
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
        _favoriteStations.removeWhere(
            (f) => f.id == station.id || f.streamUrl == station.streamUrl);
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
  // LIVE RADIO STREAM RECORDER
  // ===========================================================================
  Future<void> _toggleRadioRecording() async {
    SoundService().playClick();
    HapticFeedback.mediumImpact();

    if (_isRecordingRadio) {
      await _stopRadioRecording(save: true);
      return;
    }

    final station = _activeStation;
    if (station == null ||
        station.streamUrl.isEmpty ||
        (!_isPlaying && !_isBuffering)) {
      _showToast(
        'Play a radio station first, then tap ● REC to record!',
        color: Colors.amber.shade800,
      );
      return;
    }

    try {
      final resolvedUrl = await _resolveDirectStreamUrl(station.streamUrl);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final req = await client.getUrl(Uri.parse(resolvedUrl));
      req.headers.set('User-Agent', 'ToolerFMRadioStudio/3.0');
      final resp = await req.close().timeout(const Duration(seconds: 6));

      final ct = (resp.headers.contentType?.mimeType ?? '').toLowerCase();
      if (resp.statusCode < 200 ||
          resp.statusCode >= 300 ||
          ct.contains('mpegurl') ||
          ct.contains('text/')) {
        client.close(force: true);
        _showToast(
          'Protected stream format — switch station to record live audio',
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
      _showToast('Could not start live capture on this station',
          color: const Color(0xFFF43F5E));
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
          style: widget.theme.fontDisplay(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text('Delete "${clip.stationName}" clip permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
  // MAIN BUILD — CLEAN, MINIMAL, HIGH-END RADIO STUDIO
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final filteredStations = _getFilteredStations();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEARCH BAR + SCAN BUTTON (Directly below sheet header)
            _buildTopSearchBar(theme),

            // Scrollable Minimal Radio Console + Station Explorer
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. MINIMAL THEMED RADIO DECK (No speaker, no volume knob, no antenna)
                    _buildRealisticRadioConsole(theme),

                    const SizedBox(height: 14),

                    // 3. SEGMENTED TABS (Local FM · 3D Globe · Favorites · Recorded)
                    _buildNavigationPills(theme),

                    const SizedBox(height: 12),

                    // 4. ACTIVE TAB VIEW
                    if (_activeTab == 0)
                      _buildStationsList(
                        filteredStations,
                        theme,
                        emptyHint: _searchQuery.isNotEmpty
                            ? 'No station matches ""'
                            : 'Tap SCAN to discover local live FM stations',
                      ),
                    if (_activeTab == 1) _buildGlobal3DTab(theme),
                    if (_activeTab == 2)
                      _buildStationsList(
                        filteredStations,
                        theme,
                        emptyHint: _searchQuery.isNotEmpty
                            ? 'No favorite matches ""'
                            : 'Tap ♥ on any radio station to keep it in Favorites',
                      ),
                    if (_activeTab == 3) _buildRecordingsTab(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP SEARCH BAR + SCAN ACTION (Replacing previous cluttered top bar)
  // ===========================================================================
  Widget _buildTopSearchBar(StationeryTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: theme.border, width: 1.1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      size: 17, color: theme.textSecondary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5, color: theme.text),
                      decoration: InputDecoration(
                        hintText: 'Search station, frequency, city, genre...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: theme.textSecondary.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        _searchDebounce?.cancel();
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 260), () {
                          if (mounted) {
                            setState(() => _searchQuery = val);
                            if (_activeTab == 1 && val.trim().length > 2) {
                              _fetchGlobalStations(query: val);
                            }
                          }
                        });
                      },
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close_rounded,
                          size: 16, color: theme.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Scan Button
          BouncyTap(
            onTap: _isScanningArea ? null : () => _scanAreaStations(),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isScanningArea)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.radar_rounded,
                        color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    _isScanningArea ? 'SCAN...' : 'SCAN',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MINIMAL THEMED RADIO CONSOLE DECK
  // ===========================================================================
  Widget _buildRealisticRadioConsole(StationeryTheme theme) {
    final station = _activeStation;
    final isFav = _isFavorite(station);
    final presetPool = _areaStations.take(6).toList();
    final stationFreqs = _areaStations.map((s) => s.frequencyMhz).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPlaying
              ? theme.primary.withValues(alpha: 0.55)
              : theme.border,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isPlaying ? theme.primary : Colors.black)
                .withValues(alpha: theme.isDark ? 0.20 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Minimal Radio Top Status & RSSI Signal Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _livePulseController,
                builder: (_, __) {
                  final glow = _isPlaying
                      ? const Color(0xFF10B981)
                      : (_isBuffering
                          ? const Color(0xFFF59E0B)
                          : theme.textSecondary.withValues(alpha: 0.4));
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: glow,
                      shape: BoxShape.circle,
                      boxShadow: _isPlaying
                          ? [
                              BoxShadow(
                                color: glow.withValues(alpha: 0.6),
                                blurRadius: 5,
                                spreadRadius: 1.5,
                              )
                            ]
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(width: 7),
              Text(
                _isPlaying
                    ? 'ON AIR · LIVE BROADCAST'
                    : (_isBuffering ? 'TUNING LIVE FEED...' : _statusBannerText),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _isPlaying
                      ? const Color(0xFF10B981)
                      : (_isBuffering ? const Color(0xFFF59E0B) : theme.textSecondary),
                ),
              ),
              const Spacer(),
              // Minimal 5-bar RSSI signal meter
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  final active = _isPlaying ? (i < 4) : (_isBuffering ? (i < 2) : false);
                  final h = 4.0 + (i * 2.2);
                  return Container(
                    width: 2.5,
                    height: h,
                    margin: const EdgeInsets.only(left: 2.5),
                    decoration: BoxDecoration(
                      color: active
                          ? (_isPlaying ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                          : theme.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // B. Frequency Readout & Station Title Recessed Screen
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        station?.name ?? 'FM Tuner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ' · ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _tunedFreqMhz.toStringAsFixed(1),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: theme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MHz',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // C. Integrated Interactive Frequency Tuning Scale & Nudge
          Row(
            children: [
              _miniNudgeBtn('-0.1', () => _nudgeFrequency(-0.1), theme),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Tuner Scale Painter (88 - 108 MHz graduation markings & needle)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MinimalTunerScalePainter(
                            frequencyMhz: _tunedFreqMhz,
                            stationFrequencies: stationFreqs,
                            theme: theme,
                          ),
                        ),
                      ),
                      // Transparent Slider overlay for direct touch scrub
                      Positioned.fill(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 0.0,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.transparent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 14.0,
                              elevation: 0,
                              pressedElevation: 0,
                            ),
                            overlayColor: theme.primary.withValues(alpha: 0.12),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          ),
                          child: Slider(
                            value: _tunedFreqMhz.clamp(87.5, 108.0),
                            min: 87.5,
                            max: 108.0,
                            onChanged: (v) {
                              setState(() =>
                                  _tunedFreqMhz = double.parse(v.toStringAsFixed(1)));
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
                    ],
                  ),
                ),
              ),
              _miniNudgeBtn('+0.1', () => _nudgeFrequency(0.1), theme),
            ],
          ),

          const SizedBox(height: 10),

          // D. Quick 6-Channel Preset Ribbon (CH1..CH6)
          if (presetPool.isNotEmpty) ...[
            Row(
              children: List.generate(presetPool.length, (idx) {
                final st = presetPool[idx];
                final selected = _activeStation?.id == st.id;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: idx < presetPool.length - 1 ? 4 : 0),
                    child: BouncyTap(
                      onTap: () => _tuneAndPlayStation(st),
                      scaleFraction: 0.94,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 5.5),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.primary.withValues(alpha: 0.15)
                              : theme.bg,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: selected
                                ? theme.primary
                                : theme.border,
                            width: selected ? 1.3 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected)
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    margin: const EdgeInsets.only(right: 3),
                                    decoration: BoxDecoration(
                                      color: theme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  'CH',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? theme.primary
                                        : theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              st.frequencyMhz.toStringAsFixed(1),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: selected
                                    ? theme.primary
                                    : theme.text,
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
            const SizedBox(height: 12),
          ],

          // E. Deck Controls: [♥ Fav] [⏮ Prev] [PLAY/STOP] [⏭ Next] [● REC]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _deckActionBtn(
                icon: isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: isFav
                    ? const Color(0xFFE11D48)
                    : theme.textSecondary,
                bg: isFav
                    ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                    : theme.bg,
                border: isFav
                    ? const Color(0xFFE11D48).withValues(alpha: 0.4)
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
              _RadioSyncPlayButton(
                isPlaying: _isPlaying,
                isBuffering: _isBuffering,
                onTap: _togglePlayStop,
                syncRotation: _syncController,
                pulse: _livePulseController,
                eq: _eqController,
                theme: theme,
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
                iconColor: _isRecordingRadio
                    ? Colors.white
                    : const Color(0xFFDC2626),
                bg: _isRecordingRadio
                    ? const Color(0xFFDC2626)
                    : theme.bg,
                border: _isRecordingRadio
                    ? const Color(0xFFDC2626)
                    : theme.border,
                onTap: _toggleRadioRecording,
              ),
            ],
          ),

          // Active Recording Status Ribbon
          if (_isRecordingRadio) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fiber_manual_record_rounded,
                      color: Color(0xFFDC2626), size: 10),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE RECORDING ·  · ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.1),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _miniNudgeBtn(String label, VoidCallback onTap, StationeryTheme theme) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border, width: 1.1),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: theme.text,
          ),
        ),
      ),
    );
  }
  Widget _buildNavigationPills(StationeryTheme theme) {
    final tabs = [
      ('Local FM', _areaStations.length, Icons.radio_rounded),
      ('3D Globe', kGlobalRadioHubs.length, Icons.public_rounded),
      ('Favorites', _favoriteStations.length, Icons.favorite_rounded),
      ('Recorded', _recordedClips.length, Icons.mic_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.border, width: 1.1),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final (label, count, icon) = tabs[i];
          final sel = _activeTab == i;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                SoundService().playTap();
                setState(() => _activeTab = i);
                if (i == 1 && _globalStations.isEmpty) {
                  _fetchGlobalStations(countryCode: _selectedCountryCode);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? theme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13.5,
                      color: sel ? Colors.white : theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight:
                            sel ? FontWeight.w800 : FontWeight.w600,
                        color: sel ? Colors.white : theme.text,
                      ),
                    ),
                    if (count > 0 && i != 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? Colors.white.withValues(alpha: 0.85)
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
  // 5A. 3D GLOBE EXPLORER TAB
  // ===========================================================================
  Widget _buildGlobal3DTab(StationeryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.border, width: 1.2),
          ),
          child: Column(
            children: [
              // 3D Globe with Atmosphere, 36 Hubs & Orbit Satellite
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

              // Country Quick-Select Ribbon
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: kGlobalRadioHubs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
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
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? theme.primary : theme.bg,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: sel ? theme.primary : theme.border),
                        ),
                        child: Text(
                          '${hub.flag} ${hub.name}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : theme.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (_isLoadingGlobal)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                      strokeWidth: 2.2, color: theme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Loading live stations from $_selectedCountryName...',
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
            _getFilteredStations(),
            theme,
            emptyHint:
                'Spin the 3D Globe & tap any country beacon to tune in',
          ),
      ],
    );
  }

  // ===========================================================================
  // 5B. STREAMLINED STATIONS LIST ITEM
  // ===========================================================================
  Widget _buildStationsList(
    List<RadioStationItem> stations,
    StationeryTheme theme, {
    required String emptyHint,
  }) {
    if (stations.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Center(
          child: Text(
            emptyHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, color: theme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: stations.map((st) {
        final isActive = _activeStation?.id == st.id;
        final isFav = _isFavorite(st);

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: BouncyTap(
            onTap: () => _tuneAndPlayStation(st),
            scaleFraction: 0.985,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.primary.withValues(alpha: 0.10)
                    : theme.cardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive ? theme.primary : theme.border,
                  width: isActive ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Frequency Badge
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? theme.primary : theme.bg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: isActive ? theme.primary : theme.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          st.frequencyMhz.toStringAsFixed(1),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : theme.text,
                          ),
                        ),
                        Text(
                          'MHz',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7.2,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white70
                                : theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Station Title & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
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
                            fontSize: 9.5,
                            color: isActive
                                ? theme.primary
                                : theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Audio Equalizer Wave Indicator when Playing
                  if (isActive && _isPlaying)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.graphic_eq_rounded,
                          color: theme.primary, size: 18),
                    ),

                  // Delete Custom Station
                  if (st.isCustom)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: theme.textSecondary),
                      onPressed: () => _deleteCustomStation(st),
                    ),

                  // Favorite Toggle
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: isFav
                          ? const Color(0xFFF43F5E)
                          : theme.textSecondary,
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
  // 5C. RECORDED AUDIO CLIPS TAB
  // ===========================================================================
  Widget _buildRecordingsTab(StationeryTheme theme) {
    if (_recordedClips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Center(
          child: Text(
            'No recorded radio clips yet.\nPlay any live station and tap the red ● REC button to record live broadcasts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: theme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _recordedClips.map((clip) {
        final playing = _playingClipId == clip.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: playing ? theme.primary : theme.border),
          ),
          child: Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 18),
                onPressed: () => _playRecordedClip(clip),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.stationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      '${clip.frequencyMhz.toStringAsFixed(1)} MHz · ${_formatSec(clip.durationSeconds)} · ${_formatBytes(clip.sizeBytes)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.save_alt_rounded,
                    size: 18, color: theme.primary),
                tooltip: 'Save to Device Downloads',
                onPressed: () async {
                  final fn = clip.filePath.split(Platform.pathSeparator).last;
                  final saved = await _radioChannel
                      .invokeMethod<String>('saveRadioRecording', {
                    'sourcePath': clip.filePath,
                    'fileName': fn,
                  });
                  _showToast(
                    saved != null
                        ? 'Saved to $saved'
                        : 'Unable to save recording',
                    color: saved != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF43F5E),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
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
// ULTRA-REALISTIC TACTILE RETRO-MODERN RADIO DECK PAINTER
// Multi-stage telescopic chrome antenna + acoustic bass-pulsing speaker grille
// + recessed frosted-glass tuning window + live 8-band audio visualizer
// + 5-bar signal RSSI meter + illuminated 88–108 analog scale + neon needle!
// =============================================================================
// MINIMAL INTERACTIVE TUNER SCALE PAINTER
// Clean, elegant analog graduation markings across 87.5 - 108.0 MHz
// =============================================================================
class _MinimalTunerScalePainter extends CustomPainter {
  final double frequencyMhz;
  final List<double> stationFrequencies;
  final StationeryTheme theme;

  const _MinimalTunerScalePainter({
    required this.frequencyMhz,
    required this.stationFrequencies,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h * 0.42;

    const minF = 87.5;
    const maxF = 108.0;
    const range = maxF - minF;

    double fToX(double f) => ((f - minF) / range).clamp(0.0, 1.0) * w;

    // Horizontal baseline
    final baseLinePaint = Paint()
      ..color = theme.border
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, centerY), Offset(w, centerY), baseLinePaint);

    // Ticks & Labels
    final majorTickPaint = Paint()
      ..color = theme.textSecondary.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    final minorTickPaint = Paint()
      ..color = theme.border
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: theme.textSecondary,
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      fontFamily: 'JetBrainsMono',
    );

    for (double f = 88.0; f <= 108.0; f += 1.0) {
      final x = fToX(f);
      final isMajor = (f % 4 == 0); // 88, 92, 96, 100, 104, 108

      if (isMajor) {
        canvas.drawLine(
          Offset(x, centerY - 8),
          Offset(x, centerY + 8),
          majorTickPaint,
        );

        final tp = TextPainter(
          text: TextSpan(text: f.toInt().toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, centerY + 10));
      } else {
        canvas.drawLine(
          Offset(x, centerY - 4),
          Offset(x, centerY + 4),
          minorTickPaint,
        );
      }
    }

    // Station frequency marker dots
    final dotPaint = Paint()
      ..color = theme.primary.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    for (final sf in stationFrequencies) {
      if (sf >= minF && sf <= maxF) {
        final x = fToX(sf);
        canvas.drawCircle(Offset(x, centerY), 2.2, dotPaint);
      }
    }

    // Indicator Needle
    final needleX = fToX(frequencyMhz);
    final needlePaint = Paint()
      ..color = theme.primary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Needle vertical line
    canvas.drawLine(
      Offset(needleX, 2),
      Offset(needleX, h - 6),
      needlePaint,
    );

    // Needle center pip
    final needlePipPaint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(needleX, centerY), 4.0, needlePipPaint);
  }

  @override
  bool shouldRepaint(covariant _MinimalTunerScalePainter old) =>
      old.frequencyMhz != frequencyMhz || old.theme != theme;
}
// =============================================================================
class _RadioSyncPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  final Animation<double> syncRotation;
  final Animation<double> pulse;
  final Animation<double> eq;
  final StationeryTheme theme;

  const _RadioSyncPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
    required this.syncRotation,
    required this.pulse,
    required this.eq,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      scaleFraction: 0.88,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 74,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPlaying
                ? [const Color(0xFFE11D48), const Color(0xFFBE123C)]
                : (isBuffering
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)]),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying
                ? const Color(0xFFFDA4AF).withValues(alpha: 0.40)
                : (isBuffering
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.75)
                    : theme.border),
            width: isBuffering ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPlaying
                      ? const Color(0xFFE11D48)
                      : (isBuffering
                          ? const Color(0xFFF59E0B)
                          : theme.primary))
                  .withValues(alpha: isPlaying ? 0.45 : (isBuffering ? 0.35 : 0.20)),
              blurRadius: isBuffering ? 14 : 10,
              spreadRadius: isBuffering ? 1 : 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isBuffering)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([syncRotation, pulse]),
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _PlaySyncRadarPainter(
                        rotation: syncRotation.value,
                        pulse: pulse.value,
                      ),
                    );
                  },
                ),
              ),
            Center(
              child: isBuffering
                  ? AnimatedBuilder(
                      animation: syncRotation,
                      builder: (_, __) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: syncRotation.value * math.pi * 2,
                              child: const Icon(
                                Icons.sync_rounded,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SYNC',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : (isPlaying
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            _MiniEqualizer(eq: eq),
                          ],
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFFF59E0B),
                          size: 30,
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaySyncRadarPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  const _PlaySyncRadarPainter({required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.46;

    // Expanding concentric pulse wave
    final pR = r * (0.4 + 0.6 * pulse);
    final pAlpha = (1.0 - pulse).clamp(0.0, 1.0) * 0.35;
    canvas.drawCircle(
      center,
      pR,
      Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: pAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 8 Rotating LED sync notches around perimeter
    final angleBase = rotation * math.pi * 2;
    for (int i = 0; i < 8; i++) {
      final a = angleBase + (i / 8) * math.pi * 2;
      final notchR = r - 1.5;
      final pt = Offset(center.dx + math.cos(a) * notchR, center.dy + math.sin(a) * notchR);
      final alpha = (1.0 - (i / 8.0)).clamp(0.15, 0.95);
      canvas.drawCircle(
        pt,
        1.5,
        Paint()..color = const Color(0xFFF59E0B).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlaySyncRadarPainter old) =>
      old.rotation != rotation || old.pulse != pulse;
}

class _MiniEqualizer extends StatelessWidget {
  final Animation<double> eq;
  const _MiniEqualizer({required this.eq});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eq,
      builder: (_, __) {
        final v = eq.value;
        final h1 = 5.0 + math.sin(v * math.pi * 2) * 5.0;
        final h2 = 5.0 + math.sin((v + 0.33) * math.pi * 2) * 6.0;
        final h3 = 5.0 + math.sin((v + 0.66) * math.pi * 2) * 4.5;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _eqBar(h1),
            const SizedBox(width: 2),
            _eqBar(h2),
            const SizedBox(width: 2),
            _eqBar(h3),
          ],
        );
      },
    );
  }

  Widget _eqBar(double h) {
    return Container(
      width: 2.4,
      height: h.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.2),
      ),
    );
  }
}

