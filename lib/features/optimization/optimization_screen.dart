import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/services.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/financial_goal.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';
import '../../shared/widgets/fluid_container.dart';
import '../../shared/widgets/fluid_button.dart';
import '../../shared/widgets/fluid_sheet.dart';
import 'optimization_providers.dart';
import 'ai_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/subscription_service.dart';
import '../subscription/widgets/pro_upgrade_sheet.dart';
import '../../shared/widgets/membership_orb.dart';

/// Hedef Odaklı Tasarruf Planlayıcı & AI Finansal Koç
class OptimizationScreen extends ConsumerStatefulWidget {
  const OptimizationScreen({super.key});

  @override
  ConsumerState<OptimizationScreen> createState() => _OptimizationScreenState();
}

class _OptimizationScreenState extends ConsumerState<OptimizationScreen>
    with TickerProviderStateMixin {
  // ── Hedef Kurulum Formu ──
  final _currencyFormat = NumberFormat('#,##0', 'tr_TR');
  double _targetAmount = 50000;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  int? _scopeVaultId;

  // ── Analiz Durumu ──
  bool _isAnalyzing = false;
  bool _showPreselect = false;
  AnalysisResult? _result;
  String? _personaText;
  bool _personaLoading = false;
  final Set<int> _userLockedIds = {};
  final Set<int> _userFlexibleIds = {};

  // ── Persona Onay + Geri Bildirim ──
  bool? _userApproval;
  int? _currentGoalId;

  // ── Geçmiş Genişletilebilir ──
  int? _expandedGoalId;

  // ── Animasyon Kontrolleri ──
  late final AnimationController _breatheController;
  late final Animation<double> _breatheAnim;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    
    _breatheAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _slideController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  bool get _aiAvailable => AiService.isAvailable;

  // ── Persona Üretme ──
  Future<void> _loadPersona(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
  ) async {
    if (!_aiAvailable) return;
    setState(() => _personaLoading = true);
    try {
      final text = await AiService.generatePersona(
        allTransactions: txs,
        vaults: vaults,
        previousGoals: goals,
      );
      if (mounted) setState(() => _personaText = text);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _personaLoading = false);
    }
  }

  // ── Analiz Başlat ──
  Future<void> _startAnalysis(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> previousGoals,
  ) async {
    final subscription = ref.read(subscriptionServiceProvider);
    
    if (!subscription.isPro) {
      if (mounted) ProUpgradeSheet.show(context);
      return;
    }

    if (subscription.usedAiCount >= subscription.dailyAiLimit) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Günlük AI analiz limitine ulaştınız (3/3).')),
        );
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _userApproval = null;
    });
    
    await subscription.incrementAiUsage();
    await _loadPersona(txs, vaults, previousGoals);

    final vetoList = previousGoals
        .where((g) => g.userApproved == false)
        .expand((g) => g.rejectedCategories)
        .toSet()
        .toList();

    final result = await OptimizationEngine.analyze(
      targetAmount: _targetAmount,
      targetDate: _targetDate,
      scopeVaultId: _scopeVaultId,
      allTransactions: txs,
      allVaults: vaults,
      userLockedIds: _userLockedIds,
      userFlexibleIds: _userFlexibleIds,
      vetoedCategories: vetoList,
      previousGoals: previousGoals,
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
      _slideController.forward(from: 0);
      await _saveGoalDraft(result);
    }
  }

  Future<void> _saveGoalDraft(AnalysisResult result) async {
    final goal = FinancialGoal()
      ..targetAmount = _targetAmount
      ..targetDate = _targetDate
      ..vaultId = _scopeVaultId
      ..createdAt = DateTime.now()
      ..aiPersonaText = _personaText
      ..aiStrategyText = result.optimizationResult?.coachMessage
      ..userApproved = null
      ..rejectedCategories = [];

    final id = await DatabaseService.addGoal(goal);
    _currentGoalId = id;
    final all = await DatabaseService.getAllGoals();
    if (all.length > 3) await DatabaseService.deleteGoal(all.last.id);
  }

  Future<void> _submitFeedback(
    bool approved,
    List<FinancialGoal> prevGoals,
  ) async {
    if (_result == null || _currentGoalId == null) return;
    setState(() => _userApproval = approved);
    final goal = await DatabaseService.getGoal(_currentGoalId!);
    if (goal == null) return;
    goal
      ..aiPersonaText = approved ? _personaText : null
      ..userApproved = approved
      ..rejectedCategories = approved
          ? []
          : (_result!.optimizationResult?.cuts
                    .map((c) => c.category)
                    .toList() ??
                []);
    await DatabaseService.updateGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(activeTransactionsProvider);
    final vaultsAsync = ref.watch(vaultsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return Stack(
      children: [
        _FluidBackground(animation: _bgAnimationController),
        txsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (txs) => vaultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (vaults) => goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.error}: $e')),
              data: (goals) => _buildContent(txs, vaults, goals, AppLocalizations.of(context)!),
            ),
          ),
        ),
      ],
    );
  }

  /// Computes intelligent base/max limits from real financial data.
  /// baseValue = what the user reaches with ZERO effort (current trajectory).
  /// maxValue = theoretical ceiling if expenses minimized & income grows ~50%.
  ({double baseValue, double maxValue}) _computeDialLimits(
    List<TransactionRecord> txs,
    List<Vault> vaults,
  ) {
    final now = DateTime.now();
    final monthsToTarget =
        ((_targetDate.year - now.year) * 12 + (_targetDate.month - now.month)).clamp(1, 999);

    // Scope transactions to the selected vault (or all)
    final scopedTxs = _scopeVaultId == null
        ? txs
        : txs.where((t) => t.vaultIds.contains(_scopeVaultId)).toList();

    // 1. Calculate History-Based Monthly Averages (Fallback if no recurring txs)
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    final historyTxs = scopedTxs.where((t) => t.date.isAfter(sixtyDaysAgo)).toList();
    
    double histMonthlyIncome = 0;
    double histMonthlyExpense = 0;
    
    if (historyTxs.isNotEmpty) {
      final firstDate = historyTxs.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final daysInRange = now.difference(firstDate).inDays.clamp(1, 60);
      
      final totalIncome = historyTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final totalExpense = historyTxs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
      
      histMonthlyIncome = (totalIncome / daysInRange) * 30;
      histMonthlyExpense = (totalExpense / daysInRange) * 30;
    }

    // Current vault balance
    double currentBalance;
    if (_scopeVaultId == null) {
      currentBalance = vaults.where((v) => v.isIncludedInTotal).fold(0.0, (s, v) => s + v.balance);
    } else {
      currentBalance = vaults.firstWhere((v) => v.id == _scopeVaultId, orElse: () => Vault()..balance = 0).balance;
    }

    // 2. Monthly income & expense from recurring transactions
    final recurring = scopedTxs.where((t) => t.periodType != 0 && !t.isArchived).toList();
    double recurringIncome = recurring
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.monthlyEquivalent);
    double recurringExpense = recurring
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.monthlyEquivalent);

    // Use the maximum of recurring or historical for a more realistic baseline
    final effectiveIncome = math.max(recurringIncome, histMonthlyIncome);
    final effectiveExpense = math.max(recurringExpense, histMonthlyExpense);

    // Minimum essential expenses (only locked/mandatory items)
    final minExpense = recurring
        .where((t) => !t.isIncome && t.isLocked)
        .fold(0.0, (s, t) => s + t.monthlyEquivalent);

    // BASE: Current balance + months × current net surplus (do nothing)
    final monthlySurplus = effectiveIncome - effectiveExpense;
    final baseValue = (currentBalance + monthsToTarget * monthlySurplus).clamp(0.0, double.infinity);

    // MAX: Current balance + months × (income×1.5 − only locked expenses)
    // Income grows realistically (~50% over period), discretionary expenses eliminated
    final optimisticIncome = effectiveIncome * 1.5;
    final maxMonthlySaving = optimisticIncome - minExpense;
    
    // Calculate a dynamic ceiling that avoids being too small
    final calculatedMax = currentBalance + monthsToTarget * maxMonthlySaving;
    final safeMax = math.max(calculatedMax, math.max(currentBalance * 2.5, 100000.0));
    final maxValue = safeMax.clamp(baseValue + 1000, 2000000.0);

    return (
      baseValue: baseValue.clamp(0, 2000000).toDouble(),
      maxValue: maxValue.toDouble(),
    );
  }

  Widget _buildContent(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
    AppLocalizations l10n,
  ) {
    final limits = _computeDialLimits(txs, vaults);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _buildPersonaHeader(goals, l10n),
                const SizedBox(height: 24),
                if (_showPreselect) ...[
                  _buildPreselectPanelFluid(txs, l10n),
                  const SizedBox(height: 24),
                ],
                if (_isAnalyzing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: _ThinkingOrb(breathe: _breatheAnim),
                    ),
                  ),
                if (_result != null) ...[
                  SlideTransition(
                    position: _slideAnim,
                    child: _buildResults(_result!, txs, vaults, goals, l10n),
                  ),
                ],
                if (goals.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  _buildHistoryFluid(goals, l10n),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),

          // THE PREMIUM COCKPIT — All-in-one Control Center
          _AnalysisCockpit(
            targetAmount: _targetAmount,
            isAnalyzing: _isAnalyzing,
            onAmountChanged: (val) => setState(() => _targetAmount = val),
            onAnalyzeTap: () => _startAnalysis(txs, vaults, goals),
            targetDate: _targetDate,
            vaultName: _scopeVaultId == null 
                ? l10n.allVaults 
                : vaults.firstWhere((v) => v.id == _scopeVaultId).name,
            onDateTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now().add(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => _targetDate = picked);
            },
            onVaultTap: () => _showVaultPicker(vaults, l10n),
            onTuneTap: () => setState(() => _showPreselect = !_showPreselect),
            showPreselect: _showPreselect,
            baseValue: limits.baseValue,
            maxValue: limits.maxValue,
            onResetTap: () => setState(() => _targetAmount = limits.baseValue),
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaHeader(List<FinancialGoal> goals, AppLocalizations l10n) {
    final savedPersona = goals.firstOrNull?.aiPersonaText;
    final displayText = _personaText ?? savedPersona;

    return FluidContainer(
      padding: const EdgeInsets.all(20),
      isGlass: true,
      isConvex: false,
      blur: 20,
      borderRadius: AppSizes.radiusLarge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MembershipOrb(
            color: AppColors.getPrimary(context),
            size: 52,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _personaLoading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.analyzingFinancialIdentity,
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          color: AppColors.getSecondary(context),
                          backgroundColor: AppColors.getInnerSurface(context),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.financialIdentity.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.getSecondary(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayText ?? l10n.financialIdentityHint,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showVaultPicker(List<Vault> vaults, AppLocalizations l10n) {
    FluidSheet.show(
      context: context,
      title: l10n.scopeLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.allVaults, style: const TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(Icons.all_inclusive, color: AppColors.getPrimary(context)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () {
              setState(() => _scopeVaultId = null);
              Navigator.pop(context);
            },
          ),
          ...vaults.map((v) => ListTile(
            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(Icons.account_balance_wallet_rounded, color: AppColors.getPrimary(context)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () {
              setState(() => _scopeVaultId = v.id);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildPreselectPanelFluid(List<TransactionRecord> txs, AppLocalizations l10n) {
    final now = DateTime.now();
    final monthsToTarget =
        (_targetDate.year - now.year) * 12 + (_targetDate.month - now.month);
    final scopedTxs = _scopeVaultId == null
        ? txs
        : txs.where((t) => t.vaultIds.contains(_scopeVaultId)).toList();

    final relevant = scopedTxs.where((t) => t.periodType != 0).toList();
    final allRelevant = relevant;

    return FluidContainer(
      isConvex: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.items, Icons.tune_rounded),
          const SizedBox(height: 12),
          if (allRelevant.isEmpty)
            Center(
              child: Text(
                l10n.noItemsToAnalyze,
                style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13),
              ),
            )
          else ...[
            Text(
              l10n.itemsToAnalyze(allRelevant.length, monthsToTarget),
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...allRelevant.map((tx) => _preselectRowFluid(tx, l10n)),
          ],
        ],
      ),
    );
  }

  Widget _preselectRowFluid(TransactionRecord tx, AppLocalizations l10n) {
    final isLocked = _userLockedIds.contains(tx.id);
    final isFlexible = _userFlexibleIds.contains(tx.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getInnerSurface(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_currencyFormat.format(tx.amount.toInt())} ₺',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _chipButtonFluid(
            label: l10n.doNotTouch,
            icon: Icons.lock_rounded,
            active: isLocked,
            activeColor: AppColors.getError(context),
            onTap: () => setState(() {
              if (isLocked) {
                _userLockedIds.remove(tx.id);
              } else {
                _userLockedIds.add(tx.id);
                _userFlexibleIds.remove(tx.id);
              }
            }),
          ),
          const SizedBox(width: 8),
          _chipButtonFluid(
            label: l10n.changeable,
            icon: Icons.auto_fix_high_rounded,
            active: isFlexible,
            activeColor: AppColors.getPrimary(context),
            onTap: () => setState(() {
              if (isFlexible) {
                _userFlexibleIds.remove(tx.id);
              } else {
                _userFlexibleIds.add(tx.id);
                _userLockedIds.remove(tx.id);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _chipButtonFluid({
    required String label,
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : AppColors.getTextSecondary(context).withValues(alpha: 0.3),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? activeColor : AppColors.getTextSecondary(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? activeColor : AppColors.getTextSecondary(context),
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildAnalyzeButtonFluid kaldırıldı, Cockpit içinde _FinancialReactorButton kullanılıyor.

  Widget _buildHistoryFluid(List<FinancialGoal> goals, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.recentAnalyses, Icons.history_rounded),
        const SizedBox(height: 16),
        ...goals.map((g) => _buildHistoryCardFluid(g, l10n)),
      ],
    );
  }

  Widget _buildHistoryCardFluid(FinancialGoal g, AppLocalizations l10n) {
    final isExpanded = _expandedGoalId == g.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FluidContainer(
        isGlass: true,
        isConvex: isExpanded,
        padding: EdgeInsets.zero,
        borderRadius: AppSizes.radiusDefault,
        child: InkWell(
          onTap: () => setState(() => _expandedGoalId = isExpanded ? null : g.id),
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.insights_rounded, color: AppColors.getPrimary(context), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₺${_currencyFormat.format(g.targetAmount.toInt())}', style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(DateFormat('dd MMM yyyy HH:mm').format(g.createdAt), style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.getTextSecondary(context)),
                  ],
                ),
              ),
              if (isExpanded && g.aiStrategyText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(g.aiStrategyText!, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13, height: 1.5)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AnalysisResult result, List<TransactionRecord> txs, List<Vault> vaults, List<FinancialGoal> goals, AppLocalizations l10n) {
    final s = result.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusCardFluid(s, l10n),
        const SizedBox(height: 24),
        if (!result.usedAi && result.aiError != null) ...[
          _aiBannerFluid(result.aiError!, l10n),
          const SizedBox(height: 16),
        ],
        if (!s.isAlreadyOnTrack && result.optimizationResult != null) ...[
          _buildOptimizationSectionFluid(result.optimizationResult!, l10n),
          const SizedBox(height: 24),
        ],
        if (_userApproval == null) _buildFeedbackSectionFluid(goals, l10n) else _buildApprovalConfirmedFluid(l10n),
      ],
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
          const SizedBox(height: 24),
          Text(onTrack ? l10n.excellent : l10n.analysisResult, style: TextStyle(color: onTrack ? AppColors.getSuccess(context) : AppColors.getPrimary(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(onTrack ? l10n.onTrackMessage : l10n.savingsNeeded, textAlign: TextAlign.center, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 32),
          Row(
            children: [
              _vipMetricFluid(l10n.targetGap, _currencyFormat.format(s.gap.toInt()), Icons.flag_rounded),
              _vipMetricFluid(l10n.remainingTime, l10n.monthsToTargetLabel(s.months), Icons.calendar_month_rounded),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.getInnerSurface(context).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: (onTrack ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.2))),
            child: Column(
              children: [
                Text(onTrack ? l10n.currentSurplus : l10n.requiredMonthlySavings, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('₺${_currencyFormat.format(onTrack ? s.monthlySurplus.toInt() : s.requiredMonthlySaving.toInt())}', style: TextStyle(color: onTrack ? AppColors.getSuccess(context) : AppColors.getError(context), fontSize: 34, fontWeight: FontWeight.w900)),
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
        SizedBox(height: 140, width: 140, child: CircularProgressIndicator(value: score, strokeWidth: 12, backgroundColor: AppColors.getInnerSurface(context), color: color, strokeCap: StrokeCap.round)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(score * 100).toInt()}', style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 38, fontWeight: FontWeight.w900)),
            Text(l10n.score.toUpperCase(), style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ],
        ),
      ],
    );
  }

  Widget _vipMetricFluid(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.getTextSecondary(context)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSavingsBridgeFluid(AnalysisSnapshot s, AppLocalizations l10n) {
    final totalRequired = s.requiredMonthlySaving;
    final currentSurplus = s.monthlySurplus;
    final aiSuggestions = _result?.optimizationResult?.cuts.fold(0.0, (sum, c) => sum + c.saving) ?? 0.0;
    final surplusPct = (currentSurplus / totalRequired).clamp(0.0, 1.0);
    final aiPct = (aiSuggestions / totalRequired).clamp(0.0, 1.0 - surplusPct);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TASARRUF PLANI', style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 14, width: double.infinity, color: AppColors.getInnerSurface(context),
            child: Row(
              children: [
                if (surplusPct > 0) Expanded(flex: (surplusPct * 100).toInt(), child: Container(color: AppColors.getPrimary(context))),
                if (aiPct > 0) Expanded(flex: (aiPct * 100).toInt(), child: Container(color: AppColors.getSecondary(context))),
                Expanded(flex: ((1.0 - surplusPct - aiPct) * 100).toInt().clamp(0, 100), child: const SizedBox.shrink()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _legendRowFluid(AppColors.getPrimary(context), l10n.currentSavings, currentSurplus),
        const SizedBox(height: 12),
        _legendRowFluid(AppColors.getSecondary(context), l10n.aiSavingsTarget, aiSuggestions),
      ],
    );
  }

  Widget _legendRowFluid(Color color, String label, double value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13))),
        Text('₺${_currencyFormat.format(value.toInt())}', style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _aiBannerFluid(String error, AppLocalizations l10n) {
    return FluidContainer(color: AppColors.getWarning(context).withValues(alpha: 0.1), child: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.getWarning(context)), const SizedBox(width: 12), Expanded(child: Text('AI Önerileri şu an yüklenemedi. Yerel algoritma devrede.', style: TextStyle(color: AppColors.getWarning(context), fontSize: 13)))]));
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

  Widget _buildFeedbackSectionFluid(List<FinancialGoal> goals, AppLocalizations l10n) {
    return FluidContainer(padding: const EdgeInsets.all(20), child: Column(children: [Text(l10n.doYouLikeThisSuggestion, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [Expanded(child: FluidButton(onTap: () => _submitFeedback(true, goals), color: AppColors.getPrimary(context).withValues(alpha: 0.2), child: Text(l10n.yesILikeIt, style: TextStyle(color: AppColors.getPrimary(context))))), const SizedBox(width: 12), Expanded(child: FluidButton(onTap: () => _submitFeedback(false, goals), color: AppColors.getError(context).withValues(alpha: 0.2), child: Text(l10n.no, style: TextStyle(color: AppColors.getError(context)))))])]));
  }

  Widget _buildApprovalConfirmedFluid(AppLocalizations l10n) {
    final approved = _userApproval == true;
    return FluidContainer(color: (approved ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.1), child: Row(children: [Icon(approved ? Icons.check_circle : Icons.cancel, color: approved ? AppColors.getSuccess(context) : AppColors.getError(context)), const SizedBox(width: 12), Text(approved ? l10n.financialIdentityUpdated : l10n.feedbackMemoized)]));
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(children: [Icon(icon, color: AppColors.getPrimary(context), size: 20), const SizedBox(width: 10), Text(text.toUpperCase(), style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5))]);
  }
}

// ────────────────────────────────────────────────────────────────
// THE PREMIUM COCKPIT — All-in-one Control Center
// ────────────────────────────────────────────────────────────────

class _AnalysisCockpit extends StatelessWidget {
  final double targetAmount;
  final bool isAnalyzing;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onAnalyzeTap;
  final DateTime targetDate;
  final String vaultName;
  final VoidCallback onDateTap;
  final VoidCallback onVaultTap;
  final VoidCallback onTuneTap;
  final bool showPreselect;
  final double baseValue;
  final double maxValue;
  final VoidCallback onResetTap;
  final AppLocalizations l10n;

  const _AnalysisCockpit({
    required this.targetAmount,
    required this.isAnalyzing,
    required this.onAmountChanged,
    required this.onAnalyzeTap,
    required this.targetDate,
    required this.vaultName,
    required this.onDateTap,
    required this.onVaultTap,
    required this.onTuneTap,
    required this.showPreselect,
    required this.baseValue,
    required this.maxValue,
    required this.onResetTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'tr_TR');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.getBackground(context).withValues(alpha: 0.0),
            AppColors.getBackground(context).withValues(alpha: 0.95),
            AppColors.getBackground(context),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: FluidContainer(
        padding: const EdgeInsets.only(top: 20, bottom: 20, left: 16, right: 16),
        isGlass: true,
        borderRadius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. THE FLUTTER CIRCUIT PANEL (Left Aligned Top Layer)
                Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.getPrimary(context).withValues(alpha: 0.7), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: AppColors.getPrimary(context).withValues(alpha: 0.2), blurRadius: 10),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${currencyFormat.format(targetAmount.toInt())} ₺',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getTextPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.targetAmountLabel('').trim().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.getPrimary(context).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Reset Button (panelin yanında)
                GestureDetector(
                  onTap: onResetTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.getPrimary(context).withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.getPrimary(context)),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: _FinancialReactorButton(
                    isAnalyzing: isAnalyzing,
                    onTap: onAnalyzeTap,
                    label: l10n.analyze,
                  ),
                ),
              ],
            ),
            
            // Zero gap so the cable visually connects natively to the Flutter Panel
            const SizedBox(height: 0),
            
            SizedBox(
              height: 100,
              child: _InfiniteDialSelector(
                initialValue: targetAmount,
                onChanged: onAmountChanged,
                showPreselect: showPreselect,
                onTuneTap: onTuneTap,
                baseValue: baseValue,
                maxValue: maxValue,
              ),
            ),
            
            // Financial Horizon Summary (explicit proof of limits)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AUTO: ₺${currencyFormat.format(baseValue.toInt())}',
                    style: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  Text(
                    'HORIZON MAX: ₺${currencyFormat.format(maxValue.toInt())}',
                    style: TextStyle(color: AppColors.getPrimary(context).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _GlassChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('MMM yyyy').format(targetDate),
                    onTap: onDateTap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GlassChip(
                    icon: Icons.account_balance_wallet_rounded,
                    label: vaultName,
                    onTap: onVaultTap,
                  ),
                ),
                const SizedBox(width: 8),
                _GlassChip(
                  icon: showPreselect ? Icons.expand_less_rounded : Icons.tune_rounded,
                  label: '',
                  onTap: onTuneTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// INFINITE DIAL SELECTOR — "Premium Physical Control"
// ────────────────────────────────────────────────────────────────

class _InfiniteDialSelector extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;
  final bool showPreselect;
  final VoidCallback onTuneTap;
  final double baseValue;
  final double maxValue;

  const _InfiniteDialSelector({
    required this.initialValue,
    required this.onChanged,
    required this.showPreselect,
    required this.onTuneTap,
    required this.baseValue,
    required this.maxValue,
  });

  @override
  State<_InfiniteDialSelector> createState() => _InfiniteDialSelectorState();
}

class _InfiniteDialSelectorState extends State<_InfiniteDialSelector> with TickerProviderStateMixin {
  late double _currentValue;
  late final ScrollController _scrollController;
  int _lastTickHaptic = 0;
  
  late final AnimationController _scaleController;
  Timer? _autoScrollTimer;
  double _autoScrollSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    
    // We map 1,000 to an offset distance of 32.0 based on spacing.
    double initialOffset = (_currentValue / 1000) * 32.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _scrollController.addListener(_onScrolled);

    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  bool _isUserScrolling = false;

  @override
  void didUpdateWidget(covariant _InfiniteDialSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ONLY respond to EXTERNAL changes (reset button, vault change).
    // NEVER fight the user's active scrolling!
    if (!_isUserScrolling && (widget.initialValue - oldWidget.initialValue).abs() > 100) {
      final targetOffset = (widget.initialValue / 1000) * 32.0;
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, 2000 * 32.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startAutoScroll(bool isLeft) {
    if (_autoScrollTimer != null) return;
    
    HapticFeedback.heavyImpact(); // Immediate tactile cue that drive mode engaged
    
    _autoScrollSpeed = isLeft ? -2.0 : 2.0;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients) {
        _stopAutoScroll();
        return;
      }
      
      // Accelerate the scroll speed smoothly
      if (isLeft) {
        _autoScrollSpeed -= 1.2;
        if (_autoScrollSpeed < -120.0) _autoScrollSpeed = -120.0; // Max speed left
      } else {
        _autoScrollSpeed += 1.2;
        if (_autoScrollSpeed > 120.0) _autoScrollSpeed = 120.0; // Max speed right
      }
      
      double newOffset = _scrollController.offset + _autoScrollSpeed;
      if (newOffset < 0) newOffset = 0; 
      double maxOffset = 2000 * 32.0; // Always allow full 2M range
      if (newOffset > maxOffset) newOffset = maxOffset;
      
      _scrollController.jumpTo(newOffset);
    });
  }

  void _stopAutoScroll() {
    if (_autoScrollTimer != null) {
      _autoScrollTimer!.cancel();
      _autoScrollTimer = null;
      _autoScrollSpeed = 0.0;
      
      // Trigger magnetic snap manually after releasing auto-scroll
      if (!_scrollController.hasClients) return;
      final double currentOffset = _scrollController.offset;
      final double targetOffset = (currentOffset / 32.0).roundToDouble() * 32.0;
      if ((currentOffset - targetOffset).abs() > 0.5) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _onScrolled() {
    final double rawOffset = _scrollController.offset;
    final double scrollTicks = rawOffset / 32.0; 
    
    // Always trigger a rebuild for smooth custom paint
    setState(() {});
    
    final double newValue = (scrollTicks * 1000).clamp(0.0, widget.maxValue);
    
    if (newValue != _currentValue) {
      if ((newValue - _currentValue).abs() > 500) {
        _scaleController.forward(from: 0).then((_) => _scaleController.reverse());
      }
      
      _currentValue = newValue;
      widget.onChanged(newValue);
        
      int tick = (scrollTicks * 10).floor();
      if (tick != _lastTickHaptic) {
        _lastTickHaptic = tick;
        
        // Heavy haptic when hitting the wall
        bool isAtLimit = newValue <= 0.1 || newValue >= widget.maxValue - 0.1;
        if (isAtLimit) {
          HapticFeedback.heavyImpact();
        } else {
          if (tick % 10 == 0) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final double logicalOffset = _scrollController.hasClients ? (_scrollController.offset / 32.0) : (_currentValue / 1000);

    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.getInnerSurface(context).withValues(alpha: 0.3),
            ),
          ),
          // Dial Painter
          CustomPaint(
            size: const Size(double.infinity, 80),
            painter: _CylindricalDialPainter(
              scrollOffset: logicalOffset,
              color: AppColors.getPrimary(context),
              isDark: isDark,
              baseTick: (widget.baseValue / 1000).ceil(),
              maxTick: (widget.maxValue / 1000).ceil(),
            ),
          ),
          
          // PURE ListView — no wrappers, no gesture conflicts
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserScrolling = true;
              }
              if (notification is ScrollEndNotification) {
                _isUserScrolling = false;
                final currentOffset = _scrollController.offset;
                final targetOffset = (currentOffset / 32.0).roundToDouble() * 32.0;
                if ((currentOffset - targetOffset).abs() > 0.5) {
                  Future.microtask(() {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        targetOffset,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  });
                }
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // Add padding so first and last item can reach the center needle
              padding: EdgeInsets.symmetric(
                horizontal: (MediaQuery.of(context).size.width / 2) - 16.0,
              ),
              physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
              itemCount: (widget.maxValue / 1000).ceil() + 1,
              itemBuilder: (context, index) {
                return const SizedBox(width: 32.0, height: 80);
              },
            ),
          ),

          // ── LONG-PRESS DRIVE ZONES ──
          // Left Zone (Hold to fast-decrease)
          Positioned(
            left: 0, top: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.15, // Side rim
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPressStart: (_) => _startAutoScroll(true),
              onLongPressEnd: (_) => _stopAutoScroll(),
              onLongPressCancel: () => _stopAutoScroll(),
            ),
          ),

          // Right Zone (Hold to fast-increase)
          Positioned(
            right: 0, top: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.15, // Side rim
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPressStart: (_) => _startAutoScroll(false),
              onLongPressEnd: (_) => _stopAutoScroll(),
              onLongPressCancel: () => _stopAutoScroll(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CylindricalDialPainter extends CustomPainter {
  final double scrollOffset;
  final Color color;
  final bool isDark;
  final int baseTick;
  final int maxTick;

  _CylindricalDialPainter({
    required this.scrollOffset,
    required this.color,
    required this.isDark,
    required this.baseTick,
    required this.maxTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Core Dial Logic (Restored to exact Center)
    final double centerX = size.width / 2;
    
    final double radius = size.width / 1.1; // Wider sweep
    final double spacing = 32.0; 
    final int startTick = (scrollOffset - 30).floor();
    final int endTick = (scrollOffset + 15).ceil();

    // ── 0. ZONE BACKGROUNDS ──
    // Optional: could draw background glows for zones here.

    // ── 1. MOUNTING HARDWARE (Wire Cable coming from the SIDE of the Left Panel) ──
    final double panelRightEdge = 140.0; 
    final double panelCenterY = -24.0;
    final double needleBaseY = 2.0;

    final Paint wirePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final Path wirePath = Path();
    wirePath.moveTo(panelRightEdge, panelCenterY);
    wirePath.lineTo(centerX - 8, panelCenterY);
    wirePath.quadraticBezierTo(centerX, panelCenterY, centerX, panelCenterY + 8);
    wirePath.lineTo(centerX, needleBaseY);

    canvas.drawPath(wirePath, Paint()..color = color.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 5.0..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(wirePath, wirePaint);

    final Offset hingeCenter = Offset(centerX, needleBaseY);
    canvas.drawLine(Offset(centerX - 12, needleBaseY), Offset(centerX + 12, needleBaseY), Paint()..color=color.withValues(alpha: 0.5)..strokeWidth=2.0);
    
    canvas.drawCircle(hingeCenter, 4.0, Paint()..color = (isDark ? Colors.black : Colors.white)..style = PaintingStyle.fill);
    canvas.drawCircle(hingeCenter, 4.0, Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(hingeCenter, 1.5, Paint()..color = color);

    Path needlePath = Path();
    needlePath.moveTo(centerX - 3.5, needleBaseY + 4.0);
    needlePath.lineTo(centerX + 3.5, needleBaseY + 4.0);
    needlePath.lineTo(centerX + 0.5, needleBaseY + 10.0);
    needlePath.lineTo(centerX - 0.5, needleBaseY + 10.0);
    needlePath.close();

    canvas.drawPath(needlePath, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(needlePath, Paint()..color = color.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // ── 2. BOTTOM ALIGNED TICKS & LABELS ──
    for (int i = startTick; i <= endTick; i++) {
      if (i < 0 || i > maxTick) continue; // Strictly stop at the calculated max limit
      
      double worldOffset = (i - scrollOffset) * spacing;
      double angle = worldOffset / radius;
      
      if (angle > -math.pi / 2 && angle < math.pi / 2) {
        double x = centerX + radius * math.sin(angle);
        double cosAngle = math.cos(angle);
        
        double dist = (x - centerX).abs();
        double bulge = math.exp(-(dist * dist) / (40.0 * 40.0));

        double baseHeight = 12.0; 
        double strokeWidth = 1.0;
        double alphaBase = 0.2;

        bool isPrimary = i % 10 == 0;
        bool isSecondary = i % 5 == 0 && !isPrimary;

        if (isPrimary) {
          baseHeight = 26.0; 
          strokeWidth = 2.4;
          alphaBase = 0.5;
        } else if (isSecondary) {
          baseHeight = 18.0;
          strokeWidth = 1.6;
          alphaBase = 0.3;
        }

        double lineHeight = (baseHeight + (18.0 * bulge)) * math.pow(cosAngle, 1.2);
        double currentStroke = (strokeWidth + (1.2 * bulge)) * math.pow(cosAngle, 0.8);
        double opacity = (alphaBase + (0.5 * bulge)).clamp(0.0, 1.0) * math.pow(cosAngle, 3.0);

        if (opacity < 0.01) continue;

        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = currentStroke;

        double p2y = size.height; 
        double p1y = size.height - lineHeight; 

        // Zone-based Coloring
        Color tickColor;
        if (i <= baseTick) {
          // Zone 1: Current Trajectory (Dimmed)
          tickColor = color.withValues(alpha: 0.6);
        } else {
          // Zone 2-3: Linear range toward Max.
          // Danger zone starts after 90% of maxTick.
          double progressToMax = (i / maxTick).clamp(0.0, 1.0);
          if (progressToMax > 0.9) {
            double dangerFactor = (progressToMax - 0.9) / 0.1;
            tickColor = Color.lerp(color, const Color(0xFFFF3B30), 0.3 + (0.7 * dangerFactor))!;
          } else {
            tickColor = color;
          }
        }

        // 1. OYUK (INSET) SHADOW
        paint.color = (isDark ? Colors.black : Colors.black45).withValues(alpha: opacity * 0.6);
        canvas.drawLine(Offset(x + 1.0, p1y + 1.0), Offset(x + 1.0, p2y + 0.5), paint);

        // 2. MAIN TICK
        paint.color = tickColor.withValues(alpha: opacity);
        canvas.drawLine(Offset(x, p1y), Offset(x, p2y), paint);

        // 3. KENAR IŞIĞI (EDGE HIGHLIGHT)
        if (opacity > 0.15) {
          paint.color = Colors.white.withValues(alpha: (0.1 + (0.4 * bulge)) * opacity);
          paint.strokeWidth = currentStroke * 0.3;
          canvas.drawLine(Offset(x - 0.6, p1y + 0.3), Offset(x - 0.6, p2y), paint);
        }

        // 4. TEXT LABELS
        if ((isPrimary || isSecondary || i == baseTick || i == maxTick) && opacity > 0.4) {
          String labelText = i == 0 ? '0' : '${i}K';
          
          bool isVIPMatch = i == baseTick || i == maxTick;
          if (i == baseTick) labelText = i == 0 ? 'AUTO (0)' : 'AUTO';
          if (i == maxTick) labelText = 'MAX';
          
          final textPainter = TextPainter(
            text: TextSpan(
              text: labelText,
              style: TextStyle(
                color: tickColor.withValues(alpha: opacity * (isVIPMatch ? 1.0 : (0.6 + (0.4 * bulge)))),
                fontSize: isVIPMatch ? 10.0 : 9.0 + (3.0 * bulge),
                fontWeight: (bulge > 0.6 || isVIPMatch) ? FontWeight.w900 : FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          // Special VIP Marker Dot for BASE and MAX
          if (isVIPMatch && opacity > 0.1) {
             canvas.drawCircle(Offset(x, p1y - 6), 2.5, Paint()..color = tickColor.withValues(alpha: opacity)..style = PaintingStyle.fill);
             canvas.drawCircle(Offset(x, p1y - 6), 4.5, Paint()..color = tickColor.withValues(alpha: opacity * 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          }
          
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, p1y - 20 - (4 * bulge)),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CylindricalDialPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset || 
      oldDelegate.maxTick != maxTick ||
      oldDelegate.baseTick != baseTick;
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassChip({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 24,
        isGlass: true,
        isConvex: false,
        blur: 15,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.getPrimary(context)),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(context))),
            ],
          ],
        ),
      ),
    );
  }
}

class _FluidBackground extends StatelessWidget {
  final Animation<double> animation;
  const _FluidBackground({required this.animation});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(children: [
          Positioned(top: -100 + (math.sin(animation.value * 2 * math.pi) * 50), left: -50 + (math.cos(animation.value * 2 * math.pi) * 30), child: _Blob(color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.15), size: 300)),
          Positioned(bottom: -50 + (math.cos(animation.value * 2 * math.pi) * 40), right: -80 + (math.sin(animation.value * 2 * math.pi) * 60), child: _Blob(color: AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.12), size: 350)),
        ]);
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent))));
  }
}

class _ThinkingOrb extends StatelessWidget {
  final Animation<double> breathe;
  const _ThinkingOrb({required this.breathe});
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: breathe,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.primary, AppColors.secondary, Colors.transparent]), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5)]),
        child: const Center(child: Icon(Icons.psychology_rounded, color: Colors.white, size: 40)),
      ),
    );
  }
}

class _FinancialReactorButton extends ConsumerStatefulWidget {
  final bool isAnalyzing;
  final VoidCallback onTap;
  final String label;

  const _FinancialReactorButton({
    required this.isAnalyzing,
    required this.onTap,
    required this.label,
  });

  @override
  ConsumerState<_FinancialReactorButton> createState() => _FinancialReactorButtonState();
}

class _FinancialReactorButtonState extends ConsumerState<_FinancialReactorButton> with TickerProviderStateMixin {
  late final AnimationController _wobbleController;
  late final AnimationController _pressController;
  late final AnimationController _pulseController;
  late final AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _morphController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    
    if (widget.isAnalyzing) _morphController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_FinancialReactorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      if (widget.isAnalyzing) {
        _morphController.repeat(reverse: true);
      } else {
        _morphController.stop();
        _morphController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _pressController.dispose();
    _pulseController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactorColor = AppColors.getPrimary(context);
    final size = 54.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.isAnalyzing ? null : () {
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_wobbleController, _pressController, _pulseController, _morphController]),
          builder: (context, child) {
            final scale = (1.0 - (_pressController.value * 0.08)) * (1.0 + (_pulseController.value * 0.02));
            final t = _wobbleController.value;
            final m = _morphController.value;

            return Transform.rotate(
              angle: m * math.pi * 0.5,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Center(
                    child: _buildOrganicCore(reactorColor, t, m),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrganicCore(Color color, double t, double m) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(54, 54),
            painter: _WaterDropPainterForButton(color: color, wobbleValue: t, morphValue: m),
          ),
          Icon(
            widget.isAnalyzing ? Icons.auto_awesome_rounded : Icons.psychology_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _WaterDropPainterForButton extends CustomPainter {
  final Color color;
  final double wobbleValue;
  final double morphValue;

  _WaterDropPainterForButton({required this.color, required this.wobbleValue, required this.morphValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final path = Path();
    for (int i = 0; i <= 60; i++) {
      double angle = (i * 2 * math.pi) / 60;
      double wobble = math.sin(angle * 3 + wobbleValue * 2 * math.pi) * 2.0;
      
      // AI Morphing: Change the "spiky" or "organic" nature during analysis
      double morph = math.sin(angle * (2 + morphValue * 3)) * (morphValue * 6.0);
      
      double r = radius + wobble + morph;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.4),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawPath(path, paint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawPath(path, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


