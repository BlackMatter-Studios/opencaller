import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_colors.dart';
import '../../core/theme/platform_glass_surface.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  bool _isSyncing = false;
  int _refreshKey = 0;

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(syncServiceProvider);
      int count = await syncService.performDeltaSync(countryCode: 'CR');
      count += await syncService.performDeltaSync(countryCode: 'US');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync complete! Updated $count phone numbers.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _refreshKey++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Call Activity & Defense', style: AppTypography.headlineMedium),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: GlassColors.neonCyan),
                  )
                : const Icon(Icons.sync_rounded, color: GlassColors.neonCyan),
            onPressed: _isSyncing ? null : _triggerSync,
            tooltip: 'Sync Local Spam Database',
          ),
        ],
      ),
      body: FutureBuilder<List<CallLog>>(
        key: ValueKey(_refreshKey),
        future: db.getRecentCalls(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: GlassColors.neonCyan),
            );
          }

          final calls = snapshot.data!;
          if (calls.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: calls.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = calls[index];
              final isBlocked = log.callType == 'blocked' || log.spamScore >= 0.80;

              return PlatformGlassSurface(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                borderColor: isBlocked
                    ? GlassColors.severeScam.withValues(alpha: 0.4)
                    : GlassColors.glassBorder,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isBlocked ? GlassColors.severeScamGlass : GlassColors.cleanVerifiedGlass,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBlocked ? Icons.block_rounded : Icons.call_received_rounded,
                        color: isBlocked ? GlassColors.severeScam : GlassColors.cleanVerified,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.callerName ?? 'Unknown Caller',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${log.e164Number}',
                            style: AppTypography.bodyMedium.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat.jm().format(log.timestamp),
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: GlassColors.severeScamGlass,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BLOCKED',
                              style: AppTypography.badgeText.copyWith(color: GlassColors.severeScam),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: GlassColors.neonCyan.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Calls Recorded Yet', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Incoming calls will be screened automatically by OpenCaller. Spam callers will be silenced or rejected before your phone rings.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
