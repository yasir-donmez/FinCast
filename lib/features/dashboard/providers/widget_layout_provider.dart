import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard_widget.dart';

class WidgetConfig {
  final String id;
  final String type;
  final DashboardWidgetSize size;

  WidgetConfig({required this.id, required this.type, required this.size});

  WidgetConfig copyWith({String? id, String? type, DashboardWidgetSize? size}) {
    return WidgetConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
    );
  }
}

class WidgetLayoutNotifier extends StateNotifier<List<List<WidgetConfig>>> {
  WidgetLayoutNotifier() : super(_initialPages);

  static final List<List<WidgetConfig>> _initialPages = [
    [WidgetConfig(id: '1', type: 'timeline', size: DashboardWidgetSize.large)],
    [WidgetConfig(id: '2', type: 'radar', size: DashboardWidgetSize.large)],
    [WidgetConfig(id: '3', type: 'spending', size: DashboardWidgetSize.large)],
    [
      WidgetConfig(id: '4', type: 'quick_action', size: DashboardWidgetSize.small),
      WidgetConfig(id: '5', type: 'vault_status', size: DashboardWidgetSize.small),
      WidgetConfig(id: '6', type: 'daily_budget', size: DashboardWidgetSize.wide),
    ],
    [
      WidgetConfig(id: '7', type: 'timeline', size: DashboardWidgetSize.small),
      WidgetConfig(id: '8', type: 'radar', size: DashboardWidgetSize.small),
      WidgetConfig(id: '9', type: 'spending', size: DashboardWidgetSize.wide),
    ],
  ];

  List<List<WidgetConfig>> _normalize(List<List<WidgetConfig>> pages) {
    List<List<WidgetConfig>> newPages = [];
    List<WidgetConfig> overflow = [];

    for (int i = 0; i < pages.length; i++) {
      List<WidgetConfig> currentPage = [...pages[i]];
      
      if (overflow.isNotEmpty) {
        currentPage.insertAll(0, overflow);
        overflow = [];
      }

      List<WidgetConfig> validPage = [];
      int rowsUsed = 1;
      int currentRowRemaining = 2;
      bool hasOverflowed = false;

      for (var widget in currentPage) {
        if (hasOverflowed) {
          overflow.add(widget);
          continue;
        }

        int wWidth = (widget.size == DashboardWidgetSize.small) ? 1 : 2;
        int wHeight = (widget.size == DashboardWidgetSize.large) ? 2 : 1;

        int simulatedRowsUsed = rowsUsed;
        int simulatedRemaining = currentRowRemaining;

        if (wWidth > simulatedRemaining) {
          simulatedRowsUsed++;
          simulatedRemaining = 2;
        }

        if (simulatedRowsUsed + wHeight - 1 > 2) {
          hasOverflowed = true;
          overflow.add(widget);
        } else {
          validPage.add(widget);
          rowsUsed = simulatedRowsUsed;
          currentRowRemaining = simulatedRemaining - wWidth;
          if (wHeight == 2) {
            rowsUsed = 2;
            currentRowRemaining = 0;
          }
        }
      }
      newPages.add(validPage);
    }

    while (overflow.isNotEmpty) {
      List<WidgetConfig> newPage = [];
      int rowsUsed = 1;
      int currentRowRemaining = 2;
      List<WidgetConfig> nextOverflow = [];
      bool hasOverflowed = false;

      for (var widget in overflow) {
        if (hasOverflowed) {
          nextOverflow.add(widget);
          continue;
        }

        int wWidth = (widget.size == DashboardWidgetSize.small) ? 1 : 2;
        int wHeight = (widget.size == DashboardWidgetSize.large) ? 2 : 1;

        int simulatedRowsUsed = rowsUsed;
        int simulatedRemaining = currentRowRemaining;

        if (wWidth > simulatedRemaining) {
          simulatedRowsUsed++;
          simulatedRemaining = 2;
        }

        if (simulatedRowsUsed + wHeight - 1 > 2) {
          hasOverflowed = true;
          nextOverflow.add(widget);
        } else {
          newPage.add(widget);
          rowsUsed = simulatedRowsUsed;
          currentRowRemaining = simulatedRemaining - wWidth;
          if (wHeight == 2) {
            rowsUsed = 2;
            currentRowRemaining = 0;
          }
        }
      }
      newPages.add(newPage);
      overflow = nextOverflow;
    }

    while (newPages.isNotEmpty && newPages.last.isEmpty) {
      newPages.removeLast();
    }
    if (newPages.isEmpty) {
      newPages.add([]);
    }

    return newPages;
  }

  void removeWidget(String id) {
    final newState = state.map((page) => page.where((w) => w.id != id).toList()).toList();
    state = _normalize(newState);
  }

  void addWidget(String type, DashboardWidgetSize size, {int? pageIndex}) {
    final newState = [...state];
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newWidget = WidgetConfig(id: newId, type: type, size: size);
    
    int targetPage = pageIndex ?? (newState.isNotEmpty ? newState.length - 1 : 0);
    
    while (newState.length <= targetPage) {
      newState.add([]);
    }
    
    newState[targetPage] = [...newState[targetPage], newWidget];
    state = _normalize(newState);
  }

  void changeWidgetPage(String id, int newPageIndex) {
    WidgetConfig? widgetToMove;
    
    final newState = state.map((page) {
      final found = page.where((w) => w.id == id).toList();
      if (found.isNotEmpty) widgetToMove = found.first;
      return page.where((w) => w.id != id).toList();
    }).toList();

    if (widgetToMove == null) return;

    while (newState.length <= newPageIndex) {
      newState.add([]);
    }
    
    newState[newPageIndex] = [...newState[newPageIndex], widgetToMove!];
    state = _normalize(newState);
  }

  void setWidgetSizeById(String id, DashboardWidgetSize newSize) {
    final newState = state.map((page) {
      return page.map((w) {
        if (w.id == id) {
          return w.copyWith(size: newSize);
        }
        return w;
      }).toList();
    }).toList();
    
    state = _normalize(newState);
  }
}

final widgetLayoutProvider = StateNotifierProvider<WidgetLayoutNotifier, List<List<WidgetConfig>>>((ref) {
  return WidgetLayoutNotifier();
});
