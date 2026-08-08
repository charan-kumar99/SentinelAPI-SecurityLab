import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import 'badge_chip.dart';

class CyberHeader extends StatefulWidget {
  final VoidCallback onStateChange;

  const CyberHeader({super.key, required this.onStateChange});

  @override
  State<CyberHeader> createState() => _CyberHeaderState();
}

class _CyberHeaderState extends State<CyberHeader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showApiEndpointDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CyberTheme.primaryNeon, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_ethernet_rounded, color: CyberTheme.primaryNeon),
            const SizedBox(width: 10),
            Text('API Gateway Endpoint', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the target ASP.NET Core backend server URL (Docker, Cloud, or Localhost):',
              style: TextStyle(fontSize: 12.5, color: CyberTheme.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: CyberTheme.codeFont(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://localhost:5265/api/v1',
                prefixIcon: Icon(Icons.link_rounded, color: CyberTheme.primaryNeon),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.primaryNeon, foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                ApiService.baseUrl = controller.text.trim();
              });
              Navigator.pop(ctx);
              widget.onStateChange();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: CyberTheme.surfaceElevated,
                  content: Text(
                    'API Target set to: ${ApiService.baseUrl}',
                    style: const TextStyle(color: CyberTheme.primaryNeon),
                  ),
                ),
              );
            },
            child: const Text('Update Target'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.isLoggedIn;
    final username = ApiService.currentUsername ?? 'Guest User';
    final role = ApiService.currentRole ?? 'Anonymous';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CyberTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: CyberTheme.primaryNeon.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand & Animated Shield
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: CyberTheme.primaryNeon.withOpacity(0.12 + (_pulseController.value * 0.08)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CyberTheme.primaryNeon.withOpacity(0.4 + (_pulseController.value * 0.4)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CyberTheme.primaryNeon.withOpacity(0.2 * _pulseController.value),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, color: CyberTheme.primaryNeon, size: 28),
                  );
                },
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SENTINEL API',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: CyberTheme.textMain,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECURITY LAB',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: CyberTheme.primaryNeon,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: CyberTheme.secondaryNeon.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CyberTheme.secondaryNeon.withOpacity(0.6)),
                        ),
                        child: Text(
                          'Flutter DevSecOps v1.0',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            color: CyberTheme.secondaryNeon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Cross-Platform Enterprise Defensive Engineering & Vulnerability Workbench',
                    style: GoogleFonts.outfit(fontSize: 12, color: CyberTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),

          // Right: Target Host & User Status
          Row(
            children: [
              // Target Host Chip
              InkWell(
                onTap: _showApiEndpointDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CyberTheme.surfaceInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CyberTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: CyberTheme.emeraldNeon,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CyberTheme.emeraldNeon.withOpacity(0.7),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ApiService.baseUrl.replaceFirst('http://', '').replaceFirst('https://', ''),
                        style: CyberTheme.codeFont(fontSize: 11.5, color: CyberTheme.textMain),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded, size: 13, color: CyberTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Active Session Profile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isLoggedIn
                      ? CyberTheme.primaryNeon.withOpacity(0.1)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLoggedIn
                        ? CyberTheme.primaryNeon.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isLoggedIn ? CyberTheme.primaryNeon : CyberTheme.textSubtle,
                      child: Icon(
                        isLoggedIn ? Icons.person_rounded : Icons.person_off_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: CyberTheme.textMain,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isLoggedIn ? CyberTheme.emeraldNeon : CyberTheme.amberNeon,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLoggedIn ? 'Role: $role' : 'Unauthenticated',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isLoggedIn ? CyberTheme.emeraldNeon : CyberTheme.amberNeon,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isLoggedIn) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 16, color: CyberTheme.crimsonNeon),
                        tooltip: 'Logout Session',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ApiService.logout();
                          widget.onStateChange();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logged out of SentinelAPI session.')),
                          );
                        },
                      ),
                    ],
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
