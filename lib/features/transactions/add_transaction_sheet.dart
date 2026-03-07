import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/neu_container.dart';
import 'widgets/neumorphic_numpad.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

/// Merkez FAB ikonuna basılınca açılan Yeni Gelir/Gider Ekranı (Transaction Modal)
class AddTransactionSheet extends StatefulWidget {
  /// Düzenleme modunda: ön doldurulacak işlem bilgileri
  final int? initialId;
  final String? initialName;
  final double? initialAmount;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final bool? initialIsIncome;

  const AddTransactionSheet({
    super.key,
    this.initialId,
    this.initialName,
    this.initialAmount,
    this.initialMinAmount,
    this.initialMaxAmount,
    this.initialIsIncome,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  // Sekme Kontrolü: 0 = Gider, 1 = Gelir
  int _tabIndex = 0;

  // Kasa / Grup Seçimi
  List<Vault> _vaults = [];
  int? _selectedVaultId; // null = Genel Bakiye

  // Gelişmiş Seçenekler Görünürlüğü
  bool _showAdvancedOptions = false;

  // Numpad üzerinden girilen değerler
  String _currentAmount = "0";
  String _currentMin = "0";
  String _currentMax = "0";

  // Hangi alanın (Tutar, Min, Max) numpad ile güncellendiğini tutar
  // 'amount', 'min', 'max'
  String _activeAmountField = 'amount';

  // Seçili Kategori (İlkini varsayılan seç)
  int _selectedCategoryIndex = 0;

  // Hiyerarşik Model: Genişletilmiş kategori (-1 = hiçbiri açık değil)
  int _expandedCategoryIndex = -1;

  // Seçili alt model index'i (-1 = ana model seçili, alt model yok)
  int _selectedSubModelIndex = -1;

  /// Düzenleme modunda mı?
  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
    _loadVaults();
  }

  Future<void> _loadVaults() async {
    final vaults = await DatabaseService.getAllVaults();
    int? editingVaultId;
    if (widget.initialId != null) {
      final existingTx = await DatabaseService.getTransaction(
        widget.initialId!,
      );
      if (existingTx != null) {
        editingVaultId = existingTx.vaultId;
      }
    }

    if (mounted) {
      setState(() {
        _vaults = vaults;
        if (editingVaultId != null) {
          _selectedVaultId = editingVaultId;
        }
      });
    }
  }

  void _prefillIfEditing() {
    if (widget.initialAmount != null) {
      _currentAmount = widget.initialAmount!.toStringAsFixed(0);
    }
    if (widget.initialMinAmount != null || widget.initialMaxAmount != null) {
      _isFlexibleAmount = true;
      if (widget.initialMinAmount != null) {
        _currentMin = widget.initialMinAmount!.toStringAsFixed(0);
      }
      if (widget.initialMaxAmount != null) {
        _currentMax = widget.initialMaxAmount!.toStringAsFixed(0);
      }
      _activeAmountField = 'min'; // Varsayılanı min yap
    }
    if (widget.initialIsIncome != null) {
      _tabIndex = widget.initialIsIncome! ? 1 : 0;
    }
    if (widget.initialName != null) {
      // Kategori listesinde ismi bul
      final categories = _tabIndex == 0
          ? _expenseCategories
          : _incomeCategories;
      for (int i = 0; i < categories.length; i++) {
        if (categories[i]['name'] == widget.initialName) {
          _selectedCategoryIndex = i;
          break;
        }
        // Alt modellerde de ara
        final subs = categories[i]['subModels'] as List<Map<String, dynamic>>?;
        if (subs != null) {
          for (int j = 0; j < subs.length; j++) {
            if (subs[j]['name'] == widget.initialName) {
              _selectedCategoryIndex = i;
              _expandedCategoryIndex = i;
              _selectedSubModelIndex = j;
              break;
            }
          }
        }
      }
    }
  }

  /// İşlemi Isar DB'ye kaydet
  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_currentAmount) ?? 0;
    final minAmt = double.tryParse(_currentMin) ?? 0;
    final maxAmt = double.tryParse(_currentMax) ?? 0;

    if (!_isFlexibleAmount && amount <= 0) return; // Boş tutar kaydetme
    if (_isFlexibleAmount && minAmt <= 0 && maxAmt <= 0)
      return; // Boş esnek bütçe

    // Aktif kategori listesini al
    final categories = _tabIndex == 0 ? _expenseCategories : _incomeCategories;
    final selectedCat = categories[_selectedCategoryIndex];

    // Alt model seçiliyse onun adını, değilse ana modelin adını al
    String title;
    String? iconCode;
    if (_selectedSubModelIndex >= 0) {
      final subs = selectedCat['subModels'] as List<Map<String, dynamic>>?;
      if (subs != null && _selectedSubModelIndex < subs.length) {
        title = subs[_selectedSubModelIndex]['name'] as String;
      } else {
        title = selectedCat['name'] as String;
      }
    } else {
      title = selectedCat['name'] as String;
    }
    iconCode = selectedCat['name'] as String; // Basit ikon referansı

    TransactionRecord tx;
    if (widget.initialId != null) {
      final existingTx = await DatabaseService.getTransaction(
        widget.initialId!,
      );
      tx = existingTx ?? TransactionRecord();
    } else {
      tx = TransactionRecord();
    }

    tx
      ..isIncome = _tabIndex == 1
      ..title = title
      ..iconCode = iconCode
      ..amount = amount
      ..minAmount = _isFlexibleAmount ? minAmt : null
      ..maxAmount = _isFlexibleAmount ? maxAmt : null
      ..periodType = _periodType
      ..date = widget.initialId != null ? tx.date : DateTime.now()
      ..vaultId = _selectedVaultId; // Seçilen kasa

    if (widget.initialId != null) {
      await DatabaseService.updateTransaction(tx);
    } else {
      await DatabaseService.addTransaction(tx);
    }
  }

  // Gelişmiş Seçenekler (artık bottom sheet olarak açılıyor)
  bool _isFlexibleAmount = false;

  // Periyot Tipi (0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık)
  int _periodType = 0;

  // Tekrarlama Günü (Haftalık için 1-7, Aylık için 1-31)
  int _selectedDay = 1;

  // Aylık/Yıllık takvim seçimi için
  DateTime _selectedDateForRecurrence = DateTime.now();

  // Haftanın günleri
  final List<String> _weekDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  // Aylar
  final List<String> _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  // Süre (Örn: Kaç ay/hafta sürecek? 0 = Süresiz/Sürekli)
  int _duration = 0;

  // GİDER KATEGORİSİ (Hiyerarşik: Ana Model + Alt Modeller)
  final List<Map<String, dynamic>> _expenseCategories = [
    {
      'name': 'Market',
      'icon': Icons.shopping_basket_rounded,
      'color': Colors.orange,
      'subModels': [
        {'name': 'Gıda', 'icon': Icons.egg_rounded},
        {'name': 'Temizlik', 'icon': Icons.cleaning_services_rounded},
        {'name': 'Kişisel Bakım', 'icon': Icons.face_rounded},
      ],
    },
    {
      'name': 'Yemek',
      'icon': Icons.restaurant_rounded,
      'color': Colors.deepOrangeAccent,
      'subModels': [
        {'name': 'Restoran', 'icon': Icons.restaurant_menu_rounded},
        {'name': 'Fast Food', 'icon': Icons.fastfood_rounded},
        {'name': 'Kafe', 'icon': Icons.coffee_rounded},
        {'name': 'Paket Servis', 'icon': Icons.delivery_dining_rounded},
      ],
    },
    {
      'name': 'Kira',
      'icon': Icons.home_rounded,
      'color': Colors.blue,
      'subModels': [
        {'name': 'Ev Kirası', 'icon': Icons.apartment_rounded},
        {'name': 'İş Yeri', 'icon': Icons.business_rounded},
        {'name': 'Depo', 'icon': Icons.warehouse_rounded},
      ],
    },
    {
      'name': 'Fatura',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.lightBlue,
      'subModels': [
        {'name': 'Elektrik', 'icon': Icons.bolt_rounded},
        {'name': 'Su', 'icon': Icons.water_drop_rounded},
        {'name': 'Doğalgaz', 'icon': Icons.local_fire_department_rounded},
        {'name': 'İnternet', 'icon': Icons.wifi_rounded},
        {'name': 'Telefon', 'icon': Icons.phone_android_rounded},
      ],
    },
    {
      'name': 'Eğlence',
      'icon': Icons.movie_creation_rounded,
      'color': AppColors.secondary,
      'subModels': [
        {'name': 'Sinema', 'icon': Icons.local_movies_rounded},
        {'name': 'Konser', 'icon': Icons.music_note_rounded},
        {'name': 'Oyun', 'icon': Icons.sports_esports_rounded},
        {'name': 'Etkinlik', 'icon': Icons.event_rounded},
      ],
    },
    {
      'name': 'Abonelik',
      'icon': Icons.subscriptions_rounded,
      'color': AppColors.error,
      'subModels': [
        {'name': 'Dizi/Film', 'icon': Icons.smart_display_rounded},
        {'name': 'Müzik', 'icon': Icons.headphones_rounded},
        {'name': 'Yazılım', 'icon': Icons.code_rounded},
        {'name': 'Spor Salonu', 'icon': Icons.fitness_center_rounded},
      ],
    },
    {
      'name': 'Sağlık',
      'icon': Icons.medical_services_rounded,
      'color': Colors.greenAccent,
      'subModels': [
        {'name': 'Doktor', 'icon': Icons.local_hospital_rounded},
        {'name': 'İlaç', 'icon': Icons.medication_rounded},
        {'name': 'Ameliyat', 'icon': Icons.vaccines_rounded},
        {'name': 'Diş', 'icon': Icons.sentiment_satisfied_alt_rounded},
      ],
    },
    {
      'name': 'Ulaşım',
      'icon': Icons.directions_car_rounded,
      'color': Colors.teal,
      'subModels': [
        {'name': 'Taksi', 'icon': Icons.local_taxi_rounded},
        {'name': 'Otobüs', 'icon': Icons.directions_bus_rounded},
        {'name': 'Tren', 'icon': Icons.train_rounded},
        {'name': 'Uçak', 'icon': Icons.flight_rounded},
        {'name': 'Yakıt', 'icon': Icons.local_gas_station_rounded},
      ],
    },
    {
      'name': 'Giyim',
      'icon': Icons.checkroom_rounded,
      'color': Colors.pinkAccent,
      'subModels': [
        {'name': 'Günlük', 'icon': Icons.dry_cleaning_rounded},
        {'name': 'Ayakkabı', 'icon': Icons.ice_skating_rounded},
        {'name': 'Aksesuar', 'icon': Icons.watch_rounded},
      ],
    },
    {
      'name': 'Eğitim',
      'icon': Icons.school_rounded,
      'color': Colors.amber,
      'subModels': [
        {'name': 'Kurs', 'icon': Icons.menu_book_rounded},
        {'name': 'Kitap', 'icon': Icons.auto_stories_rounded},
        {'name': 'Okul', 'icon': Icons.account_balance_rounded},
      ],
    },
    {
      'name': 'Borç Ödeme',
      'icon': Icons.credit_card_rounded,
      'color': Colors.redAccent,
      'subModels': [
        {'name': 'Kredi Kartı', 'icon': Icons.credit_score_rounded},
        {'name': 'Bireysel Kredi', 'icon': Icons.account_balance_rounded},
        {'name': 'Kişisel Borç', 'icon': Icons.handshake_rounded},
      ],
    },
    {
      'name': 'Diğer',
      'icon': Icons.more_horiz_rounded,
      'color': Colors.grey,
      'subModels': <Map<String, dynamic>>[],
    },
  ];

  // GELİR KATEGORİSİ (Hiyerarşik: Ana Model + Alt Modeller)
  final List<Map<String, dynamic>> _incomeCategories = [
    {
      'name': 'Maaş',
      'icon': Icons.account_balance_wallet_rounded,
      'color': AppColors.primary,
      'subModels': [
        {'name': 'Ana Maaş', 'icon': Icons.payments_rounded},
        {'name': 'Prim', 'icon': Icons.card_giftcard_rounded},
        {'name': 'İkramiye', 'icon': Icons.celebration_rounded},
      ],
    },
    {
      'name': 'Ek Gelir',
      'icon': Icons.monetization_on_rounded,
      'color': Colors.green,
      'subModels': [
        {'name': 'Freelance', 'icon': Icons.laptop_mac_rounded},
        {'name': 'Part-Time', 'icon': Icons.work_outline_rounded},
        {'name': 'Komisyon', 'icon': Icons.handshake_rounded},
      ],
    },
    {
      'name': 'Yatırım Getirisi',
      'icon': Icons.trending_up_rounded,
      'color': Colors.blueAccent,
      'subModels': [
        {'name': 'Hisse', 'icon': Icons.show_chart_rounded},
        {'name': 'Kripto', 'icon': Icons.currency_bitcoin_rounded},
        {'name': 'Faiz', 'icon': Icons.savings_rounded},
      ],
    },
    {
      'name': 'Burs / Kredi',
      'icon': Icons.school_rounded,
      'color': Colors.amber,
      'subModels': [
        {'name': 'Burs', 'icon': Icons.emoji_events_rounded},
        {'name': 'Kredi', 'icon': Icons.account_balance_rounded},
      ],
    },
    {
      'name': 'Satış',
      'icon': Icons.store_rounded,
      'color': Colors.orangeAccent,
      'subModels': [
        {'name': 'Online Satış', 'icon': Icons.shopping_cart_rounded},
        {'name': 'Fiziksel Satış', 'icon': Icons.storefront_rounded},
      ],
    },
    {
      'name': 'Kira Geliri',
      'icon': Icons.house_rounded,
      'color': AppColors.secondary,
      'subModels': [
        {'name': 'Ev', 'icon': Icons.apartment_rounded},
        {'name': 'İş Yeri', 'icon': Icons.business_rounded},
      ],
    },
    {
      'name': 'Hediye',
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.pinkAccent,
      'subModels': <Map<String, dynamic>>[],
    },
    {
      'name': 'Diğer',
      'icon': Icons.more_horiz_rounded,
      'color': Colors.grey,
      'subModels': <Map<String, dynamic>>[],
    },
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

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
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

                  // 3. HİYERARŞİK KATEGORİ SEÇİCİ
                  _buildHierarchicalCategorySelector(activeCategories),

                  const SizedBox(height: AppSizes.paddingMedium),
                ],
              ),
            ),
          ),

          // 4. GELİŞMİŞ SEÇENEKLER BUTONU (numpad üstünde)
          _buildAdvancedOptionsButton(context),

          const SizedBox(height: 8),

          // 5. NUMPAD VEYA GELİŞMİŞ SEÇENEKLER
          Flexible(
            fit: FlexFit
                .loose, // Loose kullanıyoruz, Numpad boyutunda kalsın ama taşmasın
            child: SizedBox(
              height: 350,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  // Sola / sağa kayarak gelme efekti
                  final inAnimation = Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Sağdan gelsin
                    end: Offset.zero,
                  ).animate(animation);

                  final outAnimation = Tween<Offset>(
                    begin: const Offset(-1.0, 0.0), // Sola gitsin
                    end: Offset.zero,
                  ).animate(animation);

                  if (child.key == const ValueKey('numpad')) {
                    return SlideTransition(
                      position: outAnimation,
                      child: child,
                    );
                  } else {
                    return SlideTransition(position: inAnimation, child: child);
                  }
                },
                child: _showAdvancedOptions
                    ? SingleChildScrollView(
                        key: const ValueKey('advanced_options'),
                        child: _buildAdvancedOptionsPanel(context),
                      )
                    : Padding(
                        key: const ValueKey('numpad'),
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ), // Taşmayı önlemek için padding azaltıldı
                        child: NeumorphicNumpad(
                          onNumberTapped: _onNumpadTap,
                          onBackspaceTapped: _onBackspaceTap,
                          onDoneTapped: () async {
                            await _saveTransaction();
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HİYERARŞİK KATEGORİ SEÇİCİ
  Widget _buildHierarchicalCategorySelector(
    List<Map<String, dynamic>> categories,
  ) {
    final selectedCat = categories[_selectedCategoryIndex];
    final List<Map<String, dynamic>> subModels =
        (selectedCat['subModels'] as List<Map<String, dynamic>>?) ?? [];
    final bool isExpanded = _expandedCategoryIndex == _selectedCategoryIndex;
    final bool hasSubModels = subModels.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- ANA MODEL SATIRI (Yatay Scroll) ---
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = index == _selectedCategoryIndex;

              // Seçili alt model varsa, onun bilgilerini göster
              final bool showSubInfo =
                  isSelected &&
                  _selectedSubModelIndex >= 0 &&
                  _selectedSubModelIndex <
                      ((cat['subModels'] as List?)?.length ?? 0);

              final displayIcon = showSubInfo
                  ? (cat['subModels']
                            as List<
                              Map<String, dynamic>
                            >)[_selectedSubModelIndex]['icon']
                        as IconData
                  : cat['icon'] as IconData;
              final displayName = showSubInfo
                  ? (cat['subModels']
                            as List<
                              Map<String, dynamic>
                            >)[_selectedSubModelIndex]['name']
                        as String
                  : cat['name'] as String;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected && hasSubModels) {
                      // Aynı kategoriye tekrar tıklama → aç/kapat
                      _expandedCategoryIndex = isExpanded
                          ? -1
                          : _selectedCategoryIndex;
                    } else {
                      // Farklı kategori seçimi
                      _selectedCategoryIndex = index;
                      _selectedSubModelIndex = -1;
                      _expandedCategoryIndex = -1;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.paddingMedium),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 92 : 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusDefault,
                      ),
                      color: isSelected
                          ? AppColors.innerSurface
                          : AppColors.surface,
                      border: isSelected
                          ? Border.all(
                              color: (cat['color'] as Color).withOpacity(0.4),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (cat['color'] as Color).withOpacity(
                                  0.15,
                                ),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: AppColors.darkShadow,
                                offset: Offset(4, 4),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: AppColors.lightShadow,
                                offset: Offset(-3, -3),
                                blurRadius: 8,
                              ),
                            ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              displayIcon,
                              key: ValueKey('$index-$displayName'),
                              color: isSelected
                                  ? cat['color'] as Color
                                  : AppColors.textSecondary,
                              size: isSelected ? 28 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              displayName,
                              key: ValueKey('txt-$index-$displayName'),
                              style: TextStyle(
                                fontSize: 9.0,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Genişletme göstergesi (seçili & alt modeli olan)
                          if (isSelected && hasSubModels)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  size: 14,
                                  color: (cat['color'] as Color).withOpacity(
                                    0.7,
                                  ),
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

        // --- ALT MODEL SATIRI (Genişletildiğinde görünür) ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: isExpanded && hasSubModels ? 48 : 0,
          child: AnimatedOpacity(
            opacity: isExpanded && hasSubModels ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: 6,
              ),
              child: Row(
                children: List.generate(subModels.length, (subIndex) {
                  final sub = subModels[subIndex];
                  final isSubSelected = subIndex == _selectedSubModelIndex;
                  final Color parentColor = selectedCat['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubModelIndex = isSubSelected
                              ? -1
                              : subIndex;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSubSelected
                              ? parentColor.withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSubSelected
                                ? parentColor.withOpacity(0.5)
                                : AppColors.darkShadow.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: isSubSelected
                              ? [
                                  BoxShadow(
                                    color: parentColor.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sub['icon'] as IconData,
                              size: 14,
                              color: isSubSelected
                                  ? parentColor
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sub['name'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSubSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSubSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // TEK SEFERLİK SABİT TUTAR GÖSTERGESİ
  Widget _buildSingleAmountDisplay() {
    return Container(
      key: const ValueKey('single_amount'),
      height: 85, // İki durumun yüksekliğini eşitleyerek zıplamayı önler
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "₺ $_currentAmount",
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
    return Container(
      key: const ValueKey('flex_amount'),
      height: 85, // İki durumun yüksekliğini eşitleyerek zıplamayı önler
      alignment: Alignment.center,
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

  // Numpad üstündeki Gelişmiş Seçenekler butonu (Numpad 2 ile 3 arasına hizalı)
  Widget _buildAdvancedOptionsButton(BuildContext context) {
    // Ekran genişliği
    final double screenWidth = MediaQuery.of(context).size.width;

    // Numpad, 3 adet 70px tuş ve 4 adet eşit boşluk (spaceEvenly) içerir.
    // 2. ve 3. tuşun tam ortasına denk gelmesi için gereken sağdan uzaklık hesabı:
    // S (Boşluk) = (screenWidth - 210) / 4
    // 3. Tuş Merkezi (sağdan uzaklık) = S + 35
    // 2. Tuş Merkezi (sağdan uzaklık) = 2*S + 105
    // Orta Nokta (2. ve 3. tuşun tam ortası) = 1.5*S + 70
    // Butonumuzun genişliği 64px, yani kendi merkezi sağ padding (P) + 32 dir.
    // P + 32 = 1.5*S + 70 => P = 1.5 * (screenWidth/4 - 52.5) + 38
    // P = 0.375 * screenWidth - 78.75 + 38 = 0.375 * screenWidth - 40.75

    double rightPadding = (screenWidth * 0.375) - 40.75;
    if (rightPadding < 0) rightPadding = 0; // Negatif olursa emniyet kilidi

    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _showAdvancedOptions = !_showAdvancedOptions),
            child: NeuContainer(
              width: 64,
              height: 36,
              borderRadius: 18,
              padding: EdgeInsets.zero,
              isInnerShadow: _showAdvancedOptions, // Aktifken içe basık dursun
              child: Center(
                child: Icon(
                  _showAdvancedOptions
                      ? Icons.apps_rounded
                      : Icons.tune_rounded,
                  size: 20,
                  color: _showAdvancedOptions
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inline Gelişmiş Seçenekler Paneli
  Widget _buildAdvancedOptionsPanel(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.paddingMedium,
            right: AppSizes.paddingMedium,
            bottom: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // --- KASA / GRUP SEÇİMİ ---
              _buildVaultSelector(context, setSheetState),
              const SizedBox(height: 16),
              // 1. Esnek (Min/Max) Bütçe Anahtarı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Esnek (Min-Max) Tutar Gir',
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
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.darkShadow),
              // 2. Tekrarlama Periyodu
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tekrarlama Periyodu',
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
                  _buildPeriodBtnSheet('Tek Sefer', 0, setSheetState),
                  _buildPeriodBtnSheet('Haftalık', 1, setSheetState),
                  _buildPeriodBtnSheet('Aylık', 2, setSheetState),
                  _buildPeriodBtnSheet('Yıllık', 3, setSheetState),
                ],
              ),
              // 3. Tekrarlama Günü / Tarihi ve Süre (Zıplamayı Önlemek İçin Sabit Alan)
              SizedBox(
                height: 130, // Dönem seçenekleri için sabit alan tahsisi
                child: Column(
                  children: [
                    if (_periodType == 1) ...[
                      // Haftalık (Gün Adı)
                      const SizedBox(height: AppSizes.paddingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Haftanın Günü',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              int tempDayIndex = _selectedDay - 1; // 0-6 index

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (pickerContext) {
                                  return StatefulBuilder(
                                    builder: (context, setPickerState) {
                                      return Container(
                                        height: 300,
                                        decoration: const BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(
                                              AppSizes.radiusLarge,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                AppSizes.paddingMedium,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          pickerContext,
                                                        ),
                                                    child: const Text(
                                                      'İptal',
                                                      style: TextStyle(
                                                        color: AppColors.error,
                                                      ),
                                                    ),
                                                  ),
                                                  const Text(
                                                    'Gün Seç',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedDay =
                                                            tempDayIndex +
                                                            1; // 1-7 gün no
                                                      });
                                                      setSheetState(() {});
                                                      Navigator.pop(
                                                        pickerContext,
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Tamam',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: ListWheelScrollView.useDelegate(
                                                itemExtent: 40,
                                                perspective: 0.005,
                                                physics:
                                                    const FixedExtentScrollPhysics(),
                                                onSelectedItemChanged: (index) {
                                                  setPickerState(
                                                    () => tempDayIndex = index,
                                                  );
                                                },
                                                controller:
                                                    FixedExtentScrollController(
                                                      initialItem: tempDayIndex,
                                                    ),
                                                childDelegate:
                                                    ListWheelChildBuilderDelegate(
                                                      childCount: 7,
                                                      builder: (context, index) {
                                                        final isSelected =
                                                            index ==
                                                            tempDayIndex;
                                                        return Center(
                                                          child: Text(
                                                            _weekDays[index],
                                                            style: TextStyle(
                                                              fontSize:
                                                                  isSelected
                                                                  ? 24
                                                                  : 18,
                                                              fontWeight:
                                                                  isSelected
                                                                  ? FontWeight
                                                                        .bold
                                                                  : FontWeight
                                                                        .normal,
                                                              color: isSelected
                                                                  ? AppColors
                                                                        .primary
                                                                  : AppColors
                                                                        .textSecondary,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLarge,
                                ),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_view_week_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _weekDays[_selectedDay - 1],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_periodType == 2 || _periodType == 3) ...[
                      // Aylık veya Yıllık (Takvimden Seçim)
                      const SizedBox(height: AppSizes.paddingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _periodType == 2 ? 'Ayın Günü' : 'Yılın Günü',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
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
                                        decoration: const BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(
                                              AppSizes.radiusLarge,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                AppSizes.paddingMedium,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          pickerContext,
                                                        ),
                                                    child: const Text(
                                                      'İptal',
                                                      style: TextStyle(
                                                        color: AppColors.error,
                                                      ),
                                                    ),
                                                  ),
                                                  const Text(
                                                    'Tarih Seç',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedDateForRecurrence =
                                                            DateTime(
                                                              _selectedDateForRecurrence
                                                                  .year,
                                                              tempMonth,
                                                              tempDay,
                                                            );
                                                        _selectedDay = tempDay;
                                                      });
                                                      setSheetState(() {});
                                                      Navigator.pop(
                                                        pickerContext,
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Tamam',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  // Gün Seçici
                                                  Expanded(
                                                    child: ListWheelScrollView.useDelegate(
                                                      itemExtent: 40,
                                                      perspective: 0.005,
                                                      physics:
                                                          const FixedExtentScrollPhysics(),
                                                      onSelectedItemChanged:
                                                          (index) {
                                                            setPickerState(
                                                              () => tempDay =
                                                                  index + 1,
                                                            );
                                                          },
                                                      controller:
                                                          FixedExtentScrollController(
                                                            initialItem:
                                                                tempDay - 1,
                                                          ),
                                                      childDelegate: ListWheelChildBuilderDelegate(
                                                        childCount: 31,
                                                        builder: (context, index) {
                                                          final isSelected =
                                                              (index + 1) ==
                                                              tempDay;
                                                          return Center(
                                                            child: Text(
                                                              (index + 1)
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isSelected
                                                                    ? 24
                                                                    : 18,
                                                                fontWeight:
                                                                    isSelected
                                                                    ? FontWeight
                                                                          .bold
                                                                    : FontWeight
                                                                          .normal,
                                                                color:
                                                                    isSelected
                                                                    ? AppColors
                                                                          .primary
                                                                    : AppColors
                                                                          .textSecondary,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  // Yıllık ise Ay Seçici
                                                  if (_periodType == 3)
                                                    Expanded(
                                                      flex: 2,
                                                      child: ListWheelScrollView.useDelegate(
                                                        itemExtent: 40,
                                                        perspective: 0.005,
                                                        physics:
                                                            const FixedExtentScrollPhysics(),
                                                        onSelectedItemChanged:
                                                            (index) {
                                                              setPickerState(
                                                                () =>
                                                                    tempMonth =
                                                                        index +
                                                                        1,
                                                              );
                                                            },
                                                        controller:
                                                            FixedExtentScrollController(
                                                              initialItem:
                                                                  tempMonth - 1,
                                                            ),
                                                        childDelegate: ListWheelChildBuilderDelegate(
                                                          childCount: 12,
                                                          builder: (context, index) {
                                                            final isSelected =
                                                                (index + 1) ==
                                                                tempMonth;
                                                            return Center(
                                                              child: Text(
                                                                _months[index],
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      isSelected
                                                                      ? 22
                                                                      : 16,
                                                                  fontWeight:
                                                                      isSelected
                                                                      ? FontWeight
                                                                            .bold
                                                                      : FontWeight
                                                                            .normal,
                                                                  color:
                                                                      isSelected
                                                                      ? AppColors
                                                                            .primary
                                                                      : AppColors
                                                                            .textSecondary,
                                                                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLarge,
                                ),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _periodType == 2
                                        ? "Ayın ${_selectedDateForRecurrence.day}'i"
                                        : "${_selectedDateForRecurrence.day} ${_months[_selectedDateForRecurrence.month - 1]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 4. Süre
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
                                  'Bitiş Süresi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _duration == 0
                                      ? 'Sürekli Tekrar Eder'
                                      : '$_duration ${_getPeriodName(_periodType)} Sonra Biter',
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
                                if (_duration > 0) {
                                  setState(() => _duration--);
                                  setSheetState(() {});
                                }
                              }),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: _duration == 0
                                      ? const Icon(
                                          Icons.all_inclusive_rounded,
                                          color: AppColors.textPrimary,
                                          size: 20,
                                        )
                                      : Text(
                                          _duration.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildDurationBtn(Icons.add, () {
                                if (_duration < 120) {
                                  setState(() => _duration++);
                                  setSheetState(() {});
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
            ],
          ),
        );
      },
    );
  }

  // Sheet için periyot butonu (setSheetState ile güncelleme yapılır)
  Widget _buildPeriodBtnSheet(
    String label,
    int type,
    StateSetter setSheetState,
  ) {
    final bool isActive = _periodType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _periodType = type;
          if (type == 0) {
            _duration = 0;
            _selectedDay = 1;
          } else if (type == 1 && _selectedDay > 7) {
            _selectedDay = 7;
          }
        });
        setSheetState(() {});
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

  // Süre +/- butonları
  Widget _buildDurationBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
        borderRadius: AppSizes.radiusRound,
        child: Center(
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
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
            _expandedCategoryIndex = -1;
            _selectedSubModelIndex = -1;
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

  // Kasa / Grup Seçici (Periyot Seçici Formatında)
  Widget _buildVaultSelector(BuildContext context, StateSetter setSheetState) {
    if (_vaults.isEmpty) return const SizedBox();

    // Seçili kasayı bul, yoksa Genel Bakiye (null)
    Vault? selectedVault;
    if (_selectedVaultId != null) {
      try {
        selectedVault = _vaults.firstWhere((v) => v.id == _selectedVaultId);
      } catch (_) {}
    }

    // Seçenekler listesi: İlk eleman Genel Bakiye, sonrakiler kasalar
    final List<Vault?> vaultOptions = [null, ..._vaults];

    // Aktif indexi bul
    int currentIndex = vaultOptions.indexWhere(
      (v) => v?.id == _selectedVaultId,
    );
    if (currentIndex == -1) currentIndex = 0;

    // Helper: isme/koda göre ikon
    IconData getIconData(String? code) {
      if (code == null) return Icons.account_balance_wallet_rounded;
      switch (code) {
        case 'account_balance_wallet_rounded':
          return Icons.account_balance_wallet_rounded;
        case 'attach_money_rounded':
          return Icons.attach_money_rounded;
        case 'diamond_rounded':
          return Icons.diamond_rounded;
        default:
          return Icons.account_balance_wallet_rounded;
      }
    }

    return Column(
      children: [
        const SizedBox(height: AppSizes.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kasa veya Grup',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                int tempIndex = currentIndex;

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (pickerContext) {
                    return StatefulBuilder(
                      builder: (context, setPickerState) {
                        return Container(
                          height: 300,
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppSizes.radiusLarge),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                  AppSizes.paddingMedium,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(pickerContext),
                                      child: const Text(
                                        'İptal',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Kasa Seç',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedVaultId =
                                              vaultOptions[tempIndex]?.id;
                                        });
                                        setSheetState(() {});
                                        Navigator.pop(pickerContext);
                                      },
                                      child: const Text(
                                        'Tamam',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                    setPickerState(() => tempIndex = index);
                                  },
                                  controller: FixedExtentScrollController(
                                    initialItem: tempIndex,
                                  ),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: vaultOptions.length,
                                    builder: (context, index) {
                                      final isSelected = index == tempIndex;
                                      final option = vaultOptions[index];
                                      final label =
                                          option?.name ?? 'Genel Bakiye';

                                      return Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              getIconData(option?.iconCode),
                                              size: isSelected ? 24 : 18,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: isSelected ? 24 : 18,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getIconData(selectedVault?.iconCode),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedVault?.name ?? 'Genel Bakiye',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
