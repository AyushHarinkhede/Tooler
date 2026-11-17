import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../services/browser_adblock_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
import '../widgets_3d/tooler_logo.dart';
import '../widgets_3d/tooler_character.dart';

/// ---------------------------------------------------------------------------
/// TOOLER MINIMAL SMART WEB BROWSER & UNIVERSAL MEDIA DOWNLOADER
/// ---------------------------------------------------------------------------
/// - Ultra-clean landing: Tooler logo -> "Browser" -> Search bar ("Search") ->
///   subtle VPN & Incognito icons underneath (only when active), nothing else.
/// - Contextual Top Nav Bar:
///   * Landing: minimal Download + 3-dot menu only.
///   * Browsing: Back ONLY | Search bar | Dynamic Search/Refresh icon |
///     Universal Download button | 3-dot Menu (with Incognito, VPN, Fullscreen...).
/// - Super-strong Universal Web Downloader:
///   * Deep DOM + srcset + CSS bg + OpenGraph + JSON-LD + Performance API +
///     Fetch/XHR runtime sniffer + HLS (.m3u8) + Base64 data URI support.
///   * Native Android MediaStore downloader with WebView Cookies & Referer.
/// ---------------------------------------------------------------------------
class BrowserScreen extends StatefulWidget {
  final StationeryTheme theme;
  const BrowserScreen({super.key, required this.theme});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  static const MethodChannel _dlMethodChannel =
      MethodChannel('com.tooler.tooler/browser_download');
  static const EventChannel _dlEventChannel =
      EventChannel('com.tooler.tooler/browser_download_events');
  static const MethodChannel _privacyChannel =
      MethodChannel('com.tooler.tooler/browser_privacy');

  final BrowserAdBlockService _adBlock = BrowserAdBlockService();
  late final WebViewController _controller;
  final TextEditingController _urlCtrl = TextEditingController();
  final FocusNode _urlFocus = FocusNode();
  StreamSubscription<dynamic>? _dlEventSub;

  bool _hasLoadedFirstPage = false;
  bool _isLoading = false;
  double _loadProgress = 0.0;
  String _currentUrl = '';
  String _lastSearchDisplay = '';
  bool _canGoForward = false;
  bool _isDesktopMode = false;

  // Tracks whether the user typed something new in the nav search bar
  // true -> shows Search icon; false -> shows Refresh icon
  bool _hasEditedUrl = false;

  // REAL Privacy & Security Engines: Multi-API AdBlock + Live Proxy VPN + Native Incognito
  bool _isAdBlockActive = true;
  int _adsBlockedCount = 0;

  bool _isVpnActive = false;
  bool _isVpnConnecting = false;
  String _directIp = 'Checking...';
  String _directLocation = '';
  String _vpnRoutedIp = '';
  String _vpnServerLabel = 'Not Connected';
  String _vpnProxyHostPort = '';
  String _vpnSourceApi = '';
  int _vpnLatencyMs = 0;
  String _vpnErrorMsg = '';

  bool _isIncognitoMode = false;

  // Deep Sniffed Media Items on current webpage
  List<Map<String, dynamic>> _detectedMedia = [];
  bool _isSniffing = false;

  // Active & completed downloads tracked via native MediaStore downloader
  final Map<String, double> _downloadProgress = {};
  final List<Map<String, dynamic>> _downloadHistory = [];

  // Optional modal state callback so download progress animates live inside sheet
  void Function(VoidCallback)? _activeModalSetState;

  String get _activeUserAgent => _isDesktopMode
      ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
      : 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    _subscribeDownloadEvents();
    _initPrivacyEngines();
  }

  Future<void> _initPrivacyEngines() async {
    // 1. Load cached + sync 3 live AdBlock APIs
    await _adBlock.initialize();
    if (mounted) setState(() {});

    // 2. Fetch real current direct IP & restore any active native ProxyController status
    try {
      final statusRaw = await _privacyChannel.invokeMethod('getPrivacyStatus');
      if (statusRaw is Map && mounted) {
        final connected = statusRaw['connected'] == true;
        setState(() {
          _isVpnActive = connected;
          _isIncognitoMode = statusRaw['incognitoHardened'] == true;
          if (connected) {
            _vpnRoutedIp = statusRaw['ip'] as String? ?? '';
            final city = statusRaw['city'] as String? ?? '';
            final country = statusRaw['country'] as String? ?? 'Global Relay';
            _vpnServerLabel = city.isNotEmpty ? '$city, $country' : country;
            _vpnProxyHostPort = '${statusRaw['host']}:${statusRaw['port']}';
            _vpnLatencyMs = (statusRaw['latencyMs'] as num?)?.toInt() ?? 0;
            _vpnSourceApi = statusRaw['sourceApi'] as String? ?? '';
          }
        });
      }
      final directRaw = await _privacyChannel.invokeMethod('getDirectIp');
      if (directRaw is Map && mounted) {
        final ip = directRaw['ip'] as String? ?? 'Unavailable';
        final city = directRaw['city'] as String? ?? '';
        final country = directRaw['country'] as String? ?? '';
        setState(() {
          _directIp = ip;
          _directLocation = city.isNotEmpty && country.isNotEmpty
              ? '$city, $country'
              : country;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _dlEventSub?.cancel();
    if (_isIncognitoMode) {
      // Auto-purge all native cookies, WebStorage, and WebView caches on close
      _purgeWebViewTracesSilent();
      _privacyChannel.invokeMethod('setIncognitoHardening', {'enabled': false}).catchError((_) {});
    }
    _urlCtrl.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  Future<void> _purgeWebViewTracesSilent() async {
    try {
      await _controller.clearCache();
      await WebViewCookieManager().clearCookies();
      await _controller.clearLocalStorage();
      await _privacyChannel.invokeMethod('wipeAllTraces');
    } catch (_) {}
  }

  void _subscribeDownloadEvents() {
    _dlEventSub = _dlEventChannel.receiveBroadcastStream().listen(
      (raw) {
        if (!mounted || raw is! Map) return;
        final ev = Map<String, dynamic>.from(raw);
        final url = ev['url'] as String? ?? '';
        final status = ev['status'] as String? ?? '';
        final progress = (ev['progress'] as num?)?.toDouble() ?? 0.0;
        final received = (ev['receivedBytes'] as num?)?.toInt() ?? 0;
        final fileName = ev['fileName'] as String? ?? 'file';
        final location = ev['savedLocation'] as String? ?? 'Downloads/Tooler';
        final err = ev['error'] as String? ?? '';

        if (status == 'downloading') {
          setState(() {
            _downloadProgress[url] = progress;
          });
          _activeModalSetState?.call(() {});
        } else if (status == 'completed') {
          HapticFeedback.mediumImpact();
          SoundService().playSuccess();
          setState(() {
            _downloadProgress.remove(url);
            _downloadHistory.insert(0, {
              'name': fileName,
              'path': location,
              'size': _formatBytes(received),
              'url': url,
              'time': DateTime.now(),
            });
          });
          _activeModalSetState?.call(() {});
          _showToast(
            'Saved $fileName (${_formatBytes(received)}) • $location',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_rounded,
          );
        } else if (status == 'error') {
          setState(() => _downloadProgress.remove(url));
          _activeModalSetState?.call(() {});
          _showToast(
            'Download failed: ${err.isNotEmpty ? err : "Blocked by host"}',
            color: const Color(0xFFF43F5E),
            icon: Icons.error_outline_rounded,
          );
        }
      },
      onError: (_) {},
    );
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
          widget.theme.isDark ? const Color(0xFF121216) : Colors.white)
      ..setUserAgent(_activeUserAgent)
      ..addJavaScriptChannel(
        'ToolerPrivacyBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          try {
            final data = jsonDecode(msg.message);
            if (data is Map && data['type'] == 'ad_blocked') {
              final count = (data['count'] as num?)?.toInt() ?? 1;
              if (mounted && count > 0) {
                setState(() => _adsBlockedCount += count);
              }
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadProgress = progress / 100.0;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
                if (!_urlFocus.hasFocus) {
                  _lastSearchDisplay = _extractDisplayQueryOrUrl(url);
                  _urlCtrl.text = _lastSearchDisplay;
                  _hasEditedUrl = false;
                }
              });
            }
            // Early-stage Ad/Popup & Incognito shield injection right as page starts loading
            _injectPrivacyAndAdBlockShields();
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _currentUrl = url;
              if (!_urlFocus.hasFocus) {
                _lastSearchDisplay = _extractDisplayQueryOrUrl(url);
                _urlCtrl.text = _lastSearchDisplay;
                _hasEditedUrl = false;
              }
            });
            _updateNavigationState();
            await _injectPrivacyAndAdBlockShields();
            await _injectRuntimeMediaHook();
            Future.delayed(const Duration(milliseconds: 450), () {
              if (mounted) _sniffPageMedia();
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Browser resource notice: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // 1. REAL Multi-API Ad & Popup Redirect Blocker (15,000+ domains from 3 live APIs!)
            if (_isAdBlockActive && _adBlock.isAdOrPopupUrl(request.url)) {
              if (mounted) {
                setState(() => _adsBlockedCount++);
              }
              return NavigationDecision.prevent;
            }

            // 2. Direct Media / File Download Interceptor
            final urlLower = request.url.toLowerCase().split('?').first;
            final isDirectDownload = urlLower.endsWith('.apk') ||
                urlLower.endsWith('.zip') ||
                urlLower.endsWith('.rar') ||
                urlLower.endsWith('.7z') ||
                urlLower.endsWith('.pdf') ||
                urlLower.endsWith('.mp4') ||
                urlLower.endsWith('.webm') ||
                urlLower.endsWith('.mkv') ||
                urlLower.endsWith('.mp3') ||
                urlLower.endsWith('.m4a') ||
                urlLower.endsWith('.wav');

            if (isDirectDownload) {
              _startNativeDownload(
                request.url,
                _extractFilename(request.url),
                _guessTypeFromUrl(request.url),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _injectPrivacyAndAdBlockShields() async {
    try {
      if (_isAdBlockActive) {
        await _controller.runJavaScript(_adBlock.buildAdBlockInjectionJs());
      }
      if (_isIncognitoMode || _isVpnActive) {
        await _controller.runJavaScript(
          _adBlock.buildIncognitoHardeningJs(
            isIncognito: _isIncognitoMode,
            isVpn: _isVpnActive,
          ),
        );
      }
    } catch (_) {}
  }

  /// Displays clean search term if on Google or DuckDuckGo Search, otherwise clean URL
  String _extractDisplayQueryOrUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if ((uri.host.contains('google.') && uri.path.contains('/search')) ||
          uri.host.contains('duckduckgo.com')) {
        final q = uri.queryParameters['q'];
        if (q != null && q.trim().isNotEmpty) return q.trim();
      }
    } catch (_) {}
    return url;
  }

  Future<void> _updateNavigationState() async {
    final canForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoForward = canForward;
      });
    }
  }

  /// Injects a non-intrusive JS hook on fetch/XHR so dynamically loaded videos/audio/streams are captured live.
  Future<void> _injectRuntimeMediaHook() async {
    try {
      const hookJs = r'''
      (function() {
        if (window.__toolerSnifferHooked) return;
        window.__toolerSnifferHooked = true;
        window.__toolerCapturedUrls = window.__toolerCapturedUrls || [];
        var mediaRe = /\.(mp4|webm|mkv|mov|m3u8|ts|mp3|m4a|wav|ogg|aac|flac|jpg|jpeg|png|webp|gif|avif|svg|pdf|zip|rar|7z|apk|doc|docx|xls|xlsx|ppt|pptx)(\?|$|#)/i;

        function recordUrl(u) {
          if (!u || typeof u !== 'string') return;
          try {
            var full = new URL(u, location.href).href;
            if (mediaRe.test(full) || full.indexOf('mime=video') !== -1 || full.indexOf('mime=audio') !== -1) {
              if (window.__toolerCapturedUrls.indexOf(full) === -1) {
                window.__toolerCapturedUrls.push(full);
                if (window.__toolerCapturedUrls.length > 120) window.__toolerCapturedUrls.shift();
              }
            }
          } catch(e) {}
        }

        var origFetch = window.fetch;
        if (origFetch) {
          window.fetch = function(input) {
            try {
              var u = (typeof input === 'string') ? input : (input && input.url);
              recordUrl(u);
            } catch(e) {}
            return origFetch.apply(this, arguments);
          };
        }

        var origOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url) {
          try { recordUrl(url); } catch(e) {}
          return origOpen.apply(this, arguments);
        };
      })();
      ''';
      await _controller.runJavaScript(hookJs);
    } catch (_) {}
  }

  /// Deep Multi-Layer Webpage Media Sniffer:
  /// Captures videos, HLS streams, audio, high-res srcset/lazy images, CSS backgrounds,
  /// OpenGraph/Twitter meta media, JSON-LD contentUrl, Performance API network resources,
  /// hooked fetch/XHR media, downloadable file links, and inline base64 images.
  Future<void> _sniffPageMedia() async {
    if (_isSniffing || !_hasLoadedFirstPage) return;
    _isSniffing = true;
    try {
      const jsSniffer = r'''
      (function() {
        var items = [];
        var seen = {};

        var vidRe = /\.(mp4|webm|mkv|mov|avi|m3u8|ts)(\?|$|#)/i;
        var audRe = /\.(mp3|m4a|wav|ogg|aac|flac|opus)(\?|$|#)/i;
        var imgRe = /\.(jpg|jpeg|png|webp|gif|avif|bmp|svg)(\?|$|#)/i;
        var docRe = /\.(pdf|zip|rar|7z|apk|doc|docx|xls|xlsx|ppt|pptx|epub|csv|txt)(\?|$|#)/i;

        function classify(url, fallback) {
          if (!url) return fallback || 'file';
          if (url.startsWith('data:image/')) return 'image';
          if (url.startsWith('data:video/')) return 'video';
          if (url.startsWith('data:audio/')) return 'audio';
          if (vidRe.test(url) || url.indexOf('mime=video') !== -1) return 'video';
          if (audRe.test(url) || url.indexOf('mime=audio') !== -1) return 'audio';
          if (docRe.test(url)) return 'file';
          if (imgRe.test(url)) return 'image';
          return fallback || 'file';
        }

        function add(type, rawUrl, title, meta) {
          if (!rawUrl || typeof rawUrl !== 'string') return;
          rawUrl = rawUrl.trim();
          if (!rawUrl || rawUrl.startsWith('blob:') || rawUrl.startsWith('javascript:')) return;
          var url = rawUrl;
          if (!url.startsWith('data:')) {
            try { url = new URL(rawUrl, location.href).href; } catch(e) { return; }
            if (!url.startsWith('http://') && !url.startsWith('https://')) return;
          } else {
            if (url.length < 250 || url.length > 3500000) return;
          }
          if (seen[url]) return;
          seen[url] = true;
          var finalType = classify(url, type);
          items.push({
            type: finalType,
            url: url,
            title: (title || '').toString().trim().slice(0, 90),
            meta: (meta || '').toString().trim()
          });
        }

        function bestFromSrcset(srcset) {
          if (!srcset) return '';
          var bestUrl = '';
          var bestScore = -1;
          var parts = srcset.split(',');
          for (var i = 0; i < parts.length; i++) {
            var seg = parts[i].trim().split(/\s+/);
            if (!seg[0]) continue;
            var score = 0;
            if (seg[1]) {
              var num = parseFloat(seg[1]);
              if (!isNaN(num)) score = num;
            }
            if (score >= bestScore) {
              bestScore = score;
              bestUrl = seg[0];
            }
          }
          return bestUrl;
        }

        // 1. Videos & Sources
        var vids = document.querySelectorAll('video');
        for (var i = 0; i < vids.length; i++) {
          var v = vids[i];
          var res = (v.videoWidth && v.videoHeight) ? (v.videoWidth + '×' + v.videoHeight) : 'Video';
          add('video', v.currentSrc || v.src, v.title || document.title || 'Video ' + (i + 1), res);
          if (v.poster) add('image', v.poster, 'Video Poster ' + (i + 1), 'Poster');
          var vs = v.querySelectorAll('source');
          for (var s = 0; s < vs.length; s++) {
            add('video', vs[s].src, vs[s].getAttribute('label') || document.title || 'Video Source', vs[s].type || res);
          }
        }

        // 2. Audio & Sources
        var auds = document.querySelectorAll('audio');
        for (var a = 0; a < auds.length; a++) {
          var au = auds[a];
          add('audio', au.currentSrc || au.src, au.title || 'Audio Track ' + (a + 1), 'Audio');
          var asrc = au.querySelectorAll('source');
          for (var k = 0; k < asrc.length; k++) {
            add('audio', asrc[k].src, 'Audio Track ' + (a + 1), asrc[k].type || 'Audio');
          }
        }

        // 3. OpenGraph / Twitter Meta Tags (Great for hero images & embedded videos)
        var metas = document.querySelectorAll('meta[property], meta[name]');
        for (var m = 0; m < metas.length; m++) {
          var key = (metas[m].getAttribute('property') || metas[m].getAttribute('name') || '').toLowerCase();
          var val = metas[m].getAttribute('content') || '';
          if (key === 'og:video' || key === 'og:video:url' || key === 'og:video:secure_url' || key === 'twitter:player:stream') {
            add('video', val, document.title || 'Featured Video', 'Stream');
          } else if (key === 'og:audio' || key === 'og:audio:secure_url') {
            add('audio', val, document.title || 'Featured Audio', 'Audio');
          } else if (key === 'og:image' || key === 'og:image:secure_url' || key === 'twitter:image') {
            add('image', val, document.title || 'Featured Image', 'HD Preview');
          }
        }

        // 4. JSON-LD Structured Media (contentUrl / thumbnailUrl)
        var lds = document.querySelectorAll('script[type="application/ld+json"]');
        for (var d = 0; d < lds.length; d++) {
          try {
            var txt = lds[d].textContent || '';
            var matches = txt.match(/https?:\/\/[^"'\s\\]+/g) || [];
            for (var u = 0; u < matches.length; u++) {
              var mu = matches[u];
              if (vidRe.test(mu)) add('video', mu, document.title || 'Embedded Video', 'LD-JSON');
              else if (audRe.test(mu)) add('audio', mu, document.title || 'Embedded Audio', 'LD-JSON');
              else if (imgRe.test(mu)) add('image', mu, document.title || 'Media Image', 'LD-JSON');
            }
          } catch(e) {}
        }

        // 5. High-Res Images (including srcset, data-src, picture sources & base64)
        var pics = document.querySelectorAll('picture source[srcset]');
        for (var p = 0; p < pics.length; p++) {
          var b = bestFromSrcset(pics[p].getAttribute('srcset'));
          if (b) add('image', b, 'Picture Image', 'High-Res');
        }
        var imgs = document.querySelectorAll('img');
        for (var j = 0; j < imgs.length; j++) {
          var im = imgs[j];
          var w = im.naturalWidth || im.width || 0;
          var h = im.naturalHeight || im.height || 0;
          if (w >= 48 || h >= 48 || im.getAttribute('data-src') || im.getAttribute('srcset')) {
            var best = bestFromSrcset(im.getAttribute('srcset')) ||
                       im.getAttribute('data-original') ||
                       im.getAttribute('data-lazy-src') ||
                       im.getAttribute('data-src') ||
                       im.currentSrc ||
                       im.src;
            var dim = (w > 0 && h > 0) ? (w + '×' + h) : 'Image';
            add('image', best, im.alt || im.title || 'Image ' + (j + 1), dim);
          }
        }

        // 6. CSS Background Images on visible hero/media blocks
        var bgEls = document.querySelectorAll('div, section, figure, a, span');
        var bgCap = Math.min(bgEls.length, 140);
        for (var bIdx = 0; bIdx < bgCap; bIdx++) {
          var st = window.getComputedStyle(bgEls[bIdx]).backgroundImage;
          if (st && st !== 'none' && st.indexOf('url(') !== -1) {
            var bgM = st.match(/url\(["']?([^"')]+)["']?\)/);
            if (bgM && bgM[1]) add('image', bgM[1], 'Background Image', 'CSS Media');
          }
        }

        // 7. Direct Downloadable Links (Documents, Archives, APKs, Media)
        var links = document.querySelectorAll('a[href]');
        for (var l = 0; l < links.length; l++) {
          var href = links[l].href;
          if (vidRe.test(href) || audRe.test(href) || docRe.test(href) || imgRe.test(href) || links[l].hasAttribute('download')) {
            var label = (links[l].innerText || links[l].getAttribute('download') || '').trim();
            add(classify(href, 'file'), href, label || 'Web File', 'Link');
          }
        }

        // 8. Browser Performance Resource Entries + Hooked Fetch/XHR Live Network Media!
        var perfEntries = (window.performance && window.performance.getEntriesByType)
          ? window.performance.getEntriesByType('resource')
          : [];
        for (var pe = 0; pe < perfEntries.length; pe++) {
          var n = perfEntries[pe].name || '';
          if (vidRe.test(n) || audRe.test(n) || docRe.test(n) || n.indexOf('mime=video') !== -1 || n.indexOf('mime=audio') !== -1) {
            add(classify(n, 'video'), n, 'Stream / Network Media', 'Network');
          }
        }

        var hooked = window.__toolerCapturedUrls || [];
        for (var hk = 0; hk < hooked.length; hk++) {
          var hu = hooked[hk];
          add(classify(hu, 'video'), hu, 'Captured Stream Media', 'Live Hook');
        }

        // Prioritize Videos -> Audio -> Files -> Images
        var rank = { video: 0, audio: 1, file: 2, image: 3 };
        items.sort(function(x, y) { return (rank[x.type] || 9) - (rank[y.type] || 9); });

        return JSON.stringify(items.slice(0, 120));
      })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsSniffer);
      if (!mounted) return;

      String rawStr = result.toString();
      if (rawStr.startsWith('"') && rawStr.endsWith('"')) {
        rawStr = jsonDecode(rawStr) as String;
      }
      final List parsed = jsonDecode(rawStr) as List;
      setState(() {
        _detectedMedia = parsed
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (_) {
    } finally {
      _isSniffing = false;
    }
  }

  Future<String> _getPageCookies() async {
    try {
      final res = await _controller.runJavaScriptReturningResult('document.cookie');
      String s = res.toString();
      if (s.startsWith('"') && s.endsWith('"')) {
        s = jsonDecode(s) as String;
      }
      return s;
    } catch (_) {
      return '';
    }
  }

  // --- DIRECT SEARCH & NAVIGATION ---
  void _performSearchOrNavigate(String input) {
    final query = input.trim();
    if (query.isEmpty) return;

    SoundService().playClick();
    FocusScope.of(context).unfocus();

    String finalUrl;
    final bool isDirectUrl = query.startsWith('http://') ||
        query.startsWith('https://') ||
        (query.contains('.') && !query.contains(' ') && query.length > 3);

    if (isDirectUrl) {
      finalUrl = (query.startsWith('http://') || query.startsWith('https://'))
          ? query
          : 'https://$query';
    } else if (_isIncognitoMode) {
      // Real private zero-tracking search engine when Incognito is active!
      finalUrl = 'https://duckduckgo.com/?q=${Uri.encodeComponent(query)}';
    } else {
      finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    }

    setState(() {
      _hasLoadedFirstPage = true;
      _isLoading = true;
      _currentUrl = finalUrl;
      _lastSearchDisplay = query;
      _urlCtrl.text = query;
      _hasEditedUrl = false;
      _detectedMedia = [];
    });

    final headers = <String, String>{};
    if (_isIncognitoMode || _isVpnActive) {
      headers['DNT'] = '1';
      headers['Sec-GPC'] = '1';
    }

    _controller.loadRequest(Uri.parse(finalUrl), headers: headers);
  }

  /// Smart Back Handler: goes back in WebView history, or returns cleanly to Tooler landing
  Future<void> _handleBackNavigation() async {
    SoundService().playTap();
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      _updateNavigationState();
    } else {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _hasLoadedFirstPage = false;
        _isLoading = false;
        _currentUrl = '';
        _lastSearchDisplay = '';
        _urlCtrl.clear();
        _hasEditedUrl = false;
        _detectedMedia = [];
      });
    }
  }

  // --- REAL HARDENED INCOGNITO MODE TOGGLE ---
  // Disables native Chromium CookieManager persistence, blocks WebRTC/beacons,
  // switches search to DuckDuckGo Private, and wipes WebStorage + Disk Cache.
  Future<void> _toggleIncognitoMode(bool enabled) async {
    SoundService().playClick();
    HapticFeedback.lightImpact();

    await _purgeWebViewTracesSilent();
    try {
      await _privacyChannel.invokeMethod('setIncognitoHardening', {'enabled': enabled});
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isIncognitoMode = enabled;
    });

    if (_hasLoadedFirstPage && _currentUrl.isNotEmpty) {
      await _injectPrivacyAndAdBlockShields();
    }

    _showToast(
      enabled
          ? 'Real Incognito ON — cookies blocked natively, WebRTC shielded & DuckDuckGo active'
          : 'Incognito OFF — all cookies, storage & WebView caches wiped clean',
      color: enabled ? const Color(0xFF7C3AED) : widget.theme.primary,
      icon: enabled ? Icons.visibility_off_rounded : Icons.verified_user_rounded,
    );
  }

  // --- REAL VPN / PROXY TUNNEL CONNECT & DISCONNECT ---
  // Uses native Android androidx.webkit.ProxyController + GeoNode & ProxyScrape APIs
  // to route WebView traffic through a live HTTPS-verified relay node!
  Future<void> _connectRealVpn({
    String? customProxy,
    void Function(VoidCallback)? sheetSetState,
  }) async {
    if (_isVpnConnecting) return;
    SoundService().playClick();
    HapticFeedback.lightImpact();

    setState(() {
      _isVpnConnecting = true;
      _vpnErrorMsg = '';
    });
    sheetSetState?.call(() {});

    try {
      final raw = await _privacyChannel.invokeMethod('connectVpnProxy', {
        if (customProxy != null && customProxy.trim().isNotEmpty)
          'customProxy': customProxy.trim(),
      });
      if (!mounted) return;

      if (raw is Map && raw['connected'] == true) {
        final city = raw['city'] as String? ?? '';
        final country = raw['country'] as String? ?? 'Global Relay';
        setState(() {
          _isVpnConnecting = false;
          _isVpnActive = true;
          _vpnRoutedIp = raw['ip'] as String? ?? '';
          _vpnServerLabel = city.isNotEmpty ? '$city, $country' : country;
          _vpnProxyHostPort = '${raw['host']}:${raw['port']}';
          _vpnLatencyMs = (raw['latencyMs'] as num?)?.toInt() ?? 0;
          _vpnSourceApi = raw['sourceApi'] as String? ?? 'Live Proxy API';
          _vpnErrorMsg = '';
        });
        sheetSetState?.call(() {});
        SoundService().playSuccess();
        _showToast(
          'VPN Connected • $_vpnServerLabel ($_vpnRoutedIp · ${_vpnLatencyMs}ms)',
          color: const Color(0xFF10B981),
          icon: Icons.shield_rounded,
        );
      } else {
        final err = (raw is Map ? raw['error'] as String? : null) ??
            'No live relay node responded — tap Retry';
        setState(() {
          _isVpnConnecting = false;
          _isVpnActive = false;
          _vpnErrorMsg = err;
        });
        sheetSetState?.call(() {});
        _showToast(err, color: Colors.amber.shade800, icon: Icons.warning_amber_rounded);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVpnConnecting = false;
        _isVpnActive = false;
        _vpnErrorMsg = '$e';
      });
      sheetSetState?.call(() {});
    }
  }

  Future<void> _disconnectRealVpn({
    void Function(VoidCallback)? sheetSetState,
  }) async {
    SoundService().playClick();
    try {
      await _privacyChannel.invokeMethod('disconnectVpnProxy');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isVpnActive = false;
      _isVpnConnecting = false;
      _vpnRoutedIp = '';
      _vpnServerLabel = 'Not Connected';
      _vpnProxyHostPort = '';
      _vpnLatencyMs = 0;
      _vpnErrorMsg = '';
    });
    sheetSetState?.call(() {});
    _showToast(
      'VPN Disconnected • Direct connection restored',
      color: widget.theme.primary,
      icon: Icons.shield_outlined,
    );
  }

  // --- ZERO-HISTORY PURGE ENGINE ---
  Future<void> _clearAllBrowsingTraces() async {
    SoundService().playAlert();
    HapticFeedback.mediumImpact();
    await _purgeWebViewTracesSilent();

    if (mounted) {
      setState(() {
        _urlCtrl.clear();
        _currentUrl = '';
        _lastSearchDisplay = '';
        _detectedMedia.clear();
        _hasLoadedFirstPage = false;
        _hasEditedUrl = false;
      });
      _showToast(
        'All cookies, cache & browsing traces cleared!',
        color: const Color(0xFF10B981),
        icon: Icons.security_rounded,
      );
    }
  }

  void _toggleDesktopMode() {
    SoundService().playClick();
    setState(() => _isDesktopMode = !_isDesktopMode);
    _controller.setUserAgent(_activeUserAgent);
    if (_hasLoadedFirstPage && _currentUrl.isNotEmpty) {
      _controller.reload();
    }
  }

  /// Launches our native Android MediaStore downloader with WebView Cookies, Referer & User-Agent
  Future<void> _startNativeDownload(
    String fileUrl,
    String rawTitle,
    String type,
  ) async {
    SoundService().playClick();
    HapticFeedback.lightImpact();

    setState(() {
      _downloadProgress[fileUrl] = 0.02;
    });
    _activeModalSetState?.call(() {});

    final cookies = _hasLoadedFirstPage ? await _getPageCookies() : '';
    try {
      await _dlMethodChannel.invokeMethod('downloadMedia', {
        'url': fileUrl,
        'name': rawTitle.isNotEmpty ? rawTitle : _extractFilename(fileUrl),
        'type': type,
        'referer': _currentUrl,
        'userAgent': _activeUserAgent,
        'cookie': cookies,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(fileUrl));
        _activeModalSetState?.call(() {});
        _showToast('Download error: $e', color: const Color(0xFFF43F5E), icon: Icons.error_outline_rounded);
      }
    }
  }

  void _showToast(String msg, {required Color color, required IconData icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _guessTypeFromUrl(String url) {
    final l = url.toLowerCase();
    if (RegExp(r'\.(mp4|webm|mkv|mov|avi|m3u8|ts)(\?|$)').hasMatch(l)) return 'video';
    if (RegExp(r'\.(mp3|m4a|wav|ogg|aac|flac)(\?|$)').hasMatch(l)) return 'audio';
    if (RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp|avif|svg)(\?|$)').hasMatch(l)) return 'image';
    return 'file';
  }

  String _extractFilename(String url) {
    if (url.startsWith('data:')) {
      return 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    }
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last.trim();
        if (last.isNotEmpty) return last;
      }
    } catch (_) {}
    return 'tooler_media_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ===========================================================================
  // REAL BUILT-IN VPN / PROXY TUNNEL BOTTOM SHEET (ProxyController + Live APIs)
  // ===========================================================================
  void _showVpnStatusDialog() {
    SoundService().playClick();
    final customProxyCtrl = TextEditingController(text: _vpnProxyHostPort);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = widget.theme;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isVpnActive
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : (_isVpnConnecting
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.15)),
                                shape: BoxShape.circle,
                              ),
                              child: _isVpnConnecting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    )
                                  : Icon(
                                      _isVpnActive ? Icons.shield_rounded : Icons.shield_outlined,
                                      color: _isVpnActive ? const Color(0xFF10B981) : Colors.grey,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Proxy VPN Tunnel',
                                  style: theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _isVpnConnecting
                                      ? 'Verifying live HTTPS relays...'
                                      : (_isVpnActive
                                          ? 'WebView Traffic Routed'
                                          : 'Direct Connection (VPN Off)'),
                                  style: theme.fontMono(
                                    fontSize: 10.5,
                                    color: _isVpnActive
                                        ? const Color(0xFF10B981)
                                        : (_isVpnConnecting
                                            ? const Color(0xFFF59E0B)
                                            : theme.textSecondary),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _isVpnActive,
                          activeTrackColor: const Color(0xFF10B981),
                          onChanged: _isVpnConnecting
                              ? null
                              : (val) async {
                                  if (val) {
                                    await _connectRealVpn(sheetSetState: setDialogState);
                                  } else {
                                    await _disconnectRealVpn(sheetSetState: setDialogState);
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          _buildVpnMetricRow(
                            'Your Direct IP',
                            _directLocation.isNotEmpty ? '$_directIp ($_directLocation)' : _directIp,
                            Icons.router_rounded,
                          ),
                          const Divider(height: 14),
                          _buildVpnMetricRow(
                            'Routed VPN IP',
                            _isVpnActive && _vpnRoutedIp.isNotEmpty ? _vpnRoutedIp : 'Off (Direct)',
                            Icons.public_rounded,
                          ),
                          const Divider(height: 14),
                          _buildVpnMetricRow(
                            'Verified Relay',
                            _isVpnActive ? '$_vpnServerLabel (${_vpnLatencyMs}ms)' : 'Not Connected',
                            Icons.storage_rounded,
                          ),
                          const Divider(height: 14),
                          _buildVpnMetricRow(
                            'Engine & API',
                            _isVpnActive && _vpnSourceApi.isNotEmpty
                                ? 'ProxyController · $_vpnSourceApi'
                                : 'GeoNode + ProxyScrape APIs',
                            Icons.lock_outline_rounded,
                          ),
                        ],
                      ),
                    ),

                    if (_vpnErrorMsg.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _vpnErrorMsg,
                        style: theme.fontMono(fontSize: 10, color: const Color(0xFFF59E0B)),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Optional Custom Proxy Node input (host:port)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.dns_rounded, size: 16, color: theme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: customProxyCtrl,
                              style: theme.fontMono(fontSize: 11.5),
                              decoration: InputDecoration(
                                hintText: 'Optional custom proxy (ip:port)',
                                hintStyle: theme.fontMono(
                                  fontSize: 11,
                                  color: theme.textSecondary.withValues(alpha: 0.6),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _isVpnConnecting
                                ? null
                                : () {
                                    final hp = customProxyCtrl.text.trim();
                                    if (hp.contains(':')) {
                                      _connectRealVpn(
                                        customProxy: hp,
                                        sheetSetState: setDialogState,
                                      );
                                    }
                                  },
                            child: Text(
                              'USE',
                              style: theme.fontMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 17),
                              label: Text(
                                _isVpnActive ? 'Rotate Live Node' : 'Connect Auto Relay',
                                style: theme.fontDisplay(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _isVpnConnecting
                                  ? null
                                  : () => _connectRealVpn(sheetSetState: setDialogState),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.border, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _performSearchOrNavigate('https://ipwho.is/');
                            },
                            child: Text(
                              'Verify IP',
                              style: theme.fontMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: theme.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => customProxyCtrl.dispose());
  }

  // ===========================================================================
  // REAL 3-API AD & POPUP BLOCKER CONTROL SHEET
  // ===========================================================================
  void _showAdBlockSheet() {
    SoundService().playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = widget.theme;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (_isAdBlockActive ? const Color(0xFFF43F5E) : Colors.grey)
                                  .withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.gpp_good_rounded,
                              color: _isAdBlockActive ? const Color(0xFFF43F5E) : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ad & Popup Blocker',
                                style: theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$_adsBlockedCount ads/popups blocked · ${_adBlock.totalBlockedDomains} rules',
                                style: theme.fontMono(
                                  fontSize: 10.5,
                                  color: _isAdBlockActive
                                      ? const Color(0xFFF43F5E)
                                      : theme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAdBlockActive,
                        activeTrackColor: const Color(0xFFF43F5E),
                        onChanged: (val) {
                          SoundService().playClick();
                          setState(() => _isAdBlockActive = val);
                          setSheetState(() {});
                          if (_hasLoadedFirstPage && _currentUrl.isNotEmpty) {
                            _controller.reload();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _adBlock.feeds.length; i++) ...[
                          if (i > 0) const Divider(height: 14),
                          Row(
                            children: [
                              Icon(
                                _adBlock.feeds[i].synced
                                    ? Icons.check_circle_rounded
                                    : Icons.cloud_sync_rounded,
                                size: 17,
                                color: _adBlock.feeds[i].synced
                                    ? const Color(0xFF10B981)
                                    : theme.primary,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _adBlock.feeds[i].name,
                                      style: theme.fontDisplay(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _adBlock.feeds[i].shortUrl,
                                      style: theme.fontMono(
                                        fontSize: 9.5,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _adBlock.feeds[i].domainCount > 0
                                    ? '${_adBlock.feeds[i].domainCount}'
                                    : 'Cached',
                                style: theme.fontMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _adBlock.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        _adBlock.isSyncing
                            ? 'Syncing 3 AdBlock APIs...'
                            : 'Sync All 3 Filter APIs Now',
                        style: theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _adBlock.isSyncing
                          ? null
                          : () async {
                              SoundService().playTap();
                              setSheetState(() {});
                              final total = await _adBlock.syncAllApis();
                              if (mounted) {
                                setState(() {});
                                setSheetState(() {});
                                _showToast(
                                  'Synced 3 AdBlock APIs • $total ad & popup domains active!',
                                  color: const Color(0xFF10B981),
                                  icon: Icons.gpp_good_rounded,
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVpnMetricRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: widget.theme.primary),
            const SizedBox(width: 8),
            Text(label, style: widget.theme.fontDisplay(fontSize: 12, color: widget.theme.textSecondary)),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: widget.theme.fontMono(fontSize: 11.5, fontWeight: FontWeight.bold, color: widget.theme.text),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // THREE-DOT BROWSER MENU (ADBLOCK + REAL INCOGNITO + REAL VPN + TOOLS)
  // ===========================================================================
  void _showBrowserMenu() {
    SoundService().playClick();
    final isFullScreen = ToolerHoverSheet.isFullScreen(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = widget.theme;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Browser Menu', style: theme.fontDisplay(fontSize: 17, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          if (_isAdBlockActive)
                            Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'ADBLOCK',
                                style: theme.fontMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF43F5E),
                                ),
                              ),
                            ),
                          if (_isIncognitoMode)
                            Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'INCOGNITO',
                                style: theme.fontMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          if (_isVpnActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'VPN ON',
                                style: theme.fontMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. MULTI-API AD & POPUP BLOCKER (NEW!)
                  _buildMenuActionTile(
                    icon: Icons.gpp_good_rounded,
                    iconColor: _isAdBlockActive ? const Color(0xFFF43F5E) : Colors.grey,
                    title: 'Ad & Popup Blocker',
                    subtitle: _isAdBlockActive
                        ? '$_adsBlockedCount blocked • 3 Live Filter APIs (${_adBlock.totalBlockedDomains} rules)'
                        : 'Tap to block banner ads & popups',
                    trailing: Switch(
                      value: _isAdBlockActive,
                      activeTrackColor: const Color(0xFFF43F5E),
                      onChanged: (val) {
                        SoundService().playClick();
                        setState(() => _isAdBlockActive = val);
                        setSheetState(() {});
                        if (_hasLoadedFirstPage && _currentUrl.isNotEmpty) {
                          _controller.reload();
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAdBlockSheet();
                    },
                  ),

                  // 2. REAL HARDENED INCOGNITO MODE
                  _buildMenuActionTile(
                    customLeading: const _IncognitoVectorIcon(size: 22, color: Color(0xFF7C3AED)),
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Incognito Mode',
                    subtitle: _isIncognitoMode
                        ? 'Native cookies OFF • DuckDuckGo • Anti-WebRTC'
                        : 'Zero cookies, WebRTC shield & private search',
                    trailing: Switch(
                      value: _isIncognitoMode,
                      activeTrackColor: const Color(0xFF7C3AED),
                      onChanged: (val) async {
                        await _toggleIncognitoMode(val);
                        setSheetState(() {});
                      },
                    ),
                    onTap: () async {
                      await _toggleIncognitoMode(!_isIncognitoMode);
                      setSheetState(() {});
                    },
                  ),

                  // 3. REAL LIVE PROXY VPN TUNNEL
                  _buildMenuActionTile(
                    icon: _isVpnActive ? Icons.shield_rounded : Icons.shield_outlined,
                    iconColor: _isVpnActive ? const Color(0xFF10B981) : Colors.grey,
                    title: 'Built-in VPN',
                    subtitle: _isVpnConnecting
                        ? 'Finding verified HTTPS relay node...'
                        : (_isVpnActive
                            ? '$_vpnServerLabel ($_vpnRoutedIp · ${_vpnLatencyMs}ms)'
                            : 'Tap to tunnel traffic via live Proxy APIs'),
                    trailing: _isVpnConnecting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Switch(
                            value: _isVpnActive,
                            activeTrackColor: const Color(0xFF10B981),
                            onChanged: (val) async {
                              if (val) {
                                await _connectRealVpn(sheetSetState: setSheetState);
                              } else {
                                await _disconnectRealVpn(sheetSetState: setSheetState);
                              }
                            },
                          ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showVpnStatusDialog();
                    },
                  ),

                  // 4. FULLSCREEN TOGGLE
                  _buildMenuActionTile(
                    icon: isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                    iconColor: theme.primary,
                    title: isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                    subtitle: isFullScreen ? 'Return to hover sheet view' : 'Expand browser edge-to-edge',
                    onTap: () {
                      Navigator.pop(ctx);
                      ToolerHoverSheet.toggleFullScreen(context);
                    },
                  ),

                  // 5. DESKTOP MODE
                  _buildMenuActionTile(
                    icon: Icons.desktop_windows_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Desktop Site',
                    subtitle: _isDesktopMode ? 'Desktop layout active' : 'Request desktop version',
                    trailing: Switch(
                      value: _isDesktopMode,
                      activeTrackColor: const Color(0xFFF59E0B),
                      onChanged: (_) {
                        Navigator.pop(ctx);
                        _toggleDesktopMode();
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleDesktopMode();
                    },
                  ),

                  if (_hasLoadedFirstPage && _canGoForward)
                    _buildMenuActionTile(
                      icon: Icons.arrow_forward_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Forward',
                      subtitle: 'Go forward to next page',
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _controller.goForward();
                        _updateNavigationState();
                      },
                    ),

                  // 6. CLEAR ALL TRACES
                  _buildMenuActionTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: const Color(0xFFF43F5E),
                    title: 'Clear Browsing Data',
                    subtitle: 'Wipe cookies, cache & local storage now',
                    onTap: () {
                      Navigator.pop(ctx);
                      _clearAllBrowsingTraces();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuActionTile({
    IconData? icon,
    Widget? customLeading,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.1),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: customLeading ?? Icon(icon, color: iconColor, size: 20),
          ),
        ),
        title: Text(title, style: theme.fontDisplay(fontSize: 13.5, fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: theme.fontMono(fontSize: 10, color: theme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: theme.textSecondary),
        onTap: () {
          SoundService().playClick();
          onTap();
        },
      ),
    );
  }

  // ===========================================================================
  // UNIVERSAL SUPER-POWERED WEB DOWNLOADER MODAL SHEET
  // Shows everything downloadable on the page (Videos, Images, Audio, Files, Saved)
  // ===========================================================================
  Future<void> _showUniversalDownloaderModal() async {
    SoundService().playClick();
    if (_hasLoadedFirstPage) {
      await _sniffPageMedia();
    }
    if (!mounted) return;

    int selectedTab = 0; // 0=All, 1=Videos, 2=Images, 3=Audio, 4=Files, 5=Saved
    final directUrlCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            _activeModalSetState = setModalState;
            final theme = widget.theme;

            final videos = _detectedMedia.where((m) => m['type'] == 'video').toList();
            final images = _detectedMedia.where((m) => m['type'] == 'image').toList();
            final audios = _detectedMedia.where((m) => m['type'] == 'audio').toList();
            final files = _detectedMedia.where((m) => m['type'] == 'file').toList();

            final tabDefs = [
              ('All', _detectedMedia.length, theme.primary),
              ('Video', videos.length, const Color(0xFFF43F5E)),
              ('Image', images.length, const Color(0xFF10B981)),
              ('Audio', audios.length, const Color(0xFF8B5CF6)),
              ('Files', files.length, const Color(0xFF0EA5E9)),
              ('Saved', _downloadHistory.length, const Color(0xFFF59E0B)),
            ];

            final activeList = selectedTab == 0
                ? _detectedMedia
                : (selectedTab == 1
                    ? videos
                    : (selectedTab == 2
                        ? images
                        : (selectedTab == 3 ? audios : files)));

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.download_rounded, color: theme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Web Downloader',
                                style: theme.fontDisplay(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_detectedMedia.length} media assets detected on page',
                                style: theme.fontMono(fontSize: 10.5, color: theme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (_hasLoadedFirstPage)
                          IconButton(
                            icon: Icon(Icons.radar_rounded, color: theme.primary),
                            tooltip: 'Deep Re-Scan Page',
                            onPressed: () async {
                              SoundService().playTap();
                              await _sniffPageMedia();
                              setModalState(() {});
                            },
                          ),
                      ],
                    ),
                  ),

                  // Category Filter Strip
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: tabDefs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (_, i) {
                        final (label, count, color) = tabDefs[i];
                        final sel = selectedTab == i;
                        return GestureDetector(
                          onTap: () {
                            SoundService().playTap();
                            setModalState(() => selectedTab = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? color.withValues(alpha: 0.16) : theme.cardBg,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: sel ? color : theme.border,
                                width: sel ? 1.3 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: sel ? color : theme.text,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$count',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: sel ? color : theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Paste Any Direct URL Bar (Images, Videos, Audio, Docs, HLS .m3u8)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border, width: 1.1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, size: 17, color: theme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: directUrlCtrl,
                              style: theme.fontMono(fontSize: 11.5),
                              decoration: InputDecoration(
                                hintText: 'Paste any image, video, audio or file URL...',
                                hintStyle: theme.fontMono(
                                  fontSize: 11,
                                  color: theme.textSecondary.withValues(alpha: 0.65),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (val) {
                                final u = val.trim();
                                if (u.isNotEmpty) {
                                  directUrlCtrl.clear();
                                  _startNativeDownload(u, _extractFilename(u), _guessTypeFromUrl(u));
                                }
                              },
                            ),
                          ),
                          BouncyTap(
                            onTap: () {
                              final u = directUrlCtrl.text.trim();
                              if (u.isNotEmpty) {
                                directUrlCtrl.clear();
                                _startNativeDownload(u, _extractFilename(u), _guessTypeFromUrl(u));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.download_rounded, size: 16, color: theme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Content List
                  Expanded(
                    child: selectedTab == 5
                        ? _buildSavedDownloadsList(theme)
                        : activeList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cloud_download_outlined,
                                        size: 42,
                                        color: theme.textSecondary.withValues(alpha: 0.45),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _hasLoadedFirstPage
                                            ? 'No media found in this category yet'
                                            : 'Open any website to auto-detect all images, videos & audio',
                                        textAlign: TextAlign.center,
                                        style: theme.fontDisplay(fontSize: 13.5, color: theme.textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tip: Play a video briefly or scroll the page, then tap the radar icon to capture streams.',
                                        textAlign: TextAlign.center,
                                        style: theme.fontMono(fontSize: 10.5, color: theme.textSecondary.withValues(alpha: 0.75)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: activeList.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final item = activeList[index];
                                  return _buildDetectedMediaRow(item, theme);
                                },
                              ),
                  ),

                  if (selectedTab != 5 && activeList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          icon: const Icon(Icons.download_done_rounded, size: 19),
                          label: Text(
                            'Download All Shown (${activeList.length})',
                            style: theme.fontDisplay(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            for (final item in activeList.take(15)) {
                              _startNativeDownload(
                                item['url'] as String? ?? '',
                                item['title'] as String? ?? '',
                                item['type'] as String? ?? 'file',
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
    _activeModalSetState = null;
    directUrlCtrl.dispose();
  }

  Widget _buildDetectedMediaRow(Map<String, dynamic> item, StationeryTheme theme) {
    final type = item['type'] as String? ?? 'file';
    final url = item['url'] as String? ?? '';
    final title = item['title'] as String? ?? '';
    final meta = item['meta'] as String? ?? '';
    final isDownloading = _downloadProgress.containsKey(url);
    final progress = _downloadProgress[url];

    final Color badgeColor;
    final IconData typeIcon;
    switch (type) {
      case 'video':
        badgeColor = const Color(0xFFF43F5E);
        typeIcon = Icons.videocam_rounded;
        break;
      case 'audio':
        badgeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.audiotrack_rounded;
        break;
      case 'image':
        badgeColor = const Color(0xFF10B981);
        typeIcon = Icons.image_rounded;
        break;
      default:
        badgeColor = const Color(0xFF0EA5E9);
        typeIcon = Icons.insert_drive_file_rounded;
    }

    final isHttpImage = type == 'image' && (url.startsWith('http://') || url.startsWith('https://'));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.32)),
            ),
            child: isHttpImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      headers: {'Referer': _currentUrl, 'User-Agent': _activeUserAgent},
                      errorBuilder: (_, __, ___) => Icon(typeIcon, color: badgeColor, size: 22),
                    ),
                  )
                : Icon(typeIcon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: theme.fontMono(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Text(
                        meta,
                        style: theme.fontMono(fontSize: 9, color: theme.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title.isNotEmpty ? title : _extractFilename(url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.fontDisplay(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  url.startsWith('data:') ? 'Inline Base64 Media' : url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.fontMono(fontSize: 9.5, color: theme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDownloading)
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (progress ?? 0) > 0.03 ? progress : null,
                    strokeWidth: 2.8,
                    color: theme.primary,
                  ),
                  Text(
                    '${((progress ?? 0) * 100).toInt()}%',
                    style: theme.fontMono(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            BouncyTap(
              onTap: () => _startNativeDownload(url, title, type),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.download_rounded, color: theme.primary, size: 19),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedDownloadsList(StationeryTheme theme) {
    if (_downloadHistory.isEmpty) {
      return Center(
        child: Text(
          'No files downloaded in this session yet',
          style: theme.fontDisplay(fontSize: 13, color: theme.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _downloadHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, idx) {
        final item = _downloadHistory[idx];
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String? ?? 'File',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.fontDisplay(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item['size']} • ${item['path']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.fontMono(fontSize: 9.5, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isFullScreen = ToolerHoverSheet.isFullScreen(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: theme.mode),
          ),
          SafeArea(
            top: !isFullScreen,
            child: Column(
              children: [
                // 1. CONTEXTUAL TOP NAV BAR
                _buildTopNavBar(theme, isFullScreen),

                // 2. LIVE LOADING PROGRESS BAR
                if (_isLoading && _hasLoadedFirstPage)
                  LinearProgressIndicator(
                    value: _loadProgress > 0 ? _loadProgress : null,
                    minHeight: 2.5,
                    color: _isIncognitoMode ? const Color(0xFF7C3AED) : theme.primary,
                    backgroundColor: theme.border.withValues(alpha: 0.25),
                  ),

                // 3. MAIN VIEWPORT (Ultra-minimal Tooler Landing OR Live WebView)
                Expanded(
                  child: _hasLoadedFirstPage
                      ? Container(
                          margin: EdgeInsets.fromLTRB(
                            isFullScreen ? 4 : 12,
                            4,
                            isFullScreen ? 4 : 12,
                            isFullScreen ? 4 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isFullScreen ? 10 : 16),
                            border: Border.all(
                              color: _isIncognitoMode
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.45)
                                  : theme.border,
                              width: 1.3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isFullScreen ? 9 : 15),
                            child: WebViewWidget(controller: _controller),
                          ),
                        )
                      : _buildMinimalToolerLanding(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP NAV BAR
  // - NO VPN button, NO Fullscreen button
  // - Landing: clean right-aligned Download + 3-dot Menu
  // - Browsing: [Back ONLY] [Search Bar] [Search OR Refresh Icon] [Download] [3-dot Menu]
  // ===========================================================================
  Widget _buildTopNavBar(StationeryTheme theme, bool isFullScreen) {
    final activeAccent = _isIncognitoMode ? const Color(0xFF7C3AED) : theme.primary;

    // Minimal header when on the landing page (no duplicate search bar)
    if (!_hasLoadedFirstPage) {
      return Padding(
        padding: EdgeInsets.fromLTRB(isFullScreen ? 10 : 14, 6, isFullScreen ? 10 : 14, 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Download button (for direct URL download / saved history)
            _buildNavIconBox(
              theme: theme,
              badgeCount: _downloadHistory.length,
              badgeColor: const Color(0xFF10B981),
              icon: Icon(Icons.download_rounded, size: 19, color: theme.text),
              tooltip: 'Downloader',
              onTap: _showUniversalDownloaderModal,
            ),
            const SizedBox(width: 6),
            // Three-dot menu
            _buildNavIconBox(
              theme: theme,
              icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.text),
              tooltip: 'Menu',
              onTap: _showBrowserMenu,
            ),
          ],
        ),
      );
    }

    // Active Browsing Top Nav Bar:
    // [Back ONLY] [Search Bar] [Search icon if edited, else Refresh icon] [Download] [3-dot Menu]
    return Container(
      margin: EdgeInsets.fromLTRB(isFullScreen ? 8 : 12, 6, isFullScreen ? 8 : 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isIncognitoMode
              ? const Color(0xFF7C3AED).withValues(alpha: 0.45)
              : theme.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. BACK BUTTON ONLY
          BouncyTap(
            onTap: _handleBackNavigation,
            child: SizedBox(
              width: 36,
              height: 38,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: theme.text,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 2. SEARCH BAR (shows user's query / URL; hint: "Search")
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: _urlFocus.hasFocus
                      ? activeAccent.withValues(alpha: 0.7)
                      : theme.border,
                  width: 1.15,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      focusNode: _urlFocus,
                      style: theme.fontMono(fontSize: 12.5, fontWeight: FontWeight.w600),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: theme.fontMono(
                          fontSize: 12.5,
                          color: theme.textSecondary.withValues(alpha: 0.55),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onChanged: (val) {
                        final trimmed = val.trim();
                        final edited = trimmed.isNotEmpty &&
                            trimmed != _lastSearchDisplay &&
                            trimmed != _currentUrl;
                        if (edited != _hasEditedUrl) {
                          setState(() => _hasEditedUrl = edited);
                        } else {
                          setState(() {});
                        }
                      },
                      onTap: () {
                        setState(() {});
                      },
                      onSubmitted: _performSearchOrNavigate,
                    ),
                  ),
                  if (_urlFocus.hasFocus && _urlCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _urlCtrl.clear();
                        setState(() => _hasEditedUrl = false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.close_rounded, size: 16, color: theme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 3. SMART ACTION BUTTON:
          //    - If user typed something new -> SEARCH ICON (no "Go" word, no arrow!)
          //    - While browsing -> REFRESH ICON
          BouncyTap(
            onTap: () {
              if (_hasEditedUrl && _urlCtrl.text.trim().isNotEmpty) {
                _performSearchOrNavigate(_urlCtrl.text);
              } else {
                SoundService().playTap();
                _controller.reload();
              }
            },
            scaleFraction: 0.90,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _hasEditedUrl
                    ? activeAccent
                    : activeAccent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _hasEditedUrl ? Icons.search_rounded : Icons.refresh_rounded,
                  size: 19,
                  color: _hasEditedUrl ? Colors.white : activeAccent,
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // 4. UNIVERSAL DOWNLOAD BUTTON (with detected media count badge)
          _buildNavIconBox(
            theme: theme,
            badgeCount: _detectedMedia.length,
            badgeColor: activeAccent,
            highlighted: _detectedMedia.isNotEmpty,
            icon: Icon(
              Icons.download_rounded,
              size: 19,
              color: _detectedMedia.isNotEmpty ? activeAccent : theme.text,
            ),
            tooltip: 'Download Media',
            onTap: _showUniversalDownloaderModal,
          ),

          const SizedBox(width: 2),

          // 5. THREE-DOT MENU BUTTON
          BouncyTap(
            onTap: _showBrowserMenu,
            child: SizedBox(
              width: 34,
              height: 38,
              child: Center(
                child: Icon(Icons.more_vert_rounded, size: 20, color: theme.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIconBox({
    required StationeryTheme theme,
    required Widget icon,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
    Color? badgeColor,
    bool highlighted = false,
  }) {
    final color = badgeColor ?? theme.primary;
    return Tooltip(
      message: tooltip,
      child: BouncyTap(
        onTap: onTap,
        scaleFraction: 0.90,
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text(
            badgeCount > 99 ? '99+' : '$badgeCount',
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          backgroundColor: color,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: highlighted ? color.withValues(alpha: 0.13) : theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted ? color.withValues(alpha: 0.45) : theme.border,
                width: 1.1,
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ULTRA-MINIMAL TOOLER BROWSER LANDING
  // Strictly:
  //   1. Tooler Logo
  //   2. "Browser" word right below it
  //   3. Search Bar (hint: "Search" + Search Icon button — no Go/arrow)
  //   4. Below search bar to the side: VPN icon (if ON) & Incognito icon (if ON)
  //   NOTHING ELSE!
  // ===========================================================================
  Widget _buildMinimalToolerLanding(StationeryTheme theme) {
    final activeAccent = _isIncognitoMode ? const Color(0xFF7C3AED) : theme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Tooler Live Animated Wordmark Logo
            ToolerLogo(
              height: 44,
              color: theme.text,
              accentColor: activeAccent,
              interactive: true,
            ),

            const SizedBox(height: 4),

            // 2. Clean subtle "Browser" label right under the logo
            Text(
              'Browser',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: theme.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // 3. Minimal Search Bar (Hint ONLY "Search" + Search Icon button)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 5, 5, 5),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isIncognitoMode
                      ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                      : theme.border,
                  width: 1.35,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.isDark ? 0.18 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: _performSearchOrNavigate,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Search Icon Button (NO "Go" text, NO arrow!)
                  BouncyTap(
                    onTap: () => _performSearchOrNavigate(_urlCtrl.text),
                    scaleFraction: 0.90,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: activeAccent,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: activeAccent.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Below Search Bar to the Side: AdBlock, VPN & Incognito icons (only when ON)
            if (_isAdBlockActive || _isVpnActive || _isIncognitoMode) ...[
              const SizedBox(height: 11),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAdBlockActive)
                        Tooltip(
                          message: 'Ad & Popup Blocker Active',
                          child: BouncyTap(
                            onTap: _showAdBlockSheet,
                            child: Container(
                              width: 30,
                              height: 30,
                              margin: EdgeInsets.only(right: (_isVpnActive || _isIncognitoMode) ? 8 : 0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.13),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.gpp_good_rounded,
                                  size: 16,
                                  color: Color(0xFFF43F5E),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isVpnActive)
                        Tooltip(
                          message: 'Live VPN Active ($_vpnRoutedIp)',
                          child: BouncyTap(
                            onTap: _showVpnStatusDialog,
                            child: Container(
                              width: 30,
                              height: 30,
                              margin: EdgeInsets.only(right: _isIncognitoMode ? 8 : 0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.13),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isIncognitoMode)
                        Tooltip(
                          message: 'Incognito Active',
                          child: BouncyTap(
                            onTap: () => _toggleIncognitoMode(false),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                  width: 1.0,
                                ),
                              ),
                              child: const Center(
                                child: _IncognitoVectorIcon(
                                  size: 17,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // 5. Vector SVG Character — Ergonomic Chair & Tablet (Thinking)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ToolerCharacter.thinking(
                theme: theme,
                width: 240,
                height: 212,
                animate: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crisp, minimal vector Incognito icon (classic hat + brim + twin spectacles).
class _IncognitoVectorIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _IncognitoVectorIcon({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IncognitoIconPainter(color: color),
      ),
    );
  }
}

class _IncognitoIconPainter extends CustomPainter {
  final Color color;
  _IncognitoIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.095).clamp(1.3, 2.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hat crown
    final crown = Path()
      ..moveTo(w * 0.24, h * 0.44)
      ..lineTo(w * 0.34, h * 0.17)
      ..quadraticBezierTo(w * 0.50, h * 0.11, w * 0.66, h * 0.17)
      ..lineTo(w * 0.76, h * 0.44)
      ..close();
    canvas.drawPath(crown, fill);

    // Hat brim
    canvas.drawLine(
      Offset(w * 0.10, h * 0.46),
      Offset(w * 0.90, h * 0.46),
      stroke,
    );

    // Twin incognito glasses circles + bridge
    final r = w * 0.145;
    canvas.drawCircle(Offset(w * 0.31, h * 0.72), r, stroke);
    canvas.drawCircle(Offset(w * 0.69, h * 0.72), r, stroke);
    canvas.drawLine(
      Offset(w * 0.455, h * 0.72),
      Offset(w * 0.545, h * 0.72),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _IncognitoIconPainter old) => old.color != color;
}
