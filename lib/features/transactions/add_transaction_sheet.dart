import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

import 'widgets/transaction_vault_selector.dart';
import 'widgets/transaction_currency_selector.dart';
import 'widgets/transaction_type_toggle.dart';
import 'widgets/transaction_amount_input.dart';
import 'widgets/transaction_category_data.dart';
import 'widgets/transaction_category_selector.dart';
import 'widgets/transaction_period_selector.dart';
import '../../shared/widgets/precision_toggle.dart';
import '../../shared/widgets/precision_card.dart';
import '../../shared/widgets/precision_input.dart';
import '../../shared/widgets/precision_button.dart';
import '../../core/providers/settings_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final int? initialId;
  final String? initialName;
  final double? initialAmount;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final bool? initialIsIncome;
  final List<int>? initialVaultIds;
  final String? initialCategoryId;
  final String? initialNote;
  final String? initialCurrency;
  
  // --- Tekrarlama (Periyot) Alanları ---
  final int? initialPeriodType;
  final int? initialRecurrenceDay;
  final DateTime? initialRecurrenceDate;
  final int? initialRecurrenceDuration;

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
    this.initialNote,
    this.initialCurrency,
    this.initialPeriodType,
    this.initialRecurrenceDay,
    this.initialRecurrenceDate,
    this.initialRecurrenceDuration,
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
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  bool _isFlexibleAmount = false;

  int _selectedCategoryIndex = 0;
  int _expandedCategoryIndex = -1;
  int _selectedSubModelIndex = -1;
  String _selectedCurrency = '₺';

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
    _selectedCurrency = ref.read(settingsProvider).currencySymbol;
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
    _noteController.dispose();
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
      if (widget.initialNote != null) {
        _noteController.text = widget.initialNote!;
      }
      if (widget.initialCurrency != null) {
        _selectedCurrency = widget.initialCurrency!;
      }
      if (widget.initialVaultIds != null) {
        _selectedVaultIds = List<int>.from(widget.initialVaultIds!);
      }
      
      // --- Eski Periyot Ayarlarını Form'a Yükle ---
      if (widget.initialPeriodType != null && widget.initialPeriodType != 0) {
        _periodData = TransactionPeriodData(
          periodType: widget.initialPeriodType!,
          selectedDay: widget.initialRecurrenceDay ?? 1,
          selectedDateForRecurrence: widget.initialRecurrenceDate ?? DateTime.now(),
          duration: widget.initialRecurrenceDuration ?? 0,
          // expandedPeriodCategory null bırakılabilir, alt bileşen periodType'a göre kendi çıkarımını yapar
        );
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
    
    // Sadece "Esnek Tutar" aktifse min/max değerlerini al, yoksa null yap (çöpe at)
    final minAmount = _isFlexibleAmount ? double.tryParse(_minController.text) : null;
    final maxAmount = _isFlexibleAmount ? double.tryParse(_maxController.text) : null;
    
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
        final catName = _selectedSubModelIndex != -1 
            ? (cat['subModels'] as List)[_selectedSubModelIndex]['name'] as String
            : cat['name'] as String;
            
        old.title = catName;
        old.amount = amount;
        old.minAmount = minAmount;
        old.maxAmount = maxAmount;
        old.isIncome = _tabIndex == 1;
        old.vaultIds = _selectedVaultIds;
        old.categoryId = categoryId;
        
        // --- Periyot Verilerini Eksiksiz Kaydet ---
        old.periodType = _periodData.periodType;
        old.recurrenceDay = _periodData.selectedDay;
        old.recurrenceDate = _periodData.selectedDateForRecurrence;
        old.recurrenceDuration = _periodData.duration;
        
        old.note = _noteController.text.isNotEmpty ? _noteController.text : null;
        old.currency = _selectedCurrency;
        
        await DatabaseService.updateTransaction(old);
      }
    } else {
      final catName = _selectedSubModelIndex != -1 
          ? (cat['subModels'] as List)[_selectedSubModelIndex]['name'] as String
          : cat['name'] as String;

      final tx = TransactionRecord()
        ..title = catName
        ..amount = amount
        ..minAmount = minAmount
        ..maxAmount = maxAmount
        ..isIncome = _tabIndex == 1
        ..date = DateTime.now()
        ..vaultIds = _selectedVaultIds
        ..categoryId = categoryId
        
        // --- Periyot Verilerini Eksiksiz Kaydet ---
        ..periodType = _periodData.periodType
        ..recurrenceDay = _periodData.selectedDay
        ..recurrenceDate = _periodData.selectedDateForRecurrence
        ..recurrenceDuration = _periodData.duration
        
        ..note = _noteController.text.isNotEmpty ? _noteController.text : null
        ..currency = _selectedCurrency;
      
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

    return Column(
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
            currency: _selectedCurrency, // <-- Eklendi: Kullanıcının seçtiği birim buraya akıyor
            amountController: _amountController,
            minController: _minController,
            maxController: _maxController,
            amountFocusNode: _amountFocusNode,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
            child: PrecisionCard(
              scalingFactor: scalingFactor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.linear_scale_rounded, 
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
                  PrecisionToggle(
                    value: _isFlexibleAmount,
                    activeColor: AppColors.getPrimary(context),
                    activeIcon: Icons.pause_rounded,
                    inactiveIcon: Icons.stop_rounded,
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

          // --- HESAP PARAMETRELERİ (KASA & PARA BİRİMİ) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
            child: PrecisionCard(
              scalingFactor: scalingFactor,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // KASA
                  TransactionVaultSelector(
                    vaults: _vaults,
                    selectedVaultIds: _selectedVaultIds,
                    scalingFactor: scalingFactor,
                    onChanged: (ids) {
                      setState(() => _selectedVaultIds = ids);
                    },
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: (Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black).withValues(alpha: 0.08),
                  ),
                  // PARA BİRİMİ
                  TransactionCurrencySelector(
                    selectedCurrency: _selectedCurrency,
                    scalingFactor: scalingFactor,
                    onChanged: (val) {
                      setState(() => _selectedCurrency = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

                  // --- DETAYLAR (NOT & PERİYOT) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                    child: PrecisionCard(
                      scalingFactor: scalingFactor,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded, 
                                size: 20, 
                                color: AppColors.getPrimary(context).withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.description.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getTextPrimary(context).withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PrecisionInput(
                            controller: _noteController,
                            hintText: 'İşleme dair not bırakın...',
                            icon: Icons.edit_note_rounded,
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 24,
                            thickness: 0.5,
                            color: (Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black).withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 12),
                          TransactionPeriodSelector(
                            initialData: _periodData,
                            scalingFactor: scalingFactor,
                            onChanged: (data) {
                              HapticFeedback.mediumImpact();
                              setState(() => _periodData = data);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

          const SizedBox(height: AppSizes.paddingMedium),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
            child: PrecisionButton(
              label: l10n.save,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                _saveTransaction();
              },
              activeColor: AppColors.getPrimary(context),
              height: 64,
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
  }
}
