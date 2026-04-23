import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/financial_goal.dart';
import 'ai_service.dart';
import '../../shared/widgets/premium_glass_card.dart';
import '../../l10n/app_localizations.dart';
import 'optimization_providers.dart';

class AnalysisDetailScreen extends StatefulWidget {
  final FinancialGoal goal;
  const AnalysisDetailScreen({super.key, required this.goal});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'tr_TR');
  late AnalysisResult _result;
  bool? _userApproval;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _userApproval = widget.goal.userApproved;
    _parseData();
  }

  void _parseData() {
    if (widget.goal.analysisRawData == null) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final data = jsonDecode(widget.goal.analysisRawData!);
      final snapData = data['snapshot'];
      final optData = data['optimization'];

      final snapshot = AnalysisSnapshot(
        currentBalance: (snapData['currentBalance'] as num).toDouble(),
        targetAmount: (snapData['targetAmount'] as num).toDouble(),
        gap: (snapData['gap'] as num).toDouble(),
        monthlyIncome: (snapData['monthlyIncome'] as num).toDouble(),
        monthlyExpense: (snapData['monthlyExpense'] as num).toDouble(),
        monthlySurplus: (snapData['monthlySurplus'] as num).toDouble(),
        months: snapData['months'],
        requiredMonthlySaving: (snapData['requiredMonthlySaving'] as num)
            .toDouble(),
        isAlreadyOnTrack: snapData['isAlreadyOnTrack'],
      );

      OptimizationResult? opt;
      if (optData != null) {
        opt = OptimizationResult(
          coachMessage: optData['coachMessage'],
          isFeasible: optData['isFeasible'] ?? true,
          cuts: (optData['cuts'] as List)
              .map(
                (c) => CutSuggestion(
                  category: c['category'],
                  currentAmount: (c['currentAmount'] as num).toDouble(),
                  suggestedAmount: (c['suggestedAmount'] as num).toDouble(),
                  saving: (c['saving'] as num).toDouble(),
                  reason: c['reason'],
                ),
              )
              .toList(),
        );
      }

      _result = AnalysisResult(
        snapshot: snapshot,
        optimizationResult: opt,
        persona: data['persona'],
        usedAi: data['usedAi'] ?? false,
      );
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _submitFeedback(bool approved) async {
    setState(() => _userApproval = approved);
    final goal = await DatabaseService.getGoal(widget.goal.id);
    if (goal == null) return;
    goal
      ..userApproved = approved
      ..rejectedCategories = approved
          ? []
          : (_result.optimizationResult?.cuts.map((c) => c.category).toList() ??
                []);
    await DatabaseService.updateGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: _hasError
          ? _buildErrorState(l10n)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverHeader(l10n, isDark),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatusSectionFluid(_result.snapshot, l10n),
                      const SizedBox(height: 32),
                      if (_result.optimizationResult != null) ...[
                        _buildOptimizationSectionFluid(
                          _result.optimizationResult!,
                          l10n,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_userApproval == null)
                        _buildFeedbackSectionFluid(l10n)
                      else
                        _buildApprovalConfirmedFluid(l10n),
                      const SizedBox(height: 60),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.getError(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.error.toUpperCase(),
            style: TextStyle(
              color: AppColors.getError(context),
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Bu analize ait veri bulunamadı veya bozulmuş.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(AppLocalizations l10n, bool isDark) {
    final double safeTop = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentH = constraints.biggest.height;
          final double minH = kToolbarHeight + safeTop;
          final double t = ((currentH - minH) / (200 + safeTop - minH)).clamp(
            0.0,
            1.0,
          );
          final double revT = 1.0 - t;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: revT * 20, sigmaY: revT * 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.getBackground(
                    context,
                  ).withValues(alpha: revT * 0.15),
                  border: Border(
                    bottom: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: revT > 0.95 ? (revT - 0.95) * 2 : 0.0,
                      ),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient background (Expanded only)
                    Positioned.fill(
                      child: Opacity(
                        opacity: t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.getPrimary(
                                  context,
                                ).withValues(alpha: 0.1),
                                AppColors.getSecondary(
                                  context,
                                ).withValues(alpha: 0.03),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Title Morphing
                    Positioned(
                      top: safeTop + (kToolbarHeight - 20) / 2 + (t * 70),
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Text(
                          l10n.analysisResult.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0 + (t * 2),
                          ),
                        ),
                      ),
                    ),

                    // Left Chip
                    Positioned(
                      top: safeTop + (kToolbarHeight - 20) / 2 + (t * 115),
                      right:
                          MediaQuery.of(context).size.width / 2 +
                          (t * 6) +
                          ((1.0 - t) * 40),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (t * 2 - 0.5).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.8 + (t * 0.2),
                            child: Transform.rotate(
                              angle: -0.05 * (1.0 - t),
                              child: _headerInfoChip(
                                icon: Icons.flag_circle_rounded,
                                label:
                                    '₺${_currencyFormat.format(widget.goal.targetAmount.toInt())}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Chip
                    Positioned(
                      top: safeTop + (kToolbarHeight - 20) / 2 + (t * 115),
                      left:
                          MediaQuery.of(context).size.width / 2 +
                          (t * 6) +
                          ((1.0 - t) * 40),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (t * 2 - 0.5).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.8 + (t * 0.2),
                            child: Transform.rotate(
                              angle: 0.05 * (1.0 - t),
                              child: _headerInfoChip(
                                icon: Icons.calendar_month_rounded,
                                label: widget.goal.targetDate != null
                                    ? DateFormat(
                                        'MMM yyyy',
                                      ).format(widget.goal.targetDate!)
                                    : "Süresiz",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Back Button
                    Positioned(
                      top: safeTop + 4,
                      left: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.getPrimary(
                                  context,
                                ).withValues(alpha: 0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _headerInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.getPrimary(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSectionFluid(AnalysisSnapshot s, AppLocalizations l10n) {
    final onTrack = s.isAlreadyOnTrack;
    final healthScore = onTrack
        ? 1.0
        : (s.monthlySurplus / s.requiredMonthlySaving).clamp(0.0, 1.0);

    return Column(
      children: [
        const SizedBox(height: 20), // Extra space to prevent cropping
        _buildExecutiveScoreFluid(healthScore, onTrack, l10n),
        const SizedBox(height: 40),
        Text(
          onTrack ? l10n.onTrackMessage : l10n.savingsNeeded,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 40),

        // Metrics Row - Engraved look
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              _vipMetricFluid(
                l10n.targetGap,
                _currencyFormat.format(s.gap.toInt()),
                Icons.flag_circle_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.getTextSecondary(
                  context,
                ).withValues(alpha: 0.1),
              ),
              _vipMetricFluid(
                l10n.remainingTime,
                l10n.monthsToTargetLabel(s.months),
                Icons.timelapse_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Main Value Display - Engraved look
        Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color:
                    (onTrack
                            ? AppColors.getSuccess(context)
                            : AppColors.getError(context))
                        .withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                onTrack ? l10n.currentSurplus : l10n.requiredMonthlySavings,
                style: TextStyle(
                  color: AppColors.getTextSecondary(
                    context,
                  ).withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₺',
                    style: TextStyle(
                      color: onTrack
                          ? AppColors.getSuccess(context)
                          : AppColors.getError(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currencyFormat.format(
                      onTrack
                          ? s.monthlySurplus.toInt()
                          : s.requiredMonthlySaving.toInt(),
                    ),
                    style: TextStyle(
                      color: onTrack
                          ? AppColors.getSuccess(context)
                          : AppColors.getError(context),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (!onTrack) ...[
          const SizedBox(height: 40),
          _buildSavingsBridgeFluid(s, l10n),
        ],
      ],
    );
  }

  Widget _buildExecutiveScoreFluid(
    double score,
    bool onTrack,
    AppLocalizations l10n,
  ) {
    final color = onTrack
        ? AppColors.getSuccess(context)
        : (score < 0.4
              ? AppColors.getError(context)
              : AppColors.getPrimary(context));
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Shadow for "Engraved" look
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(4, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          width: 150,
          child: CircularProgressIndicator(
            value: score,
            strokeWidth: 12,
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(score * 100).toInt()}',
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            Text(
              l10n.score.toUpperCase(),
              style: TextStyle(
                color: AppColors.getTextSecondary(
                  context,
                ).withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vipMetricFluid(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: AppColors.getPrimary(context).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsBridgeFluid(AnalysisSnapshot s, AppLocalizations l10n) {
    final totalRequired = s.requiredMonthlySaving;
    final currentSurplus = s.monthlySurplus;
    final aiSuggestions =
        _result.optimizationResult?.cuts.fold(
          0.0,
          (sum, c) => sum + c.saving,
        ) ??
        0.0;
    final surplusPct = (currentSurplus / totalRequired).clamp(0.0, 1.0);
    final aiPct = (aiSuggestions / totalRequired).clamp(0.0, 1.0 - surplusPct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TASARRUF PLANI',
              style: TextStyle(
                color: AppColors.getTextSecondary(
                  context,
                ).withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              '%${((surplusPct + aiPct) * 100).toInt()} TAMAM',
              style: TextStyle(
                color: AppColors.getPrimary(context),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 20,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                if (surplusPct > 0)
                  Expanded(
                    flex: (surplusPct * 1000).toInt(),
                    child: Container(color: AppColors.getPrimary(context)),
                  ),
                if (aiPct > 0)
                  Expanded(
                    flex: (aiPct * 1000).toInt(),
                    child: Container(color: AppColors.getSecondary(context)),
                  ),
                Expanded(
                  flex: ((1.0 - surplusPct - aiPct) * 1000).toInt().clamp(
                    0,
                    1000,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationSectionFluid(
    OptimizationResult opt,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumGlassCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppColors.getSecondary(context),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiCoachSuggestion.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.getSecondary(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      opt.coachMessage,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...opt.cuts.map((cut) => _buildCutRowFluid(cut, l10n)),
      ],
    );
  }

  Widget _buildCutRowFluid(CutSuggestion cut, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cut.category,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cut.reason,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(
                        context,
                      ).withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${_currencyFormat.format(cut.suggestedAmount.toInt())}',
                  style: TextStyle(
                    color: AppColors.getPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '← ₺${_currencyFormat.format(cut.currentAmount.toInt())}',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(
                      context,
                    ).withValues(alpha: 0.5),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSectionFluid(AppLocalizations l10n) {
    return PremiumGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Text(
            l10n.doYouLikeThisSuggestion,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(context).withValues(alpha: 0.7),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Negative - Left, borderless, very subtle
              Expanded(
                child: _elegantTactileButton(
                  label: l10n.no,
                  isPrimary: false,
                  onTap: () => _submitFeedback(false),
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(width: 12),
              // Positive - Right, soft glass look
              Expanded(
                child: _elegantTactileButton(
                  label: l10n.yes,
                  isPrimary: true,
                  onTap: () => _submitFeedback(true),
                  color: AppColors.getPrimary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _elegantTactileButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isPrimary,
  }) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setBtnState) {
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => isPressed = true),
          onTapUp: (_) => setBtnState(() => isPressed = false),
          onTapCancel: () => setBtnState(() => isPressed = false),
          onTap: onTap,
          child: AnimatedScale(
            scale: isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isPressed 
                    ? (isPrimary ? color : Colors.white).withValues(alpha: 0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isPrimary 
                        ? color.withValues(alpha: 0.9) 
                        : AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovalConfirmedFluid(AppLocalizations l10n) {
    final approved = _userApproval == true;
    return PremiumGlassCard(
      color:
          (approved
                  ? AppColors.getSuccess(context)
                  : AppColors.getError(context))
              .withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(
            approved ? Icons.check_circle : Icons.cancel,
            color: approved
                ? AppColors.getSuccess(context)
                : AppColors.getError(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              approved ? l10n.financialIdentityUpdated : l10n.feedbackMemoized,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
