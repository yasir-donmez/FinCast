import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/app_constants.dart';
import '../../shared/widgets/neu_container.dart';
import 'widgets/neumorphic_numpad.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

/// Merkez FAB ikonuna basılınca açılan Yeni Gelir/Gider Ekranı (Transaction Modal)
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
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
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

  bool _isPrefilled = false; // Localization hatasını önlemek için flag

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
    if (widget.initialCategoryId != null || widget.initialName != null) {
      // Kategori listesinde ID veya isim bul
      final l10n = AppLocalizations.of(context)!;
      final categories = _tabIndex == 0
          ? _getExpenseCategories(l10n)
          : _getIncomeCategories(l10n);
      
      bool found = false;
      for (int i = 0; i < categories.length; i++) {
        final cat = categories[i];
        if ((widget.initialCategoryId != null && cat['id'] == widget.initialCategoryId) ||
            (widget.initialCategoryId == null && cat['name'] == widget.initialName)) {
          _selectedCategoryIndex = i;
          found = true;
          break;
        }
        // Alt modellerde de ara
        final subs = cat['subModels'] as List<Map<String, dynamic>>?;
        if (subs != null) {
          for (int j = 0; j < subs.length; j++) {
            final sub = subs[j];
            if ((widget.initialCategoryId != null && sub['id'] == widget.initialCategoryId) ||
                (widget.initialCategoryId == null && sub['name'] == widget.initialName)) {
              _selectedCategoryIndex = i;
              _expandedCategoryIndex = i;
              _selectedSubModelIndex = j;
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }
    }

    // Periyot Tipini Önceden Doldur (Düzenleme Modu için)
    _loadInitialPeriod();
  }

  Future<void> _loadInitialPeriod() async {
    if (widget.initialId == null) return;
    final tx = await DatabaseService.getTransaction(widget.initialId!);
    if (tx == null) return;

    if (mounted) {
      setState(() {
        _periodType = tx.periodType;
        // Kategori genişletme mantığı
        if ([8, 9, 10].contains(_periodType)) {
          _expandedPeriodCategory = 'gun';
        } else if ([1, 4, 5].contains(_periodType)) {
          _expandedPeriodCategory = 'hafta';
        } else if ([2, 6, 7].contains(_periodType)) {
          _expandedPeriodCategory = 'ay';
        }
      });
    }
  }


  /// İşlemi Isar DB'ye kaydet
  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_currentAmount) ?? 0;
    final minAmt = double.tryParse(_currentMin) ?? 0;
    final maxAmt = double.tryParse(_currentMax) ?? 0;

    if (!_isFlexibleAmount && amount <= 0) {
      return; // Boş tutar kaydetme
    }
    if (_isFlexibleAmount && minAmt <= 0 && maxAmt <= 0) {
      return; // Boş esnek bütçe
    }

    // Aktif kategori listesini al
    final l10n = AppLocalizations.of(context)!;
    final categories = _tabIndex == 0 ? _getExpenseCategories(l10n) : _getIncomeCategories(l10n);
    final selectedCat = categories[_selectedCategoryIndex];

    // Alt model seçiliyse onun adını, değilse ana modelin adını al
    String title;
    String? iconCode;
    String? categoryId;

    if (_selectedSubModelIndex >= 0) {
      final subs = selectedCat['subModels'] as List<Map<String, dynamic>>?;
      if (subs != null && _selectedSubModelIndex < subs.length) {
        final sub = subs[_selectedSubModelIndex];
        title = sub['name'] as String;
        categoryId = sub['id'] as String?;
      } else {
        title = selectedCat['name'] as String;
        categoryId = selectedCat['id'] as String?;
      }
    } else {
      title = selectedCat['name'] as String;
      categoryId = selectedCat['id'] as String?;
    }
    iconCode = categoryId ?? title; // Artık ID'yi ikon referansı olarak kullanıyoruz

    TransactionRecord tx;
    if (widget.initialId != null) {
      final existingTx = await DatabaseService.getTransaction(
        widget.initialId!,
      );
      tx = existingTx ?? TransactionRecord();
    } else {
      tx = TransactionRecord();
    }

    // Esnek bütçe: min/max varsa amount'u otomatik ortalama yap
    double finalAmount = amount;
    if (_isFlexibleAmount && minAmt > 0 && maxAmt > 0) {
      finalAmount = (minAmt + maxAmt) / 2;
    } else if (_isFlexibleAmount && maxAmt > 0) {
      finalAmount = maxAmt;
    } else if (_isFlexibleAmount && minAmt > 0) {
      finalAmount = minAmt;
    }

    tx
      ..isIncome = _tabIndex == 1
      ..title = title
      ..categoryId = categoryId
      ..iconCode = iconCode
      ..amount = finalAmount
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

  // Hangi periyot kategorisinin açık olduğunu tutar (null, 'gun', 'hafta', 'ay')
  String? _expandedPeriodCategory;

  // Tekrarlama Günü (Haftalık için 1-7, Aylık için 1-31)
  int _selectedDay = 1;

  // Aylık/Yıllık takvim seçimi için
  DateTime _selectedDateForRecurrence = DateTime.now();

  // Haftanın günleri
  List<String> _getWeekDays(AppLocalizations l10n) => [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];

  // Aylar
  List<String> _getMonths(AppLocalizations l10n) => [
        l10n.january,
        l10n.february,
        l10n.march,
        l10n.april,
        l10n.may,
        l10n.june,
        l10n.july,
        l10n.august,
        l10n.september,
        l10n.october,
        l10n.november,
        l10n.december,
      ];

  // Süre (Örn: Kaç ay/hafta sürecek? 0 = Süresiz/Sürekli)
  int _duration = 0;

  // GİDER KATEGORİSİ (Hiyerarşik: Ana Model + Alt Modeller)
  List<Map<String, dynamic>> _getExpenseCategories(AppLocalizations l10n) => [
        {
          'id': 'exp_grocery',
          'name': l10n.grocery,
          'icon': Icons.shopping_basket_rounded,
          'color': Colors.orange,
          'subModels': [
            {'id': 'exp_grocery_food', 'name': l10n.food, 'icon': Icons.egg_rounded},
            {'id': 'exp_grocery_cleaning', 'name': l10n.cleaning, 'icon': Icons.cleaning_services_rounded},
            {'id': 'exp_grocery_personal', 'name': l10n.personalCare, 'icon': Icons.face_rounded},
          ],
        },
        {
          'id': 'exp_dining',
          'name': l10n.dining,
          'icon': Icons.restaurant_rounded,
          'color': Colors.deepOrangeAccent,
          'subModels': [
            {'id': 'exp_dining_restaurant', 'name': l10n.restaurant, 'icon': Icons.restaurant_menu_rounded},
            {'id': 'exp_dining_fastfood', 'name': l10n.fastFood, 'icon': Icons.fastfood_rounded},
            {'id': 'exp_dining_cafe', 'name': l10n.cafe, 'icon': Icons.coffee_rounded},
            {'id': 'exp_dining_delivery', 'name': l10n.delivery, 'icon': Icons.delivery_dining_rounded},
          ],
        },
        {
          'id': 'exp_rent',
          'name': l10n.rent,
          'icon': Icons.home_rounded,
          'color': Colors.blue,
          'subModels': [
            {'id': 'exp_rent_home', 'name': l10n.homeRent, 'icon': Icons.apartment_rounded},
            {'id': 'exp_rent_office', 'name': l10n.workspace, 'icon': Icons.business_rounded},
            {'id': 'exp_rent_storage', 'name': l10n.storage, 'icon': Icons.warehouse_rounded},
          ],
        },
        {
          'id': 'exp_bill',
          'name': l10n.bill,
          'icon': Icons.receipt_long_rounded,
          'color': Colors.lightBlue,
          'subModels': [
            {'id': 'exp_bill_electricity', 'name': l10n.electricity, 'icon': Icons.bolt_rounded},
            {'id': 'exp_bill_water', 'name': l10n.water, 'icon': Icons.water_drop_rounded},
            {'id': 'exp_bill_gas', 'name': l10n.gas, 'icon': Icons.local_fire_department_rounded},
            {'id': 'exp_bill_internet', 'name': l10n.internet, 'icon': Icons.wifi_rounded},
            {'id': 'exp_bill_phone', 'name': l10n.phone, 'icon': Icons.phone_android_rounded},
          ],
        },
        {
          'id': 'exp_fun',
          'name': l10n.entertainment,
          'icon': Icons.movie_creation_rounded,
          'color': AppColors.secondary,
          'subModels': [
            {'id': 'exp_fun_cinema', 'name': l10n.cinema, 'icon': Icons.local_movies_rounded},
            {'id': 'exp_fun_concert', 'name': l10n.concert, 'icon': Icons.music_note_rounded},
            {'id': 'exp_fun_game', 'name': l10n.game, 'icon': Icons.sports_esports_rounded},
            {'id': 'exp_fun_event', 'name': l10n.event, 'icon': Icons.event_rounded},
          ],
        },
        {
          'id': 'exp_sub',
          'name': l10n.subscription,
          'icon': Icons.subscriptions_rounded,
          'color': AppColors.getError(context),
          'subModels': [
            {'id': 'exp_sub_stream', 'name': l10n.streaming, 'icon': Icons.smart_display_rounded},
            {'id': 'exp_sub_music', 'name': l10n.musicSubscription, 'icon': Icons.headphones_rounded},
            {'id': 'exp_sub_software', 'name': l10n.software, 'icon': Icons.code_rounded},
            {'id': 'exp_sub_gym', 'name': l10n.gym, 'icon': Icons.fitness_center_rounded},
          ],
        },
        {
          'id': 'exp_health',
          'name': l10n.health,
          'icon': Icons.medical_services_rounded,
          'color': AppColors.getIncome(context),
          'subModels': [
            {'id': 'exp_health_doctor', 'name': l10n.doctor, 'icon': Icons.local_hospital_rounded},
            {'id': 'exp_health_medicine', 'name': l10n.medicine, 'icon': Icons.medication_rounded},
            {'id': 'exp_health_surgery', 'name': l10n.surgery, 'icon': Icons.vaccines_rounded},
            {'id': 'exp_health_dentist', 'name': l10n.dentist, 'icon': Icons.sentiment_satisfied_alt_rounded},
          ],
        },
        {
          'id': 'exp_trans',
          'name': l10n.transportation,
          'icon': Icons.directions_car_rounded,
          'color': Colors.teal,
          'subModels': [
            {'id': 'exp_trans_taxi', 'name': l10n.taxi, 'icon': Icons.local_taxi_rounded},
            {'id': 'exp_trans_bus', 'name': l10n.bus, 'icon': Icons.directions_bus_rounded},
            {'id': 'exp_trans_train', 'name': l10n.train, 'icon': Icons.train_rounded},
            {'id': 'exp_trans_flight', 'name': l10n.flight, 'icon': Icons.flight_rounded},
            {'id': 'exp_trans_fuel', 'name': l10n.fuel, 'icon': Icons.local_gas_station_rounded},
          ],
        },
        {
          'id': 'exp_cloth',
          'name': l10n.clothing,
          'icon': Icons.checkroom_rounded,
          'color': Colors.pinkAccent,
          'subModels': [
            {'id': 'exp_cloth_daily', 'name': l10n.dailyWear, 'icon': Icons.dry_cleaning_rounded},
            {'id': 'exp_cloth_shoes', 'name': l10n.shoes, 'icon': Icons.ice_skating_rounded},
            {'id': 'exp_cloth_acc', 'name': l10n.accessory, 'icon': Icons.watch_rounded},
          ],
        },
        {
          'id': 'exp_edu',
          'name': l10n.education,
          'icon': Icons.school_rounded,
          'color': Colors.amber,
          'subModels': [
            {'id': 'exp_edu_course', 'name': l10n.course, 'icon': Icons.menu_book_rounded},
            {'id': 'exp_edu_book', 'name': l10n.book, 'icon': Icons.auto_stories_rounded},
            {'id': 'exp_edu_school', 'name': l10n.school, 'icon': Icons.account_balance_rounded},
          ],
        },
        {
          'id': 'exp_debt',
          'name': l10n.debtPayment,
          'icon': Icons.credit_card_rounded,
          'color': AppColors.getExpense(context),
          'subModels': [
            {'id': 'exp_debt_credit_card', 'name': l10n.creditCard, 'icon': Icons.credit_score_rounded},
            {'id': 'exp_debt_loan', 'name': l10n.loan, 'icon': Icons.account_balance_rounded},
            {'id': 'exp_debt_personal', 'name': l10n.personalDebt, 'icon': Icons.handshake_rounded},
          ],
        },
        {
          'id': 'exp_other',
          'name': l10n.other,
          'icon': Icons.more_horiz_rounded,
          'color': Colors.grey,
          'subModels': <Map<String, dynamic>>[],
        },
      ];

  // GELİR KATEGORİSİ (Hiyerarşik: Ana Model + Alt Modeller)
  List<Map<String, dynamic>> _getIncomeCategories(AppLocalizations l10n) => [
        {
          'id': 'inc_salary',
          'name': l10n.salary,
          'icon': Icons.account_balance_wallet_rounded,
          'color': AppColors.getPrimary(context),
          'subModels': [
            {'id': 'inc_salary_main', 'name': l10n.mainSalary, 'icon': Icons.payments_rounded},
            {'id': 'inc_salary_bonus', 'name': l10n.bonus, 'icon': Icons.card_giftcard_rounded},
            {'id': 'inc_salary_dividend', 'name': l10n.dividend, 'icon': Icons.celebration_rounded},
          ],
        },
        {
          'id': 'inc_extra',
          'name': l10n.extraIncome,
          'icon': Icons.monetization_on_rounded,
          'color': AppColors.getIncome(context),
          'subModels': [
            {'id': 'inc_extra_freelance', 'name': l10n.freelance, 'icon': Icons.laptop_mac_rounded},
            {'id': 'inc_extra_parttime', 'name': l10n.partTime, 'icon': Icons.work_outline_rounded},
            {'id': 'inc_extra_commission', 'name': l10n.commission, 'icon': Icons.handshake_rounded},
          ],
        },
        {
          'id': 'inc_invest',
          'name': l10n.investmentReturn,
          'icon': Icons.trending_up_rounded,
          'color': Colors.blueAccent,
          'subModels': [
            {'id': 'inc_invest_stock', 'name': l10n.stock, 'icon': Icons.show_chart_rounded},
            {'id': 'inc_invest_crypto', 'name': l10n.crypto, 'icon': Icons.currency_bitcoin_rounded},
            {'id': 'inc_invest_interest', 'name': l10n.interest, 'icon': Icons.savings_rounded},
          ],
        },
        {
          'id': 'inc_scholarship',
          'name': l10n.scholarshipLoan,
          'icon': Icons.school_rounded,
          'color': Colors.amber,
          'subModels': [
            {'id': 'inc_scholarship_award', 'name': l10n.scholarship, 'icon': Icons.emoji_events_rounded},
            {'id': 'inc_scholarship_loan', 'name': l10n.credit, 'icon': Icons.account_balance_rounded},
          ],
        },
        {
          'id': 'inc_sale',
          'name': l10n.sale,
          'icon': Icons.store_rounded,
          'color': Colors.orangeAccent,
          'subModels': [
            {'id': 'inc_sale_online', 'name': l10n.onlineSale, 'icon': Icons.shopping_cart_rounded},
            {'id': 'inc_sale_physical', 'name': l10n.physicalSale, 'icon': Icons.storefront_rounded},
          ],
        },
        {
          'id': 'inc_rent',
          'name': l10n.rentalIncome,
          'icon': Icons.house_rounded,
          'color': AppColors.secondary,
          'subModels': [
            {'id': 'inc_rent_home', 'name': l10n.home, 'icon': Icons.apartment_rounded},
            {'id': 'inc_rent_office', 'name': l10n.officeIncome, 'icon': Icons.business_rounded},
          ],
        },
        {
          'id': 'inc_gift',
          'name': l10n.gift,
          'icon': Icons.card_giftcard_rounded,
          'color': Colors.pinkAccent,
          'subModels': <Map<String, dynamic>>[],
        },
        {
          'id': 'inc_other',
          'name': l10n.other,
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
    final l10n = AppLocalizations.of(context)!;
    // Aktif Sekmeye göre geçerli kategorileri seç
    final activeCategories =
        _tabIndex == 0 ? _getExpenseCategories(l10n) : _getIncomeCategories(l10n);

    return Container(
      // Yukarıdan ekranın %95'ini kaplayan Bottom Sheet boyutlandırması
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: AppColors.getSurface(context), // Using surface as background proxy
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
              color: AppColors.getSurface(context),
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
              height: 340,
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
                            if (!context.mounted) return;
                            Navigator.pop(context);
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
          height: 105,
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
                          ? AppColors.getInnerSurface(context)
                          : AppColors.getSurface(context),
                      border: isSelected
                          ? Border.all(
                              color: (cat['color'] as Color).withValues(alpha: 0.4),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (cat['color'] as Color).withValues(alpha: 
                                  0.15,
                                ),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.getDarkShadow(context),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: AppColors.getLightShadow(context),
                                offset: const Offset(-3, -3),
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
                                  : AppColors.getTextSecondary(context),
                              size: isSelected ? 28 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              height: 34,
                              alignment: Alignment.center,
                              child: Text(
                                displayName,
                                key: ValueKey('txt-$index-$displayName'),
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.getTextPrimary(context)
                                      : AppColors.getTextSecondary(context),
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                                  color: (cat['color'] as Color).withValues(alpha: 
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
                              ? parentColor.withValues(alpha: 0.15)
                              : AppColors.getSurface(context), // Changed from AppColors.surface
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSubSelected
                                ? parentColor.withValues(alpha: 0.5)
                                : AppColors.getDarkShadow(context).withValues(alpha: 0.3), // Changed from AppColors.darkShadow
                            width: 1,
                          ),
                          boxShadow: isSubSelected
                              ? [
                                  BoxShadow(
                                    color: parentColor.withValues(alpha: 0.1),
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
                                  : AppColors.getTextSecondary(context), // Changed from AppColors.textSecondary
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
                                    ? AppColors.getTextPrimary(context) // Changed from AppColors.textPrimary
                                    : AppColors.getTextSecondary(context), // Changed from AppColors.textSecondary
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
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
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
          Expanded(child: _buildFlexBox(l10n.minimum, "₺$_currentMin", 'min')),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "-",
              style: TextStyle(
                fontSize: 24,
                color: AppColors.getTextSecondary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildFlexBox(l10n.maximum, "₺$_currentMax", 'max')),
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
                color: isActive ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context),
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
                      ? AppColors.getTextPrimary(context)
                      : AppColors.getTextSecondary(context),
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.getPrimary(context).withValues(alpha: 0.5),
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
                      ? AppColors.getPrimary(context)
                      : AppColors.getTextSecondary(context),
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
                  Expanded(
                    child: Text(
                      l10n.flexibleAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                  Switch(
                    value: _isFlexibleAmount,
                    activeThumbColor: AppColors.getPrimary(context),
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
              Divider(color: AppColors.getDarkShadow(context)),
              // 2. Tekrarlama Periyodu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.recurrencePeriod,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildPeriodCategoryBtn(l10n.oneTime, 0, null, setSheetState),
                  const SizedBox(width: 4),
                  _buildPeriodCategoryBtn(l10n.day, 8, 'gun', setSheetState),
                  const SizedBox(width: 4),
                  _buildPeriodCategoryBtn(l10n.week, 1, 'hafta', setSheetState),
                  const SizedBox(width: 4),
                  _buildPeriodCategoryBtn(l10n.month, 2, 'ay', setSheetState),
                  const SizedBox(width: 4),
                  _buildPeriodCategoryBtn(l10n.yearly, 3, null, setSheetState),
                ],
              ),


              // 3. Tekrarlama Günü / Tarihi ve Süre (Animasyonlu Geçiş)
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
                  height: 130, // Dönem seçenekleri için sabit alan tahsisi
                  child: Column(
                    children: [
                      if (_periodType == 1 || [4, 5].contains(_periodType)) ...[
                        // Haftalık (Gün Adı)
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
                                int tempDayIndex = _selectedDay - 1; // 0-6 index

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
                                                      child: Text(
                                                        l10n.cancel,
                                                        style: TextStyle(
                                                          color: AppColors.getError(context),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      l10n.selectDay,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color:
                                                            AppColors.getTextPrimary(context),
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
                                                      child: Text(
                                                        l10n.ok,
                                                        style: const TextStyle(
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
                                                              _getWeekDays(l10n)[index],
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
                                                                          .getPrimary(context)
                                                                    : AppColors
                                                                          .darkTextSecondary,
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
                                  color: AppColors.getBackground(context),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusLarge,
                                  ),
                                  border: Border.all(
                                    color: AppColors.getInnerSurface(context),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_view_week_rounded,
                                      size: 16,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getWeekDays(l10n)[_selectedDay - 1],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if ([2, 3, 6, 7].contains(_periodType)) ...[
                        // Aylık veya Yıllık (Takvimden Seçim)
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
                                            borderRadius: const BorderRadius.vertical(
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
                                                      child: Text(
                                                        l10n.cancel,
                                                        style: TextStyle(
                                                          color: AppColors.getError(context),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      l10n.selectDate,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color:
                                                            AppColors.getTextPrimary(context),
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
                                                      child: Text(
                                                        l10n.ok,
                                                        style: const TextStyle(
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
                                                                  color: isSelected
                                                                       ? AppColors.primary
                                                                       : AppColors.getTextSecondary(context),
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
                                                                  _getMonths(l10n)[index],
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
                                                                        ? AppColors.primary
                                                                        : AppColors.getTextSecondary(context),
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
                                  color: AppColors.getBackground(context),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusLarge,
                                  ),
                                  border: Border.all(
                                    color: AppColors.getSurface(context),
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
                                      _periodType == 3
                                          ? "${_selectedDateForRecurrence.day} ${_getMonths(l10n)[_selectedDateForRecurrence.month - 1]}"
                                          : "${l10n.dayOf} ${_selectedDateForRecurrence.day}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.getTextPrimary(context),
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
                                  Text(
                                    l10n.duration,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    _duration == 0
                                        ? l10n.repeatsIndefinitely
                                        : '$_duration ${_getPeriodName(_periodType)} ${l10n.endsAfter}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _duration == 0
                                          ? AppColors.getTextSecondary(context)
                                          : AppColors.getPrimary(context),
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
                                        ? Icon(
                                            Icons.all_inclusive_rounded,
                                            color: AppColors.getTextPrimary(context),
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
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildPeriodCategoryBtn(
    String label,
    int defaultValue,
    String? category,
    StateSetter setSheetState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Durum Belirleme
    final bool isThisExpanded = (category == null) 
        ? (_periodType == defaultValue && _expandedPeriodCategory == null)
        : (_expandedPeriodCategory == category);
    
    final bool isAnyOtherExpanded = _expandedPeriodCategory != null && _expandedPeriodCategory != category;
    
    // Dinamik Kısaltma
    final String abb = label.isNotEmpty ? label[0].toUpperCase() : "";

    // Dinamik Flex Logic
    int flexValue = 2;
    if (_expandedPeriodCategory != null) {
      flexValue = isThisExpanded ? 7 : 2; // Genişleme miktarını artır
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
                _periodType = defaultValue; // Varsayılanı ata
              }
            }
          });
          setSheetState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          height: 32, // Çok daha küçük (38 -> 32)
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isThisExpanded 
                ? AppColors.getPrimary(context).withValues(alpha: 0.1) 
                : AppColors.getSurface(context).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall), 
            border: Border.all(
              color: isThisExpanded 
                  ? AppColors.getPrimary(context).withValues(alpha: 0.6) 
                  : AppColors.getDarkShadow(context).withValues(alpha: 0.15),
              width: 0.8, // Daha ince kenar çizgisi
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
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      (isAnyOtherExpanded) ? abb : label,
                      key: ValueKey((isAnyOtherExpanded) ? abb : label),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: (isAnyOtherExpanded) ? 12 : 9.5, // Daha küçük font
                        fontWeight: isThisExpanded ? FontWeight.bold : FontWeight.w600,
                        color: isThisExpanded 
                            ? AppColors.getPrimary(context) 
                            : AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (isThisExpanded && category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: AppColors.getPrimary(context).withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 4),
                    _buildSubPeriodInlineOptions(category, l10n, setSheetState),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Alt Periyot Seçenekleri (Daha Kompakt)
  Widget _buildSubPeriodInlineOptions(String category, AppLocalizations l10n, StateSetter setSheetState) {
    List<Widget> options = [];
    if (category == 'gun') {
      final d = l10n.day[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet(d, 8, setSheetState), // Sadece 'G'
        _buildPeriodBtnSheet('2$d', 9, setSheetState),
        _buildPeriodBtnSheet('3$d', 10, setSheetState),
      ];
    } else if (category == 'hafta') {
      final h = l10n.week[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet(h, 1, setSheetState), // Sadece 'H'
        _buildPeriodBtnSheet('2$h', 4, setSheetState),
        _buildPeriodBtnSheet('3$h', 5, setSheetState),
      ];
    } else if (category == 'ay') {
      final a = l10n.month[0].toUpperCase();
      options = [
        _buildPeriodBtnSheet(a, 2, setSheetState), // Sadece 'A'
        _buildPeriodBtnSheet('3$a', 6, setSheetState),
        _buildPeriodBtnSheet('6$a', 7, setSheetState),
      ];
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.expand((w) => [w, const SizedBox(width: 4)]).toList()..removeLast(),
    );
  }

  // Sheet için periyot butonu
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
        });
        setSheetState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Daha sıkı padding
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.getPrimary(context).withValues(alpha: 0.08) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: isActive 
                ? AppColors.getPrimary(context).withValues(alpha: 0.3) 
                : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9, // Çok daha küçük font
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive 
                ? AppColors.getPrimary(context) 
                : AppColors.getTextSecondary(context).withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // Periyot isimleri yardımcısı
  String _getPeriodName(int type) {
    switch (type) {
      case 1:
        return l10n.week;
      case 2:
        return l10n.month;
      case 3:
        return l10n.year;
      case 4:
        return l10n.every2Weeks;
      case 5:
        return l10n.every3Weeks;
      case 6:
        return l10n.every3Months;
      case 7:
        return l10n.every6Months;
      case 8:
        return l10n.day;
      case 9:
        return l10n.every2Days;
      case 10:
        return l10n.every3Days;
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
          child: Icon(icon, size: 20, color: AppColors.getTextPrimary(context)),
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
          Expanded(
            child: _buildTabBtn(
              l10n.expense.toUpperCase(),
              0,
              Icons.arrow_downward_rounded,
              AppColors.error,
            ),
          ),
          Expanded(
            child: _buildTabBtn(
              l10n.income.toUpperCase(),
              1,
              Icons.arrow_upward_rounded,
              AppColors.primary,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.getSurface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.getDarkShadow(context),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.getLightShadow(context),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : AppColors.getTextSecondary(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kasa / Grup Seçici (Periyot Seçici Formatında)
  Widget _buildVaultSelector(
    BuildContext context,
    StateSetter setSheetState,
  ) {
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
            Text(
              l10n.vaultOrGroup,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
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
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: const BorderRadius.vertical(
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
                                      child: Text(
                                        l10n.cancel,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      l10n.selectVault,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.getTextPrimary(context),
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
                                      child: Text(
                                        l10n.ok,
                                        style: const TextStyle(
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
                                          option?.name ?? l10n.generalBalance;

                                      return Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              getIconData(option?.iconCode),
                                              size: isSelected ? 24 : 18,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.getTextSecondary(context),
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
                                                    : AppColors.getTextSecondary(context),
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
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  border: Border.all(color: AppColors.getSurface(context), width: 1.5),
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
                      selectedVault?.name ?? l10n.generalBalance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getTextPrimary(context),
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
