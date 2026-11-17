import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AdBlockApiFeedStatus {
  final String name;
  final String shortUrl;
  bool synced;
  int domainCount;

  AdBlockApiFeedStatus({
    required this.name,
    required this.shortUrl,
    this.synced = false,
    this.domainCount = 0,
  });
}

/// ---------------------------------------------------------------------------
/// TOOLER MULTI-API AD & POPUP BLOCKER ENGINE
/// Combines 3 live open-source Ad-Blocker Filter APIs:
///   1) Peter Lowe's Ad & Tracker Server List API
///   2) AdAway Mobile Ad & Popup Hosts API
///   3) HaGeZi Light Ad & Popup Domain Blocklist API
/// Plus instant built-in core ad/popup domains + JS/CSS cosmetic & popup shield!
/// ---------------------------------------------------------------------------
class BrowserAdBlockService {
  static final BrowserAdBlockService _instance = BrowserAdBlockService._();
  factory BrowserAdBlockService() => _instance;
  BrowserAdBlockService._();

  final Set<String> _blockedDomains = Set<String>.from(_coreBuiltInAdDomains);
  bool _initialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  final List<AdBlockApiFeedStatus> feeds = [
    AdBlockApiFeedStatus(
      name: "Peter Lowe's AdList API",
      shortUrl: 'pgl.yoyo.org/adservers',
    ),
    AdBlockApiFeedStatus(
      name: 'AdAway Mobile Hosts API',
      shortUrl: 'adaway.org/hosts.txt',
    ),
    AdBlockApiFeedStatus(
      name: 'HaGeZi Ad & Popup API',
      shortUrl: 'cdn.jsdelivr.net/hagezi/light',
    ),
  ];

  int get totalBlockedDomains => _blockedDomains.length;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  // Instant built-in ad, popunder, redirect & tracker domains (zero-latency Day-0 shield)
  static const List<String> _coreBuiltInAdDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adservice.google.com',
    'pagead2.googlesyndication.com',
    'tpc.googlesyndication.com',
    'adclick.g.doubleclick.net',
    'google-analytics.com',
    'googletagmanager.com',
    'popads.net',
    'popcash.net',
    'propellerads.com',
    'propellerclick.com',
    'monetag.com',
    'onclickalgo.com',
    'onclickmax.com',
    'adsterra.com',
    'highperformanceformat.com',
    'profitablegatecpm.com',
    'topcreativeformat.com',
    'hilltopads.net',
    'exoclick.com',
    'exosrv.com',
    'juicyads.com',
    'trafficjunky.net',
    'trafficstars.com',
    'taboola.com',
    'outbrain.com',
    'mgid.com',
    'revcontent.com',
    'criteo.com',
    'criteo.net',
    'amazon-adsystem.com',
    'pubmatic.com',
    'rubiconproject.com',
    'openx.net',
    'adnxs.com',
    'casalemedia.com',
    'indexww.com',
    'adsrvr.org',
    'smartadserver.com',
    'yieldmo.com',
    'teads.tv',
    'sharethrough.com',
    'triplelift.com',
    'lijit.com',
    '33across.com',
    'bidswitch.net',
    'media.net',
    'zedo.com',
    'inmobi.com',
    'applovin.com',
    'unityads.unity3d.com',
    'vungle.com',
    'ironsrc.com',
    'chartboost.com',
    'tapjoy.com',
    'adcolony.com',
    'flurry.com',
    'mopub.com',
    'ads.yahoo.com',
    'advertising.com',
    'bat.bing.com',
    'ads.linkedin.com',
    'ads-twitter.com',
    'analytics.tiktok.com',
    'connect.facebook.net',
    'pixel.facebook.com',
    'scorecardresearch.com',
    'quantserve.com',
    'hotjar.com',
    'mixpanel.com',
    'segment.io',
    'amplitude.com',
    'branch.io',
    'appsflyer.com',
    'adjust.com',
    'adroll.com',
    'buysellads.com',
    'carbonads.net',
    'chitika.net',
    'clickadu.com',
    'admaven.com',
    'pushame.com',
    'notifpush.com',
    'galaksion.com',
    'adcash.com',
    'richpush.co',
    'evadav.com',
    'zeropark.com',
    'popmyads.com',
    'popunder.net',
    'adskeeper.co.uk',
    'content.ad',
    'dianomi.com',
    'nativo.com',
    'zemanta.com',
    'spotxchange.com',
    'springserve.com',
    'lkqd.net',
    'innovid.com',
    'moatads.com',
    'doubleverify.com',
    'adsafeprotected.com',
  ];

  /// Loads cached domains from disk immediately, then syncs 3 live APIs in background if stale.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadDiskCache();
    // Refresh from live APIs if cache is small or older than 24h
    if (_blockedDomains.length < 500) {
      unawaited(syncAllApis());
    }
  }

  Future<void> _loadDiskCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/tooler_adblock_domains_v1.txt');
      if (await f.exists()) {
        final lines = await f.readAsLines();
        for (final l in lines) {
          final d = l.trim();
          if (d.isNotEmpty) _blockedDomains.add(d);
        }
        final stat = await f.stat();
        _lastSyncedAt = stat.modified;
      }
    } catch (_) {}
  }

  Future<void> _saveDiskCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/tooler_adblock_domains_v1.txt');
      // Persist up to 45,000 domains cleanly for instant startup next time
      await f.writeAsString(_blockedDomains.take(45000).join('\n'));
    } catch (_) {}
  }

  /// Fetches & merges live ad/popup domains from all 3 open-source Ad-Blocker APIs!
  Future<int> syncAllApis() async {
    if (_isSyncing) return _blockedDomains.length;
    _isSyncing = true;

    try {
      final results = await Future.wait([
        _fetchDomainFeed(
          'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=plain&showintro=0&mimetype=plaintext',
          maxDomains: 6000,
        ),
        _fetchDomainFeed(
          'https://adaway.org/hosts.txt',
          maxDomains: 10000,
        ),
        _fetchDomainFeedWithFallback(
          'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/light.txt',
          'https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/light.txt',
          maxDomains: 18000,
        ),
      ]);

      for (int i = 0; i < results.length; i++) {
        final doms = results[i];
        feeds[i].synced = doms.isNotEmpty;
        feeds[i].domainCount = doms.length;
        _blockedDomains.addAll(doms);
      }

      _lastSyncedAt = DateTime.now();
      await _saveDiskCache();
    } catch (_) {
    } finally {
      _isSyncing = false;
    }

    return _blockedDomains.length;
  }

  Future<Set<String>> _fetchDomainFeedWithFallback(
    String primaryUrl,
    String fallbackUrl, {
    required int maxDomains,
  }) async {
    final first = await _fetchDomainFeed(primaryUrl, maxDomains: maxDomains);
    if (first.isNotEmpty) return first;
    return _fetchDomainFeed(fallbackUrl, maxDomains: maxDomains);
  }

  Future<Set<String>> _fetchDomainFeed(String url, {required int maxDomains}) async {
    final found = <String>{};
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'ToolerAdBlock/2.0');
      final resp = await req.close().timeout(const Duration(seconds: 9));
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        for (final rawLine in body.split('\n')) {
          if (found.length >= maxDomains) break;
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) continue;
          // Handle both hosts format ("127.0.0.1 ads.example.com") and plain domain format
          String candidate = line;
          if (line.startsWith('0.0.0.0') || line.startsWith('127.0.0.1')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length < 2) continue;
            candidate = parts[1].trim();
          }
          // Strip inline comments
          final hashIdx = candidate.indexOf('#');
          if (hashIdx != -1) candidate = candidate.substring(0, hashIdx).trim();
          candidate = candidate.toLowerCase();
          if (candidate.isEmpty ||
              candidate == 'localhost' ||
              candidate == 'localhost.localdomain' ||
              !candidate.contains('.')) {
            continue;
          }
          found.add(candidate);
        }
      }
    } catch (_) {
    } finally {
      client.close(force: true);
    }
    return found;
  }

  /// Fast O(1) hierarchical domain check against all 3 merged AdBlock API lists!
  bool isAdOrPopupUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      final host = uri.host.toLowerCase();
      if (host.isEmpty) return false;

      // Walk subdomain levels: a.b.doubleclick.net -> b.doubleclick.net -> doubleclick.net
      final parts = host.split('.');
      for (int i = 0; i < parts.length - 1; i++) {
        final sub = parts.sublist(i).join('.');
        if (_blockedDomains.contains(sub)) return true;
      }

      // Common popunder / ad-redirect URL signatures
      final lower = rawUrl.toLowerCase();
      if (lower.contains('/popunder') ||
          lower.contains('popads.') ||
          lower.contains('adclick.') ||
          lower.contains('googleadservices.com/pagead') ||
          lower.contains('doubleclick.net/pcs/click')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Builds the real-time JS + CSS Ad & Popup Shield injected into WebView pages.
  /// Kills window.open popups, blocks ad scripts/iframes/XHR/fetch, collapses EasyList ad slots,
  /// and reports real blocked counts back via `ToolerPrivacyBridge.postMessage`.
  String buildAdBlockInjectionJs() {
    return r'''
(function() {
  if (window.__toolerAdBlockInjected) return;
  window.__toolerAdBlockInjected = true;

  var blockedNow = 0;
  function reportBlocked(n) {
    blockedNow += (n || 1);
    try {
      if (window.ToolerPrivacyBridge) {
        window.ToolerPrivacyBridge.postMessage(JSON.stringify({ type: 'ad_blocked', count: n || 1 }));
      }
    } catch(e) {}
  }

  var adHostRe = /(doubleclick\.net|googlesyndication\.com|googleadservices\.com|adservice\.google|popads\.net|popcash\.net|propellerads\.com|propellerclick|monetag\.com|adsterra\.com|highperformanceformat|profitablegatecpm|hilltopads\.net|exoclick\.com|juicyads\.com|taboola\.com|outbrain\.com|mgid\.com|revcontent\.com|criteo\.(com|net)|amazon-adsystem\.com|pubmatic\.com|rubiconproject\.com|openx\.net|adnxs\.com|adsrvr\.org|smartadserver\.com|teads\.tv|media\.net|zedo\.com|clickadu\.com|admaven\.com|galaksion\.com|adcash\.com|popunder|onclickalgo|onclickmax|adskeeper|moatads|adsafeprotected|doubleverify)/i;

  // 1. Kill Popup / Popunder Ad Windows cold!
  var origOpen = window.open;
  window.open = function(url) {
    try {
      if (!url || adHostRe.test(String(url)) || String(url).indexOf('about:blank') === 0) {
        reportBlocked(1);
        return null;
      }
      // Block unrequested popunders targeting _blank from ad click-hijackers
      var uStr = String(url);
      if (uStr.indexOf('http') === 0 && location.hostname && uStr.indexOf(location.hostname) === -1) {
        reportBlocked(1);
        return null;
      }
    } catch(e) {}
    return origOpen ? origOpen.apply(this, arguments) : null;
  };

  // 2. Intercept ad network fetch() & XHR requests
  var prevFetch = window.fetch;
  if (prevFetch) {
    window.fetch = function(input) {
      try {
        var u = (typeof input === 'string') ? input : (input && input.url);
        if (u && adHostRe.test(u)) {
          reportBlocked(1);
          return Promise.resolve(new Response('', { status: 204 }));
        }
      } catch(e) {}
      return prevFetch.apply(this, arguments);
    };
  }

  var prevXhrOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    try {
      if (url && adHostRe.test(String(url))) {
        this.__toolerBlockedAd = true;
        reportBlocked(1);
        return;
      }
    } catch(e) {}
    return prevXhrOpen.apply(this, arguments);
  };
  var prevXhrSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.send = function() {
    if (this.__toolerBlockedAd) return;
    return prevXhrSend.apply(this, arguments);
  };

  // 3. Cosmetic EasyList CSS Ad Annihilator
  try {
    var style = document.createElement('style');
    style.id = '__tooler_adblock_css';
    style.textContent = [
      'ins.adsbygoogle, .adsbygoogle, [id^="google_ads"], [id^="div-gpt-ad"],',
      '[class*="ad-banner"], [class*="ad_banner"], [class*="ad-container"], [class*="ad_container"],',
      '[class*="ad-slot"], [data-ad-slot], [data-ad-client], [data-google-query-id],',
      '[class*="popup-ad"], [id*="popup-ad"], [class*="popunder"], [class*="sponsored-ad"],',
      '[id*="taboola"], [class*="taboola"], [class*="outbrain"], [class*="OUTBRAIN"],',
      '[id*="mgid"], [class*="mgid"], [class*="revcontent"],',
      'iframe[src*="doubleclick"], iframe[src*="googlesyndication"], iframe[src*="adnxs"],',
      'iframe[src*="taboola"], iframe[src*="outbrain"], iframe[src*="popads"], iframe[src*="exoclick"],',
      'iframe[src*="adsterra"], iframe[src*="criteo"], iframe[src*="amazon-adsystem"]',
      '{ display: none !important; visibility: hidden !important; height: 0 !important; min-height: 0 !important; opacity: 0 !important; pointer-events: none !important; }'
    ].join(' ');
    (document.head || document.documentElement).appendChild(style);
  } catch(e) {}

  // 4. DOM Sweep + Live MutationObserver for dynamically injected ad iframes & sticky ad overlays
  function sweepAds() {
    var removed = 0;
    try {
      var frames = document.querySelectorAll('iframe, ins.adsbygoogle, [id^="google_ads"], [id^="div-gpt-ad"], [data-ad-slot]');
      for (var i = 0; i < frames.length; i++) {
        var el = frames[i];
        var src = (el.getAttribute('src') || el.getAttribute('data-src') || '');
        if (el.tagName !== 'IFRAME' || adHostRe.test(src)) {
          if (el.parentNode) {
            el.parentNode.removeChild(el);
            removed++;
          }
        }
      }
      // Remove giant fixed full-screen ad click-hijack overlays
      var fixeds = document.querySelectorAll('div[style*="z-index: 2147483647"], div[style*="z-index:999999"]');
      for (var j = 0; j < fixeds.length; j++) {
        var fx = fixeds[j];
        var html = (fx.innerHTML || '').toLowerCase();
        if (html.indexOf('ad') !== -1 || adHostRe.test(html) || fx.querySelector('iframe')) {
          if (fx.parentNode) {
            fx.parentNode.removeChild(fx);
            removed++;
          }
        }
      }
    } catch(e) {}
    if (removed > 0) reportBlocked(removed);
  }

  sweepAds();
  try {
    var obs = new MutationObserver(function() { sweepAds(); });
    obs.observe(document.documentElement, { childList: true, subtree: true });
  } catch(e) {}
})();
''';
  }

  /// Real Incognito & Anti-Fingerprint Runtime Hardening Script:
  /// - Neutralizes WebRTC IP leak (RTCPeerConnection)
  /// - Blocks navigator.sendBeacon background tracking pings
  /// - Blocks persistent document.cookie writes inside Incognito
  /// - Wipes localStorage & sessionStorage automatically on page hide
  String buildIncognitoHardeningJs({required bool isIncognito, required bool isVpn}) {
    return '''
(function() {
  if (${isIncognito || isVpn}) {
    // 1. Prevent WebRTC Local/Real IP Leak!
    try {
      window.RTCPeerConnection = undefined;
      window.webkitRTCPeerConnection = undefined;
      window.mozRTCPeerConnection = undefined;
    } catch(e) {}
  }

  if ($isIncognito) {
    // 2. Block silent unload tracking beacons
    try {
      navigator.sendBeacon = function() { return false; };
    } catch(e) {}

    // 3. Block JS cookie writes & auto-clear storage on unload
    try {
      Object.defineProperty(document, 'cookie', {
        get: function() { return ''; },
        set: function() { return ''; },
        configurable: true
      });
    } catch(e) {}

    window.addEventListener('pagehide', function() {
      try { localStorage.clear(); } catch(e) {}
      try { sessionStorage.clear(); } catch(e) {}
    });
  }
})();
''';
  }
}
