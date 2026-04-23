import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../shared/widgets/precision_clickable.dart';
import '../../shared/widgets/precision_card.dart';

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

  late TransactionPeriodData _periodData;

  bool _isPrefilled = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _periodData = TransactionPeriodData(
      periodType: 0,
      selectedDay: 1,
      selectedDateForRecurrence: DateTime.now(),
      duration: 0,
    );
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

  void _prefillIfEditing() {
    if (widget.initialId != null) {
      _tabIndex = widget.initialIsIncome == true ? 1 : 0;
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(0);
      }
      if (widget.initialMinAmount != null) {
        _minController.text = widget.initialMinAmount!.toStringAsFixed(0);
        _isFlexibleAmount = true;
      }
      if (widget.initialMaxAmount != null) {
        _maxController.text = widget.initialMaxAmount!.toStringAsFixed(0);
        _isFlexibleAmount = true;
      }
      if (widget.initialVaultIds != null) {
        _selectedVaultIds = List<int>.from(widget.initialVaultIds!);
      }
      
      if (widget.initialCategoryId != null) {
        final categories = _tabIndex == 0 
            ? TransactionCategoryData.getExpenseCategories(context, l10n)
            : TransactionCategoryData.getIncomeCategories(context, l10n);
            
        for (int i = 0; i < categories.length; i++) {
          final cat = categories[i];
          if (cat['id'] == widget.initialCategoryId) {
            _selectedCategoryIndex = i;
            _selectedSubModelIndex = -1;
            break;
          }
          final subModels = cat['subModels'] as List?;
          if (subModels != null) {
            for (int j = 0; j < subModels.length; j++) {
              if (subModels[j]['id'] == widget.initialCategoryId) {
                _selectedCategoryIndex = i;
                _selectedSubModelIndex = j;
                break;
              }
            }
          }
        }
      }
    }
  }

  Future<void> _loadVaults() async {
    final v = await DatabaseService.getAllVaults();
    if (mounted) {
      setState(() {
        _vaults = v;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final minAmount = double.tryParse(_minController.text);
    final maxAmount = double.tryParse(_maxController.text);
    
    final categories = _tabIndex == 0 
        ? TransactionCategoryData.getExpenseCategories(context, l10n)
        : TransactionCategoryData.getIncomeCategories(context, l10n);
        
    final cat = categories[_selectedCategoryIndex];
    final String categoryId = _selectedSubModelIndex != -1 
        ? (cat['subModels'] as List)[_selectedSubModelIndex]['id'] as String
        : cat['id'] as String;

    if (widget.initialId != null) {
      final old = await DatabaseService.getTransaction(widget.initialId!);
      if (old != null) {
        old.title = widget.initialName ?? l10n.all;
        old.amount = amount;
        old.minAmount = minAmount;
        old.maxAmount = maxAmount;
        old.isIncome = _tabIndex == 1;
        old.vaultIds = _selectedVaultIds;
        old.categoryId = categoryId;
        old.periodType = _periodData.periodType;
        await DatabaseService.updateTransaction(old);
      }
    } else {
      final tx = TransactionRecord()
        ..title = widget.initialName ?? l10n.all
        ..amount = amount
        ..minAmount = minAmount
        ..maxAmount = maxAmount
        ..isIncome = _tabIndex == 1
        ..date = DateTime.now()
        ..vaultIds = _selectedVaultIds
        ..categoryId = categoryId
        ..periodType = _periodData.periodType;
      await DatabaseService.addTransaction(tx);
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);
    final activeCategories = _tabIndex == 0 
        ? TransactionCategoryData.getExpenseCategories(context, l10n)
        : TransactionCategoryData.getIncomeCategories(context, l10n);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          TransactionTypeToggle(
            tabIndex: _tabIndex,
            onTabChanged: (index) {
              HapticFeedback.selectionClick();
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
              HapticFeedback.lightImpact();
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
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedVaultIds = ids;
                    });
                  },
                ),
                
                const SizedBox(height: AppSizes.paddingLarge),

                PrecisionCard(
                  scalingFactor: scalingFactor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded, 
                            size: 20, 
                            color: AppColors.getPrimary(context).withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.flexibleAmount,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      FluidSwitch(
                        value: _isFlexibleAmount,
                        activeColor: AppColors.getPrimary(context),
                        activeIcon: Icons.check_rounded,
                        inactiveIcon: Icons.close_rounded,
                        scalingFactor: scalingFactor * 0.9,
                        onChanged: (val) {
                          HapticFeedback.mediumImpact();
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
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                Text(
                  l10n.recurrencePeriod.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                TransactionPeriodSelector(
                  initialData: _periodData,
                  onChanged: (data) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _periodData = data;
                    });
                  },
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium, 
              vertical: AppSizes.paddingLarge
            ),
            child: SizedBox(
              width: double.infinity,
              child: PrecisionClickable(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _saveTransaction();
                },
                height: 64,
                color: Colors.transparent,
                pressedColor: AppColors.getPrimary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                child: Center(
                  child: Text(
                    l10n.save.toUpperCase(), 
                    style: TextStyle(
                      color: AppColors.getPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
