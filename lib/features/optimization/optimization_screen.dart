import 'package:flutter/material.dart';
import 'dart:ui';
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

  Widget _buildContent(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildPersonaHeader(goals, l10n),
              const SizedBox(height: 24),
              if (_showPreselect) ...[
                _buildPreselectPanelFluid(txs, l10n),
                const SizedBox(height: 24),
              ],
              _buildAnalyzeButtonFluid(txs, vaults, goals, l10n),
              const SizedBox(height: 32),
              if (_isAnalyzing)
                Center(
                  child: _ThinkingOrb(breathe: _breatheAnim),
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
              const SizedBox(height: 360), // Kadran ve Navbar için yeterli boşluk
            ],
          ),

          // INFINITE DIAL SELECTOR - "The Control Unit"
          Positioned(
            bottom: 100, // Navbar'ın hemen üzerinde durması için
            left: 0,
            right: 0,
            child: _InfiniteDialSelector(
              initialValue: _targetAmount,
              onChanged: (val) => setState(() => _targetAmount = val),
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
            ),
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
          ScaleTransition(
            scale: _breatheAnim,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.getSecondary(context),
                    AppColors.getPrimary(context),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getSecondary(context).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
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
        : txs.where((t) => t.vaultId == _scopeVaultId).toList();

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

  Widget _buildAnalyzeButtonFluid(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
    AppLocalizations l10n,
  ) {
    return _FinancialReactorButton(
      isAnalyzing: _isAnalyzing,
      onTap: () => _startAnalysis(txs, vaults, goals),
      label: l10n.analyze.toUpperCase(),
    );
  }

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
// INFINITE DIAL SELECTOR — "Premium Physical Control"
// ────────────────────────────────────────────────────────────────

class _InfiniteDialSelector extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;
  final DateTime targetDate;
  final String vaultName;
  final VoidCallback onDateTap;
  final VoidCallback onVaultTap;
  final VoidCallback onTuneTap;
  final bool showPreselect;

  const _InfiniteDialSelector({
    required this.initialValue,
    required this.onChanged,
    required this.targetDate,
    required this.vaultName,
    required this.onDateTap,
    required this.onVaultTap,
    required this.onTuneTap,
    required this.showPreselect,
  });

  @override
  State<_InfiniteDialSelector> createState() => _InfiniteDialSelectorState();
}

class _InfiniteDialSelectorState extends State<_InfiniteDialSelector> with TickerProviderStateMixin {
  late double _currentValue;
  double _scrollOffset = 0;
  int _lastTickHaptic = 0;
  
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _scrollOffset = _currentValue / 100;
    
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    setState(() {
      _scrollOffset -= delta;
      
      final double newValue = (_scrollOffset * 100).clamp(5000, 2000000);
      
      if (newValue != _currentValue) {
        _currentValue = newValue;
        widget.onChanged(newValue);
        
        _scaleController.forward(from: 0).then((_) => _scaleController.reverse());

        // Haptic: Çizgi hiyerarşisine göre titreşim
        int tick = (_scrollOffset / 8).floor();
        if (tick != _lastTickHaptic) {
          _lastTickHaptic = tick;
          if (tick % 10 == 0) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'tr_TR');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.getBackground(context).withValues(alpha: 0.8),
            AppColors.getBackground(context),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // DEĞER GÖSTERİMİ
          Positioned(
            top: 40,
            child: Column(
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Text(
                    '${currencyFormat.format(_currentValue.toInt())} ₺',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -1,
                      shadows: [
                        Shadow(
                          color: AppColors.getPrimary(context).withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'HEDEFİNİ BELİRLE'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: AppColors.getPrimary(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // 3D GLASS CYLINDER SELECTOR
          Positioned(
            bottom: 80,
            child: GestureDetector(
              onHorizontalDragUpdate: _onPanUpdate,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. KAZINMIŞ ZEMİN (The Etched Floor)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.92,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.getInnerSurface(context).withValues(alpha: 0.4),
                      ),
                    ),

                    // 2. DİNAMİK ÇİZGİLER (Painter - Under the glass)
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width * 0.92, 84),
                      painter: _CylindricalDialPainter(
                        scrollOffset: _scrollOffset,
                        color: AppColors.getPrimary(context),
                        isDark: isDark,
                      ),
                    ),

                    // 3. SAYDAM CAM SİLİNDİR (The Glass Tube)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.92,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                            Colors.white.withValues(alpha: isDark ? 0.02 : 0.05),
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: isDark ? 0.02 : 0.05),
                            Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 4. MERKEZ ODAK İĞNESİ (Focus Needle)
                    Container(
                      width: 4,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.getSecondary(context),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.getSecondary(context).withValues(alpha: 0.6),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ALT SEÇENEKLER
          Positioned(
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GlassChip(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('MMM yyyy').format(widget.targetDate),
                  onTap: widget.onDateTap,
                ),
                const SizedBox(width: 12),
                _GlassChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: widget.vaultName,
                  onTap: widget.onVaultTap,
                ),
                const SizedBox(width: 12),
                _GlassChip(
                  icon: widget.showPreselect ? Icons.expand_less_rounded : Icons.tune_rounded,
                  label: '',
                  onTap: widget.onTuneTap,
                  isSecondary: true,
                ),
              ],
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

  _CylindricalDialPainter({
    required this.scrollOffset,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double radius = size.width / 1.4;
    final double spacing = 40.0;

    for (int i = -40; i <= 40; i++) {
      double worldX = (i * spacing) - (scrollOffset % (spacing * 1000));
      double angle = worldX / radius;
      
      // Sadece görünür açıdaki çizgileri çiz
      if (angle > -math.pi / 2 && angle < math.pi / 2) {
        double x = centerX + radius * math.sin(angle);
        double cosAngle = math.cos(angle);
        
        // --- BULGE (ODAK) EFEKTİ ---
        // Merkeze yakınlık (0-1 arası)
        double distFromCenter = angle.abs() / (math.pi / 2); 
        double bulge = math.exp(-(angle * angle) / (0.4 * 0.4)); // Dashboard sigma: 0.4

        // --- HİYERARŞİ ---
        double baseHeight = 20.0;
        double strokeWidth = 1.2;
        double alphaBase = 0.3;

        if (i % 10 == 0) {
          baseHeight = 48.0;
          strokeWidth = 2.5;
          alphaBase = 0.7;
        } else if (i % 5 == 0) {
          baseHeight = 32.0;
          strokeWidth = 1.8;
          alphaBase = 0.5;
        }

        // Odaklanan çizginin uzaması ve kalınlaşması
        double lineHeight = (baseHeight + (20.0 * bulge)) * cosAngle;
        double currentStroke = strokeWidth + (1.2 * bulge);
        double opacity = (alphaBase + (0.3 * bulge)) * math.pow(cosAngle, 1.5);

        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = currentStroke;

        // 1. ETCHED SHADOW (Kazıma Derinliği)
        paint.color = Colors.black.withValues(alpha: opacity * (isDark ? 0.4 : 0.2));
        canvas.drawLine(
          Offset(x + 1.2, (size.height - lineHeight) / 2 + 1.2),
          Offset(x + 1.2, (size.height + lineHeight) / 2 + 1.2),
          paint,
        );

        // 2. MAIN TICK (Ana Çizgi)
        paint.color = color.withValues(alpha: opacity);
        if (bulge > 0.8) {
          // Odaktaki çizgi parlaması
          paint.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.2), color, color.withValues(alpha: 0.2)],
          ).createShader(Rect.fromLTWH(x, (size.height - lineHeight) / 2, currentStroke, lineHeight));
        }
        
        canvas.drawLine(
          Offset(x, (size.height - lineHeight) / 2),
          Offset(x, (size.height + lineHeight) / 2),
          paint,
        );
        paint.shader = null;

        // 3. HIGHLIGHT (Kenar Işığı)
        if (opacity > 0.2) {
          paint.color = Colors.white.withValues(alpha: opacity * 0.15);
          paint.strokeWidth = currentStroke * 0.4;
          canvas.drawLine(
            Offset(x - 0.6, (size.height - lineHeight) / 2),
            Offset(x - 0.6, (size.height + lineHeight) / 2),
            paint,
          );
        }

        // DEĞER ETİKETLERİ
        if (i % 10 == 0 && opacity > 0.4) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${(i.abs() * 5)}K',
              style: TextStyle(
                color: color.withValues(alpha: opacity * 0.8),
                fontSize: 10 + (2.0 * bulge),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, (size.height / 2) + (lineHeight / 2) + 8),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CylindricalDialPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;
  const _GlassChip({required this.icon, required this.label, required this.onTap, this.isSecondary = false});
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
    return SizedBox(width: size, height: size, child: Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent))));
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

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactorColor = AppColors.getPrimary(context);
    final size = 160.0;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.isAnalyzing ? null : () {
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_wobbleController, _pressController, _pulseController]),
          builder: (context, child) {
            final scale = (1.0 - (_pressController.value * 0.08)) * (1.0 + (_pulseController.value * 0.02));
            final t = _wobbleController.value;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: _buildOrganicCore(reactorColor, t),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrganicCore(Color color, double t) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(54, 54),
                painter: _WaterDropPainterForButton(color: color, wobbleValue: t),
              ),
              Icon(
                widget.isAnalyzing ? Icons.auto_awesome_rounded : Icons.psychology_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!widget.isAnalyzing)
            Text(
              widget.label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _WaterDropPainterForButton extends CustomPainter {
  final Color color;
  final double wobbleValue;

  _WaterDropPainterForButton({required this.color, required this.wobbleValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Organic Wobble Effect
    final path = Path();
    for (int i = 0; i <= 60; i++) {
      double angle = (i * 2 * math.pi) / 60;
      double wobble = math.sin(angle * 3 + wobbleValue * 2 * math.pi) * 2.0;
      double r = radius + wobble;
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

    // Rim light
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawPath(path, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


