import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/neu_container.dart';

class TransactionPeriodData {
  final int periodType;
  final String? expandedPeriodCategory;
  final int selectedDay;
  final DateTime selectedDateForRecurrence;
  final int duration;

  TransactionPeriodData({
    required this.periodType,
    this.expandedPeriodCategory,
    required this.selectedDay,
    required this.selectedDateForRecurrence,
    required this.duration,
  });
}

class TransactionPeriodSelector extends StatefulWidget {
  final TransactionPeriodData initialData;
  final ValueChanged<TransactionPeriodData> onChanged;

  const TransactionPeriodSelector({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<TransactionPeriodSelector> createState() => _TransactionPeriodSelectorState();
}

class _TransactionPeriodSelectorState extends State<TransactionPeriodSelector> {
  late int _periodType;
  late String? _expandedPeriodCategory;
  late int _selectedDay;
  late DateTime _selectedDateForRecurrence;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _periodType = widget.initialData.periodType;
    _expandedPeriodCategory = widget.initialData.expandedPeriodCategory;
    _selectedDay = widget.initialData.selectedDay;
    _selectedDateForRecurrence = widget.initialData.selectedDateForRecurrence;
    _duration = widget.initialData.duration;
  }

  void _notifyChanges() {
    widget.onChanged(TransactionPeriodData(
      periodType: _periodType,
      expandedPeriodCategory: _expandedPeriodCategory,
      selectedDay: _selectedDay,
      selectedDateForRecurrence: _selectedDateForRecurrence,
      duration: _duration,
    ));
  }

  List<String> _getWeekDays(AppLocalizations l10n) => [
    l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
    l10n.friday, l10n.saturday, l10n.sunday,
  ];

  List<String> _getMonths(AppLocalizations l10n) => [
    l10n.january, l10n.february, l10n.march, l10n.april,
    l10n.may, l10n.june, l10n.july, l10n.august,
    l10n.september, l10n.october, l10n.november, l10n.december,
  ];

  String _getPeriodName(AppLocalizations l10n, int type) {
    switch (type) {
      case 1: return l10n.week;
      case 2: return l10n.month;
      case 3: return l10n.year;
      case 4: return l10n.every2Weeks;
      case 5: return l10n.every3Weeks;
      case 6: return l10n.every3Months;
      case 7: return l10n.every6Months;
      case 8: return l10n.day;
      case 9: return l10n.every2Days;
      case 10: return l10n.every3Days;
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPeriodCategoryBtn(l10n.oneTime, 0, null),
            const SizedBox(width: 4),
            _buildPeriodCategoryBtn(l10n.day, 8, 'gun'),
            const SizedBox(width: 4),
            _buildPeriodCategoryBtn(l10n.week, 1, 'hafta'),
            const SizedBox(width: 4),
            _buildPeriodCategoryBtn(l10n.month, 2, 'ay'),
            const SizedBox(width: 4),
            _buildPeriodCategoryBtn(l10n.yearly, 3, null),
          ],
        ),
        
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: SizedBox(
            key: ValueKey('period_detail_$_periodType'),
            height: _periodType == 0 ? 0 : 130, // Dönem seçenekleri için alan tahsisi
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (_periodType == 1 || [4, 5].contains(_periodType)) ...[
                    const SizedBox(height: AppSizes.paddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.dayOfWeek,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            int tempDayIndex = _selectedDay - 1;
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (pickerContext) {
                                return StatefulBuilder(
                                  builder: (context, setPickerState) {
                                    return Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        color: AppColors.getBackground(context),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(AppSizes.radiusLarge),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(pickerContext),
                                                  child: Text(
                                                    l10n.cancel,
                                                    style: TextStyle(color: AppColors.getError(context)),
                                                  ),
                                                ),
                                                Text(
                                                  l10n.selectDay,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppColors.getTextPrimary(context),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedDay = tempDayIndex + 1;
                                                    });
                                                    _notifyChanges();
                                                    Navigator.pop(pickerContext);
                                                  },
                                                  child: const Text(
                                                    "OK",
                                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: ListWheelScrollView.useDelegate(
                                              itemExtent: 40,
                                              perspective: 0.005,
                                              physics: const FixedExtentScrollPhysics(),
                                              onSelectedItemChanged: (index) {
                                                setPickerState(() => tempDayIndex = index);
                                              },
                                              controller: FixedExtentScrollController(initialItem: tempDayIndex),
                                              childDelegate: ListWheelChildBuilderDelegate(
                                                childCount: 7,
                                                builder: (context, index) {
                                                  final isSelected = index == tempDayIndex;
                                                  return Center(
                                                    child: Text(
                                                      _getWeekDays(l10n)[index],
                                                      style: TextStyle(
                                                        fontSize: isSelected ? 24 : 18,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                        color: isSelected ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.getBackground(context),
                              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                              border: Border.all(color: AppColors.getInnerSurface(context), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_view_week_rounded, size: 16, color: AppColors.getTextPrimary(context)),
                                const SizedBox(width: 8),
                                Text(
                                  _getWeekDays(l10n)[_selectedDay - 1],
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if ([2, 3, 6, 7].contains(_periodType)) ...[
                    const SizedBox(height: AppSizes.paddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          [2, 6, 7].contains(_periodType) ? l10n.dayOfMonth : l10n.dayOfYear,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            int tempDay = _selectedDateForRecurrence.day;
                            int tempMonth = _selectedDateForRecurrence.month;
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (pickerContext) {
                                return StatefulBuilder(
                                  builder: (context, setPickerState) {
                                    return Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        color: AppColors.getBackground(context),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge)),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(pickerContext),
                                                  child: Text(l10n.cancel, style: TextStyle(color: AppColors.getError(context))),
                                                ),
                                                Text(
                                                  l10n.selectDate,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(context)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedDateForRecurrence = DateTime(_selectedDateForRecurrence.year, tempMonth, tempDay);
                                                      _selectedDay = tempDay;
                                                    });
                                                    _notifyChanges();
                                                    Navigator.pop(pickerContext);
                                                  },
                                                  child: const Text("OK", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: ListWheelScrollView.useDelegate(
                                                    itemExtent: 40,
                                                    perspective: 0.005,
                                                    physics: const FixedExtentScrollPhysics(),
                                                    onSelectedItemChanged: (index) {
                                                      setPickerState(() => tempDay = index + 1);
                                                    },
                                                    controller: FixedExtentScrollController(initialItem: tempDay - 1),
                                                    childDelegate: ListWheelChildBuilderDelegate(
                                                      childCount: 31,
                                                      builder: (context, index) {
                                                        final isSelected = (index + 1) == tempDay;
                                                        return Center(
                                                          child: Text(
                                                            (index + 1).toString(),
                                                            style: TextStyle(fontSize: isSelected ? 24 : 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context)),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                if (_periodType == 3)
                                                  Expanded(
                                                    flex: 2,
                                                    child: ListWheelScrollView.useDelegate(
                                                      itemExtent: 40,
                                                      perspective: 0.005,
                                                      physics: const FixedExtentScrollPhysics(),
                                                      onSelectedItemChanged: (index) {
                                                        setPickerState(() => tempMonth = index + 1);
                                                      },
                                                      controller: FixedExtentScrollController(initialItem: tempMonth - 1),
                                                      childDelegate: ListWheelChildBuilderDelegate(
                                                        childCount: 12,
                                                        builder: (context, index) {
                                                          final isSelected = (index + 1) == tempMonth;
                                                          return Center(
                                                            child: Text(
                                                              _getMonths(l10n)[index],
                                                              style: TextStyle(fontSize: isSelected ? 22 : 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context)),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.getBackground(context),
                              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                              border: Border.all(color: AppColors.getSurface(context), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _periodType == 3
                                      ? "${_selectedDateForRecurrence.day} ${_getMonths(l10n)[_selectedDateForRecurrence.month - 1]}"
                                      : "${l10n.dayOf} ${_selectedDateForRecurrence.day}",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_periodType != 0) ...[
                    const SizedBox(height: AppSizes.paddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.duration,
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
                              ),
                              Text(
                                _duration == 0
                                    ? l10n.repeatsIndefinitely
                                    : '$_duration ${_getPeriodName(l10n, _periodType)} ${l10n.endsAfter}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _duration == 0 ? AppColors.getTextSecondary(context) : AppColors.getPrimary(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDurationBtn(Icons.remove, () {
                              if (_duration > 0) {
                                setState(() => _duration--);
                                _notifyChanges();
                              }
                            }),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: _duration == 0
                                    ? Icon(Icons.all_inclusive_rounded, color: AppColors.getTextPrimary(context), size: 20)
                                    : Text(_duration.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildDurationBtn(Icons.add, () {
                              if (_duration < 120) {
                                setState(() => _duration++);
                                _notifyChanges();
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodCategoryBtn(String label, int defaultValue, String? category) {
    final l10n = AppLocalizations.of(context)!;
    final bool isThisExpanded = (category == null)
        ? (_periodType == defaultValue && _expandedPeriodCategory == null)
        : (_expandedPeriodCategory == category);

    final bool isAnyOtherExpanded = _expandedPeriodCategory != null && _expandedPeriodCategory != category;
    final String abb = label.isNotEmpty ? label[0].toUpperCase() : "";

    int flexValue = 2;
    if (_expandedPeriodCategory != null) {
      flexValue = isThisExpanded ? 7 : 2;
    }

    return Expanded(
      flex: flexValue,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (category == null) {
              _periodType = defaultValue;
              _expandedPeriodCategory = null;
              _duration = 0;
              _selectedDay = 1;
            } else {
              if (_expandedPeriodCategory != category) {
                _expandedPeriodCategory = category;
                _periodType = defaultValue;
              }
            }
          });
          _notifyChanges();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isThisExpanded ? AppColors.getPrimary(context).withOpacity(0.1) : AppColors.getSurface(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(
              color: isThisExpanded ? AppColors.getPrimary(context).withOpacity(0.6) : AppColors.getDarkShadow(context).withOpacity(0.15),
              width: 0.8,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      (isAnyOtherExpanded) ? abb : label,
                      key: ValueKey((isAnyOtherExpanded) ? abb : label),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: (isAnyOtherExpanded) ? 12 : 9.5,
                        fontWeight: isThisExpanded ? FontWeight.bold : FontWeight.w600,
                        color: isThisExpanded ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context).withOpacity(0.7),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (isThisExpanded && category != null) ...[
                    const SizedBox(width: 8),
                    Container(width: 1, height: 12, color: AppColors.getPrimary(context).withOpacity(0.15)),
                    const SizedBox(width: 4),
                    _buildSubPeriodInlineOptions(category, l10n),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubPeriodInlineOptions(String category, AppLocalizations l10n) {
    List<Widget> options = [];
    if (category == 'gun') {
      final d = l10n.day[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet(d, 8),
        _buildPeriodBtnSheet('2$d', 9),
        _buildPeriodBtnSheet('3$d', 10),
      ];
    } else if (category == 'hafta') {
      final h = l10n.week[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet(h, 1),
        _buildPeriodBtnSheet('2$h', 4),
        _buildPeriodBtnSheet('3$h', 5),
      ];
    } else if (category == 'ay') {
      final a = l10n.month[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet(a, 2),
        _buildPeriodBtnSheet('3$a', 6),
        _buildPeriodBtnSheet('6$a', 7),
      ];
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.expand((w) => [w, const SizedBox(width: 4)]).toList()..removeLast(),
    );
  }

  Widget _buildPeriodBtnSheet(String label, int type) {
    final bool isActive = _periodType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _periodType = type);
        _notifyChanges();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.getPrimary(context).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(color: isActive ? AppColors.getPrimary(context).withOpacity(0.3) : Colors.transparent, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context).withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
        borderRadius: AppSizes.radiusRound,
        child: Center(
          child: Icon(icon, size: 20, color: AppColors.getTextPrimary(context)),
        ),
      ),
    );
  }
}
