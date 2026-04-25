import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../../shared/widgets/precision_clickable.dart';
import '../../../shared/widgets/precision_card.dart';
import '../../../shared/widgets/precision_picker.dart';
import '../../../shared/widgets/precision_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PrecisionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // --- ESNEK PERİYOT ŞERİDİ (INLINE EXPANSION) ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_repeat_rounded,
                      size: 20,
                      color: AppColors.getPrimary(context).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.period.toUpperCase(),
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
                Container(
                  height: 44, // Alt seçeneklerin inline sığabilmesi için biraz daha uzun
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final List<Map<String, dynamic>> cats = [
                        {'label': l10n.oneTime, 'type': 0, 'cat': null},
                        {'label': l10n.day, 'type': 8, 'cat': 'gun'},
                        {'label': l10n.week, 'type': 1, 'cat': 'hafta'},
                        {'label': l10n.month, 'type': 2, 'cat': 'ay'},
                        {'label': l10n.yearly, 'type': 3, 'cat': null},
                      ];

                      const double spacing = 4.0;
                      final double totalWidth = constraints.maxWidth;
                      final double availableWidth = totalWidth - (spacing * (cats.length - 1));

                      // --- KARAKTER BAZLI HASSAS AĞIRLIK (CHAR-WEIGHTING) ---
                      double getWeight(int i) {
                        final c = cats[i];
                        final bool isSelected = (c['cat'] == null)
                            ? (_periodType == c['type'] && _expandedPeriodCategory == null)
                            : (_expandedPeriodCategory == c['cat']);
                        
                        if (!isSelected) return 1.1;

                        final String labelText = c['label'] as String;
                        // Karakter sayısına göre esneklik ekle (Her harf için 0.15 ek yük)
                        final double charWeight = labelText.length * 0.15;

                        if (c['cat'] != null) {
                          // Seçenekli olanlar (Gün/Hafta/Ay) + Karakter farkı
                          return 3.1 + charWeight;
                        } else {
                          // Sabit metinler (Tek Seferlik/Yıllık) + Karakter farkı
                          return 0.7 + charWeight;
                        }
                      }

                      double totalWeight = 0;
                      for (int i = 0; i < cats.length; i++) {
                        totalWeight += getWeight(i);
                      }

                      // Genişlikleri ve sol pozisyonları hesapla
                      List<double> widths = [];
                      List<double> lefts = [];
                      double currentLeft = 0;

                      for (int i = 0; i < cats.length; i++) {
                        double w = (getWeight(i) / totalWeight) * availableWidth;
                        widths.add(w);
                        lefts.add(currentLeft);
                        currentLeft += w + spacing;
                      }

                      return Stack(
                        children: List.generate(cats.length, (index) {
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeInOutQuart,
                            left: lefts[index],
                            width: widths[index],
                            top: 0,
                            bottom: 0,
                            child: _buildAnimatedCategoryBtnInner(cats[index]),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // AYIRICI
          if (_periodType != 0)
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),

          // 3. SATIR: DETAY SEÇİCİ (GÜN/TARİH)
          if (_periodType != 0)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  if (_periodType == 1 || [4, 5].contains(_periodType)) 
                    _buildStandardRow(
                      l10n.dayOfWeek,
                      _getWeekDays(l10n)[_selectedDay - 1],
                      Icons.calendar_view_week_rounded,
                      () => _showWeekDayPicker(l10n),
                    ),
                  if ([2, 3, 6, 7, 9, 10].contains(_periodType))
                    _buildStandardRow(
                      [2, 6, 7, 9, 10].contains(_periodType) ? l10n.dayOfMonth : l10n.dayOfYear,
                      _periodType == 3
                          ? "${_selectedDateForRecurrence.day} ${_getMonths(l10n)[_selectedDateForRecurrence.month - 1]}"
                          : "${l10n.dayOf} ${_selectedDateForRecurrence.day}",
                      Icons.calendar_month_rounded,
                      () => _showDatePicker(l10n),
                    ),
                  
                  // AYIRICI (Süre öncesi)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  ),

                  // 4. SATIR: BİTİŞ SÜRESİ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 20,
                          color: AppColors.getPrimary(context).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.duration,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              Text(
                                _duration == 0 ? l10n.repeatsIndefinitely : '$_duration ${l10n.endsAfter}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildDurationBtn(Icons.remove_rounded, () {
                              if (_duration > 0) {
                                setState(() { _duration--; });
                                _notifyChanges();
                              }
                            }),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  _duration == 0 ? "∞" : _duration.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.getPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildDurationBtn(Icons.add_rounded, () {
                              if (_duration < 120) {
                                setState(() { _duration++; });
                                _notifyChanges();
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStandardRow(String label, String value, IconData icon, VoidCallback onTap) {
    return PrecisionClickable(
      onTap: onTap,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.getPrimary(context).withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.getPrimary(context),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.getPrimary(context).withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildAnimatedCategoryBtnInner(Map<String, dynamic> catData) {
    final l10n = AppLocalizations.of(context)!;
    final String label = catData['label'];
    final int type = catData['type'];
    final String? category = catData['cat'];

    final bool isThisExpanded = (category == null)
        ? (_periodType == type && _expandedPeriodCategory == null)
        : (_expandedPeriodCategory == category);

    final bool isAnyOtherExpanded = _expandedPeriodCategory != null && !isThisExpanded;
    final String abb = label.isNotEmpty ? label[0].toUpperCase() : "";

    return PrecisionClickable(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (category == null) {
            _periodType = type;
            _expandedPeriodCategory = null;
            _duration = 0;
            _selectedDay = 1;
          } else {
            if (_expandedPeriodCategory != category) {
              _expandedPeriodCategory = category;
              _periodType = type;
            }
          }
        });
        _notifyChanges();
      },
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
        alignment: Alignment.centerLeft, // Yazı hep solda kalsın, sağa doğru genişlesin
        decoration: BoxDecoration(
          color: isThisExpanded 
              ? AppColors.getPrimary(context).withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isThisExpanded 
                ? AppColors.getPrimary(context).withValues(alpha: 0.2) 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      (isAnyOtherExpanded) ? abb : label,
                      key: ValueKey((isAnyOtherExpanded) ? abb : label),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isThisExpanded ? FontWeight.w900 : FontWeight.w600,
                        color: isThisExpanded ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  AnimatedSize(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeInOutQuart,
                    alignment: Alignment.centerLeft,
                    child: (isThisExpanded && category != null)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 6),
                            Container(width: 1, height: 12, color: AppColors.getPrimary(context).withValues(alpha: 0.3)),
                            const SizedBox(width: 4),
                            _buildSubPeriodInlineOptions(category, l10n),
                          ],
                        )
                      : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
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
        _buildPeriodBtnSheet('1$d', 8),
        _buildPeriodBtnSheet('2$d', 9),
        _buildPeriodBtnSheet('3$d', 10),
      ];
    } else if (category == 'hafta') {
      final h = l10n.week[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet('1$h', 1),
        _buildPeriodBtnSheet('2$h', 4),
        _buildPeriodBtnSheet('3$h', 5),
      ];
    } else if (category == 'ay') {
      final a = l10n.month[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet('1$a', 2),
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
    return PrecisionClickable(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _periodType = type);
        _notifyChanges();
      },
      color: isActive ? AppColors.getPrimary(context).withValues(alpha: 0.2) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      borderRadius: BorderRadius.circular(6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
          color: isActive ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context).withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildDurationBtn(IconData icon, VoidCallback onTap) {
    return PrecisionClickable(
      onTap: onTap,
      width: 32,
      height: 32,
      color: AppColors.getPrimary(context).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: Icon(icon, size: 18, color: AppColors.getPrimary(context)),
    );
  }

  void _showWeekDayPicker(AppLocalizations l10n) {
    int tempDayIndex = _selectedDay - 1;
    FluidSheet.show(
      context: context,
      title: l10n.selectDay,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrecisionPicker.strings(
            items: List.generate(7, (i) => _getWeekDays(l10n)[i]),
            initialItem: tempDayIndex,
            onSelectedItemChanged: (idx) => tempDayIndex = idx,
          ),
          const SizedBox(height: 32),
          PrecisionButton(
            label: l10n.ok,
            onTap: () {
              setState(() => _selectedDay = tempDayIndex + 1);
              _notifyChanges();
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
    );
  }

  void _showDatePicker(AppLocalizations l10n) {
    int tempDay = _selectedDateForRecurrence.day;
    int tempMonth = _selectedDateForRecurrence.month;
    FluidSheet.show(
      context: context,
      title: l10n.selectDate,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: PrecisionPicker.strings(
                  items: List.generate(31, (i) => (i + 1).toString()),
                  initialItem: tempDay - 1,
                  onSelectedItemChanged: (idx) => tempDay = idx + 1,
                ),
              ),
              if (_periodType == 3)
                Expanded(
                  flex: 2,
                  child: PrecisionPicker.strings(
                    items: List.generate(12, (i) => _getMonths(l10n)[i]),
                    initialItem: tempMonth - 1,
                    onSelectedItemChanged: (idx) => tempMonth = idx + 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          PrecisionButton(
            label: l10n.ok,
            onTap: () {
              setState(() {
                _selectedDateForRecurrence = DateTime(_selectedDateForRecurrence.year, tempMonth, tempDay);
                _selectedDay = tempDay;
              });
              _notifyChanges();
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
    );
  }

}
