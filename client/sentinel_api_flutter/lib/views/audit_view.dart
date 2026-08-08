import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audit_models.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/badge_chip.dart';

class AuditView extends StatefulWidget {
  const AuditView({super.key});

  @override
  State<AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<AuditView> {
  bool _loading = false;
  List<AuditLogDto> _logs = [];
  String _searchQuery = '';
  String? _selectedRiskFilter;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() => _loading = true);
    final logs = await ApiService.fetchRecentAuditLogs(count: 50);
    setState(() {
      _loading = false;
      _logs = logs;
    });
  }

  List<AuditLogDto> get _filteredLogs {
    return _logs.where((log) {
      if (_selectedRiskFilter != null && _selectedRiskFilter != 'All') {
        if (log.riskString.toLowerCase() != _selectedRiskFilter!.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return log.action.toLowerCase().contains(q) ||
            log.endpoint.toLowerCase().contains(q) ||
            log.clientIp.toLowerCase().contains(q) ||
            log.details.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CyberCard(
            title: 'Security Audit Telemetry Stream',
            subtitle: 'Structured Real-Time Threat Intelligence & DevSecOps Log Aggregation',
            icon: Icons.analytics_rounded,
            accentColor: CyberTheme.primaryNeon,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: CyberTheme.primaryNeon),
                  tooltip: 'Refresh Telemetry Stream',
                  onPressed: _refreshLogs,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters Bar
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search by action, endpoint, client IP, or payload details...',
                          prefixIcon: Icon(Icons.search_rounded, color: CyberTheme.primaryNeon),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Critical', 'High', 'Medium', 'Low'].map((risk) {
                        final isSelected = (_selectedRiskFilter == null && risk == 'All') ||
                            _selectedRiskFilter == risk;
                        return ChoiceChip(
                          label: Text(risk),
                          selected: isSelected,
                          selectedColor: risk == 'Critical'
                              ? CyberTheme.crimsonNeon.withOpacity(0.25)
                              : risk == 'High'
                                  ? CyberTheme.amberNeon.withOpacity(0.25)
                                  : CyberTheme.primaryNeon.withOpacity(0.25),
                          onSelected: (selected) {
                            setState(() {
                              _selectedRiskFilter = selected ? risk : 'All';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Audit Log List
                Container(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security_rounded, size: 48, color: CyberTheme.textSubtle),
                                const SizedBox(height: 12),
                                Text(
                                  _loading ? 'Fetching audit telemetry...' : 'No audit records match the selected filter.',
                                  style: const TextStyle(color: CyberTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final log = filtered[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: CyberTheme.surfaceInput,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: CyberTheme.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CyberBadge.risk(log.riskLevel),
                                          const SizedBox(width: 10),
                                          CyberBadge.status(log.statusCode),
                                          const SizedBox(width: 10),
                                          Text(
                                            log.action,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: CyberTheme.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        log.timestamp.replaceFirst('T', ' ').split('.').first,
                                        style: CyberTheme.codeFont(fontSize: 11, color: CyberTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: CyberTheme.primaryNeon.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          log.httpMethod,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: CyberTheme.primaryNeon,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        log.endpoint,
                                        style: CyberTheme.codeFont(fontSize: 11.5, color: Colors.white70),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'IP: ${log.clientIp}',
                                        style: const TextStyle(fontSize: 11.5, color: CyberTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  if (log.details.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      log.details,
                                      style: const TextStyle(fontSize: 12, color: CyberTheme.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
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
