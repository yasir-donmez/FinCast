# Proje Dosya Haritası

Bu belge, FinCast Flutter projesindeki önemli dosya ve klasörlerin kısa bir açıklamasını sunar. Amacı, geliştiricilerin proje yapısını hızlıca anlamalarına yardımcı olmaktır.

---

## 🗂 Kök Dizin

- `pubspec.yaml` – Projenin Flutter/Dart bağımlılıkları ve metadata'sı.
- `README.md` – Projeyle ilgili genel bilgiler ve kullanım notları.
- `analysis_options.yaml`, `analyze.json` – Dart analiz kuralları ve çıktıları.
- `implementation_plan.md` – Plan veya yol haritası belgesi.

## android/

Android uygulama kaynakları ve yapılandırma.
- `build.gradle.kts`, `settings.gradle.kts` – Gradle yapı betikleri.
- `app/` – Android uygulama modülü; manifestler, kaynaklar, java/kotlin kodları.

## ios/

iOS platformuna özgü proje dosyaları.
- `Runner/` – iOS uygulama kaynakları ve Swift/ObjC köprüleri.
- `Runner.xcodeproj`, `Runner.xcworkspace` – Xcode proje ayarları.

## lib/

Flutter/Dart uygulamasının ana çalışma alanı.

### main.dart
Uygulamanın giriş noktası. `runApp()` çağrısı burada bulunur.

### core/
Temel yapı taşları ve ortak çekirdek bileşenler.
- `constants/` – Sabit değerler ve anahtarlar.
- `database/` – Uygulama içi veri depolama ile ilgili modeller ve generator dosyaları.
  - `models/transaction_record.dart` & `transaction_record.g.dart` – İşlem kayıtları model sınıfı ve üretici kodu.
  - `models/vault.dart` & `vault.g.dart` – Kasa (vault) modeli ve üretici kodu.

- `theme/` – Uygulama teması ve stil ayarları.
  - `app_constants.dart` – Tema ve UI ile ilgili sabitler.
  - `app_theme.dart` – Renk paleti ve tema yapılandırması.

### features/
Uygulamanın farklı işlevsel modülleri (feature"lar).
- `budget/` – Bütçe yönetimi (içerik yok veya kendi alt klasörü var olabilir).
- `dashboard/` – Ana gösterge paneli.
  - `dashboard_providers.dart` – State yönetimi sağlayıcıları.
  - `dashboard_screen.dart` – Dashboard ana ekran widget'ı.
  - `main_scaffold.dart` – Uygulama genel iskeleti/ana görünümü.
  - `widgets/` – Dashboard ile ilgili özel widget'lar.
    - `expandable_vault_grid.dart` – Genişleyebilir kasa ızgarası.
    - `rotary_time_dial.dart` – Saat şeklinde zaman seçme bileşeni.
- `optimization/` – Optimizasyon özellikleri.
  - `optimization_screen.dart` – Optimizasyon ekranı.
  - `services/optimization_engine.dart` – İş mantığı ve hesaplama motoru.
  - `widgets/` – Optimizasyon arayüzü elementleri.
    - `ai_insight_card.dart`, `liquid_constraint_tube.dart`, `neumorphic_circular_slider.dart` gibi özel widget'lar.
- `profile/` – Kullanıcı profili ekranı.
  - `profile_screen.dart` – Profil gösterim/edits ekranı.
- `transactions/` – İşlem ekleme ve listeleme.
  - `add_transaction_sheet.dart` – Yeni işlem ekleme modalı.
  - `widgets/neumorphic_numpad.dart` – Neumorphic tarzda sayısal tuş takımı.
- `vaults/` – Kasa yönetimi işlevleri (detaylara klasördeki dosyalar göre).

### shared/
Genel tekrar kullanılabilir yardımcılar ve bileşenler.
- `utils/` – Yardımcı fonksiyonlar.
- `widgets/` – Ortak widget'lar.
  - `neu_button.dart`, `neu_container.dart` – Neumorphic stil dekorasyonlu bileşenler.

## test/
- `widget_test.dart` – Flutter widget testi örneği.

## build/
Derleme çıktıları ve raporlar. Genelde versiyon kontrolüne dahil edilmez.

---

> Bu harita geliştiricilere proje yapısını hızlıca anlatmayı amaçlar. Her özelliğin içeriği, klasördeki dosyaların kendilerine bakılarak daha ayrıntılı incelenebilir.
