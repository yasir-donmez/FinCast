# 🚀 FinCast
**Akıllı Finansal Takip ve Gelecek Projeksiyonu Uygulaması**

FinCast, geleneksel "geçmiş odaklı" bütçe takip uygulamalarının aksine, kullanıcıların finansal geleceğini matematiksel olarak hesaplayan kişisel bir servet yönetimi uygulamasıdır. Kullanıcıların yaşam standartlarını düşürmeden hedeflerine ulaşmaları için kısıtlı optimizasyon (constrained optimization) algoritmaları kullanarak akıllı tasarruf rotaları çizer.

## ✨ Temel Özellikler (Core Features)
* **🔮 Finansal Zaman Makinesi**: Özel tasarlanmış zaman kaydırıcısı (slider) ile kullanıcıların harcama alışkanlıklarına göre aylar veya yıllar sonraki tahmini bakiyelerini anında simüle eder.
* **🔒 Kilit Mekanizması (Kırmızı Çizgiler)**: Kullanıcılar zorunlu giderlerini (kira, aidat, eğitim, sağlık) "kilitler". Algoritma, tasarruf rotası çizerken bu yaşam standartlarına dokunmaz, sadece esnek harcamalar üzerinden tavsiye verir.
* **📊 Esnek Bütçeleme (Min-Max)**: Harcamalar için tek ve katı bir rakam yerine aralıklar (Örn: Haftalık 200 TL - 450 TL) belirlenerek kullanıcının stresten uzak bir finansal takip yapması sağlanır.
* **💼 Çoklu Varlık Kasaları**: Kullanıcılar sadece tek bir para birimine bağlı kalmaz; nakit, döviz veya altın gibi farklı "Kasalar" (Vaults) oluşturarak toplam servetlerini tek ekranda görebilirler.
* **⚡ Çevrimdışı Öncelikli (Offline-First)**: Bulut bağımlılığı yoktur. Tüm veriler ve algoritmik hesaplamalar cihazın kendi işlemcisi ve yerel veritabanı kullanılarak milisaniyeler içinde, %100 gizlilikle gerçekleşir.

## 🛠️ Teknoloji Yığını (Tech Stack)
* **Mobil Çerçeve**: Flutter (Dart)
* **Yerel Veritabanı**: Isar Database (Yüksek performanslı, ilişkisel NoSQL)
* **Mimari Yaklaşım**: Feature-First Architecture (Özellik Odaklı Klasörleme)
* **Tasarım Dili**: Dark Mode First, Neumorphism (Kabartmalı / Fiziksel Hissiyat) & Glassmorphism

## 📂 Klasör Mimarisi (Architecture)
Proje, sürdürülebilirlik ve temiz kod prensiplerine uygun olarak Feature-First yapısında kurgulanmıştır:

```plaintext
lib/
├── core/             # Tema (Neumorphic renkler), veritabanı motoru ve sabitler
├── features/         # Uygulamanın ana modülleri (Her özellik kendi içinde bağımsızdır)
│   ├── dashboard/    # Ana ekran ve Zaman Makinesi UI
│   ├── budget/       # Kilit mekanizması ve Min-Max kuralları
│   └── vaults/       # Çoklu varlık kasaları
├── shared/           # Ortak kullanılan Neumorphic butonlar, özel widget'lar
└── main.dart         # Uygulamanın giriş noktası
```

## 🎨 Arayüz Vizyonu (UI/UX)
FinCast, sıkıcı beyaz banka arayüzlerinden sıyrılarak Dark Neumorphism (Karanlık Kabartma) stiliyle tasarlanmıştır. Ekranda yer alan butonlar ve kartlar, arka planın içine gömülü veya dışarı doğru fiziksel olarak kabartılmış gibi durarak kullanıcıya dokunsal (tactile) bir premium hissiyat verir. Vurgu renkleri olarak fütüristik Neon Mor ve Elektrik Mavisi kullanılmıştır.

## 🚀 Kurulum (Getting Started)
Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

1. Repoyu bilgisayarınıza klonlayın:
```bash
git clone https://github.com/KULLANICI_ADIN/fincast.git
```

2. Proje dizinine gidin ve bağımlılıkları yükleyin:
```bash
cd fincast
flutter pub get
```

3. Isar veritabanı modelleri için kod üreticiyi (code generation) çalıştırın:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Uygulamayı başlatın:
```bash
flutter run
```