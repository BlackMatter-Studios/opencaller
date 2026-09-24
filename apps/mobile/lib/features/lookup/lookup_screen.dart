import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_colors.dart';
import '../../core/theme/neon_glow_button.dart';
import '../../core/theme/platform_glass_surface.dart';

class LookupScreen extends ConsumerStatefulWidget {
  const LookupScreen({super.key});

  @override
  ConsumerState<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends ConsumerState<LookupScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _lookupResult;
  String? _errorMessage;

  Future<void> _performLookup() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lookupResult = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final result = await client.lookupNumber(query);
      setState(() {
        _lookupResult = result;
      });
    } catch (e, stack) {
      debugPrint('Lookup error: $e\n$stack');
      setState(() {
        _errorMessage = 'Lookup failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showReportDialog(int e164Number, String countryCode) {
    String selectedCategory = 'spam';
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: PlatformGlassSurface(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report Number', style: AppTypography.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Help protect the community. Your report updates the Bayesian reputation score.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: GlassColors.darkSurface,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: GlassColors.glassFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GlassColors.glassBorder),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'spam', child: Text('Telemarketing / Spam')),
                        DropdownMenuItem(value: 'scam', child: Text('Scam / Financial Fraud')),
                        DropdownMenuItem(value: 'robocall', child: Text('Automated Robocall')),
                        DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                        DropdownMenuItem(value: 'delivery', child: Text('Delivery / Legitimate')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Additional details (optional)',
                        hintStyle: const TextStyle(color: GlassColors.textMuted),
                        filled: true,
                        fillColor: GlassColors.glassFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GlassColors.glassBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    NeonGlowButton(
                      text: 'Submit Community Report',
                      glowColor: GlassColors.severeScam,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        try {
                          await ref.read(apiClientProvider).submitReport(
                                e164Number: e164Number,
                                countryCode: countryCode,
                                category: selectedCategory,
                                comment: commentController.text.trim(),
                              );
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Report submitted successfully!')),
                          );
                          _performLookup();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Submission failed: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: GlassColors.cyanPurpleGradient,
              ),
              child: const Icon(Icons.shield_outlined, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('OpenCaller', style: AppTypography.headlineMedium),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformGlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: GlassColors.neonCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.phone,
                      style: AppTypography.titleMedium,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number with country code...',
                        hintStyle: TextStyle(color: GlassColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _performLookup(),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GlassColors.neonCyan),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: GlassColors.neonCyan),
                      onPressed: _performLookup,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GlassColors.severeScamGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassColors.severeScam),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: GlassColors.severeScam)),
              ),
            if (_lookupResult != null) _buildResultCard(_lookupResult!),
            if (_lookupResult == null && !_isLoading && _errorMessage == null)
              _buildPlaceholderState(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final e164 = data['e164_number'] as int;
    final ccode = data['country_code'] as String? ?? 'XX';
    final rawName = data['caller_name'] as String?;
    final nameConfidence = (data['name_confidence'] as num?)?.toDouble() ?? 0.0;
    final spamScore = (data['spam_score'] as num?)?.toDouble() ?? 0.0;
    final isSpam = (data['is_spam'] as bool?) ?? false;
    final isPrivate = (data['is_private'] as bool?) ?? false;
    final isVerified = (data['is_verified_business'] as bool?) ?? false;
    final category = data['category'] as String? ?? 'unknown';
    final reports = data['report_count'] as int? ?? 0;

    final Color statusColor = isSpam
        ? GlassColors.severeScam
        : (spamScore >= 0.40 ? GlassColors.warningSpam : GlassColors.cleanVerified);

    // Graduated confidence calculation
    String displayName;
    String confidenceBadgeText;
    Color confidenceColor;
    IconData confidenceIcon;
    String? confidenceNote;

    if (isPrivate) {
      displayName = 'Private / Delisted Number';
      confidenceBadgeText = 'PROTECTED';
      confidenceColor = GlassColors.textMuted;
      confidenceIcon = Icons.lock_outline_rounded;
      confidenceNote = 'Este número ejerció su derecho a ser olvidado.';
    } else if (rawName != null && rawName.isNotEmpty) {
      if (nameConfidence < 0.50) {
        displayName = 'Podría ser: $rawName';
        confidenceBadgeText = 'HINT COMUNITARIO (1 SUGERENCIA)';
        confidenceColor = const Color(0xFFFBBF24); // Amber
        confidenceIcon = Icons.help_outline_rounded;
        confidenceNote = 'Sugerido por 1 colaborador comunitario. Usar con precaución.';
      } else if (nameConfidence < 0.80) {
        displayName = 'Probable: $rawName';
        confidenceBadgeText = 'IDENTIFICADOR PROBABLE';
        confidenceColor = GlassColors.neonCyan;
        confidenceIcon = Icons.flaky_outlined;
        confidenceNote = 'Confirmado por 2 usuarios independientes.';
      } else {
        displayName = rawName;
        confidenceBadgeText = isVerified ? 'NEGOCIO VERIFICADO' : 'CONSENSO VERIFICADO';
        confidenceColor = GlassColors.cleanVerified;
        confidenceIcon = Icons.verified_user_outlined;
        confidenceNote = 'Consenso comunitario de 3+ colaboradores alcanzado.';
      }
    } else {
      displayName = 'Número No Identificado';
      confidenceBadgeText = 'SIN REGISTRO';
      confidenceColor = GlassColors.textMuted;
      confidenceIcon = Icons.help_outline_rounded;
      confidenceNote = null;
    }

    return PlatformGlassSurface(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(24),
      borderColor: statusColor.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSpam ? Icons.warning_amber_rounded : Icons.shield_outlined,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSpam ? 'SPAM / BLOQUEADO' : (isVerified ? 'VERIFIED BUSINESS' : 'LIMPIO'),
                      style: AppTypography.badgeText.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              Text(
                'Spam Score: ${(spamScore * 100).toInt()}%',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            displayName,
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22,
              color: isSpam ? Colors.white70 : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text('+$e164 ($ccode)', style: AppTypography.monoNumber.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          // Graduated confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: confidenceColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: confidenceColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(confidenceIcon, size: 14, color: confidenceColor),
                const SizedBox(width: 6),
                Text(
                  confidenceBadgeText,
                  style: TextStyle(
                    color: confidenceColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (rawName != null && nameConfidence > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${(nameConfidence * 100).toInt()}% conf.',
                    style: TextStyle(
                      color: confidenceColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (confidenceNote != null) ...[
            const SizedBox(height: 6),
            Text(
              confidenceNote,
              style: TextStyle(color: confidenceColor.withValues(alpha: 0.7), fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricChip(Icons.category_outlined, 'Category', category.toUpperCase()),
              const SizedBox(width: 12),
              _buildMetricChip(Icons.report_outlined, 'Reports', '$reports reports'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: NeonGlowButton(
                  text: 'Report Spam',
                  glowColor: GlassColors.severeScam,
                  height: 46,
                  onPressed: () => _showReportDialog(e164, ccode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GlassColors.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlassColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GlassColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: $value', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.perm_phone_msg_outlined, size: 64, color: GlassColors.neonCyan.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text('Look Up Any Number', style: AppTypography.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Search global community records, verified business directories, and spam defense reports.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
