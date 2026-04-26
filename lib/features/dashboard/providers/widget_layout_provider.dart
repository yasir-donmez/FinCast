import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard_widget.dart';

class WidgetConfig {
  final String id;
  final String type;
  final DashboardWidgetSize size;
  final int page;

  WidgetConfig({
    required this.id,
    required this.type,
    required this.size,
    required this.page,
  });

  WidgetConfig copyWith({String? id, String? type, DashboardWidgetSize? size, int? page}) {
    return WidgetConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      page: page ?? this.page,
    );
  }
}

class WidgetLayoutNotifier extends StateNotifier<List<List<WidgetConfig>>> {
  WidgetLayoutNotifier() : super([]) {
    // Başlangıç verilerini normalize ederek yükle
    _normalize(_initialWidgets);
  }

  static final List<WidgetConfig> _initialWidgets = [
    WidgetConfig(id: '1', type: 'timeline', size: DashboardWidgetSize.large, page: 0),
    WidgetConfig(id: '2', type: 'radar', size: DashboardWidgetSize.large, page: 1),
    WidgetConfig(id: '3', type: 'spending', size: DashboardWidgetSize.large, page: 2),
    WidgetConfig(id: '4', type: 'quick_action', size: DashboardWidgetSize.small, page: 3),
    WidgetConfig(id: '5', type: 'vault_status', size: DashboardWidgetSize.small, page: 3),
    WidgetConfig(id: '6', type: 'daily_budget', size: DashboardWidgetSize.wide, page: 3),
  ];

  int _getWeight(DashboardWidgetSize size) {
    switch (size) {
      case DashboardWidgetSize.small: return 1;
      case DashboardWidgetSize.wide: return 2;
      case DashboardWidgetSize.large: return 4;
    }
  }

  void _normalize(List<WidgetConfig> widgets) {
    // 1. Sıralama (Sayfa -> ID)
    widgets.sort((a, b) {
      if (a.page != b.page) return a.page.compareTo(b.page);
      return a.id.compareTo(b.id);
    });

    final List<List<WidgetConfig>> newPages = [[], [], [], []];
    List<WidgetConfig> overflow = [];
    
    // Maksimum 4 sayfa (0, 1, 2, 3)
    for (int pageIdx = 0; pageIdx < 4; pageIdx++) {
      int currentWeight = 0;
      final candidateWidgets = [
        ...widgets.where((w) => w.page == pageIdx),
        ...overflow
      ];
      overflow = []; 

      for (var w in candidateWidgets) {
        final wWeight = _getWeight(w.size);
        if (currentWeight + wWeight <= 4) {
          newPages[pageIdx].add(w.copyWith(page: pageIdx));
          currentWeight += wWeight;
        } else {
          overflow.add(w.copyWith(page: pageIdx + 1));
        }
      }
    }
    // 4 sayfa dolduysa ve hala overflow varsa, onlar eklenmez (silinir)
    state = newPages;
  }

  void removeWidget(String id) {
    final allWidgets = state.expand((p) => p).toList();
    allWidgets.removeWhere((w) => w.id == id);
    _normalize(allWidgets);
  }

  void addWidget(String type, DashboardWidgetSize size) {
    final id = 'widget_${DateTime.now().millisecondsSinceEpoch}';
    // Son sayfada yer varsa oraya, yoksa ilk boşluğa eklemeye çalışır
    final newWidget = WidgetConfig(
      id: id,
      type: type,
      size: size,
      page: 3, // Önce son sayfayı dene, normalize en uygun yere iter
    );

    final allWidgets = [...state.expand((p) => p), newWidget];
    _normalize(allWidgets);
  }

  void changeWidgetPage(String widgetId, int newPageIndex) {
    final int targetPage = newPageIndex.clamp(0, 3);
    final allWidgets = state.expand((p) => p).toList();
    
    _normalize(allWidgets.map((w) {
      if (w.id == widgetId) return w.copyWith(page: targetPage);
      return w;
    }).toList());
  }

  void setWidgetSizeById(String id, DashboardWidgetSize newSize) {
    final allWidgets = state.expand((p) => p).toList();
    _normalize(allWidgets.map((w) {
      if (w.id == id) return w.copyWith(size: newSize);
      return w;
    }).toList());
  }
}

final widgetLayoutProvider = StateNotifierProvider<WidgetLayoutNotifier, List<List<WidgetConfig>>>((ref) {
  return WidgetLayoutNotifier();
});
