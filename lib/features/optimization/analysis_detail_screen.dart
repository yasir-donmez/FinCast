import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/financial_goal.dart';
import '../../shared/widgets/fluid_container.dart';
import '../../shared/widgets/fluid_button.dart';
import '../../l10n/app_localizations.dart';
import 'optimization_providers.dart';
import 'ai_service.dart';

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

  @override
  void initState() {
    super.initState();
    _userApproval = widget.goal.userApproved;
    _parseData();
  }

  void _parseData() {
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
      requiredMonthlySaving: (snapData['requiredMonthlySaving'] as num).toDouble(),
      isAlreadyOnTrack: snapData['isAlreadyOnTrack'],
    );

    OptimizationResult? opt;
    if (optData != null) {
      opt = OptimizationResult(
        coachMessage: optData['coachMessage'],
        isFeasible: optData['isFeasible'] ?? true,
        cuts: (optData['cuts'] as List).map((c) => CutSuggestion(
          category: c['category'],
          currentAmount: (c['currentAmount'] as num).toDouble(),
          suggestedAmount: (c['suggestedAmount'] as num).toDouble(),
          saving: (c['saving'] as num).toDouble(),
          reason: c['reason'],
        )).toList(),
      );
    }

    _result = AnalysisResult(
      snapshot: snapshot,
      optimizationResult: opt,
      persona: data['persona'],
      usedAi: data['usedAi'] ?? false,
    );
  }

  Future<void> _submitFeedback(bool approved) async {
    setState(() => _userApproval = approved);
    final goal = await DatabaseService.getGoal(widget.goal.id);
    if (goal == null) return;
    goal
      ..userApproved = approved
      ..rejectedCategories = approved
          ? []
          : (_result.optimizationResult?.cuts.map((c) => c.category).toList() ?? []);
    await DatabaseService.updateGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.analysisResult.toUpperCase(),
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatusCardFluid(_result.snapshot, l10n),
          const SizedBox(height: 24),
          if (_result.optimizationResult != null) ...[
            _buildOptimizationSectionFluid(_result.optimizationResult!, l10n),
            const SizedBox(height: 24),
          ],
          if (_userApproval == null) 
            _buildFeedbackSectionFluid(l10n) 
          else 
            _buildApprovalConfirmedFluid(l10n),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCardFluid(AnalysisSnapshot s, AppLocalizations l10n) {
    final onTrack = s.isAlreadyOnTrack;
    final healthScore = onTrack ? 1.0 : (s.monthlySurplus / s.requiredMonthlySaving).clamp(0.0, 1.0);

    return FluidContainer(
      padding: const EdgeInsets.all(24),
      isGlass: true,
      borderRadius: 32,
      child: Column(
        children: [
          _buildExecutiveScoreFluid(healthScore, onTrack, l10n),
          const SizedBox(height: 28),
          Text(
            onTrack ? l10n.excellent.toUpperCase() : l10n.analysisResult.toUpperCase(), 
            style: TextStyle(
              color: onTrack ? AppColors.getSuccess(context) : AppColors.getPrimary(context), 
              fontSize: 11, 
              fontWeight: FontWeight.w800, 
              letterSpacing: 2.0
            )
          ),
          const SizedBox(height: 10),
          Text(
            onTrack ? l10n.onTrackMessage : l10n.savingsNeeded, 
            textAlign: TextAlign.center, 
            style: TextStyle(
              color: AppColors.getTextPrimary(context), 
              fontSize: 20, 
              fontWeight: FontWeight.w800, 
              letterSpacing: -0.5
            )
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.getInnerSurface(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _vipMetricFluid(l10n.targetGap, _currencyFormat.format(s.gap.toInt()), Icons.flag_circle_rounded),
                Container(width: 1, height: 30, color: AppColors.getTextSecondary(context).withValues(alpha: 0.1)),
                _vipMetricFluid(l10n.remainingTime, l10n.monthsToTargetLabel(s.months), Icons.timelapse_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (onTrack ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.08),
                  (onTrack ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (onTrack ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Text(
                  onTrack ? l10n.currentSurplus : l10n.requiredMonthlySavings, 
                  style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('₺', style: TextStyle(color: onTrack ? AppColors.getSuccess(context) : AppColors.getError(context), fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text(
                      _currencyFormat.format(onTrack ? s.monthlySurplus.toInt() : s.requiredMonthlySaving.toInt()), 
                      style: TextStyle(color: onTrack ? AppColors.getSuccess(context) : AppColors.getError(context), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.0)
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!onTrack) ...[const SizedBox(height: 32), _buildSavingsBridgeFluid(s, l10n)],
        ],
      ),
    );
  }

  Widget _buildExecutiveScoreFluid(double score, bool onTrack, AppLocalizations l10n) {
    final color = onTrack ? AppColors.getSuccess(context) : (score < 0.4 ? AppColors.getError(context) : AppColors.getPrimary(context));
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5)])),
        SizedBox(height: 150, width: 150, child: CircularProgressIndicator(value: score, strokeWidth: 10, backgroundColor: AppColors.getInnerSurface(context).withValues(alpha: 0.5), color: color, strokeCap: StrokeCap.round)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(score * 100).toInt()}', style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1)),
            Text(l10n.score.toUpperCase(), style: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ],
        ),
      ],
    );
  }

  Widget _vipMetricFluid(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.getPrimary(context).withValues(alpha: 0.8)),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSavingsBridgeFluid(AnalysisSnapshot s, AppLocalizations l10n) {
    final totalRequired = s.requiredMonthlySaving;
    final currentSurplus = s.monthlySurplus;
    final aiSuggestions = _result.optimizationResult?.cuts.fold(0.0, (sum, c) => sum + c.saving) ?? 0.0;
    final surplusPct = (currentSurplus / totalRequired).clamp(0.0, 1.0);
    final aiPct = (aiSuggestions / totalRequired).clamp(0.0, 1.0 - surplusPct);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TASARRUF PLANI', style: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('%${((surplusPct + aiPct) * 100).toInt()} TAMAM', style: TextStyle(color: AppColors.getPrimary(context), fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 16, width: double.infinity, color: AppColors.getInnerSurface(context),
            child: Row(
              children: [
                if (surplusPct > 0) Expanded(flex: (surplusPct * 1000).toInt(), child: Container(color: AppColors.getPrimary(context))),
                if (aiPct > 0) Expanded(flex: (aiPct * 1000).toInt(), child: Container(color: AppColors.getSecondary(context))),
                Expanded(flex: ((1.0 - surplusPct - aiPct) * 1000).toInt().clamp(0, 1000), child: const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationSectionFluid(OptimizationResult opt, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluidContainer(isGlass: true, padding: const EdgeInsets.all(20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.psychology_rounded, color: AppColors.getSecondary(context), size: 28), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.aiCoachSuggestion.toUpperCase(), style: TextStyle(color: AppColors.getSecondary(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(height: 8), Text(opt.coachMessage, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500))]))])),
        const SizedBox(height: 24),
        ...opt.cuts.map((cut) => _buildCutRowFluid(cut, l10n)),
      ],
    );
  }

  Widget _buildCutRowFluid(CutSuggestion cut, AppLocalizations l10n) {
    return Container(margin: const EdgeInsets.only(bottom: 16), child: FluidContainer(padding: const EdgeInsets.all(16), isConvex: false, child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cut.category, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(cut.reason, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12, fontStyle: FontStyle.italic))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('₺${_currencyFormat.format(cut.suggestedAmount.toInt())}', style: TextStyle(color: AppColors.getPrimary(context), fontSize: 16, fontWeight: FontWeight.w900)), Text('← ₺${_currencyFormat.format(cut.currentAmount.toInt())}', style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12, decoration: TextDecoration.lineThrough))])])));
  }

  Widget _buildFeedbackSectionFluid(AppLocalizations l10n) {
    return FluidContainer(padding: const EdgeInsets.all(20), child: Column(children: [Text(l10n.doYouLikeThisSuggestion, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [Expanded(child: FluidButton(onTap: () => _submitFeedback(true), color: AppColors.getPrimary(context).withValues(alpha: 0.2), child: Text(l10n.yesILikeIt, style: TextStyle(color: AppColors.getPrimary(context))))), const SizedBox(width: 12), Expanded(child: FluidButton(onTap: () => _submitFeedback(false), color: AppColors.getError(context).withValues(alpha: 0.2), child: Text(l10n.no, style: TextStyle(color: AppColors.getError(context)))))])]));
  }

  Widget _buildApprovalConfirmedFluid(AppLocalizations l10n) {
    final approved = _userApproval == true;
    return FluidContainer(color: (approved ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.1), child: Row(children: [Icon(approved ? Icons.check_circle : Icons.cancel, color: approved ? AppColors.getSuccess(context) : AppColors.getError(context)), const SizedBox(width: 12), Text(approved ? l10n.financialIdentityUpdated : l10n.feedbackMemoized)]));
  }
}
