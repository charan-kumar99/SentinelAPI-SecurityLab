import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/badge_chip.dart';

class RateLimitView extends StatefulWidget {
  const RateLimitView({super.key});

  @override
  State<RateLimitView> createState() => _RateLimitViewState();
}

class _RateLimitViewState extends State<RateLimitView> {
  bool _loading = false;
  int _burstCount = 10;
  List<Map<String, dynamic>> _results = [];

  Future<void> _launchBurst() async {
    setState(() {
      _loading = true;
      _results = [];
    });
    final res = await ApiService.testRateLimitBurst(count: _burstCount);
    setState(() {
      _loading = false;
      _results = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allowedCount = _results.where((r) => r['statusCode'] == 200).length;
    final throttledCount = _results.where((r) => r['statusCode'] == 429).length;
    final totalCount = _results.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Attack Controls & Metrics
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Rate Limiter & DDoS Mitigation Hammer',
                      subtitle: 'Redis Sliding Window & ASP.NET Core RateLimiter Policy',
                      icon: Icons.flash_on_rounded,
                      accentColor: CyberTheme.amberNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Launch high-frequency burst traffic against the API gateway to test HTTP 429 Too Many Requests throttling:',
                            style: TextStyle(fontSize: 12.5, color: CyberTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('Burst Size: $_burstCount req', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: _burstCount.toDouble(),
                                  min: 5,
                                  max: 20,
                                  divisions: 3,
                                  activeColor: CyberTheme.amberNeon,
                                  onChanged: (v) => setState(() => _burstCount = v.toInt()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CyberTheme.amberNeon,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 20),
                            label: Text(
                              _loading ? 'BURSTING TRAFFIC...' : 'LAUNCH BURST TRAFFIC ($_burstCount REQ)',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            onPressed: _loading ? null : _launchBurst,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metrics Tiles
                    Row(
                      children: [
                        Expanded(
                          child: CyberMetricTile(
                            title: '$allowedCount / $totalCount',
                            subtitle: 'Allowed (200 OK)',
                            color: CyberTheme.emeraldNeon,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CyberMetricTile(
                            title: '$throttledCount / $totalCount',
                            subtitle: 'Throttled (429)',
                            color: CyberTheme.crimsonNeon,
                            icon: Icons.block_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right: Real-time Request Stream
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Live Request Stream & Latency Timeline',
                      subtitle: 'Real-time HTTP Status Codes & Sub-millisecond Execution Times',
                      icon: Icons.timeline_rounded,
                      accentColor: CyberTheme.primaryNeon,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 380),
                        child: _results.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'Click Launch Burst Traffic to start the rate limiter test stream.',
                                    style: TextStyle(color: CyberTheme.textMuted),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (ctx, i) {
                                  final item = _results[i];
                                  final isThrottled = item['statusCode'] == 429;
                                  final isOk = item['statusCode'] == 200;
                                  final color = isThrottled
                                      ? CyberTheme.crimsonNeon
                                      : isOk
                                          ? CyberTheme.emeraldNeon
                                          : CyberTheme.amberNeon;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isThrottled ? Icons.block_rounded : Icons.check_circle_rounded,
                                              color: color,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Request #${item['index']}: ${isThrottled ? "🚫 [429 TOO MANY REQUESTS]" : isOk ? "✅ [200 OK ALLOWED]" : "⚠️ [STATUS ${item['statusCode']}]"}',
                                              style: GoogleFonts.firaCode(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${item['timeMs']} ms',
                                          style: GoogleFonts.firaCode(
                                            fontSize: 12,
                                            color: CyberTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
