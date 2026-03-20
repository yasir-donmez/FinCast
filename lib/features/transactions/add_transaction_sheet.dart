import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/fluid_container.dart';
import 'widgets/fluid_numpad.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

/// Merkez FAB ikonuna basılınca açılan Yeni Gelir/Gider Ekranı (Transaction Modal)
class AddTransactionSheet extends ConsumerStatefulWidget {
  final int? initialId;
  final String? initialName;
  final double? initialAmount;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final bool? initialIsIncome;
  final int? initialVaultId;
  final String? initialCategoryId;

  const AddTransactionSheet({
    super.key,
    this.initialId,
    this.initialName,
    this.initialAmount,
    this.initialMinAmount,
    this.initialMaxAmount,
    this.initialIsIncome,
    this.initialVaultId,
    this.initialCategoryId,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  int _tabIndex = 0;
  List<Vault> _vaults = [];
  int? _selectedVaultId;
  bool _showAdvancedOptions = false;
  String _currentAmount = "0";
  String _currentMin = "0";
  String _currentMax = "0";
  String _activeAmountField = 'amount';
  int _selectedCategoryIndex = 0;
  int _expandedCategoryIndex = -1;
  int _selectedSubModelIndex = -1;
  bool _isPrefilled = false;
  bool _isFlexibleAmount = false;
  int _periodType = 0;
  String? _expandedPeriodCategory;
  int _selectedDay = 1;
  DateTime _selectedDateForRecurrence = DateTime.now();
  int _duration = 0;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadVaults();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPrefilled) {
      _prefillIfEditing();
      _isPrefilled = true;
    }
  }

  Future<void> _loadVaults() async {
    final vaults = await DatabaseService.getAllVaults();
    if (mounted) {
      setState(() {
        _vaults = vaults;
        if (widget.initialVaultId != null) {
          _selectedVaultId = widget.initialVaultId;
        }
      });
    }
  }

  void _prefillIfEditing() {
    if (widget.initialAmount != null) _currentAmount = widget.initialAmount!.toStringAsFixed(0);
    if (widget.initialIsIncome != null) _tabIndex = widget.initialIsIncome! ? 1 : 0;
    if (widget.initialMinAmount != null || widget.initialMaxAmount != null) {
      _isFlexibleAmount = true;
      if (widget.initialMinAmount != null) _currentMin = widget.initialMinAmount!.toStringAsFixed(0);
      if (widget.initialMaxAmount != null) _currentMax = widget.initialMaxAmount!.toStringAsFixed(0);
      _activeAmountField = 'min';
    }
    // Kategori bulma mantığı burada basitleştirildi
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_currentAmount) ?? 0;
    final minAmt = double.tryParse(_currentMin) ?? 0;
    final maxAmt = double.tryParse(_currentMax) ?? 0;

    final categories = _tabIndex == 0 ? _getExpenseCategories(l10n) : _getIncomeCategories(l10n);
    final selectedCat = categories[_selectedCategoryIndex];
    
    String title = selectedCat['name'];
    String? categoryId = selectedCat['id'];
    
    if (_selectedSubModelIndex >= 0) {
      final subs = selectedCat['subModels'] as List<Map<String, dynamic>>?;
      if (subs != null && _selectedSubModelIndex < subs.length) {
        title = subs[_selectedSubModelIndex]['name'];
        categoryId = subs[_selectedSubModelIndex]['id'];
      }
    }

    TransactionRecord tx = widget.initialId != null 
        ? (await DatabaseService.getTransaction(widget.initialId!) ?? TransactionRecord())
        : TransactionRecord();

    tx
      ..isIncome = _tabIndex == 1
      ..title = title
      ..categoryId = categoryId
      ..iconCode = categoryId
      ..amount = _isFlexibleAmount ? ((minAmt + maxAmt) / 2) : amount
      ..minAmount = _isFlexibleAmount ? minAmt : null
      ..maxAmount = _isFlexibleAmount ? maxAmt : null
      ..periodType = _periodType
      ..date = tx.date
      ..vaultId = _selectedVaultId;

    if (widget.initialId != null) {
      await DatabaseService.updateTransaction(tx);
    } else {
      await DatabaseService.addTransaction(tx);
    }
  }

  void _onNumpadTap(String val) {
    setState(() {
      if (_activeAmountField == 'amount') {
        _currentAmount = _currentAmount == "0" ? val : (_currentAmount.length < 7 ? _currentAmount + val : _currentAmount);
      } else if (_activeAmountField == 'min') {
        _currentMin = _currentMin == "0" ? val : (_currentMin.length < 7 ? _currentMin + val : _currentMin);
      } else {
        _currentMax = _currentMax == "0" ? val : (_currentMax.length < 7 ? _currentMax + val : _currentMax);
      }
    });
  }

  void _onBackspaceTap() {
    setState(() {
      if (_activeAmountField == 'amount') {
        _currentAmount = _currentAmount.length > 1 ? _currentAmount.substring(0, _currentAmount.length - 1) : "0";
      } else if (_activeAmountField == 'min') {
        _currentMin = _currentMin.length > 1 ? _currentMin.substring(0, _currentMin.length - 1) : "0";
      } else {
        _currentMax = _currentMax.length > 1 ? _currentMax.substring(0, _currentMax.length - 1) : "0";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = _tabIndex == 0 ? _getExpenseCategories(l10n) : _getIncomeCategories(l10n);

    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingMedium),
          FluidContainer(
            width: 50, height: 5, padding: EdgeInsets.zero,
            color: AppColors.getSurface(context).withValues(alpha: 0.5),
            borderRadius: 10,
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTypeToggle(),
                  const SizedBox(height: 32),
                  _isFlexibleAmount ? _buildFlexibleAmountDisplay() : _buildSingleAmountDisplay(),
                  const SizedBox(height: 32),
                  _buildHierarchicalCategorySelector(activeCategories),
                ],
              ),
            ),
          ),
          _buildAdvancedOptionsButton(),
          const SizedBox(height: 8),
          SizedBox(
            height: 340,
            child: _showAdvancedOptions 
                ? SingleChildScrollView(child: _buildAdvancedOptionsPanel())
                : FluidNumpad(
                    activeColor: _tabIndex == 1 ? AppColors.getPrimary(context) : AppColors.getError(context),
                    onNumberTapped: _onNumpadTap,
                    onBackspaceTapped: _onBackspaceTap,
                    onDoneTapped: () async {
                      await _saveTransaction();
                      if (mounted) Navigator.pop(context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return FluidContainer(
      width: 240, padding: const EdgeInsets.all(4), borderRadius: 30, isGlass: true,
      color: AppColors.getSurface(context).withValues(alpha: 0.5),
      child: Row(
        children: [
          _buildTabBtn(l10n.expense, 0, Icons.arrow_downward_rounded, AppColors.getError(context)),
          _buildTabBtn(l10n.income, 1, Icons.arrow_upward_rounded, AppColors.getPrimary(context)),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, int index, IconData icon, Color color) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _tabIndex = index; _selectedCategoryIndex = 0; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : AppColors.getTextSecondary(context)),
              const SizedBox(width: 8),
              Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isActive ? Colors.white : AppColors.getTextSecondary(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleAmountDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text("₺", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context).withValues(alpha: 0.5))),
        const SizedBox(width: 12),
        Text(_currentAmount, style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context))),
      ],
    );
  }

  Widget _buildFlexibleAmountDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFlexBox(l10n.minimum, _currentMin, 'min'),
        FluidContainer(width: 24, height: 3, padding: EdgeInsets.zero, color: AppColors.getTextSecondary(context).withValues(alpha: 0.3), borderRadius: 2, child: const SizedBox.shrink()),
        _buildFlexBox(l10n.maximum, _currentMax, 'max'),
      ],
    );
  }

  Widget _buildFlexBox(String label, String value, String field) {
    final isActive = _activeAmountField == field;
    final color = _tabIndex == 1 ? AppColors.getPrimary(context) : AppColors.getError(context);
    return GestureDetector(
      onTap: () => setState(() => _activeAmountField = field),
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16, isGlass: true,
        color: isActive ? color.withValues(alpha: 0.1) : null,
        borderWidth: isActive ? 2 : 0.8,
        child: Column(
          children: [
            Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: isActive ? color : AppColors.getTextSecondary(context), fontWeight: FontWeight.w900)),
            Text("₺$value", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isActive ? AppColors.getTextPrimary(context) : AppColors.getTextSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchicalCategorySelector(List<Map<String, dynamic>> categories) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = index == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () => setState(() { _selectedCategoryIndex = index; _selectedSubModelIndex = -1; }),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FluidContainer(
                    width: 80, isGlass: true, borderRadius: 12,
                    color: isSelected ? (cat['color'] as Color).withValues(alpha: 0.2) : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'], color: isSelected ? cat['color'] : AppColors.getTextSecondary(context)),
                        const SizedBox(height: 4),
                        Text(cat['name'], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsButton() {
    return GestureDetector(
      onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
      child: FluidContainer(
        width: 60, height: 40, borderRadius: 20, isGlass: true,
        child: Icon(_showAdvancedOptions ? Icons.apps_rounded : Icons.tune_rounded),
      ),
    );
  }

  Widget _buildAdvancedOptionsPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVaultSelector(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.flexibleAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: _isFlexibleAmount,
                activeTrackColor: AppColors.getPrimary(context).withValues(alpha: 0.3),
                activeThumbColor: AppColors.getPrimary(context),
                onChanged: (v) => setState(() { _isFlexibleAmount = v; _activeAmountField = v ? 'min' : 'amount'; }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaultSelector() {
    final selectedVault = _selectedVaultId != null ? _vaults.firstWhere((v) => v.id == _selectedVaultId, orElse: () => Vault()) : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.vaultOrGroup.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () {
            // Basit seçim mantığı veya modal eklenebilir
          },
          child: FluidContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 16, isGlass: true,
            child: Text(selectedVault?.name ?? l10n.generalBalance),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getExpenseCategories(AppLocalizations l10n) => [
    {'id': 'exp_grocery', 'name': l10n.grocery, 'icon': Icons.shopping_basket_rounded, 'color': Colors.orange},
    {'id': 'exp_dining', 'name': l10n.dining, 'icon': Icons.restaurant_rounded, 'color': Colors.deepOrangeAccent},
    {'id': 'exp_bill', 'name': l10n.bill, 'icon': Icons.receipt_long_rounded, 'color': Colors.blue},
    {'id': 'exp_other', 'name': l10n.other, 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];

  List<Map<String, dynamic>> _getIncomeCategories(AppLocalizations l10n) => [
    {'id': 'inc_salary', 'name': l10n.salary, 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.green},
    {'id': 'inc_other', 'name': l10n.other, 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];
}
