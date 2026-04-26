import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/precision_segmented_control.dart';
import '../../../shared/widgets/precision_card.dart';
import '../../../shared/widgets/fluid_triple_toggle.dart';
import '../providers/widget_layout_provider.dart';
import 'dashboard_widget.dart'; // for DashboardWidgetSize

enum WidgetManagerTab { active, library }

class DashboardWidgetManagerSheet extends ConsumerStatefulWidget {
  const DashboardWidgetManagerSheet({super.key});

  @override
  ConsumerState<DashboardWidgetManagerSheet> createState() => _DashboardWidgetManagerSheetState();
}

class _DashboardWidgetManagerSheetState extends ConsumerState<DashboardWidgetManagerSheet> {
  WidgetManagerTab _activeTab = WidgetManagerTab.active;

  void _switchTab(WidgetManagerTab tab) {
    if (_activeTab == tab) return;
    HapticFeedback.mediumImpact();
    setState(() => _activeTab = tab);
  }

  final List<Map<String, dynamic>> _library = [
    {'type': 'timeline', 'name': 'İşlem Geçmişi', 'icon': Icons.history_rounded, 'defaultSize': DashboardWidgetSize.large},
    {'type': 'radar', 'name': 'Harcama Radarı', 'icon': Icons.radar_rounded, 'defaultSize': DashboardWidgetSize.large},
    {'type': 'spending', 'name': 'Harcama Devleri', 'icon': Icons.bar_chart_rounded, 'defaultSize': DashboardWidgetSize.large},
    {'type': 'quick_action', 'name': 'Hızlı İşlem', 'icon': Icons.flash_on_rounded, 'defaultSize': DashboardWidgetSize.small},
    {'type': 'vault_status', 'name': 'Kasa Durumları', 'icon': Icons.account_balance_wallet_rounded, 'defaultSize': DashboardWidgetSize.small},
    {'type': 'daily_budget', 'name': 'Günlük Bütçe', 'icon': Icons.attach_money_rounded, 'defaultSize': DashboardWidgetSize.wide},
  ];

  String _getWidgetName(String type) {
    return _library.firstWhere((w) => w['type'] == type, orElse: () => {'name': type})['name'] as String;
  }

  IconData _getWidgetIcon(String type) {
    return _library.firstWhere((w) => w['type'] == type, orElse: () => {'icon': Icons.widgets_rounded})['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(widgetLayoutProvider);
    final activeColor = AppColors.getPrimary(context);
    final scalingFactor = (MediaQuery.of(context).size.height / 812.0).clamp(0.85, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrecisionSegmentedControl(
          tabs: const ['Aktif Widget\'lar', 'Kütüphane'],
          selectedIndex: _activeTab == WidgetManagerTab.active ? 0 : 1,
          onTabChanged: (index) => _switchTab(index == 0 ? WidgetManagerTab.active : WidgetManagerTab.library),
          scalingFactor: scalingFactor,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _activeTab == WidgetManagerTab.active 
              ? _buildActiveWidgetsList(context, pages, activeColor, scalingFactor)
              : _buildLibraryList(context, pages, activeColor, scalingFactor),
        ),
      ],
    );
  }

  Widget _buildActiveWidgetsList(BuildContext context, List<List<WidgetConfig>> pages, Color activeColor, double scalingFactor) {
    final List<Map<String, dynamic>> flatList = [];
    for (int i = 0; i < pages.length; i++) {
      for (var widget in pages[i]) {
        flatList.add({'page': i, 'widget': widget});
      }
    }

    return Column(
      key: const ValueKey('active_widgets'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flatList.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
              physics: const BouncingScrollPhysics(),
              itemCount: flatList.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) {
                final item = flatList[index];
                return _buildActiveItem(context, item['widget'] as WidgetConfig, item['page'] as int, activeColor, scalingFactor, pages.length);
              },
            ),
          )
        else
          _buildEmptyState('Panoda aktif widget yok.', Icons.dashboard_customize_rounded, activeColor, scalingFactor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLibraryList(BuildContext context, List<List<WidgetConfig>> pages, Color activeColor, double scalingFactor) {
    return Column(
      key: const ValueKey('library_widgets'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_library.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
              physics: const BouncingScrollPhysics(),
              itemCount: _library.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) {
                final libItem = _library[index];
                return _buildLibraryItem(context, libItem, activeColor, scalingFactor);
              },
            ),
          )
        else
          _buildEmptyState('Kütüphane boş.', Icons.check_circle_outline_rounded, activeColor, scalingFactor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActiveItem(BuildContext context, WidgetConfig widget, int pageIndex, Color activeColor, double scalingFactor, int totalPages) {
    return PrecisionCard(
      scalingFactor: scalingFactor,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scalingFactor),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12 * scalingFactor),
                ),
                child: Icon(
                  _getWidgetIcon(widget.type),
                  color: activeColor,
                  size: 20 * scalingFactor,
                ),
              ),
              SizedBox(width: 12 * scalingFactor),
              Expanded(
                child: Text(
                  _getWidgetName(widget.type),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15 * scalingFactor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(widgetLayoutProvider.notifier).removeWidget(widget.id);
                },
              ),
            ],
          ),
          SizedBox(height: 12 * scalingFactor),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scalingFactor, vertical: 4 * scalingFactor),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8 * scalingFactor),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: pageIndex,
                      icon: Icon(Icons.arrow_drop_down_rounded, size: 20 * scalingFactor),
                      items: List.generate(totalPages + 1, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(
                            index == totalPages ? 'Yeni Sayfa' : 'Sayfa ${index + 1}',
                            style: TextStyle(fontSize: 13 * scalingFactor, fontWeight: FontWeight.w600),
                          ),
                        );
                      }),
                      onChanged: (newVal) {
                        if (newVal != null && newVal != pageIndex) {
                          HapticFeedback.lightImpact();
                          ref.read(widgetLayoutProvider.notifier).changeWidgetPage(widget.id, newVal);
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * scalingFactor),
              FluidTripleToggle(
                labels: const ['S', 'W', 'L'],
                selectedIndex: widget.size == DashboardWidgetSize.small ? 0 : widget.size == DashboardWidgetSize.wide ? 1 : 2,
                activeColors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary,
                ],
                scalingFactor: scalingFactor,
                onChanged: (index) {
                  HapticFeedback.mediumImpact();
                  final newSize = index == 0 ? DashboardWidgetSize.small : index == 1 ? DashboardWidgetSize.wide : DashboardWidgetSize.large;
                  ref.read(widgetLayoutProvider.notifier).setWidgetSizeById(widget.id, newSize);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(BuildContext context, Map<String, dynamic> libItem, Color activeColor, double scalingFactor) {
    return PrecisionCard(
      scalingFactor: scalingFactor,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * scalingFactor),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12 * scalingFactor),
            ),
            child: Icon(
              libItem['icon'] as IconData,
              color: activeColor,
              size: 20 * scalingFactor,
            ),
          ),
          SizedBox(width: 12 * scalingFactor),
          Expanded(
            child: Text(
              libItem['name'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15 * scalingFactor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16 * scalingFactor, vertical: 8 * scalingFactor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scalingFactor)),
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              ref.read(widgetLayoutProvider.notifier).addWidget(
                libItem['type'] as String,
                libItem['defaultSize'] as DashboardWidgetSize,
              );
              
              // Ekranda minik bir görsel bildirim gösterebiliriz (opsiyonel ama kullanıcı eklendiğini anlasın diye)
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${libItem['name']} panoya eklendi!'),
                  duration: const Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: Text('Ekle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13 * scalingFactor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color, double scalingFactor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60 * scalingFactor),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Icon(icon, size: 48 * scalingFactor, color: color),
            SizedBox(height: 12 * scalingFactor),
            Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13 * scalingFactor)),
          ],
        ),
      ),
    );
  }
}
