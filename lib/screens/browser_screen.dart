import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER MINIMAL SMART WEB BROWSER & UNIVERSAL MEDIA DOWNLOADER
/// ---------------------------------------------------------------------------
/// Features:
/// 1. Direct Search & Navigation:
///    - Type any query to instantly search Google without dummy pre-suggestions
///    - Type any URL to directly navigate to the live webpage
/// 2. Automatic Live Webpage Media Sniffer:
///    - Auto-detects all pictures, videos, audio, and download files from any website
///    - Glowing Download Badge Icon automatically appears in the top header bar
/// 3. Universal Device File Downloader:
///    - Streams and saves videos, pictures, and files directly to device Download storage
///    - Live download progress percentage and success notifications
///    - Custom direct link downloader option for any media URL
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
      ..setBackgroundColor(Colors.white)
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
              _sniffPageMedia();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: ${error.description}');
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

        // 2. Detect all high-res and content images (filter out tiny icons < 40px)
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
    } catch (e) {
      debugPrint('Media Sniffer JS Error: $e');
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
      // Direct Google search without pre-suggestions
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

      // 1. Resolve Target Device Storage Directory (Downloads folder)
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
                  // Modal Drag Handle
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

                  // Header with Title & Sniffer Stats
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
                        // Refresh sniffer
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

                  // Media Type Quick Badges
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

                  // Custom Direct URL Downloader Bar
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

                  // Media List View
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
                                    // Thumbnail / Type Badge
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

                                    // Title & URL info
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

                                    // Download Button / Progress Ring
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

                  // Bottom Action: Download All
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // Background Notebook Grid
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: theme.mode),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. SMART BROWSER TOP BAR (Controls, URL/Search Bar, & Auto-Download Icon)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
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
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 19,
                          color: theme.text,
                        ),
                        onPressed: () => _controller.reload(),
                      ),

                      // Search / Address Input Field
                      Expanded(
                        child: Tooltip(
                          message: _pageTitle.isNotEmpty ? _pageTitle : "Mini Browser URL / Search",
                          child: Container(
                            height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.border, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _currentUrl.startsWith('https://')
                                    ? Icons.lock_outline_rounded
                                    : Icons.search_rounded,
                                size: 15,
                                color: theme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _urlCtrl,
                                  style: theme.fontMono(fontSize: 12),
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: "Type search or website URL...",
                                    hintStyle: theme.fontMono(
                                      fontSize: 12,
                                      color: theme.textSecondary.withValues(alpha: 0.6),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                                  child: Icon(Icons.cancel_rounded, size: 16, color: theme.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                      const SizedBox(width: 6),

                      // Search Action (➔)
                      IconButton(
                        icon: Icon(Icons.arrow_forward_rounded, color: theme.primary, size: 20),
                        tooltip: "Search / Go",
                        onPressed: () => _performSearchOrNavigate(_urlCtrl.text),
                      ),

                      // AUTOMATIC MEDIA DOWNLOAD ICON (Appears when pictures/videos detected)
                      Container(
                        margin: const EdgeInsets.only(left: 2),
                        child: Badge(
                          isLabelVisible: _detectedMedia.isNotEmpty,
                          label: Text(
                            "${_detectedMedia.length}",
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: theme.primary,
                          child: IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: _detectedMedia.isNotEmpty
                                  ? theme.primary.withValues(alpha: 0.18)
                                  : theme.cardBg,
                              side: BorderSide(
                                color: _detectedMedia.isNotEmpty ? theme.primary : theme.border,
                                width: 1.2,
                              ),
                            ),
                            icon: Icon(
                              _detectedMedia.isNotEmpty
                                  ? Icons.download_for_offline_rounded
                                  : Icons.file_download_outlined,
                              size: 19,
                              color: _detectedMedia.isNotEmpty ? theme.primary : theme.textSecondary,
                            ),
                            tooltip: _detectedMedia.isNotEmpty
                                ? "${_detectedMedia.length} Media Detected (Download Available)"
                                : "Download Files / Paste URL",
                            onPressed: _showMediaDownloadModal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. LIVE PROGRESS BAR
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _loadProgress > 0 ? _loadProgress : null,
                    minHeight: 2.5,
                    color: theme.primary,
                    backgroundColor: theme.border.withValues(alpha: 0.4),
                  ),

                // 3. MAIN BROWSER VIEWPORT
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
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
                "Mini Smart Browser",
                style: theme.fontDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Direct Search & Universal Media Downloader",
                style: theme.fontMono(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Minimal Search Card (Direct User Input)
              Container(
                padding: const EdgeInsets.all(4),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search_rounded, color: theme.primary, size: 22),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _urlCtrl,
                        textInputAction: TextInputAction.search,
                        style: theme.fontMono(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Type search query or website URL...",
                          hintStyle: theme.fontMono(
                            fontSize: 13,
                            color: theme.textSecondary.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _performSearchOrNavigate,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => _performSearchOrNavigate(_urlCtrl.text),
                      child: Text(
                        "Search",
                        style: theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Features overview pill
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureBadge(Icons.bolt_rounded, "Instant Search"),
                  const SizedBox(width: 8),
                  _buildFeatureBadge(Icons.download_rounded, "Auto Media Detector"),
                  const SizedBox(width: 8),
                  _buildFeatureBadge(Icons.save_alt_rounded, "Device Files"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: widget.theme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: widget.theme.fontMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.theme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        "$label: $count",
        style: widget.theme.fontMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
