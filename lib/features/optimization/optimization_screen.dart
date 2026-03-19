import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/financial_goal.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';
import 'optimization_providers.dart';
import 'ai_service.dart';
import '../../l10n/app_localizations.dart';

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

  // ── Animasyon ──
  late final AnimationController _breatheController;
  late final Animation<double> _breatheAnim;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _slideController.dispose();
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
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _userApproval = null;
    });
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

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(activeTransactionsProvider);
    final vaultsAsync = ref.watch(vaultsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return txsAsync.when(
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
    );
  }

  Widget _buildContent(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildPersonaCard(goals, l10n),
          const SizedBox(height: 16),
          _buildGoalSetup(vaults, txs, l10n),
          const SizedBox(height: 16),
          if (_showPreselect) ...[
            _buildPreselectPanel(txs, l10n),
            const SizedBox(height: 16),
          ],
          _buildAnalyzeButton(txs, vaults, goals, l10n),
          const SizedBox(height: 20),
          if (_isAnalyzing)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.getPrimary(context)),
              ),
            ),
          if (_result != null) ...[
            SlideTransition(
              position: _slideAnim,
              child: _buildResults(_result!, txs, vaults, goals, l10n),
            ),
          ],
          if (goals.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildHistory(goals, l10n),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // PERSONA KARTI
  // ────────────────────────────────────────────────────────────────
  Widget _buildPersonaCard(List<FinancialGoal> goals, AppLocalizations l10n) {
    final savedPersona = goals.firstOrNull?.aiPersonaText;
    final displayText = _personaText ?? savedPersona;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getSecondary(context).withValues(alpha: 0.15),
            AppColors.getPrimary(context).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.getSecondary(context).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: _breatheAnim,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.getSecondary(context).withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getSecondary(context).withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.getSecondary(context),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _personaLoading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.analyzingFinancialIdentity,
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        color: AppColors.getSecondary(context),
                        backgroundColor: AppColors.getInnerSurface(context),
                      ),
                    ],
                  )
                : displayText != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.financialIdentity,
                        style: TextStyle(
                          color: AppColors.getSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayText,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  )
                : Text(
                    l10n.financialIdentityHint,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // HEDEF KURULUM
  // ────────────────────────────────────────────────────────────────
  Widget _buildGoalSetup(
    List<Vault> vaults,
    List<TransactionRecord> txs,
    AppLocalizations l10n,
  ) {
    return _neumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.setTarget, Icons.flag_rounded),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.targetAmountLabel(
                _currencyFormat.format(_targetAmount.toInt()),
              ),
              style: TextStyle(
                color: AppColors.getPrimary(context),
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          Slider(
            value: _targetAmount.clamp(5000, 1000000),
            min: 5000,
            max: 1000000,
            divisions: 199,
            activeColor: AppColors.getPrimary(context),
            inactiveColor: AppColors.getInnerSurface(context),
            onChanged: (v) => setState(() => _targetAmount = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppColors.getTextSecondary(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.targetDateLabel,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now().add(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (ctx, child) =>
                        Theme(data: ThemeData.dark(), child: child!),
                  );
                  if (picked != null) setState(() => _targetDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                    decoration: BoxDecoration(
                      color: AppColors.getInnerSurface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.getPrimary(context).withValues(alpha: 0.3),
                      ),
                    ),
                  child: Text(
                    DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(_targetDate),
                    style: TextStyle(
                      color: AppColors.getPrimary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.getTextSecondary(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.scopeLabel,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _scopeVaultId,
                    dropdownColor: AppColors.getSurface(context),
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 13,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.getTextSecondary(context),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.allVaults),
                      ),
                      ...vaults.map(
                        (v) =>
                            DropdownMenuItem(value: v.id, child: Text(v.name)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _scopeVaultId = val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _showPreselect = !_showPreselect),
            child: Row(
              children: [
                Icon(
                  _showPreselect
                      ? Icons.expand_less_rounded
                      : Icons.tune_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _showPreselect
                      ? l10n.hidePreselect
                      : l10n.preselectHint,
                  style: TextStyle(
                    color: AppColors.getPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // ÖN SEÇİM PANELİ
  // ────────────────────────────────────────────────────────────────
  Widget _buildPreselectPanel(List<TransactionRecord> txs, AppLocalizations l10n) {
    final now = DateTime.now();
    final monthsToTarget =
        (_targetDate.year - now.year) * 12 + (_targetDate.month - now.month);
    final scopedTxs = _scopeVaultId == null
        ? txs
        : txs.where((t) => t.vaultId == _scopeVaultId).toList();

    final relevant = scopedTxs.where((t) {
      if (t.periodType == 0) return false;
      switch (t.periodType) {
        case 1:
          final weeksToTarget = _targetDate.difference(now).inDays ~/ 7;
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= weeksToTarget;
        case 4: // 2 Haftalık
          final biWeeksToTarget = _targetDate.difference(now).inDays ~/ 14;
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= biWeeksToTarget;
        case 5: // 3 Haftalık
          final triWeeksToTarget = _targetDate.difference(now).inDays ~/ 21;
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= triWeeksToTarget;
        case 2:
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= monthsToTarget;
        case 6: // 3 Aylık
          final quartersToTarget = (monthsToTarget / 3).ceil();
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= quartersToTarget;
        case 7: // 6 Aylık
          final halfYearsToTarget = (monthsToTarget / 6).ceil();
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= halfYearsToTarget;
        case 3:
          final yearsToTarget = (monthsToTarget / 12).ceil();
          if (t.remainingInstallments == null) return true;
          return t.remainingInstallments! >= yearsToTarget;
        default:
          return true;
      }
    }).toList();

    final expensesList = relevant.where((t) => !t.isIncome).toList();
    final incomesList = relevant.where((t) => t.isIncome).toList();
    final allRelevant = [...expensesList, ...incomesList];

    if (allRelevant.isEmpty) {
      return _neumorphicCard(
        child: Column(
          children: [
            _sectionTitle(l10n.items, Icons.tune_rounded),
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.noItemsToAnalyze,
                style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return _neumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.items, Icons.tune_rounded),
          const SizedBox(height: 4),
          Text(
            l10n.itemsToAnalyze(allRelevant.length, monthsToTarget),
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (expensesList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.expenses,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...expensesList.map((tx) => _preselectRow(tx, l10n)),
          ],
          if (incomesList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.incomes,
              style: TextStyle(
                color: AppColors.getIncome(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...incomesList.map((tx) => _preselectRow(tx, l10n)),
          ],
        ],
      ),
    );
  }

  Widget _preselectRow(TransactionRecord tx, AppLocalizations l10n) {
    final isLocked = _userLockedIds.contains(tx.id);
    final isFlexible = _userFlexibleIds.contains(tx.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_currencyFormat.format(tx.amount.toInt())} ₺',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _chipButton(
            label: l10n.doNotTouch,
            icon: Icons.lock_rounded,
            active: isLocked,
            activeColor: AppColors.error,
            onTap: () => setState(() {
              if (isLocked) {
                _userLockedIds.remove(tx.id);
              } else {
                _userLockedIds.add(tx.id);
                _userFlexibleIds.remove(tx.id);
              }
            }),
          ),
          const SizedBox(width: 6),
          _chipButton(
            label: l10n.changeable,
            icon: Icons.edit_rounded,
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

  Widget _chipButton({
    required String label,
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.15)
              : AppColors.getInnerSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? activeColor
                : AppColors.getTextSecondary(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: active ? activeColor : AppColors.getTextSecondary(context),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? activeColor : AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // ANALİZ BUTONU
  // ────────────────────────────────────────────────────────────────
  Widget _buildAnalyzeButton(
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: _isAnalyzing ? null : () => _startAnalysis(txs, vaults, goals),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAnalyzing
                ? [AppColors.getInnerSurface(context), AppColors.getInnerSurface(context)]
                : [
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primary
                        : AppColors.secondary,
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF00ACC1)
                        : const Color(0xFF7E57C2),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isAnalyzing
              ? []
              : [
                  BoxShadow(
                    color: AppColors.getPrimary(context).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isAnalyzing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.getTextSecondary(context),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.analytics_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.analyze,
                      style: TextStyle(
                        color: AppColors.getPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // SONUÇLAR — Bütünleşik Akış
  // ────────────────────────────────────────────────────────────────
  Widget _buildResults(
    AnalysisResult result,
    List<TransactionRecord> txs,
    List<Vault> vaults,
    List<FinancialGoal> goals,
    AppLocalizations l10n,
  ) {
    final s = result.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero kart — tek ana kart
        _buildStatusCard(s, l10n),
        const SizedBox(height: 24),

        // AI bağlantı sorunu banneri
        if (!result.usedAi && result.aiError != null) ...[
          _aiBanner(result.aiError!, l10n),
          const SizedBox(height: 16),
        ],

        // AI önerileri — kart değil, doğal akış
        if (!s.isAlreadyOnTrack && result.optimizationResult != null) ...[
          _buildOptimizationSection(result.optimizationResult!, l10n),
          const SizedBox(height: 24),
        ],

        // Geri bildirim
        if (_userApproval == null)
          _buildFeedbackSection(goals, l10n)
        else
          _buildApprovalConfirmed(l10n),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // HERO STATUS KART — Glassmorphic
  // ────────────────────────────────────────────────────────────────
  Widget _buildStatusCard(AnalysisSnapshot s, AppLocalizations l10n) {
    final onTrack = s.isAlreadyOnTrack;
    final fmt = _currencyFormat;
    final healthScore = onTrack
        ? 1.0
        : (s.monthlySurplus / s.requiredMonthlySaving).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.getPrimary(context).withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.getPrimary(context).withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Hero Score
              Center(child: _buildExecutiveScore(healthScore, onTrack, l10n)),
              const SizedBox(height: 20),
              Text(
                onTrack ? l10n.excellent : l10n.analysisResult,
                style: TextStyle(
                color: onTrack ? AppColors.getSecondary(context) : AppColors.getPrimary(context),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
              ),
              const SizedBox(height: 6),
              Text(
                onTrack ? l10n.onTrackMessage : l10n.savingsNeeded,
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // 3 Metrik
              Row(
                children: [
                  _vipMetric(
                    l10n.currentBalance,
                    fmt.format(s.currentBalance.toInt()),
                    Icons.account_balance_rounded,
                    l10n,
                  ),
                  _vipMetric(
                    l10n.targetGap,
                    fmt.format(s.gap.toInt()),
                    Icons.flag_rounded,
                    l10n,
                  ),
                  _vipMetric(
                    l10n.remainingTime,
                    l10n.monthsToTargetLabel(s.months),
                    Icons.calendar_month_rounded,
                    l10n,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Vurgu paneli
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      onTrack
                          ? AppColors.getPrimary(context).withValues(alpha: 0.15)
                          : AppColors.getError(context).withValues(alpha: 0.1),
                      onTrack
                          ? AppColors.getSecondary(context).withValues(alpha: 0.05)
                          : AppColors.getError(context).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (onTrack ? AppColors.getPrimary(context) : AppColors.getError(context))
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      onTrack ? l10n.currentSurplus : l10n.requiredMonthlySavings,
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${fmt.format(onTrack ? s.monthlySurplus.toInt() : s.requiredMonthlySaving.toInt())}',
                      style: TextStyle(
                        color: onTrack ? AppColors.getSecondary(context) : AppColors.getError(context),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    if (!onTrack) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.currentSurplus}: ₺${fmt.format(s.monthlySurplus.toInt())}',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!onTrack) ...[
                const SizedBox(height: 24),
                _buildSavingsBridge(s, l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveScore(double score, bool onTrack, AppLocalizations l10n) {
    final color = onTrack
        ? AppColors.getSecondary(context)
        : (score < 0.4 ? AppColors.getError(context) : AppColors.getPrimary(context));
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            width: 120,
            child: CircularProgressIndicator(
              value: score,
              strokeWidth: 10,
              backgroundColor: AppColors.getInnerSurface(context).withValues(alpha: 0.5),
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(score * 100).toInt()}',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  l10n.score,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vipMetric(String label, String value, IconData icon, AppLocalizations l10n) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.getInnerSurface(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.getTextSecondary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // TASARRUF KÖPRÜSÜ
  // ────────────────────────────────────────────────────────────────
  Widget _buildSavingsBridge(AnalysisSnapshot s, AppLocalizations l10n) {
    final totalRequired = s.requiredMonthlySaving;
    if (totalRequired <= 0) return const SizedBox.shrink();

    final currentSurplus = s.monthlySurplus;
    final aiSuggestions =
        _result?.optimizationResult?.cuts.fold(
          0.0,
          (sum, c) => sum + c.saving,
        ) ??
        0.0;
    final totalPotential = currentSurplus + aiSuggestions;

    final surplusPct = (currentSurplus / totalRequired).clamp(0.0, 1.0);
    final aiPct = (aiSuggestions / totalRequired).clamp(0.0, 1.0 - surplusPct);
    final remainingGapPct = (1.0 - (surplusPct + aiPct)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TASARRUF KÖPRÜSÜ (AYLIK)',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.getInnerSurface(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (surplusPct > 0)
                Expanded(
                  flex: (surplusPct * 1000).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: (aiPct * 1000).toInt(),
                  child: Container(color: AppColors.getSecondary(context)),
                ),
              if (remainingGapPct > 0)
                Expanded(
                  flex: (remainingGapPct * 1000).toInt(),
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _legendRow(
          AppColors.getPrimary(context),
          l10n.currentSavings,
          _currencyFormat.format(currentSurplus.toInt()),
        ),
        const SizedBox(height: 8),
        _legendRow(
          AppColors.getSecondary(context),
          l10n.aiSavingsTarget,
          '+${_currencyFormat.format(aiSuggestions.toInt())}',
        ),
        if (remainingGapPct > 0.05) ...[
          const SizedBox(height: 8),
          _legendRow(
            AppColors.getTextSecondary(context).withValues(alpha: 0.4),
            l10n.remainingGap,
            _currencyFormat.format((totalRequired - totalPotential).toInt()),
          ),
        ],
      ],
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '₺$value',
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // AI BAĞLANTI BANNER
  // ────────────────────────────────────────────────────────────────
  Widget _aiBanner(String errorText, AppLocalizations l10n) {
    final isQuota =
        errorText.toLowerCase().contains('quota') ||
        errorText.toLowerCase().contains('429');
    final isNetwork =
        errorText.toLowerCase().contains('socket') ||
        errorText.toLowerCase().contains('network');
    final icon = isQuota
        ? Icons.timelapse_rounded
        : isNetwork
        ? Icons.wifi_off_rounded
        : Icons.api_rounded;
    final label = isQuota
        ? l10n.dailyAiQuotaFull
        : isNetwork
        ? l10n.noInternetConnection
        : l10n.aiApiError;
    final sub = isQuota
        ? 'Yerel öneriler sunuldu.'
        : isNetwork
        ? 'Yerel algoritma kullanıldı. Bağlantı sağlandığında AI önerileri gelecek.'
        : 'Yerel algoritma: ${errorText.length > 80 ? '${errorText.substring(0, 80)}…' : errorText}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getWarning(context).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getWarning(context).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.getWarning(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.getWarning(context),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // AI ÖNERİLERİ — Doğal akış, kart yok
  // ────────────────────────────────────────────────────────────────
  Widget _buildOptimizationSection(OptimizationResult optResult, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Koç mesajı — kart yok, flat
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: _breatheAnim,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getSecondary(context).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: AppColors.getSecondary(context),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiCoachSuggestion,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    optResult.coachMessage,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (!optResult.isFeasible) ...[
          _warningBanner(
            l10n.budgetNotFeasible,
          ),
          const SizedBox(height: 12),
        ],

        // Divider
        if (optResult.cuts.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.cutbackPlan,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...optResult.cuts.map((cut) => _buildCutRow(cut, l10n)),
        ],
      ],
    );
  }

  Widget _buildCutRow(CutSuggestion cut, AppLocalizations l10n) {
    final pct = cut.currentAmount > 0
        ? (cut.suggestedAmount / cut.currentAmount).clamp(0.0, 1.0)
        : 0.0;
    final fmt = _currencyFormat;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cut.category,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cut.newPeriod != null && cut.newPeriod != 0)
                      Text(
                        l10n.newFrequency(_getPeriodName(cut.newPeriod!, l10n)),
                        style: TextStyle(
                          color: AppColors.getSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₺${fmt.format(cut.suggestedAmount.toInt())}',
                      style: TextStyle(
                        color: AppColors.getPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (cut.suggestedMin != null && cut.suggestedMax != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${fmt.format(cut.suggestedMin!.toInt())} ~ ${fmt.format(cut.suggestedMax!.toInt())}',
                        style: TextStyle(
                          color: AppColors.getPrimary(context).withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '← ₺${fmt.format(cut.currentAmount.toInt())}',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  color: AppColors.getError(context).withValues(alpha: 0.12),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (cut.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cut.reason,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 11,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // GERİ BİLDİRİM
  // ────────────────────────────────────────────────────────────────
  Widget _buildFeedbackSection(List<FinancialGoal> goals, AppLocalizations l10n) {
    return _neumorphicCard(
      child: Column(
        children: [
          Text(
            l10n.doYouLikeThisSuggestion,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _submitFeedback(true, goals),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getPrimary(context).withValues(alpha: 0.4),
                      ),
                    ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_rounded,
                          color: AppColors.getPrimary(context),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.yesILikeIt,
                          style: TextStyle(
                            color: AppColors.getPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _submitFeedback(false, goals),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getError(context).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getError(context).withValues(alpha: 0.3),
                      ),
                    ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_down_rounded,
                          color: AppColors.getError(context),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.no,
                          style: TextStyle(
                            color: AppColors.getError(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalConfirmed(AppLocalizations l10n) {
    final approved = _userApproval == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (approved ? AppColors.getPrimary(context) : AppColors.getError(context)).withValues(alpha: 
          0.08,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (approved ? AppColors.getPrimary(context) : AppColors.getError(context)).withValues(alpha: 
            0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: approved ? AppColors.getPrimary(context) : AppColors.getError(context),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              approved
                  ? l10n.financialIdentityUpdated
                  : l10n.feedbackMemoized,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // GEÇMİŞ
  // ────────────────────────────────────────────────────────────────
  Widget _buildHistory(List<FinancialGoal> goals, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _sectionTitle(l10n.recentAnalyses, Icons.history_rounded),
        ),
        ...goals.map((g) => _buildHistoryCard(g, l10n)),
      ],
    );
  }

  Widget _buildHistoryCard(FinancialGoal g, AppLocalizations l10n) {
    final approved = g.userApproved;
    final isExpanded = _expandedGoalId == g.id;
    final statusColor = approved == true
        ? AppColors.getSecondary(context)
        : approved == false
        ? AppColors.getError(context)
        : AppColors.getTextSecondary(context);

    return GestureDetector(
      onTap: () => setState(() => _expandedGoalId = isExpanded ? null : g.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context).withValues(alpha: isExpanded ? 0.9 : 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? AppColors.getPrimary(context).withValues(alpha: 0.3)
                : AppColors.getPrimary(context).withValues(alpha: 0.1),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            if (isExpanded)
              BoxShadow(
                color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        approved == true
                            ? Icons.verified_rounded
                            : Icons.history_rounded,
                        color: statusColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₺${_currencyFormat.format(g.targetAmount.toInt())} ${l10n.setGoal}',
                              style: TextStyle(
                                color: AppColors.getTextPrimary(context),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd MMMM yyyy HH:mm',
                              Localizations.localeOf(context).languageCode,
                            ).format(g.createdAt),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (g.aiPersonaText != null)
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.getSecondary(context),
                        size: 14,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: AppColors.getInnerSurface(context), height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _historyStat(
                            l10n.targetDate,
                            DateFormat(
                              'MMM yyyy',
                              Localizations.localeOf(context).languageCode,
                            ).format(g.targetDate ?? DateTime.now()),
                          ),
                          _historyStat(
                            l10n.vault,
                            g.vaultId == null ? l10n.allVaults : l10n.custom,
                          ),
                          _historyStat(
                            l10n.status,
                            approved == true
                                ? l10n.approved
                                : (approved == false
                                      ? l10n.rejected
                                      : l10n.pending),
                          ),
                        ],
                      ),
                      if (g.aiStrategyText != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getInnerSurface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.getTextSecondary(context).withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            g.aiStrategyText!,
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      if (g.rejectedCategories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${l10n.excludedCategories}:',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: g.rejectedCategories
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.getError(context).withValues(alpha: 
                                      0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.getError(context).withValues(alpha: 
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      color: AppColors.getError(context),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 10),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // YARDIMCI WİDGET'LAR
  // ────────────────────────────────────────────────────────────────
  Widget _neumorphicCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.getDarkShadow(context),
            blurRadius: 12,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: AppColors.getLightShadow(context),
            blurRadius: 12,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.getPrimary(context), size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _warningBanner(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getWarning(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getWarning(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.getWarning(context),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodName(int type, AppLocalizations l10n) {
    switch (type) {
      case 1:
        return l10n.weekly;
      case 4:
        return l10n.every2Weeks;
      case 5:
        return l10n.every3Weeks;
      case 2:
        return l10n.monthly;
      case 6:
        return l10n.every3Months;
      case 7:
        return l10n.every6Months;
      case 3:
        return l10n.yearly;
      default:
        return l10n.oneTime;
    }
  }
}
