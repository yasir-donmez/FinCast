import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'analysis_detail_screen.dart';
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
  final _currencyFormat = NumberFormat('#,##0', 'tr_TR');
  double _targetAmount = 50000;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  int? _scopeVaultId;

  bool _isAnalyzing = false;
  bool _showPreselect = false;
  String? _personaText;
  // Final removed as it's not final
  bool _personaLoading = false;
  final Set<int> _userLockedIds = {};
  final Set<int> _userFlexibleIds = {};

  late final AnimationController _breatheController;
  late final Animation<double> _breatheAnim;
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
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

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
          const SnackBar(content: Text('Günlük AI analiz limitine ulaştınız.')),
        );
      }
      return;
    }

    setState(() => _isAnalyzing = true);
    await subscription.incrementAiUsage();

    // 1. Persona Üret
    try {
      final pText = await AiService.generatePersona(
        allTransactions: txs,
        vaults: vaults,
        previousGoals: previousGoals,
      );
      if (mounted) {
        setState(() => _personaText = pText);
      }
    } catch (_) {}

    // 2. Analiz Et
    final result = await OptimizationEngine.analyze(
      targetAmount: _targetAmount,
      targetDate: _targetDate,
      scopeVaultId: _scopeVaultId,
      allTransactions: txs,
      allVaults: vaults,
      userLockedIds: _userLockedIds,
      userFlexibleIds: _userFlexibleIds,
      vetoedCategories: previousGoals
          .where((g) => g.userApproved == false)
          .expand((g) => g.rejectedCategories)
          .toSet()
          .toList(),
      previousGoals: previousGoals,
    );

    // 3. Kaydet
    final latestGoalId = await _saveGoalDraft(result);
    final savedGoal = await DatabaseService.getGoal(latestGoalId);

    if (mounted) {
      setState(() => _isAnalyzing = false);
      if (savedGoal != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnalysisDetailScreen(goal: savedGoal),
          ),
        );
      }
    }
  }

  Future<int> _saveGoalDraft(AnalysisResult result) async {
    final rawJson = jsonEncode({
      'snapshot': {
        'currentBalance': result.snapshot.currentBalance,
        'targetAmount': result.snapshot.targetAmount,
        'gap': result.snapshot.gap,
        'monthlyIncome': result.snapshot.monthlyIncome,
        'monthlyExpense': result.snapshot.monthlyExpense,
        'monthlySurplus': result.snapshot.monthlySurplus,
        'months': result.snapshot.months,
        'requiredMonthlySaving': result.snapshot.requiredMonthlySaving,
        'isAlreadyOnTrack': result.snapshot.isAlreadyOnTrack,
      },
      'optimization': result.optimizationResult == null
          ? null
          : {
              'coachMessage': result.optimizationResult!.coachMessage,
              'isFeasible': result.optimizationResult!.isFeasible,
              'cuts': result.optimizationResult!.cuts
                  .map(
                    (c) => {
                      'category': c.category,
                      'currentAmount': c.currentAmount,
                      'suggestedAmount': c.suggestedAmount,
                      'saving': c.saving,
                      'reason': c.reason,
                    },
                  )
                  .toList(),
            },
      'usedAi': result.usedAi,
      'persona': result.persona,
    });

    final goal = FinancialGoal()
      ..targetAmount = _targetAmount
      ..targetDate = _targetDate
      ..vaultId = _scopeVaultId
      ..createdAt = DateTime.now()
      ..aiPersonaText = _personaText
      ..aiStrategyText = result.optimizationResult?.coachMessage
      ..analysisRawData = rawJson;

    final id = await DatabaseService.addGoal(goal);
    final all = await DatabaseService.getAllGoals();
    if (all.length > 5) await DatabaseService.deleteGoal(all.last.id);
    return id;
  }

  void _showManualAmountEntry() {
    final controller = TextEditingController(
      text: _targetAmount.toInt().toString(),
    );
    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.amount,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
              decoration: InputDecoration(
                suffixText: '₺',
                filled: true,
                fillColor: AppColors.getInnerSurface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FluidButton(
              onTap: () {
                final val = double.tryParse(controller.text);
                if (val != null)
                  setState(() => _targetAmount = val.clamp(0, 2000000));
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(activeTransactionsProvider);
    final vaultsAsync = ref.watch(vaultsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return Stack(
      fit: StackFit.expand,
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
              error: (e, _) => Center(child: Text('Hata')),
              data: (goals) => _buildContent(
                txs,
                vaults,
                goals,
                AppLocalizations.of(context)!,
              ),
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
        alignment: Alignment.topCenter,
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 260),
            children: [
              _buildPersonaHeader(goals, l10n),
              const SizedBox(height: 16),
              _buildItemsSection(txs, l10n),
              const SizedBox(height: 32),
              if (_isAnalyzing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        _ThinkingOrb(breathe: _breatheAnim),
                        const SizedBox(height: 20),
                        Text(
                          l10n.analyzingFinancialIdentity,
                          style: TextStyle(
                            color: AppColors.getPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (goals.isNotEmpty && !_isAnalyzing) ...[
                _buildHistoryFluid(goals, l10n),
              ],
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _AnalysisCockpit(
              targetAmount: _targetAmount,
              isAnalyzing: _isAnalyzing,
              onAnalyzeTap: () => _startAnalysis(txs, vaults, goals),
              onAmountTap: _showManualAmountEntry,
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
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaHeader(List<FinancialGoal> goals, AppLocalizations l10n) {
    final savedPersona = goals.firstOrNull?.aiPersonaText;
    final displayText = _personaText ?? savedPersona;
    final screenWidth = MediaQuery.of(context).size.width;

    return FluidContainer(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 20,
      ),
      isGlass: true,
      isConvex: false,
      blur: 25,
      borderRadius: AppSizes.radiusLarge,
      child: Row(
        children: [
          MembershipOrb(color: AppColors.getPrimary(context), size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.financialIdentity.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.getPrimary(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayText ?? l10n.financialIdentityHint,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
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

  Widget _buildItemsSection(
    List<TransactionRecord> txs,
    AppLocalizations l10n,
  ) {
    final scopedTxs = _scopeVaultId == null
        ? txs
        : txs.where((t) => t.vaultIds.contains(_scopeVaultId)).toList();
    final relevant = scopedTxs.where((t) => t.periodType != 0).toList();

    return FluidContainer(
      isConvex: false,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showPreselect = !_showPreselect);
            },
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _showPreselect
                        ? Icons.auto_awesome_motion_rounded
                        : Icons.tune_rounded,
                    color: AppColors.getPrimary(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.items.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPreselect ? 0.5 : 0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.getTextSecondary(
                        context,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            child: _showPreselect
                ? Column(
                    children: [
                      const Divider(height: 1),
                      ...relevant.map((tx) => _preselectRowFluid(tx, l10n)),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
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
            title: Text(
              l10n.allVaults,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: Icon(
              Icons.all_inclusive,
              color: AppColors.getPrimary(context),
            ),
            onTap: () {
              setState(() => _scopeVaultId = null);
              Navigator.pop(context);
            },
          ),
          ...vaults.map(
            (v) => ListTile(
              title: Text(
                v.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.getPrimary(context),
              ),
              onTap: () {
                setState(() => _scopeVaultId = v.id);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _preselectRowFluid(TransactionRecord tx, AppLocalizations l10n) {
    final isLocked = _userLockedIds.contains(tx.id);
    final isFlexible = _userFlexibleIds.contains(tx.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return Wrap(
            spacing: 8,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: isNarrow
                    ? constraints.maxWidth
                    : constraints.maxWidth * 0.45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
            ],
          );
        },
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
          color: active
              ? activeColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? activeColor
                : AppColors.getTextSecondary(context).withValues(alpha: 0.3),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
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
                color: active
                    ? activeColor
                    : AppColors.getTextSecondary(context),
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFluid(List<FinancialGoal> goals, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: AppColors.getPrimary(context),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.recentAnalyses.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...goals.map((g) => _buildHistoryCardFluid(g, l10n)),
      ],
    );
  }

  Widget _buildHistoryCardFluid(FinancialGoal g, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FluidContainer(
        isGlass: true,
        padding: EdgeInsets.zero,
        borderRadius: AppSizes.radiusDefault,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AnalysisDetailScreen(goal: g),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.getTextSecondary(
                      context,
                    ).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: AppColors.getTextSecondary(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₺${_currencyFormat.format(g.targetAmount.toInt())}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm').format(g.createdAt),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(
                            context,
                          ).withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.getTextSecondary(
                    context,
                  ).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisCockpit extends StatelessWidget {
  final double targetAmount;
  final bool isAnalyzing;
  final VoidCallback onAnalyzeTap;
  final VoidCallback onAmountTap;
  final DateTime targetDate;
  final String vaultName;
  final VoidCallback onDateTap;
  final VoidCallback onVaultTap;
  final AppLocalizations l10n;

  const _AnalysisCockpit({
    required this.targetAmount,
    required this.isAnalyzing,
    required this.onAnalyzeTap,
    required this.onAmountTap,
    required this.targetDate,
    required this.vaultName,
    required this.onDateTap,
    required this.onVaultTap,
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
            AppColors.getBackground(context).withValues(alpha: 0.7),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: FluidContainer(
        padding: const EdgeInsets.all(20),
        isGlass: true,
        borderRadius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onAmountTap,
                    child: FluidContainer(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      isConvex: false,
                      borderRadius: 20,
                      color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.targetAmountLabel('').trim().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.getPrimary(
                                context,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₺${currencyFormat.format(targetAmount.toInt())}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _FinancialReactorButton(
                  isAnalyzing: isAnalyzing,
                  onTap: onAnalyzeTap,
                  label: l10n.analyze,
                ),
              ],
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 20,
        isGlass: true,
        isConvex: false,
        blur: 15,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.getPrimary(context)),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
        return Stack(
          children: [
            Positioned(
              top: -100 + (math.sin(animation.value * 2 * math.pi) * 50),
              left: -50 + (math.cos(animation.value * 2 * math.pi) * 30),
              child: _Blob(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.12 : 0.15,
                ),
                size: 300,
              ),
            ),
            Positioned(
              bottom: -50 + (math.cos(animation.value * 2 * math.pi) * 40),
              right: -80 + (math.sin(animation.value * 2 * math.pi) * 60),
              child: _Blob(
                color: AppColors.secondary.withValues(
                  alpha: isDark ? 0.1 : 0.12,
                ),
                size: 350,
              ),
            ),
          ],
        );
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
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
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
        ),
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
  ConsumerState<_FinancialReactorButton> createState() =>
      _FinancialReactorButtonState();
}

class _FinancialReactorButtonState
    extends ConsumerState<_FinancialReactorButton>
    with TickerProviderStateMixin {
  late final AnimationController _wobbleController,
      _pressController,
      _pulseController,
      _morphController;
  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isAnalyzing) _morphController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_FinancialReactorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      if (widget.isAnalyzing)
        _morphController.repeat(reverse: true);
      else {
        _morphController.stop();
        _morphController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
        );
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.isAnalyzing
          ? null
          : () {
              HapticFeedback.heavyImpact();
              widget.onTap();
            },
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _wobbleController,
            _pressController,
            _pulseController,
            _morphController,
          ]),
          builder: (context, child) {
            final scale =
                (1.0 - (_pressController.value * 0.08)) *
                (1.0 + (_pulseController.value * 0.02));
            return Transform.rotate(
              angle: _morphController.value * math.pi * 0.5,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: _buildOrganicCore(
                      reactorColor,
                      _wobbleController.value,
                      _morphController.value,
                    ),
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
            size: const Size(64, 64),
            painter: _WaterDropPainterForButton(
              color: color,
              wobbleValue: t,
              morphValue: m,
            ),
          ),
          Icon(
            widget.isAnalyzing
                ? Icons.auto_awesome_rounded
                : Icons.psychology_rounded,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _WaterDropPainterForButton extends CustomPainter {
  final Color color;
  final double wobbleValue, morphValue;
  _WaterDropPainterForButton({
    required this.color,
    required this.wobbleValue,
    required this.morphValue,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    for (int i = 0; i <= 60; i++) {
      double angle = (i * 2 * math.pi) / 60;
      double r =
          radius +
          (math.sin(angle * 3 + wobbleValue * 2 * math.pi) * 2.0) +
          (math.sin(angle * (2 + morphValue * 3)) * (morphValue * 6.0));
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.4), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
