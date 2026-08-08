import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/cyber_theme.dart';
import 'widgets/cyber_header.dart';
import 'widgets/badge_chip.dart';
import 'views/auth_view.dart';
import 'views/file_vault_view.dart';
import 'views/sandbox_view.dart';
import 'views/crypto_view.dart';
import 'views/rate_limit_view.dart';
import 'views/audit_view.dart';
import 'widgets/cyber_footer.dart';

void main() {
  runApp(const SentinelApiApp());
}

class SentinelApiApp extends StatelessWidget {
  const SentinelApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SentinelAPI Security Lab - Enterprise Cyber Operations',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: CyberTheme.darkTheme,
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Glowing Cyber Navigation Header
            CyberHeader(onStateChange: _triggerRebuild),

            // Metrics Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CyberMetricTile(
                      title: 'Argon2id v13',
                      subtitle: '64MB Memory Matrix',
                      color: CyberTheme.primaryNeon,
                      icon: Icons.lock_outline_rounded,
                      badge: 'RFC 9106',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberMetricTile(
                      title: 'AES-256-GCM',
                      subtitle: 'Field & File Encryption',
                      color: CyberTheme.secondaryNeon,
                      icon: Icons.enhanced_encryption_rounded,
                      badge: 'NIST GCM',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberMetricTile(
                      title: 'Sliding Window',
                      subtitle: 'Redis Rate Limiter',
                      color: CyberTheme.amberNeon,
                      icon: Icons.speed_rounded,
                      badge: 'DDoS Shield',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberMetricTile(
                      title: 'Audit Stream',
                      subtitle: 'DevSecOps Telemetry',
                      color: CyberTheme.emeraldNeon,
                      icon: Icons.analytics_outlined,
                      badge: 'Live',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab Bar Switcher
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: CyberTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CyberTheme.borderSubtle),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: CyberTheme.primaryNeon,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: CyberTheme.primaryNeon,
                unselectedLabelColor: CyberTheme.textMuted,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.vpn_key_rounded, size: 18),
                    text: 'Auth & JWT Hub',
                  ),
                  Tab(
                    icon: Icon(Icons.folder_special_rounded, size: 18),
                    text: 'Secure File Vault',
                  ),
                  Tab(
                    icon: Icon(Icons.pest_control_rounded, size: 18),
                    text: 'Attack Sandbox (SQLi/XSS)',
                  ),
                  Tab(
                    icon: Icon(Icons.lock_clock_rounded, size: 18),
                    text: 'Crypto & Argon2id Studio',
                  ),
                  Tab(
                    icon: Icon(Icons.flash_on_rounded, size: 18),
                    text: 'Rate Limiter Hammer',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics_rounded, size: 18),
                    text: 'Security Telemetry Stream',
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AuthView(onStateChange: _triggerRebuild),
                  const FileVaultView(),
                  const SandboxView(),
                  const CryptoView(),
                  const RateLimitView(),
                  const AuditView(),
                ],
              ),
            ),

            // Bottom DevSecOps Cyber Footer
            const CyberFooter(),
          ],
        ),
      ),
    );
  }
}
