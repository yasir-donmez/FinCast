import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/neu_container.dart';
import 'widgets/neumorphic_numpad.dart';

/// Merkez FAB ikonuna basılınca açılan Yeni Gelir/Gider Ekranı (Transaction Modal)
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  // Sekme Kontrolü: 0 = Gider, 1 = Gelir
  int _tabIndex = 0;

  // Numpad üzerinden girilen değerler
  String _currentAmount = "0";
  String _currentMin = "0";
  String _currentMax = "0";

  // Hangi alanın (Tutar, Min, Max) numpad ile güncellendiğini tutar
  // 'amount', 'min', 'max'
  String _activeAmountField = 'amount';

  // Seçili Kategori (İlkini varsayılan seç)
  int _selectedCategoryIndex = 0;

  // Gelişmiş Seçenekler
  bool _showAdvancedOpts = false;
  bool _isFlexibleAmount = false;

  // Periyot Tipi (0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık)
  int _periodType = 0;

  // Tekrarlama Günü (Haftalık için 1-7, Aylık için 1-31)
  int _selectedDay = 1;

  // Süre (Örn: Kaç ay/hafta sürecek? 0 = Süresiz/Sürekli)
  int _duration = 0;

  // GİDER KATEGORİSİ (12 Çeşitli Model)
  final List<Map<String, dynamic>> _expenseCategories = [
    {
      'name': 'Market',
      'icon': Icons.shopping_basket_rounded,
      'color': Colors.orange,
    },
    {
      'name': 'Yemek',
      'icon': Icons.restaurant_rounded,
      'color': Colors.deepOrangeAccent,
    },
    {'name': 'Kira', 'icon': Icons.home_rounded, 'color': Colors.blue},
    {
      'name': 'Fatura',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.lightBlue,
    },
    {
      'name': 'Eğlence',
      'icon': Icons.movie_creation_rounded,
      'color': AppColors.secondary,
    },
    {
      'name': 'Abonelik',
      'icon': Icons.subscriptions_rounded,
      'color': AppColors.error,
    },
    {
      'name': 'Sağlık',
      'icon': Icons.medical_services_rounded,
      'color': Colors.greenAccent,
    },
    {
      'name': 'Ulaşım',
      'icon': Icons.directions_car_rounded,
      'color': Colors.teal,
    },
    {
      'name': 'Giyim',
      'icon': Icons.checkroom_rounded,
      'color': Colors.pinkAccent,
    },
    {'name': 'Eğitim', 'icon': Icons.school_rounded, 'color': Colors.amber},
    {
      'name': 'Borç Ödeme',
      'icon': Icons.credit_card_rounded,
      'color': Colors.redAccent,
    },
    {'name': 'Diğer', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];

  // GELİR KATEGORİSİ (8 Çeşitli Model)
  final List<Map<String, dynamic>> _incomeCategories = [
    {
      'name': 'Maaş',
      'icon': Icons.account_balance_wallet_rounded,
      'color': AppColors.primary,
    },
    {
      'name': 'Ek Gelir',
      'icon': Icons.monetization_on_rounded,
      'color': Colors.green,
    },
    {
      'name': 'Yatırım Getirisi',
      'icon': Icons.trending_up_rounded,
      'color': Colors.blueAccent,
    },
    {
      'name': 'Burs / Kredi',
      'icon': Icons.school_rounded,
      'color': Colors.amber,
    },
    {
      'name': 'Satış',
      'icon': Icons.store_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Kira Geliri',
      'icon': Icons.house_rounded,
      'color': AppColors.secondary,
    },
    {
      'name': 'Hediye',
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.pinkAccent,
    },
    {'name': 'Diğer', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];

  void _onNumpadTap(String val) {
    setState(() {
      String currentTarget = _getActiveFieldContent();

      if (currentTarget == "0") {
        _setActiveFieldContent(val);
      } else {
        // En fazla 7 haneye kadar izin ver (milyonlar)
        if (currentTarget.length < 7) {
          _setActiveFieldContent(currentTarget + val);
        }
      }
    });
  }

  void _onBackspaceTap() {
    setState(() {
      String currentTarget = _getActiveFieldContent();

      if (currentTarget.length > 1) {
        _setActiveFieldContent(
          currentTarget.substring(0, currentTarget.length - 1),
        );
      } else {
        _setActiveFieldContent("0");
      }
    });
  }

  String _getActiveFieldContent() {
    if (!_isFlexibleAmount) return _currentAmount;
    return _activeAmountField == 'min' ? _currentMin : _currentMax;
  }

  void _setActiveFieldContent(String val) {
    if (!_isFlexibleAmount) {
      _currentAmount = val;
    } else {
      if (_activeAmountField == 'min') {
        _currentMin = val;
      } else {
        _currentMax = val;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aktif Sekmeye göre geçerli kategorileri seç
    final activeCategories = _tabIndex == 0
        ? _expenseCategories
        : _incomeCategories;

    return Container(
      // Yukarıdan ekranın %95'ini kaplayan Bottom Sheet boyutlandırması
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingMedium),
          // Tutma / Kaydırma (Handle) Çizgisi
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          // 1. GELİR / GİDER SEKMELERİ
          _buildTypeToggle(),

          const SizedBox(height: AppSizes.paddingMedium),

          // 2. GİRİLEN MİKTAR / ESNEK MİKTAR GÖSTERGESİ
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isFlexibleAmount
                ? _buildFlexibleAmountDisplay()
                : _buildSingleAmountDisplay(),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // 3. KATEGORİ SEÇİCİ
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              itemCount: activeCategories.length,
              itemBuilder: (context, index) {
                final cat = activeCategories[index];
                final isSelected = index == _selectedCategoryIndex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AppSizes.paddingMedium,
                    ),
                    child: NeuContainer(
                      width: 82,
                      isInnerShadow: isSelected, // Seçiliyse içe gömülü
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat['icon'],
                              color: isSelected
                                  ? cat['color']
                                  : AppColors.textSecondary,
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Center(
                                child: Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontSize:
                                        9.5, // slightly smaller to fit "Abonelik" and "Yemek"
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    height: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // 4. GELİŞMİŞ SEÇENEKLER BAŞLIĞI / GERİ DÖN BUTONU
          _buildAdvancedOptionsHeader(),

          // Boşluk doldurucu
          const Spacer(),

          // 5. ALT PANEL: (NUMPAD veya GELİŞMİŞ SEÇENEKLER ÇIKAR)
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.4),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _showAdvancedOpts
                  ? _buildAdvancedOptionsPanel()
                  : NeumorphicNumpad(
                      key: const ValueKey('numpad'),
                      onNumberTapped: _onNumpadTap,
                      onBackspaceTapped: _onBackspaceTap,
                      onDoneTapped: () {
                        // İşlemi Veritabanına (Isar) Kaydetme Adımı
                        Navigator.pop(context); // Ekranı kapat
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // TEK SEFERLİK SABİT TUTAR GÖSTERGESİ
  Widget _buildSingleAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "₺ $_currentAmount",
          key: const ValueKey('single_amount'),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }

  // ESNEK (MİN-MAX) TUTAR GÖSTERGESİ
  Widget _buildFlexibleAmountDisplay() {
    return Padding(
      key: const ValueKey('flex_amount'),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildFlexBox("Minimum", "₺$_currentMin", 'min')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "-",
              style: TextStyle(
                fontSize: 24,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildFlexBox("Maksimum", "₺$_currentMax", 'max')),
        ],
      ),
    );
  }

  // Esnek tutar alt öğesi (Min veya Max kutucuğu)
  Widget _buildFlexBox(String label, String value, String fieldType) {
    final bool isActive = _activeAmountField == fieldType;
    return GestureDetector(
      onTap: () => setState(() => _activeAmountField = fieldType),
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        isInnerShadow: isActive, // Aktif odaklanan kutucuk içe göçer
        borderRadius: AppSizes.radiusLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sadece Aç/Kapa Başlığı (Panelin İçini Ayırdık)
  Widget _buildAdvancedOptionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showAdvancedOpts = !_showAdvancedOpts;
            if (!_showAdvancedOpts) {
              _isFlexibleAmount = false; // Kapatılınca iptal olsun
              _periodType = 0;
              _duration = 0;
              _selectedDay = 1;
              _activeAmountField = 'amount';
            }
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showAdvancedOpts
                  ? "Seçenekleri Kapat ve Numpad'e Dön"
                  : "Gelişmiş Seçenekler (Esnek Tutar & Tekrarlama)",
              style: TextStyle(
                fontSize: 12,
                color: _showAdvancedOpts
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: _showAdvancedOpts
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showAdvancedOpts
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: _showAdvancedOpts
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // SADECE Gelişmiş Ayarlar Paneli (Numpad yerine geçecek)
  Widget _buildAdvancedOptionsPanel() {
    return Container(
      key: const ValueKey('advanced_panel'),
      height: 300, // Numpad ile ortalama aynı yükseklik
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: NeuContainer(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        borderRadius: AppSizes.radiusLarge,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Esnek (Min/Max) Bütçe Anahtarı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Esnek (Min-Max) Tutar Gir",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isFlexibleAmount,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isFlexibleAmount = val;
                        _activeAmountField = val ? 'min' : 'amount';
                      });
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.darkShadow),

              // 2. Periyot Tipi (Tek Sefer, Haftalık, Aylık...)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Tekrarlama Periyodu",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildPeriodBtn("Tek Sefer", 0),
                  _buildPeriodBtn("Haftalık", 1),
                  _buildPeriodBtn("Aylık", 2),
                  _buildPeriodBtn("Yıllık", 3),
                ],
              ),

              // 3. Tekrarlama Günü (Eğer Aylık veya Haftalık seçildiyse)
              if (_periodType == 1 || _periodType == 2) ...[
                const SizedBox(height: AppSizes.paddingMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _periodType == 1
                          ? "Haftanın Günü (1-7)"
                          : "Ayın Günü (1-31)",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDurationBtn(Icons.remove, () {
                          setState(() {
                            if (_selectedDay > 1) {
                              _selectedDay--;
                            }
                          });
                        }),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDay.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildDurationBtn(Icons.add, () {
                          setState(() {
                            int maxDays = _periodType == 1 ? 7 : 31;
                            if (_selectedDay < maxDays) {
                              _selectedDay++;
                            }
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ],

              // 4. Süre (Eğer Tek Seferlik değilse)
              if (_periodType != 0) ...[
                const SizedBox(height: AppSizes.paddingMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bitiş Süresi",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _duration == 0
                                ? "Sürekli Tekrar Eder"
                                : "$_duration ${_getPeriodName(_periodType)} Sonra Biter",
                            style: TextStyle(
                              fontSize: 12,
                              color: _duration == 0
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
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
                          if (_duration > 0) setState(() => _duration--);
                        }),
                        const SizedBox(width: 12),
                        Text(
                          _duration == 0 ? "Sınırsız" : _duration.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildDurationBtn(Icons.add, () {
                          if (_duration < 120) setState(() => _duration++);
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
    );
  }

  // Periyot isimleri yardımcısı
  String _getPeriodName(int type) {
    switch (type) {
      case 1:
        return "Hafta";
      case 2:
        return "Ay";
      case 3:
        return "Yıl";
      default:
        return "";
    }
  }

  // Periyot tekli buton yapısı
  Widget _buildPeriodBtn(String label, int type) {
    final bool isActive = _periodType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _periodType = type;
          if (type == 0) {
            _duration = 0; // Tek seferliğe dönünce süreyi sıfırla
            _selectedDay = 1;
          } else if (type == 1 && _selectedDay > 7) {
            _selectedDay = 7; // Haftalık max 7 olabilir
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.surface,
            width: 1.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // Süre +/- butonları
  Widget _buildDurationBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        width: 36,
        height: 36,
        borderRadius: AppSizes.radiusRound,
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  // Gelir/Gider geçiş butonu UI
  Widget _buildTypeToggle() {
    return NeuContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: AppSizes.radiusRound,
      isInnerShadow: true, // İçe gömülmüş zemin
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBtn(
            "GİDER",
            0,
            Icons.arrow_downward_rounded,
            AppColors.error,
          ),
          _buildTabBtn(
            "GELİR",
            1,
            Icons.arrow_upward_rounded,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  // Toggle içindeki butonlar
  Widget _buildTabBtn(
    String label,
    int index,
    IconData icon,
    Color activeColor,
  ) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () {
        if (_tabIndex != index) {
          setState(() {
            _tabIndex = index;
            _selectedCategoryIndex = 0; // Kategori sıfırlama
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: AppColors.background,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.lightShadow,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
