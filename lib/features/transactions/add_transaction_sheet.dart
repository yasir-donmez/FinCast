import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/neu_container.dart';
import 'widgets/neumorphic_numpad.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

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
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
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
        if (widget.initialVaultId != null) _selectedVaultId = widget.initialVaultId;
      });
    }
  }

  void _prefillIfEditing() {
    if (widget.initialAmount != null) _currentAmount = widget.initialAmount!.toStringAsFixed(0);
    if (widget.initialMinAmount != null || widget.initialMaxAmount != null) {
      _isFlexibleAmount = true;
      if (widget.initialMinAmount != null) _currentMin = widget.initialMinAmount!.toStringAsFixed(0);
      if (widget.initialMaxAmount != null) _currentMax = widget.initialMaxAmount!.toStringAsFixed(0);
      _activeAmountField = 'min';
    }
    if (widget.initialIsIncome != null) _tabIndex = widget.initialIsIncome! ? 1 : 0;
    
    if (widget.initialCategoryId != null || widget.initialName != null) {
      final categories = _tabIndex == 0 ? _getExpenseCategories(l10n) : _getIncomeCategories(l10n);
      bool found = false;
      for (int i = 0; i < categories.length; i++) {
        final cat = categories[i];
        if (cat['id'] == widget.initialCategoryId || cat['name'] == widget.initialName) {
          _selectedCategoryIndex = i;
          found = true; break;
        }
        final subs = cat['subModels'] as List<Map<String, dynamic>>?;
        if (subs != null) {
          for (int j = 0; j < subs.length; j++) {
            if (subs[j]['id'] == widget.initialCategoryId || subs[j]['name'] == widget.initialName) {
              _selectedCategoryIndex = i; _expandedCategoryIndex = i; _selectedSubModelIndex = j;
              found = true; break;
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
        _periodType = tx.periodType;
        if ([8, 9, 10].contains(_periodType)) _expandedPeriodCategory = 'gun';
        else if ([1, 4, 5].contains(_periodType)) _expandedPeriodCategory = 'hafta';
        else if ([2, 6, 7].contains(_periodType)) _expandedPeriodCategory = 'ay';
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_currentAmount) ?? 0;
    final minAmt = double.tryParse(_currentMin) ?? 0;
    final maxAmt = double.tryParse(_currentMax) ?? 0;
    if (!_isFlexibleAmount && amount <= 0) return;
    if (_isFlexibleAmount && minAmt <= 0 && maxAmt <= 0) return;

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
      ..iconCode = categoryId ?? title
      ..amount = _isFlexibleAmount ? ((minAmt + maxAmt) / 2) : amount
      ..minAmount = _isFlexibleAmount ? minAmt : null
      ..maxAmount = _isFlexibleAmount ? maxAmt : null
      ..periodType = _periodType
      ..date = widget.initialId != null ? tx.date : DateTime.now()
      ..vaultId = _selectedVaultId;

    if (widget.initialId != null) await DatabaseService.updateTransaction(tx);
    else await DatabaseService.addTransaction(tx);
  }

  void _onNumpadTap(String val) {
    setState(() {
      String current = _getActiveFieldContent();
      if (current == "0") _setActiveFieldContent(val);
      else if (current.length < 7) _setActiveFieldContent(current + val);
    });
  }

  void _onBackspaceTap() {
    setState(() {
      String current = _getActiveFieldContent();
      if (current.length > 1) _setActiveFieldContent(current.substring(0, current.length - 1));
      else _setActiveFieldContent("0");
    });
  }

  String _getActiveFieldContent() => !_isFlexibleAmount ? _currentAmount : (_activeAmountField == 'min' ? _currentMin : _currentMax);
  void _setActiveFieldContent(String val) {
    if (!_isFlexibleAmount) _currentAmount = val;
    else if (_activeAmountField == 'min') _currentMin = val;
    else _currentMax = val;
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = _tabIndex == 0 ? _getExpenseCategories(l10n) : _getIncomeCategories(l10n);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPhysicalRockerSwitch(),
        const SizedBox(height: AppSizes.paddingMedium),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isFlexibleAmount ? _buildFlexibleAmountDisplay() : _buildSingleAmountDisplay(),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        _buildHierarchicalCategorySelector(activeCategories),
        const SizedBox(height: AppSizes.paddingMedium),
        _buildAdvancedOptionsButton(context),
        const SizedBox(height: 8),
        SizedBox(
          height: 340,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final inAnim = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation);
              final outAnim = Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(animation);
              return SlideTransition(position: child.key == const ValueKey('numpad') ? outAnim : inAnim, child: child);
            },
            child: _showAdvancedOptions
                ? SingleChildScrollView(key: const ValueKey('advanced_options'), child: _buildAdvancedOptionsPanel(context))
                : Padding(
                    key: const ValueKey('numpad'),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NeumorphicNumpad(
                      onNumberTapped: _onNumpadTap,
                      onBackspaceTapped: _onBackspaceTap,
                      onDoneTapped: () async {
                        await _saveTransaction();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalRockerSwitch() {
    final isIncome = _tabIndex == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, height: 70, margin: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => setState(() { _tabIndex = isIncome ? 0 : 1; _selectedCategoryIndex = 0; _expandedCategoryIndex = -1; _selectedSubModelIndex = -1; }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: NeuContainer(borderRadius: 35, isInnerShadow: true, showBezel: true, child: const SizedBox.shrink())),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack,
              transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(isIncome ? 0.2 : -0.2),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Expanded(child: Center(child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: isIncome ? 0.3 : 1.0, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_downward_rounded, color: AppColors.error, size: 18), const SizedBox(width: 8), Text(l10n.expense.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.error))])))),
                  Container(width: 2, height: 30, color: Colors.grey.withOpacity(0.1)),
                  Expanded(child: Center(child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: isIncome ? 1.0 : 0.3, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_upward_rounded, color: AppColors.primary, size: 18), const SizedBox(width: 8), Text(l10n.income.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primary))])))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: NeuContainer(
        height: 110, borderRadius: 24, isInnerShadow: true, showBezel: true,
        child: Center(child: _DotMatrixText(text: "₺ $_currentAmount", fontSize: 56, color: _tabIndex == 1 ? AppColors.primary : AppColors.error)),
      ),
    );
  }

  Widget _buildFlexibleAmountDisplay() {
    return Container(
      height: 110, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [Expanded(child: _buildFlexBox(l10n.minimum, "₺$_currentMin", 'min')), const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.remove_rounded, color: Colors.grey, size: 24)), Expanded(child: _buildFlexBox(l10n.maximum, "₺$_currentMax", 'max'))]),
    );
  }

  Widget _buildFlexBox(String label, String value, String fieldType) {
    final bool isActive = _activeAmountField == fieldType;
    final activeColor = _tabIndex == 1 ? AppColors.getPrimary(context) : AppColors.getError(context);
    return GestureDetector(
      onTap: () => setState(() => _activeAmountField = fieldType),
      child: NeuContainer(
        borderRadius: 20, isInnerShadow: true, showBezel: true,
        color: isActive ? null : AppColors.getBackground(context).withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: isActive ? activeColor : Colors.grey, fontWeight: FontWeight.w900)), const SizedBox(height: 6), _DotMatrixText(text: value, fontSize: 24, color: isActive ? AppColors.getTextPrimary(context) : Colors.grey, isActive: isActive)]),
      ),
    );
  }

  Widget _buildHierarchicalCategorySelector(List<Map<String, dynamic>> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = index == _selectedCategoryIndex;
              final bool showSubInfo = isSelected && _selectedSubModelIndex >= 0;
              final displayIcon = showSubInfo ? (cat['subModels'] as List)[_selectedSubModelIndex]['icon'] as IconData : cat['icon'] as IconData;
              final displayName = showSubInfo ? (cat['subModels'] as List)[_selectedSubModelIndex]['name'] as String : cat['name'] as String;

              return GestureDetector(
                onTap: () => setState(() { if (isSelected && (cat['subModels'] as List).isNotEmpty) _expandedCategoryIndex = _expandedCategoryIndex == index ? -1 : index; else { _selectedCategoryIndex = index; _selectedSubModelIndex = -1; _expandedCategoryIndex = -1; } }),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250), width: isSelected ? 95 : 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isSelected ? AppColors.getInnerSurface(context) : (isDark ? AppColors.getSurface(context) : Colors.white.withOpacity(0.5)),
                      border: isSelected ? Border.all(color: cat['color'], width: 1.5) : null,
                      boxShadow: isSelected ? [BoxShadow(color: (cat['color'] as Color).withOpacity(0.2), blurRadius: 12)] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DotMatrixText(text: displayName, fontSize: 9, color: isSelected ? AppColors.getTextPrimary(context) : Colors.grey, isActive: isSelected),
                        const SizedBox(height: 6),
                        Icon(displayIcon, color: isSelected ? cat['color'] : Colors.grey, size: isSelected ? 28 : 24),
                        if (isSelected && (cat['subModels'] as List).isNotEmpty) Icon(Icons.expand_more_rounded, size: 14, color: (cat['color'] as Color).withOpacity(0.7)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_expandedCategoryIndex != -1) _buildSubCategoryRow(categories[_expandedCategoryIndex]),
      ],
    );
  }

  Widget _buildSubCategoryRow(Map<String, dynamic> cat) {
    final subs = cat['subModels'] as List;
    return Container(
      height: 50, margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subs.length,
        itemBuilder: (context, idx) {
          final isSubSelected = idx == _selectedSubModelIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubModelIndex = isSubSelected ? -1 : idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isSubSelected ? (cat['color'] as Color).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSubSelected ? cat['color'] : Colors.grey.withOpacity(0.2))),
                child: Row(children: [Icon(subs[idx]['icon'], size: 14, color: isSubSelected ? cat['color'] : Colors.grey), const SizedBox(width: 6), Text(subs[idx]['name'], style: TextStyle(fontSize: 11, fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal, color: isSubSelected ? cat['color'] : Colors.grey))]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedOptionsButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
        child: NeuContainer(width: 64, height: 36, borderRadius: 18, isInnerShadow: _showAdvancedOptions, child: Icon(_showAdvancedOptions ? Icons.apps_rounded : Icons.tune_rounded, size: 20, color: _showAdvancedOptions ? AppColors.primary : Colors.grey)),
      ),
    );
  }

  Widget _buildAdvancedOptionsPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVaultSelectorRow(),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.flexibleAmount, style: const TextStyle(fontWeight: FontWeight.bold)), Switch(value: _isFlexibleAmount, onChanged: (v) => setState(() { _isFlexibleAmount = v; _activeAmountField = v ? 'min' : 'amount'; }))]),
          const Divider(),
          _buildRecurrenceSection(),
        ],
      ),
    );
  }

  Widget _buildVaultSelectorRow() {
    final selected = _selectedVaultId == null ? null : _vaults.firstWhere((v) => v.id == _selectedVaultId, orElse: () => _vaults.first);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.vaultOrGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => _showVaultPicker(),
          child: NeuContainer(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), borderRadius: 12, child: Text(selected?.name ?? l10n.generalBalance, style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
      ],
    );
  }

  void _showVaultPicker() {
    showModalBottomSheet(context: context, builder: (ctx) => Container(
      height: 300, color: AppColors.getBackground(context),
      child: ListView.builder(
        itemCount: _vaults.length + 1,
        itemBuilder: (c, i) {
          final v = i == 0 ? null : _vaults[i-1];
          return ListTile(title: Text(v?.name ?? l10n.generalBalance), onTap: () { setState(() => _selectedVaultId = v?.id); Navigator.pop(ctx); });
        },
      ),
    ));
  }

  Widget _buildRecurrenceSection() {
    return Column(
      children: [
        Text(l10n.recurrencePeriod, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [0, 1, 2, 3].map((p) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(p == 0 ? l10n.oneTime : (p == 1 ? l10n.week : (p == 2 ? l10n.month : l10n.yearly))), selected: _periodType == p, onSelected: (v) => setState(() => _periodType = p)))).toList())),
      ],
    );
  }

  List<Map<String, dynamic>> _getExpenseCategories(AppLocalizations l10n) => [
    {'id': 'exp_grocery', 'name': l10n.grocery, 'icon': Icons.shopping_basket_rounded, 'color': Colors.orange, 'subModels': [{'id': 'exp_grocery_food', 'name': l10n.food, 'icon': Icons.egg_rounded}, {'id': 'exp_grocery_cleaning', 'name': l10n.cleaning, 'icon': Icons.cleaning_services_rounded}, {'id': 'exp_grocery_personal', 'name': l10n.personalCare, 'icon': Icons.face_rounded}]},
    {'id': 'exp_dining', 'name': l10n.dining, 'icon': Icons.restaurant_rounded, 'color': Colors.red, 'subModels': [{'id': 'exp_dining_restaurant', 'name': l10n.restaurant, 'icon': Icons.restaurant_menu_rounded}, {'id': 'exp_dining_fastfood', 'name': l10n.fastFood, 'icon': Icons.fastfood_rounded}, {'id': 'exp_dining_cafe', 'name': l10n.cafe, 'icon': Icons.coffee_rounded}]},
    {'id': 'exp_rent', 'name': l10n.rent, 'icon': Icons.home_rounded, 'color': Colors.blue, 'subModels': [{'id': 'exp_rent_home', 'name': l10n.homeRent, 'icon': Icons.apartment_rounded}, {'id': 'exp_rent_office', 'name': l10n.workspace, 'icon': Icons.business_rounded}]},
    {'id': 'exp_other', 'name': l10n.other, 'icon': Icons.more_horiz_rounded, 'color': Colors.grey, 'subModels': <Map<String, dynamic>>[]},
  ];

  List<Map<String, dynamic>> _getIncomeCategories(AppLocalizations l10n) => [
    {'id': 'inc_salary', 'name': l10n.salary, 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.green, 'subModels': [{'id': 'inc_salary_main', 'name': l10n.mainSalary, 'icon': Icons.payments_rounded}, {'id': 'inc_salary_bonus', 'name': l10n.bonus, 'icon': Icons.card_giftcard_rounded}]},
    {'id': 'inc_other', 'name': l10n.other, 'icon': Icons.more_horiz_rounded, 'color': Colors.grey, 'subModels': <Map<String, dynamic>>[]},
  ];
}

class _DotMatrixText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final bool isActive;
  const _DotMatrixText({required this.text, required this.fontSize, required this.color, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      child: Text(
        text, key: ValueKey(text),
        style: TextStyle(
          fontFamily: 'monospace', fontSize: fontSize, fontWeight: FontWeight.w900, 
          color: isActive ? color : color.withOpacity(0.2), 
          letterSpacing: 1, 
          shadows: [if (isActive) Shadow(color: color.withOpacity(0.5), blurRadius: 10)]
        ),
      ),
    );
  }
}
