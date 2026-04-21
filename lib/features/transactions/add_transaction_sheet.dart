import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

import 'widgets/transaction_type_toggle.dart';
import 'widgets/transaction_amount_input.dart';
import 'widgets/transaction_category_data.dart';
import 'widgets/transaction_category_selector.dart';
import 'widgets/transaction_vault_selector.dart';
import 'widgets/transaction_period_selector.dart';
import '../../shared/widgets/fluid_switch.dart';
import '../../shared/widgets/fluid_button.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final int? initialId;
  final String? initialName;
  final double? initialAmount;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final bool? initialIsIncome;
  final List<int>? initialVaultIds;
  final String? initialCategoryId;

  const AddTransactionSheet({
    super.key,
    this.initialId,
    this.initialName,
    this.initialAmount,
    this.initialMinAmount,
    this.initialMaxAmount,
    this.initialIsIncome,
    this.initialVaultIds,
    this.initialCategoryId,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  int _tabIndex = 0;

  List<Vault> _vaults = [];
  List<int> _selectedVaultIds = [];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  bool _isFlexibleAmount = false;

  int _selectedCategoryIndex = 0;
  int _expandedCategoryIndex = -1;
  int _selectedSubModelIndex = -1;

  TransactionPeriodData _periodData = TransactionPeriodData(
    periodType: 0,
    selectedDay: 1,
    selectedDateForRecurrence: DateTime.now(),
    duration: 0,
  );

  bool _isPrefilled = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadVaults();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isFlexibleAmount && mounted) {
        _amountFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
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
    List<int> editingVaultIds = [];
    if (widget.initialId != null) {
      final existingTx = await DatabaseService.getTransaction(widget.initialId!);
      if (existingTx != null) {
        editingVaultIds = existingTx.vaultIds;
      }
    }

    if (mounted) {
      setState(() {
        _vaults = vaults;
        if (editingVaultIds.isNotEmpty) {
          _selectedVaultIds = List.from(editingVaultIds);
        } else if (widget.initialVaultIds != null) {
          _selectedVaultIds = List.from(widget.initialVaultIds!);
        }
      });
    }
  }

  void _prefillIfEditing() {
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
    if (widget.initialMinAmount != null || widget.initialMaxAmount != null) {
      _isFlexibleAmount = true;
      if (widget.initialMinAmount != null) {
        _minController.text = widget.initialMinAmount!.toStringAsFixed(0);
      }
      if (widget.initialMaxAmount != null) {
        _maxController.text = widget.initialMaxAmount!.toStringAsFixed(0);
      }
    }
    if (widget.initialIsIncome != null) {
      _tabIndex = widget.initialIsIncome! ? 1 : 0;
    }
    if (widget.initialCategoryId != null || widget.initialName != null) {
      final categories = _tabIndex == 0
          ? TransactionCategoryData.getExpenseCategories(context, l10n)
          : TransactionCategoryData.getIncomeCategories(context, l10n);

      bool found = false;
      for (int i = 0; i < categories.length; i++) {
        final cat = categories[i];
        if ((widget.initialCategoryId != null && cat['id'] == widget.initialCategoryId) ||
            (widget.initialCategoryId == null && cat['name'] == widget.initialName)) {
          _selectedCategoryIndex = i;
          found = true;
          break;
        }
        final subs = cat['subModels'] as List<Map<String, dynamic>>?;
        if (subs != null) {
          for (int j = 0; j < subs.length; j++) {
            final sub = subs[j];
            if ((widget.initialCategoryId != null && sub['id'] == widget.initialCategoryId) ||
                (widget.initialCategoryId == null && sub['name'] == widget.initialName)) {
              _selectedCategoryIndex = i;
              _expandedCategoryIndex = i;
              _selectedSubModelIndex = j;
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }
    }
    _loadInitialPeriod();
  }

  Future<void> _loadInitialPeriod() async {
    if (widget.initialId == null) return;
    final tx = await DatabaseService.getTransaction(widget.initialId!);
    if (tx == null) return;

    if (mounted) {
      setState(() {
        String? expCat;
        if ([8, 9, 10].contains(tx.periodType)) {
          expCat = 'gun';
        } else if ([1, 4, 5].contains(tx.periodType)) {
          expCat = 'hafta';
        } else if ([2, 6, 7].contains(tx.periodType)) {
          expCat = 'ay';
        }
        _periodData = TransactionPeriodData(
          periodType: tx.periodType,
          expandedPeriodCategory: expCat,
          selectedDay: _periodData.selectedDay,
          selectedDateForRecurrence: tx.date,
          duration: 0, 
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final minText = _minController.text.replaceAll(',', '.');
    final maxText = _maxController.text.replaceAll(',', '.');

    final amount = double.tryParse(amountText) ?? 0;
    final minAmt = double.tryParse(minText) ?? 0;
    final maxAmt = double.tryParse(maxText) ?? 0;

    if (!_isFlexibleAmount && amount <= 0) return;
    if (_isFlexibleAmount && minAmt <= 0 && maxAmt <= 0) return;

    final categories = _tabIndex == 0
        ? TransactionCategoryData.getExpenseCategories(context, l10n)
        : TransactionCategoryData.getIncomeCategories(context, l10n);

    final safeSelectedIndex = _selectedCategoryIndex >= 0 && _selectedCategoryIndex < categories.length 
        ? _selectedCategoryIndex 
        : 0;

    final selectedCat = categories[safeSelectedIndex];

    String title;
    String? categoryId;

    if (_selectedSubModelIndex >= 0) {
      final subs = selectedCat['subModels'] as List<Map<String, dynamic>>?;
      if (subs != null && _selectedSubModelIndex < subs.length) {
        final sub = subs[_selectedSubModelIndex];
        title = sub['name'] as String;
        categoryId = sub['id'] as String?;
      } else {
        title = selectedCat['name'] as String;
        categoryId = selectedCat['id'] as String?;
      }
    } else {
      title = selectedCat['name'] as String;
      categoryId = selectedCat['id'] as String?;
    }
    final iconCode = categoryId ?? title;

    TransactionRecord tx;
    if (widget.initialId != null) {
      final existingTx = await DatabaseService.getTransaction(widget.initialId!);
      tx = existingTx ?? TransactionRecord();
    } else {
      tx = TransactionRecord();
    }

    double finalAmount = amount;
    if (_isFlexibleAmount && minAmt > 0 && maxAmt > 0) {
      finalAmount = (minAmt + maxAmt) / 2;
    } else if (_isFlexibleAmount && maxAmt > 0) {
      finalAmount = maxAmt;
    } else if (_isFlexibleAmount && minAmt > 0) {
      finalAmount = minAmt;
    }

    tx
      ..isIncome = _tabIndex == 1
      ..title = title
      ..categoryId = categoryId
      ..iconCode = iconCode
      ..amount = finalAmount
      ..minAmount = _isFlexibleAmount ? minAmt : null
      ..maxAmount = _isFlexibleAmount ? maxAmt : null
      ..periodType = _periodData.periodType
      ..date = widget.initialId != null ? tx.date : DateTime.now()
      ..vaultIds = _selectedVaultIds;

    if (widget.initialId != null) {
      await DatabaseService.updateTransaction(tx);
    } else {
      await DatabaseService.addTransaction(tx);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = _tabIndex == 0
        ? TransactionCategoryData.getExpenseCategories(context, l10n)
        : TransactionCategoryData.getIncomeCategories(context, l10n);

    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSizes.paddingMedium * scalingFactor),
          TransactionTypeToggle(
                    tabIndex: _tabIndex,
                    onTabChanged: (index) {
                      setState(() {
                        _tabIndex = index;
                        _selectedCategoryIndex = 0;
                        _expandedCategoryIndex = -1;
                        _selectedSubModelIndex = -1;
                      });
                    },
                  ),

                  const SizedBox(height: AppSizes.paddingMedium),

                  TransactionAmountInput(
                    isFlexibleAmount: _isFlexibleAmount,
                    amountController: _amountController,
                    minController: _minController,
                    maxController: _maxController,
                    amountFocusNode: _amountFocusNode,
                  ),

                  const SizedBox(height: AppSizes.paddingLarge),

                  TransactionCategorySelector(
                    categories: activeCategories,
                    selectedCategoryIndex: _selectedCategoryIndex,
                    selectedSubModelIndex: _selectedSubModelIndex,
                    expandedCategoryIndex: _expandedCategoryIndex,
                    onChanged: (catIndex, subIndex, expIndex) {
                      setState(() {
                        _selectedCategoryIndex = catIndex;
                        _selectedSubModelIndex = subIndex;
                        _expandedCategoryIndex = expIndex;
                      });
                    },
                  ),

                  const SizedBox(height: AppSizes.paddingLarge),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TransactionVaultSelector(
                          vaults: _vaults,
                          selectedVaultIds: _selectedVaultIds,
                          onChanged: (ids) {
                            setState(() => _selectedVaultIds = ids);
                          },
                        ),
                        
                        const SizedBox(height: AppSizes.paddingMedium),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.flexibleAmount,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            FluidSwitch(
                              value: _isFlexibleAmount,
                              activeColor: AppColors.getPrimary(context),
                              activeIcon: Icons.tune_rounded,
                              inactiveIcon: Icons.horizontal_rule_rounded,
                              scalingFactor: scalingFactor,
                              onChanged: (val) {
                                setState(() {
                                  _isFlexibleAmount = val;
                                  if (!val) {
                                    _amountFocusNode.requestFocus();
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.paddingMedium),

                        Text(
                          l10n.recurrencePeriod,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TransactionPeriodSelector(
                          initialData: _periodData,
                          onChanged: (data) {
                            setState(() => _periodData = data);
                          },
                        ),

                        const SizedBox(height: AppSizes.paddingXLarge),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium, 
                      vertical: AppSizes.paddingLarge
                    ),
                    child: FluidButton(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _saveTransaction();
                      },
                      width: double.infinity,
                      height: 64,
                      color: AppColors.getPrimary(context),
                      child: Text(
                        l10n.save, 
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
        ],
      ),
    );
  }
}
