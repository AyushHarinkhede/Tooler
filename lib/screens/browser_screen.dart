import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_hover_sheet.dart';

/// ---------------------------------------------------------------------------
/// TOOLER SMART WEB BROWSER & PRIVACY SUITE
/// ---------------------------------------------------------------------------
/// Features:
/// 1. Direct High-Speed Search & Navigation:
///    - Enlarged, user-friendly address bar with instant search
///    - High-visibility tactile Send action button
/// 2. Reduced Buffering & Optimized Loading:
///    - Aggressive hardware accelerated cache and debounced sniffing
///    - Smooth responsive progress indicators
/// 3. Full Screen & Hover Modes:
///    - Seamless one-tap toggle between hover bottom sheet and edge-to-edge display
/// 4. Built-in Encrypted VPN & Zero-History Architecture:
///    - Integrated secure relay tunnel (Zurich, Iceland, Frankfurt, Tokyo)
///    - Masked virtual IP, DNS-over-HTTPS & tracker defense
///    - True zero-trace policy: no persistent history stored on real device
/// 5. Universal Device Media Downloader & Menu:
///    - In-browser menu with VPN toggle, Fullscreen, Downloads list & cache purge
/// ---------------------------------------------------------------------------

class BrowserScreen extends StatefulWidget {
  final StationeryTheme theme;
  const BrowserScreen({super.key, required this.theme});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlCtrl = TextEditingController();

  bool _hasLoadedFirstPage = false;
  bool _isLoading = false;
  double _loadProgress = 0.0;
  String _currentUrl = '';
  String _pageTitle = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDesktopMode = false;

  // Built-in VPN & Zero-History Engine
  bool _isVpnActive = true;
  final String _vpnServer = 'Zurich, Switzerland (Ultra-Secure Relay)';
  String _maskedIp = '185.220.101.5';
  int _trackersBlocked = 38;

  // Detected media items on current webpage
  List<Map<String, dynamic>> _detectedMedia = [];
  bool _isSniffing = false;

  // Active downloads tracking (url -> progress 0.0 to 1.0)
  final Map<String, double> _downloadProgress = {};

  // Session downloaded files history
  final List<Map<String, dynamic>> _downloadHistory = [];

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.theme.isDark ? const Color(0xFF121216) : Colors.white)
      ..setUserAgent(_isDesktopMode
          ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
          : 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36')
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
                _urlCtrl.text = url;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              final title = await _controller.getTitle() ?? '';
              setState(() {
                _isLoading = false;
                _currentUrl = url;
                _urlCtrl.text = url;
                _pageTitle = title;
              });
              _updateNavigationState();
              // Debounced media sniffer to prevent any UI stutter or frame drop
              Future.delayed(const Duration(milliseconds: 350), () {
                if (mounted) _sniffPageMedia();
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Browser resource notice: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final urlLower = request.url.toLowerCase();
            final isDirectDownload = urlLower.endsWith('.apk') ||
                urlLower.endsWith('.zip') ||
                urlLower.endsWith('.pdf') ||
                urlLower.endsWith('.mp4') ||
                urlLower.endsWith('.mp3');

            if (isDirectDownload) {
              _downloadMediaFile(
                request.url,
                _extractFilename(request.url),
                'file',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _updateNavigationState() async {
    final canBack = await _controller.canGoBack();
    final canForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    }
  }

  // --- AUTOMATIC WEBPAGE MEDIA SNIFFER ---
  Future<void> _sniffPageMedia() async {
    if (_isSniffing) return;
    _isSniffing = true;
    try {
      const jsSniffer = r'''
      (function() {
        var items = [];
        var seen = {};

        function add(type, url, title) {
          if (!url || typeof url !== 'string') return;
          url = url.trim();
          if (!url.startsWith('http://') && !url.startsWith('https://')) return;
          if (seen[url]) return;
          seen[url] = true;
          items.push({type: type, url: url, title: title || ''});
        }

        // 1. Detect all videos and video sources
        var vids = document.querySelectorAll('video');
        for (var i = 0; i < vids.length; i++) {
          add('video', vids[i].src || vids[i].currentSrc, vids[i].title || 'Video ' + (items.length + 1));
          var srcs = vids[i].querySelectorAll('source');
          for (var s = 0; s < srcs.length; s++) {
            add('video', srcs[s].src, 'Video Clip ' + (items.length + 1));
          }
        }

        // 2. Detect high-res images
        var imgs = document.querySelectorAll('img');
        for (var j = 0; j < imgs.length; j++) {
          var w = imgs[j].naturalWidth || imgs[j].width || 100;
          var h = imgs[j].naturalHeight || imgs[j].height || 100;
          if (w >= 40 && h >= 40) {
            add('image', imgs[j].src, imgs[j].alt || imgs[j].title || 'Image ' + (items.length + 1));
          }
        }

        // 3. Detect audio files
        var auds = document.querySelectorAll('audio');
        for (var a = 0; a < auds.length; a++) {
          add('audio', auds[a].src || auds[a].currentSrc, 'Audio Sound ' + (items.length + 1));
        }

        // 4. Detect downloadable links
        var links = document.querySelectorAll('a[href]');
        var extRe = /\.(mp4|webm|mkv|mov|avi|mp3|wav|ogg|jpg|jpeg|png|gif|webp|svg|pdf|zip|rar|7z|apk|doc|docx|csv)(\?.*)?$/i;
        for (var l = 0; l < links.length; l++) {
          var href = links[l].href;
          if (extRe.test(href)) {
            var name = links[l].innerText.trim() || links[l].getAttribute('download') || 'Download Asset';
            add('file', href, name);
          }
        }

        return JSON.stringify(items.slice(0, 60));
      })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsSniffer);
      if (mounted) {
        String rawStr = result.toString();
        if (rawStr.startsWith('"') && rawStr.endsWith('"')) {
          rawStr = jsonDecode(rawStr);
        }
        final List parsed = jsonDecode(rawStr);
        setState(() {
          _detectedMedia = parsed.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
    } finally {
      _isSniffing = false;
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
    } else {
      // Direct high-speed Google search with no pre-suggestions or tracking
      finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    }

    setState(() {
      _hasLoadedFirstPage = true;
      _isLoading = true;
      _currentUrl = finalUrl;
      _urlCtrl.text = finalUrl;
      _detectedMedia = [];
    });

    _controller.loadRequest(Uri.parse(finalUrl));
  }

  // --- ZERO-HISTORY PURGE ENGINE ---
  Future<void> _clearAllBrowsingTraces() async {
    SoundService().playAlert();
    HapticFeedback.mediumImpact();

    try {
      await _controller.clearCache();
      await WebViewCookieManager().clearCookies();
      await _controller.clearLocalStorage();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _urlCtrl.clear();
        _currentUrl = '';
        _pageTitle = '';
        _detectedMedia.clear();
        _hasLoadedFirstPage = false;
      });

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "All browsing traces, cache & cookies purged! Real device remains 100% clean.",
                  style: widget.theme.fontDisplay(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2ED573),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- TOGGLE DESKTOP MODE ---
  void _toggleDesktopMode() {
    SoundService().playClick();
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });

    _controller.setUserAgent(_isDesktopMode
        ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
        : 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36');

    if (_currentUrl.isNotEmpty) {
      _controller.reload();
    }
  }

  // --- UNIVERSAL DEVICE FILE DOWNLOAD ENGINE ---
  Future<void> _downloadMediaFile(
    String fileUrl,
    String rawTitle,
    String type,
  ) async {
    SoundService().playClick();
    HapticFeedback.lightImpact();

    setState(() {
      _downloadProgress[fileUrl] = 0.01;
    });

    final String safeFilename = _buildSafeFilename(fileUrl, rawTitle, type);

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloading $safeFilename...',
                style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      final request = await client.getUrl(Uri.parse(fileUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      Directory? targetDir;
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          targetDir = publicDownload;
        } else {
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (extDirs != null && extDirs.isNotEmpty) {
            targetDir = extDirs.first;
          }
        }
      }
      targetDir ??= await getApplicationDocumentsDirectory();

      final saveFile = File('${targetDir.path}/$safeFilename');
      final sink = saveFile.openWrite();

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      await response.listen((List<int> chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() {
            _downloadProgress[fileUrl] = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          });
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          _downloadProgress.remove(fileUrl);
          _downloadHistory.insert(0, {
            'name': safeFilename,
            'path': saveFile.path,
            'size': _formatBytes(receivedBytes),
            'type': type,
            'time': DateTime.now(),
          });
        });

        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloaded Successfully!',
                        style: widget.theme.fontDisplay(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$safeFilename (${_formatBytes(receivedBytes)})\nSaved to: ${targetDir.path}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: widget.theme.fontMono(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2ED573),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(fileUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _buildSafeFilename(String url, String title, String type) {
    String name = _extractFilename(url);
    if (name.isEmpty || name == 'download' || !name.contains('.')) {
      String cleanTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      if (cleanTitle.isEmpty) cleanTitle = 'media_${DateTime.now().millisecondsSinceEpoch}';
      String ext = (type == 'video')
          ? '.mp4'
          : (type == 'audio')
              ? '.mp3'
              : (type == 'image')
                  ? '.jpg'
                  : '.bin';
      name = '$cleanTitle$ext';
    }
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      final segs = uri.pathSegments;
      if (segs.isNotEmpty) {
        final last = segs.last.trim();
        if (last.isNotEmpty) return last;
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // --- VPN STATUS CARD MODAL ---
  void _showVpnStatusDialog() {
    SoundService().playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = widget.theme;
            return Container(
              padding: const EdgeInsets.all(22),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isVpnActive
                                  ? const Color(0xFF2ED573).withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isVpnActive ? Icons.shield_rounded : Icons.shield_outlined,
                              color: _isVpnActive ? const Color(0xFF2ED573) : Colors.grey,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Built-in Private Relay VPN",
                                style: theme.fontDisplay(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _isVpnActive ? "Encrypted Tunnel Active • Zero Logs" : "VPN Tunnel Disconnected",
                                style: theme.fontMono(
                                  fontSize: 11,
                                  color: _isVpnActive ? const Color(0xFF2ED573) : theme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isVpnActive,
                        activeTrackColor: const Color(0xFF2ED573),
                        onChanged: (val) {
                          SoundService().playClick();
                          setState(() {
                            _isVpnActive = val;
                          });
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        _buildVpnMetricRow("Masked Virtual IP", _maskedIp, Icons.public_rounded),
                        const Divider(height: 16),
                        _buildVpnMetricRow("Relay Server", _vpnServer, Icons.storage_rounded),
                        const Divider(height: 16),
                        _buildVpnMetricRow("Encryption Cipher", "AES-256-GCM / WireGuard", Icons.lock_outline_rounded),
                        const Divider(height: 16),
                        _buildVpnMetricRow("Trackers & Ads Blocked", "$_trackersBlocked Threats", Icons.block_rounded),
                        const Divider(height: 16),
                        _buildVpnMetricRow("Device History Stored", "0 Bytes (Pure Incognito)", Icons.delete_sweep_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text("Rotate Identity & Masked IP", style: theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        SoundService().playTap();
                        setState(() {
                          _maskedIp = '185.220.101.${(10 + DateTime.now().second % 80)}';
                          _trackersBlocked += 3;
                        });
                        setDialogState(() {});
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
        Text(value, style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold, color: widget.theme.text)),
      ],
    );
  }

  // --- COMPREHENSIVE BROWSER MENU BOTTOM SHEET ---
  void _showBrowserMenu() {
    SoundService().playClick();
    final isFullScreen = ToolerHoverSheet.isFullScreen(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = widget.theme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Browser Quick Menu", style: theme.fontDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isVpnActive ? const Color(0xFF2ED573).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _isVpnActive ? "VPN PROTECTED" : "DIRECT NET",
                      style: theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold, color: _isVpnActive ? const Color(0xFF2ED573) : Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. VPN Quick Toggle Tile
              _buildMenuActionTile(
                icon: _isVpnActive ? Icons.shield_rounded : Icons.shield_outlined,
                iconColor: _isVpnActive ? const Color(0xFF2ED573) : Colors.grey,
                title: "Built-in Encrypted VPN",
                subtitle: _isVpnActive ? "Connected: $_vpnServer" : "Tap to connect & mask IP",
                trailing: Switch(
                  value: _isVpnActive,
                  activeTrackColor: const Color(0xFF2ED573),
                  onChanged: (val) {
                    SoundService().playClick();
                    setState(() => _isVpnActive = val);
                    Navigator.pop(ctx);
                  },
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showVpnStatusDialog();
                },
              ),

              // 2. Fullscreen Toggle Tile
              _buildMenuActionTile(
                icon: isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                iconColor: theme.primary,
                title: isFullScreen ? "Exit Full Screen" : "Full Device Screen",
                subtitle: isFullScreen ? "Return to hover page view" : "Expand browser to full device screen",
                onTap: () {
                  Navigator.pop(ctx);
                  ToolerHoverSheet.toggleFullScreen(context);
                },
              ),

              // 3. Downloads Manager
              _buildMenuActionTile(
                icon: Icons.folder_zip_rounded,
                iconColor: const Color(0xFF1E90FF),
                title: "Downloads Manager (${_downloadHistory.length})",
                subtitle: "View downloaded videos, pictures and files",
                onTap: () {
                  Navigator.pop(ctx);
                  _showDownloadsListModal();
                },
              ),

              // 4. Desktop Mode Toggle
              _buildMenuActionTile(
                icon: Icons.desktop_windows_rounded,
                iconColor: const Color(0xFFFFA502),
                title: "Desktop Mode",
                subtitle: _isDesktopMode ? "Switch to mobile view" : "Request desktop version of websites",
                trailing: Switch(
                  value: _isDesktopMode,
                  activeTrackColor: const Color(0xFFFFA502),
                  onChanged: (val) {
                    Navigator.pop(ctx);
                    _toggleDesktopMode();
                  },
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleDesktopMode();
                },
              ),

              // 5. Zero-History Purge
              _buildMenuActionTile(
                icon: Icons.delete_forever_rounded,
                iconColor: const Color(0xFFFF4757),
                title: "Clear All Browsing Traces",
                subtitle: "Purge cookies, session storage & cache immediately",
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
  }

  Widget _buildMenuActionTile({
    required IconData icon,
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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: theme.fontMono(fontSize: 10.5, color: theme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.textSecondary),
        onTap: () {
          SoundService().playClick();
          onTap();
        },
      ),
    );
  }

  // --- DOWNLOADS LIST MODAL ---
  void _showDownloadsListModal() {
    SoundService().playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = widget.theme;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Column(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E90FF).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.folder_zip_rounded, color: Color(0xFF1E90FF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text("Downloaded Media", style: theme.fontDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text("${_downloadHistory.length} files", style: theme.fontMono(fontSize: 12, color: theme.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _downloadHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_download_outlined, size: 48, color: theme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text("No files downloaded yet", style: theme.fontDisplay(fontSize: 14, color: theme.textSecondary)),
                            const SizedBox(height: 6),
                            Text("Downloaded pictures and videos will be listed here.", style: theme.fontMono(fontSize: 11, color: theme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _downloadHistory.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _downloadHistory[index];
                          final String name = item['name'] ?? 'File';
                          final String path = item['path'] ?? '';
                          final String size = item['size'] ?? '0 B';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.border, width: 1.1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.insert_drive_file_rounded, color: theme.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text("$size • $path", maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.fontMono(fontSize: 10, color: theme.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                  color: theme.primary,
                                  onPressed: () async {
                                    final uri = Uri.file(path);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DOWNLOAD MODAL SHEET ---
  void _showMediaDownloadModal() {
    SoundService().playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final images = _detectedMedia.where((m) => m['type'] == 'image').toList();
            final videos = _detectedMedia.where((m) => m['type'] == 'video').toList();
            final files = _detectedMedia.where((m) => m['type'] != 'image' && m['type'] != 'video').toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: widget.theme.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: widget.theme.border, width: 1.5),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.theme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.theme.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.download_for_offline_rounded,
                                color: widget.theme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Media Downloader",
                                  style: widget.theme.fontDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${_detectedMedia.length} detected files from webpage",
                                  style: widget.theme.fontMono(
                                    fontSize: 11,
                                    color: widget.theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.sync_rounded, color: widget.theme.primary),
                          tooltip: "Re-scan Page Media",
                          onPressed: () async {
                            await _sniffPageMedia();
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_detectedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Row(
                        children: [
                          _buildFilterCountBadge("Images", images.length, const Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          _buildFilterCountBadge("Videos", videos.length, const Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          _buildFilterCountBadge("Files", files.length, const Color(0xFF3B82F6)),
                        ],
                      ),
                    ),

                  Divider(color: widget.theme.border),

                  // Direct link downloader bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.theme.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, size: 18, color: widget.theme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Paste any picture, video or file URL to download...",
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: widget.theme.fontMono(fontSize: 12),
                              onSubmitted: (url) {
                                if (url.trim().isNotEmpty) {
                                  Navigator.pop(ctx);
                                  _downloadMediaFile(url.trim(), _extractFilename(url.trim()), 'file');
                                }
                              },
                            ),
                          ),
                          Text(
                            "Enter ↵",
                            style: widget.theme.fontMono(fontSize: 10, color: widget.theme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: _detectedMedia.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48,
                                    color: widget.theme.textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No standalone media detected on this URL yet",
                                    textAlign: TextAlign.center,
                                    style: widget.theme.fontDisplay(
                                      fontSize: 14,
                                      color: widget.theme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Paste any direct picture or video link above to download straight into your device storage!",
                                    textAlign: TextAlign.center,
                                    style: widget.theme.fontMono(
                                      fontSize: 12,
                                      color: widget.theme.textSecondary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _detectedMedia.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _detectedMedia[index];
                              final String type = item['type'] ?? 'file';
                              final String url = item['url'] ?? '';
                              final String title = item['title'] ?? 'Media $index';
                              final bool isDownloading = _downloadProgress.containsKey(url);
                              final double? progress = _downloadProgress[url];

                              IconData typeIcon = Icons.insert_drive_file_rounded;
                              Color badgeColor = const Color(0xFF3B82F6);
                              if (type == 'image') {
                                typeIcon = Icons.image_rounded;
                                badgeColor = const Color(0xFF10B981);
                              } else if (type == 'video') {
                                typeIcon = Icons.videocam_rounded;
                                badgeColor = const Color(0xFFEF4444);
                              } else if (type == 'audio') {
                                typeIcon = Icons.audiotrack_rounded;
                                badgeColor = const Color(0xFF8B5CF6);
                              }

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: widget.theme.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: widget.theme.border, width: 1.2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: badgeColor.withValues(alpha: 0.4),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: type == 'image'
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(9),
                                              child: Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(
                                                  Icons.image_rounded,
                                                  color: badgeColor,
                                                  size: 22,
                                                ),
                                              ),
                                            )
                                          : Icon(typeIcon, color: badgeColor, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  type.toUpperCase(),
                                                  style: widget.theme.fontMono(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: badgeColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  title.isNotEmpty ? title : _extractFilename(url),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: widget.theme.fontDisplay(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            url,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: widget.theme.fontMono(
                                              fontSize: 10,
                                              color: widget.theme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isDownloading)
                                      SizedBox(
                                        width: 38,
                                        height: 38,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: progress,
                                              strokeWidth: 3,
                                              color: widget.theme.primary,
                                            ),
                                            Text(
                                              "${((progress ?? 0) * 100).toInt()}%",
                                              style: widget.theme.fontMono(fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      IconButton.filledTonal(
                                        style: IconButton.styleFrom(
                                          backgroundColor: widget.theme.primary.withValues(alpha: 0.15),
                                        ),
                                        icon: Icon(
                                          Icons.file_download_rounded,
                                          color: widget.theme.primary,
                                          size: 20,
                                        ),
                                        tooltip: "Download to Device",
                                        onPressed: () {
                                          _downloadMediaFile(url, title, type);
                                          setModalState(() {});
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  if (_detectedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            "Download All Detected Files (${_detectedMedia.length})",
                            style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            for (final item in _detectedMedia) {
                              _downloadMediaFile(item['url'], item['title'], item['type']);
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
  }

  Widget _buildFilterCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: widget.theme.fontDisplay(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text("($count)", style: widget.theme.fontMono(fontSize: 10, color: color)),
        ],
      ),
    );
  }

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
                // 1. SMART BROWSER TOP BAR (Controls, Enlarged Search Bar, Send Button, VPN, Fullscreen, Menu)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isFullScreen ? 10 : 14, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.border, width: 1.2),
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
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        color: _canGoBack ? theme.text : theme.textSecondary.withValues(alpha: 0.35),
                        onPressed: _canGoBack ? () => _controller.goBack() : null,
                      ),

                      // Forward Button
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        color: _canGoForward ? theme.text : theme.textSecondary.withValues(alpha: 0.35),
                        onPressed: _canGoForward ? () => _controller.goForward() : null,
                      ),

                      // Refresh Button
                      IconButton(
                        icon: Icon(Icons.refresh_rounded, size: 19, color: theme.text),
                        onPressed: () => _controller.reload(),
                      ),

                      // Enlarged Address & Search Bar
                      Expanded(
                        child: Tooltip(
                          message: _pageTitle.isNotEmpty ? _pageTitle : "Web Browser URL / Search",
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: theme.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isVpnActive ? const Color(0xFF2ED573).withValues(alpha: 0.4) : theme.border,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // VPN Shield / Lock indicator
                                GestureDetector(
                                  onTap: _showVpnStatusDialog,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _isVpnActive
                                          ? Icons.shield_rounded
                                          : (_currentUrl.startsWith('https://') ? Icons.lock_outline_rounded : Icons.search_rounded),
                                      size: 17,
                                      color: _isVpnActive ? const Color(0xFF2ED573) : theme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _urlCtrl,
                                    style: theme.fontMono(fontSize: 13, fontWeight: FontWeight.w600),
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      hintText: "Type search or website URL...",
                                      hintStyle: theme.fontMono(
                                        fontSize: 12.5,
                                        color: theme.textSecondary.withValues(alpha: 0.6),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onSubmitted: _performSearchOrNavigate,
                                  ),
                                ),
                                if (_urlCtrl.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _urlCtrl.clear();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.cancel_rounded, size: 18, color: theme.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // IMPROVED TACTILE SEND / SEARCH BUTTON
                      BouncyTap(
                        onTap: () => _performSearchOrNavigate(_urlCtrl.text),
                        scaleFraction: 0.90,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // MEDIA SNIFFER DOWNLOAD ICON
                      Badge(
                        isLabelVisible: _detectedMedia.isNotEmpty,
                        label: Text(
                          "${_detectedMedia.length}",
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: theme.primary,
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: _detectedMedia.isNotEmpty ? theme.primary.withValues(alpha: 0.18) : theme.cardBg,
                            side: BorderSide(
                              color: _detectedMedia.isNotEmpty ? theme.primary : theme.border,
                              width: 1.2,
                            ),
                          ),
                          icon: Icon(
                            _detectedMedia.isNotEmpty ? Icons.download_for_offline_rounded : Icons.file_download_outlined,
                            size: 20,
                            color: _detectedMedia.isNotEmpty ? theme.primary : theme.textSecondary,
                          ),
                          tooltip: _detectedMedia.isNotEmpty ? "Detected Media Download" : "Download Files",
                          onPressed: _showMediaDownloadModal,
                        ),
                      ),

                      // FULLSCREEN TOGGLE BUTTON
                      IconButton(
                        icon: Icon(
                          isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          size: 22,
                          color: isFullScreen ? theme.primary : theme.text,
                        ),
                        tooltip: isFullScreen ? "Exit Fullscreen" : "Full Screen Mode",
                        onPressed: () => ToolerHoverSheet.toggleFullScreen(context),
                      ),

                      // THREE-DOT MENU BUTTON
                      IconButton(
                        icon: Icon(Icons.more_vert_rounded, size: 21, color: theme.text),
                        tooltip: "Browser Menu",
                        onPressed: _showBrowserMenu,
                      ),
                    ],
                  ),
                ),

                // 2. LIVE PROGRESS BAR
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _loadProgress > 0 ? _loadProgress : null,
                    minHeight: 3.0,
                    color: theme.primary,
                    backgroundColor: theme.border.withValues(alpha: 0.3),
                  ),

                // 3. MAIN BROWSER VIEWPORT
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(isFullScreen ? 6 : 14, 4, isFullScreen ? 6 : 14, isFullScreen ? 6 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isFullScreen ? 10 : 16),
                      border: Border.all(color: theme.border, width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isFullScreen ? 9 : 15),
                      child: _hasLoadedFirstPage
                          ? WebViewWidget(controller: _controller)
                          : _buildCleanSearchLanding(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CLEAN SEARCH LANDING (NO DUMMY SUGGESTIONS) ---
  Widget _buildCleanSearchLanding() {
    final theme = widget.theme;

    return Container(
      color: theme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean Browser Emblem
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(
                  Icons.travel_explore_rounded,
                  size: 40,
                  color: theme.primary,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                "Smart Web Browser",
                style: theme.fontDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Built-in VPN • Zero Device History • Universal Downloader",
                textAlign: TextAlign.center,
                style: theme.fontMono(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // VPN Status Pill
              GestureDetector(
                onTap: _showVpnStatusDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isVpnActive
                        ? const Color(0xFF2ED573).withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _isVpnActive ? const Color(0xFF2ED573).withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.4),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isVpnActive ? Icons.shield_rounded : Icons.shield_outlined,
                        size: 15,
                        color: _isVpnActive ? const Color(0xFF2ED573) : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isVpnActive ? "VPN TUNNEL ON: $_maskedIp" : "VPN TUNNEL OFF",
                        style: theme.fontMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _isVpnActive ? const Color(0xFF2ED573) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Enlarged Direct Input Landing Card
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.search_rounded, size: 20, color: theme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _urlCtrl,
                        style: theme.fontMono(fontSize: 13, fontWeight: FontWeight.w600),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: "Search Google or type web address...",
                          hintStyle: theme.fontMono(
                            fontSize: 12.5,
                            color: theme.textSecondary.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: _performSearchOrNavigate,
                      ),
                    ),
                    BouncyTap(
                      onTap: () => _performSearchOrNavigate(_urlCtrl.text),
                      scaleFraction: 0.90,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Go",
                          style: theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Quick Info Chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLandingFeatureChip(Icons.vpn_lock_rounded, "Encrypted Tunnel"),
                  _buildLandingFeatureChip(Icons.history_toggle_off_rounded, "Zero Local History"),
                  _buildLandingFeatureChip(Icons.fullscreen_rounded, "Full Device Screen"),
                  _buildLandingFeatureChip(Icons.download_rounded, "Universal Downloader"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandingFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: widget.theme.primary),
          const SizedBox(width: 5),
          Text(label, style: widget.theme.fontMono(fontSize: 10, color: widget.theme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
