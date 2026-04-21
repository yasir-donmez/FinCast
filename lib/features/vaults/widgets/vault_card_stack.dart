import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../vaults_providers.dart';
import 'integrated_vault_card.dart';

class VaultCardStack extends StatefulWidget {
  final List<String?> deckItems;
  final List<TransactionUI> allTransactions;
  final int currentIndex;
  final Function(String?) onVaultSelect;
  final Color activeColor;
  final AppLocalizations l10n;
  final List<TransactionGroup> groups;
  final double morphProgress;
  final Function(String) onVaultTap;

  const VaultCardStack({
    super.key,
    required this.deckItems, 
    required this.allTransactions, 
    required this.currentIndex, 
    required this.onVaultSelect, 
    required this.activeColor, 
    required this.l10n, 
    required this.groups, 
    required this.morphProgress,
    required this.onVaultTap,
  });

  @override
  State<VaultCardStack> createState() => _VaultCardStackState();
}

class _VaultCardStackState extends State<VaultCardStack> {
  late PageController _pageController;
  int? _lastTargetIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex, viewportFraction: 0.70);
    _lastTargetIndex = widget.currentIndex;
  }
  
  @override
  void didUpdateWidget(covariant VaultCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // YENİ: Manyetik Kilit Mantığı
    // Eğer dikey kaydırma (morphing) başladıysa ve yatayda tam oturmamışsak, hemen en yakın sayfaya kilitlen.
    if (widget.morphProgress > 0.01 && oldWidget.morphProgress <= 0.01) {
      if (_pageController.hasClients) {
        final double? currentPage = _pageController.page;
        if (currentPage != null) {
          final int targetPage = currentPage.round();
          // Eğer şu anki sayfa hedef sayfadan farklıysa veya tam integer değilse kilitlen
          if ((currentPage - targetPage).abs() > 0.01) {
             _pageController.animateToPage(
              targetPage, 
              duration: const Duration(milliseconds: 200), 
              curve: Curves.easeOutCubic
            );
            // Seçimi de anında güncelle ki header verisi doğru gelsin
            // HATA FİX: Build aşamasında provider değiştirmemek için mikro görev (microtask) içine alıyoruz.
            Future.microtask(() => widget.onVaultSelect(widget.deckItems[targetPage]));
          }
        }
      }
    }

    if (oldWidget.currentIndex != widget.currentIndex && _pageController.hasClients) {
      if (_lastTargetIndex != widget.currentIndex) {
        _lastTargetIndex = widget.currentIndex;
        _pageController.animateToPage(widget.currentIndex, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kasa kartları %1 bile küçülmeye başlasa etkileşimi (kaydırmayı) kapatıyoruz.
    final bool isInteractingDisabled = widget.morphProgress > 0.01;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification && !isInteractingDisabled) {
          final page = _pageController.page?.round() ?? 0;
          if (_lastTargetIndex != page) {
            _lastTargetIndex = page;
            HapticFeedback.selectionClick();
            widget.onVaultSelect(widget.deckItems[page]);
          }
        }
        return true;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: isInteractingDisabled ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        itemCount: widget.deckItems.length,
        itemBuilder: (context, index) {
          final vaultId = widget.deckItems[index];
          final txs = vaultId == null ? widget.allTransactions : widget.allTransactions.where((t) => t.groupIds.contains(vaultId)).toList();
          final income = txs.where((t) => t.isIncome).fold<double>(0, (sum, t) => sum + t.monthlyEquivalent);
          final expense = txs.where((t) => !t.isIncome).fold<double>(0, (sum, t) => sum + t.monthlyEquivalent);
          final balance = income - expense;

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                double diff = (_pageController.page! - index).abs();
                value = (1 - (diff * 0.15)).clamp(0.85, 1.0);
              } else {
                value = index == widget.currentIndex ? 1.0 : 0.85;
              }
              
              final isCurrent = index == widget.currentIndex;
              final cardOpacity = isCurrent ? 1.0 : (1 - widget.morphProgress * 3.5).clamp(0.0, 1.0);
              
              // Seçili olmayan kartlar daha hızlı yanlara doğru kaysın (Depth Effect)
              final double slideOutOffset = (index - widget.currentIndex) * (widget.morphProgress * 450);

              return Center(
                child: Opacity(
                  opacity: cardOpacity * (isCurrent ? 1.0 : (value * 2 - 1).clamp(0.0, 1.0)),
                  child: Transform.translate(
                    offset: Offset(slideOutOffset, 0),
                    child: Transform.scale(
                      scale: isCurrent ? value : value * (1 - widget.morphProgress * 0.2), // Küçük bir küçülme eklendi
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onTap: isCurrent && vaultId != null ? () => widget.onVaultTap(vaultId) : null,
                          child: IntegratedVaultCard(
                            vaultId: vaultId,
                            income: income,
                            expense: expense,
                            balance: balance,
                            txs: txs,
                            activeColor: widget.activeColor,
                            l10n: widget.l10n,
                            vaultName: index == 0 ? widget.l10n.mainVault : widget.groups[index - 1].name,
                            morphProgress: widget.morphProgress,
                            isCurrent: isCurrent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
