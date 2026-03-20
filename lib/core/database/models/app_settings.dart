import 'package:isar/isar.dart';

part 'app_settings.g.dart';

/// Uygulama geneli ayarlar — Tek satırlık koleksiyon (id = 1 daima)
@collection
class AppSettings {
  Id id = 1; // Tek kayıt, her zaman id=1

  /// Veri saklama süresi (gün cinsinden)
  /// -1 = Hiçbir zaman silme (sonsuz)
  /// 30 / 90 / 180 / 365 = ilgili süre
  int dataRetentionDays = 90;

  /// Tema Modu
  /// 0 = Sistem Varsayılanı
  /// 1 = Aydınlık (Light)
  /// 2 = Karanlık (Dark)
  int themeModeIndex = 0;

  /// Uygulama dili (varsayılan: tr)
  String languageCode = 'tr';

  /// AI asistan bildirimleri açık mı?
  bool isAiNotificationsEnabled = true;

  /// Bulut senkronizasyonu aktif mi?
  bool isSyncEnabled = false;

  /// --- Senkronizasyon Alanları ---
  @Index()
  String? remoteId;

  @Index()
  DateTime updatedAt = DateTime.now();

  @Index()
  int syncStatus = 0;
}
