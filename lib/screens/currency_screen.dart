import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER REAL-TIME CURRENCY CONVERTER
/// ---------------------------------------------------------------------------
/// Features:
/// 1. Real-Time Exchange Rates API:
///    - Live rates from open.er-api.com with zero API key required
///    - Background automatic updates whenever data/internet is active
/// 2. Offline Price Memory / Persistence:
///    - Caches real-time rates and timestamp in SharedPreferences
///    - Works offline seamlessly using remembered prices
/// 3. Transparent Last Update Info:
///    - Displays "Last updated: <date/time>" in small font with live status
/// 4. Pure Currency Names & Vector SVG Badges:
///    - Shows Currency Name (e.g., "US Dollar", "Indian Rupee") — no country names
///    - Elegant SVG-styled squircle symbol badges ($, ₹, €, £, ¥, etc.)
/// ---------------------------------------------------------------------------

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

const Map<String, CurrencyInfo> kCurrencies = {
  'USD': CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: r'$'),
  'INR': CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  'EUR': CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€'),
  'GBP': CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£'),
  'JPY': CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  'AED': CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
  'SAR': CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
  'CAD': CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: r'C$'),
  'AUD': CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: r'A$'),
  'CHF': CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
  'SGD': CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: r'S$'),
  'CNY': CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  'NZD': CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', symbol: r'NZ$'),
  'KWD': CurrencyInfo(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'KD'),
  'QAR': CurrencyInfo(code: 'QAR', name: 'Qatari Riyal', symbol: 'QR'),
  'OMR': CurrencyInfo(code: 'OMR', name: 'Omani Rial', symbol: 'RO'),
  'BHD': CurrencyInfo(code: 'BHD', name: 'Bahraini Dinar', symbol: 'BD'),
  'KRW': CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
  'BRL': CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: r'R$'),
  'TRY': CurrencyInfo(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
  'RUB': CurrencyInfo(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
  'ZAR': CurrencyInfo(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
  'THB': CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿'),
  'MYR': CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
  'IDR': CurrencyInfo(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
  'PKR': CurrencyInfo(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs'),
  'BDT': CurrencyInfo(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳'),
  'PHP': CurrencyInfo(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
  'VND': CurrencyInfo(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
  'EGP': CurrencyInfo(code: 'EGP', name: 'Egyptian Pound', symbol: r'E£'),
  'MXN': CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: r'Mex$'),
  'HKD': CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', symbol: r'HK$'),
};

class CurrencyScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CurrencyScreen({super.key, required this.theme});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _amountCtrl = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  double _convertedAmount = 0.0;

  // Real-time exchange rates relative to 1 USD (with default fallback values)
  final Map<String, double> _rates = {
    'USD': 1.0,
    'INR': 84.38,
    'EUR': 0.95,
    'GBP': 0.79,
    'JPY': 154.60,
    'AED': 3.67,
    'SAR': 3.75,
    'CAD': 1.40,
    'AUD': 1.54,
    'CHF': 0.88,
    'SGD': 1.34,
    'CNY': 7.24,
    'NZD': 1.70,
    'KWD': 0.31,
    'QAR': 3.64,
    'OMR': 0.38,
    'BHD': 0.38,
    'KRW': 1395.0,
    'BRL': 5.75,
    'TRY': 34.40,
    'RUB': 98.20,
    'ZAR': 18.10,
    'THB': 34.80,
    'MYR': 4.46,
    'IDR': 15850.0,
    'PKR': 278.20,
    'BDT': 119.50,
    'PHP': 58.70,
    'VND': 25380.0,
    'EGP': 49.30,
    'MXN': 20.40,
    'HKD': 7.78,
  };

  bool _isFetchingRates = false;
  bool _isLiveRate = false;
  String _lastUpdatedText = 'Default rates';

  @override
  void initState() {
    super.initState();
    _loadCachedExchangeRates().then((_) {
      _calculate();
      // If internet/data is active, automatically fetch real-time rates
      _fetchLiveExchangeRates(showFeedback: false);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // --- PERSISTENCE: LOAD CACHED RATES ---
  Future<void> _loadCachedExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('tooler_cached_fx_rates');
      final cachedTime = prefs.getString('tooler_cached_fx_time');

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedStr);
        final map = <String, double>{};
        decoded.forEach((k, v) {
          if (v is num) map[k] = v.toDouble();
        });
        if (mounted) {
          setState(() {
            _rates.addAll(map);
            if (cachedTime != null) {
              _lastUpdatedText = cachedTime;
            }
            _isLiveRate = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading cached rates: $e");
    }
  }

  // --- REAL-TIME EXCHANGE RATES API ---
  Future<void> _fetchLiveExchangeRates({bool showFeedback = false}) async {
    if (_isFetchingRates) return;
    setState(() => _isFetchingRates = true);

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        if (data['result'] == 'success' && data['rates'] != null) {
          final ratesMap = data['rates'] as Map<String, dynamic>;
          final newRates = <String, double>{};
          ratesMap.forEach((k, v) {
            if (v is num) newRates[k] = v.toDouble();
          });

          final now = DateTime.now();
          final formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(now);

          // Save to SharedPreferences so it remembers the real-time prices
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('tooler_cached_fx_rates', jsonEncode(newRates));
          await prefs.setString('tooler_cached_fx_time', formattedTime);

          if (mounted) {
            setState(() {
              _rates.addAll(newRates);
              _lastUpdatedText = formattedTime;
              _isLiveRate = true;
              _isFetchingRates = false;
            });
            _calculate();

            if (showFeedback) {
              SoundService().playClick();
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Real-time exchange rates updated!",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF2ED573),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch live FX rates: $e");
    }

    if (mounted) {
      setState(() => _isFetchingRates = false);
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Offline mode: Using cached exchange rates ($lastUpdateLabel)",
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: Colors.grey.shade800,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _calculate() {
    final double? amount = double.tryParse(_amountCtrl.text);
    if (amount == null) {
      setState(() => _convertedAmount = 0.0);
      return;
    }

    final double fromRate = _rates[_fromCurrency] ?? 1.0;
    final double toRate = _rates[_toCurrency] ?? 1.0;

    // Convert from source to USD then USD to target
    final inUsd = amount / fromRate;
    final inTarget = inUsd * toRate;

    setState(() {
      _convertedAmount = inTarget;
    });
  }

  void _swap() {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _calculate();
    });
  }

  String get lastUpdateLabel => _lastUpdatedText;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final double ratePerUnit = (_rates[_toCurrency] ?? 1.0) / (_rates[_fromCurrency] ?? 1.0);

    final fromInfo = kCurrencies[_fromCurrency] ??
        CurrencyInfo(code: _fromCurrency, name: _fromCurrency, symbol: _fromCurrency);
    final toInfo = kCurrencies[_toCurrency] ??
        CurrencyInfo(code: _toCurrency, name: _toCurrency, symbol: _toCurrency);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: theme.mode),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. AMOUNT INPUT & CURRENCY PICKER CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: theme.doodleCard(borderWidth: 2.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Amount to Convert:",
                          style: theme.fontMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Amount Input Box
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                          onChanged: (_) => _calculate(),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.bg,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 10),
                              child: Text(
                                fromInfo.symbol,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.border, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.border, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.primary, width: 2.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // From / Swap / To Currency Selection Row
                        Row(
                          children: [
                            // FROM CURRENCY BUTTON
                            Expanded(
                              child: _buildCurrencySelectorTile(
                                label: "From",
                                info: fromInfo,
                                onTap: () => _openCurrencyPicker(true),
                              ),
                            ),

                            // SWAP BUTTON
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.primary.withValues(alpha: 0.15),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                ),
                                icon: Icon(Icons.swap_horiz_rounded, size: 26, color: theme.primary),
                                tooltip: "Swap Currencies",
                                onPressed: _swap,
                              ),
                            ),

                            // TO CURRENCY BUTTON
                            Expanded(
                              child: _buildCurrencySelectorTile(
                                label: "To",
                                info: toInfo,
                                onTap: () => _openCurrencyPicker(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. CONVERTED RESULT DISPLAY CARD
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: theme.doodleCard(
                      color: theme.accent.withValues(alpha: 0.15),
                      borderWidth: 2.5,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "EXCHANGE RESULT",
                          style: theme.fontMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Formatted Converted Amount
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                toInfo.symbol,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SelectableText(
                                _formatAmount(_convertedAmount),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: theme.text,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Currency Name and Sign Badge (No country name)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CurrencySymbolBadge(
                              symbol: toInfo.symbol,
                              theme: theme,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              toInfo.name,
                              style: theme.fontDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 1 Unit Exchange Rate Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.border, width: 1.5),
                          ),
                          child: Text(
                            "1 ${fromInfo.code} = ${ratePerUnit.toStringAsFixed(4)} ${toInfo.code}",
                            style: theme.fontMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.text,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(color: theme.border.withValues(alpha: 0.6), height: 1),
                        const SizedBox(height: 10),

                        // LAST UPDATE TIMESTAMP & REFRESH BUTTON (Small Font as requested)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Live Status Indicator Dot
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _isLiveRate ? const Color(0xFF2ED573) : const Color(0xFFFFA502),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isLiveRate ? "Live FX · " : "Cached · ",
                              style: theme.fontMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isLiveRate ? const Color(0xFF2ED573) : const Color(0xFFFFA502),
                              ),
                            ),
                            Text(
                              "Last updated: $lastUpdateLabel",
                              style: theme.fontMono(
                                fontSize: 10,
                                color: theme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Quick Refresh Icon Button
                            InkWell(
                              onTap: _isFetchingRates
                                  ? null
                                  : () => _fetchLiveExchangeRates(showFeedback: true),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: _isFetchingRates
                                    ? SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: theme.primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.sync_rounded,
                                        size: 15,
                                        color: theme.primary,
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
          ),
        ],
      ),
    );
  }

  // --- CURRENCY SELECTOR BUTTON TILE ---
  Widget _buildCurrencySelectorTile({
    required String label,
    required CurrencyInfo info,
    required VoidCallback onTap,
  }) {
    final theme = widget.theme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.fontMono(
                fontSize: 10,
                color: theme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Currency Symbol Badge
                CurrencySymbolBadge(
                  symbol: info.symbol,
                  theme: theme,
                  size: 32,
                ),
                const SizedBox(width: 8),

                // Currency Code & Currency Name (NO country name)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.code,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        info.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.fontDisplay(
                          fontSize: 10,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CURRENCY PICKER BOTTOM SHEET ---
  void _openCurrencyPicker(bool isFrom) {
    SoundService().playClick();
    String search = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = widget.theme;
            final activeCode = isFrom ? _fromCurrency : _toCurrency;

            final filteredList = kCurrencies.values.where((c) {
              if (search.isEmpty) return true;
              final q = search.toLowerCase();
              return c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Column(
                children: [
                  // Drag Handle
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

                  // Header Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFrom ? "Select Source Currency" : "Select Target Currency",
                          style: theme.fontDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${filteredList.length} Currencies",
                          style: theme.fontMono(
                            fontSize: 11,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: theme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Search by currency name or code...",
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: theme.fontMono(fontSize: 13),
                              onChanged: (val) {
                                setModalState(() => search = val.trim());
                              },
                            ),
                          ),
                          if (search.isNotEmpty)
                            GestureDetector(
                              onTap: () => setModalState(() => search = ''),
                              child: Icon(Icons.cancel_rounded, size: 16, color: theme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),

                  Divider(color: theme.border),

                  // Currency List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, index) {
                        final item = filteredList[index];
                        final bool isSelected = item.code == activeCode;
                        final double rate = _rates[item.code] ?? 1.0;

                        return InkWell(
                          onTap: () {
                            SoundService().playClick();
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isFrom) {
                                _fromCurrency = item.code;
                              } else {
                                _toCurrency = item.code;
                              }
                              _calculate();
                            });
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primary.withValues(alpha: 0.12)
                                  : theme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? theme.primary : theme.border,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Symbol Badge
                                CurrencySymbolBadge(
                                  symbol: item.symbol,
                                  theme: theme,
                                  size: 38,
                                ),
                                const SizedBox(width: 12),

                                // Currency Name & Code (NO country name)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: theme.fontDisplay(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? theme.primary : theme.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${item.code} · Rate: ${rate.toStringAsFixed(2)} / USD",
                                        style: theme.fontMono(
                                          fontSize: 11,
                                          color: theme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkmark
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
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
      },
    );
  }

  String _formatAmount(double val) {
    if (val >= 1000000) {
      return NumberFormat("#,##0.00").format(val);
    }
    return val.toStringAsFixed(2);
  }
}

/// ---------------------------------------------------------------------------
/// CURRENCY SYMBOL SVG-STYLED BADGE WITH UI TOUCH
/// ---------------------------------------------------------------------------
class CurrencySymbolBadge extends StatelessWidget {
  final String symbol;
  final StationeryTheme theme;
  final double size;

  const CurrencySymbolBadge({
    super.key,
    required this.symbol,
    required this.theme,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.isDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? theme.cardBg : theme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: isDark ? theme.border : theme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: theme.primary,
          ),
        ),
      ),
    );
  }
}
