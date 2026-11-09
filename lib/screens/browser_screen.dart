import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class BrowserScreen extends StatefulWidget {
  final StationeryTheme theme;
  const BrowserScreen({super.key, required this.theme});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _urlCtrl = TextEditingController(text: 'https://en.wikipedia.org');
  String _currentUrl = 'https://en.wikipedia.org';
  bool _isLoading = false;
  final List<String> _history = ['https://en.wikipedia.org'];
  int _historyIndex = 0;

  final List<Map<String, dynamic>> _bookmarks = [
    {'title': 'Wikipedia', 'url': 'https://en.wikipedia.org', 'icon': Icons.menu_book},
    {'title': 'Google', 'url': 'https://www.google.com', 'icon': Icons.search},
    {'title': 'Khan Academy', 'url': 'https://www.khanacademy.org', 'icon': Icons.school},
    {'title': 'Math is Fun', 'url': 'https://www.mathsisfun.com', 'icon': Icons.calculate},
    {'title': 'GitHub', 'url': 'https://github.com', 'icon': Icons.code},
  ];

  void _navigateTo(String target) {
    SoundService().playClick();
    String url = target.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }

    setState(() {
      _isLoading = true;
      _currentUrl = url;
      _urlCtrl.text = url;
      _history.add(url);
      _historyIndex = _history.length - 1;
    });

    // Simulate page load finished
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _goBack() {
    if (_historyIndex > 0) {
      SoundService().playClick();
      setState(() {
        _historyIndex--;
        _currentUrl = _history[_historyIndex];
        _urlCtrl.text = _currentUrl;
      });
    }
  }

  void _goForward() {
    if (_historyIndex < _history.length - 1) {
      SoundService().playClick();
      setState(() {
        _historyIndex++;
        _currentUrl = _history[_historyIndex];
        _urlCtrl.text = _currentUrl;
      });
    }
  }

  void _reload() {
    _navigateTo(_currentUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Stationery Web Viewer",
          style: widget.theme.fontDisplay(fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: Column(
              children: [
                // Browser Address Bar & Controls
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: widget.theme.doodleCard(borderWidth: 2.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: _historyIndex > 0 ? _goBack : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: _historyIndex < _history.length - 1 ? _goForward : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _reload,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: widget.theme.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: widget.theme.border, width: 1.5),
                          ),
                          child: TextField(
                            controller: _urlCtrl,
                            style: widget.theme.fontMono(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "Search Google or type URL...",
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: _navigateTo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: widget.theme.primary),
                        onPressed: () => _navigateTo(_urlCtrl.text),
                      ),
                    ],
                  ),
                ),

                // Quick Bookmarks Carousel
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final b = _bookmarks[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(b['icon'] as IconData, size: 16, color: widget.theme.primary),
                          label: Text(
                            b['title'] as String,
                            style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: widget.theme.cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: widget.theme.border, width: 1.5),
                          ),
                          onPressed: () => _navigateTo(b['url'] as String),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Web View Container Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: widget.theme.doodleCard(borderWidth: 2.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          // Browser viewport view
                          Container(
                            color: Colors.white,
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.public, size: 64, color: Color(0xFF4ECDC4)),
                                const SizedBox(height: 14),
                                Text(
                                  "Web Page Destination:",
                                  style: widget.theme.fontMono(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  _currentUrl,
                                  textAlign: TextAlign.center,
                                  style: widget.theme.fontMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Ready to browse web content & research tools within your stationery notebook desk!",
                                  textAlign: TextAlign.center,
                                  style: widget.theme.fontDoodle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Loading Bar Indicator
                          if (_isLoading)
                            LinearProgressIndicator(
                              color: widget.theme.primary,
                              backgroundColor: widget.theme.accent.withOpacity(0.3),
                            ),
                        ],
                      ),
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
}
