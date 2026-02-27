# FinCast - Proje Geliştirme Yol Haritası ve Görev Takibi (Implementation Plan)

Bu belge, FinCast uygulamasının adım adım geliştirilmesi için bir rehber ve checklist görevi görür. Tüm teknik mimari, özellikler ve UI/UX kararları bu belgeye göre uygulanacaktır.

## 🎯 Kesinleşen Mimari ve UI/UX Kararları

1.  **Navigasyon Yapısı:** Geleneksel Alt Navigasyon Çubuğu (Bottom Navigation Bar) + Ortada belirgin FAB (Floating Action Button).
2.  **Zaman Makinesi (Gelecek Projeysiyonu):** Dairesel Çevirmeli Buton (Rotary Dial/Knob). Yenilikçi ve fiziksel dokunma hissi (Dark Neumorphism) veren, çevirdikçe ekrandaki bakiyeyi simüle eden özel bir UI.
3.  **Veri Giriş Ekranı (Transaction):** Tam ekran açılan dinamik sayfa. Fiziksel hissiyatlı, animasyonlu büyük tuş takımı (Neumorphic Numpad) ile hızlı ve kolay veri girme.
4.  **Renk Paleti & Tema:** **Obsidyen Siyahı Tema**. Arka plan `#0A0A0A`, kartlar `#141414`. OLED ekranlar için pil dostu ve Neon Mor/Cyan vurgu renklerini en iyi patlatan zemin.
5.  **State Management:** `Riverpod` (Güvenli, esnek ve modern çözüm).
6.  **Veritabanı:** `Isar Database` (Offline-first, hızlı, ilişkisel NoSQL).

---

## ✨ Uygulama Özellikleri ve Ekran Tasarımları

### 1. Ana Sayfa (Dashboard) - 3 Ana Bölüm
*   **Dinamik Varlık Kasaları:** Seçili varlıklar (Altın, Dolar hesabı, Cepteki Nakit vs.) yatay kaydırılabilir kutularda gösterilir. Tıklanan kutu sıvı animasyonla büyüyüp öne çıkar (detaylanır), diğerleri küçülür. API ile anlık kur dönüşümü merkezdedir.
*   **Ana Bakiye & Toplam Servet:** Ekran merkezinde yer alan devasa, Neumorphic "Ana Toplam". Seçili varlıkların birleşik değeridir. Dolar/TL/Altın ikonuna basarak anında tüm serveti o birime çevirebilir.
*   **Zaman Makinesi (Rotary Dial Controller):** Ekranın altındaki büyük, haptic titreşimli dairesel düğme (Knob/Dial). Kullanıcı bunu sağa sola çevirerek günü/haftayı/yılı değiştirir; bakiye, algoritma tarafında hesaplanarak (harcama eğilimleri ve kilitli borçlara göre) dinamik şekilde değişir ve neon ışıklar efektiyle simüle edilir.

### 2. Gelir / Gider Ekleme Sayfası (Transaction Entry)
*   **Zengin Hazır Modeller (Kategoriler):** Eğlence, Market, Abonelik (Netflix/Spotify), Kira, Ekstra Harcama gibi çok çeşitli, ikonografileri ve renkleri özel olarak tasarlanmış yuvarlak/kare Neumorphic kutulardan oluşan "Kategori Grid"i. 
*   **Periyot Seçimi (Slider/Dropdown):** Seçilen giderin (veya gelirin) tekrarlama periyodunu belirleme. (Örn: Sadece 1 Kez, 1 Haftalık, 1 Aylık, Yıllık).
*   **Taksit ve Borç Yönetimi (Sınırlı Süreli Kilit):** Ekrandaki "Bu bir Taksit mi?" anahtarına (switch) basıldığında, kullanıcıdan "Kaç ay kaldı?" bilgisi istenir. Bu sistem, uygulamanın asıl gücü olan Zaman Makinesine entegredir; örneğin 6 ay sonrasına simülasyon yapıldığında kredi kartı taksiti otomatik olarak bitmiş sayılır ve bakiye zıplar.
*   **Min - Max Aralık (Esnek Bütçeleme):** İki adet kaydırıcı (Range Slider) veya Numpad ile "Minimum 200 TL - Maksimum 600 TL" gibi bir aralık (Range) seçtiren ekran bölümü.
*   **UI/UX Vurgusu:** Alt kısımda yer alan Neumorphic fiziksel Numpad (tuş takımı) ile aralık limitleri hızlıca girilir ve devasa siyah-neon mor bir "Kaydet" butonu ile işlem sonlandırılır.

### 3. Hedef ve Tavsiye Rotası (AI Destekli Optimizasyon Ekranı)
*   **Zaman ve Hedef Kurgusu:** Kullanıcı üstten "3 ay sonra" zamanını ve "100.000 TL" hedefini belirler.
*   **Kırmızı Çizgi (Kilitli Gider/Gelir) Tespiti:** Ekranın ortasında kullanıcının düzenli gelirleri ve giderleri listelenir. Kullanıcı; "Kira", "Maaş", "Yurt Aidatı" gibi asla değişmeyecek olanların yanındaki **"Asma Kilit (Lock) 🔒"** ikonuna tıklar. Bu öğeler parlak Kırmızıya/Mora dönerek sisteme "Bana tavsiye verirken bunlara dokunma" mesajı verir.
*   **Görsel Optimizasyon Sunumu (Sıvı/Su Mekanizması):** Sıkıcı metinler yerine sistem, UX olarak **"Sıvı Dolu Tüpler / Kaplar"** (Liquid Fill Animation) kullanır. Algoritma hedefe ulaşmak için örneğin eğlenceyi kısmayı uygun bulursa, Eğlence tüpündeki parlak neon sıvı animasyonlu bir şekilde aşağı doğru iner. 
*   **Sisteme Entegre AI Karar Motoru (Brain/Decision Engine):** Bir sohbet botu (Chatbot) veya pencere açıp konuştuğunuz bir asistan yerine, uygulamanın **kalbine gömülü (integrated) çalışan** bir yapay zekadır. 
    *   Siz hedefi girdiğinizde, AI geçmiş verilerinize, enflasyona ve kilitli borçlarınıza bakarak "Cam Tüplerin" ne kadar azalması gerektiğini matematiksel olarak hesaplayan ve arayüzü doğrudan (sıvı animasyonlarıyla) besleyen asıl güçtür.
    *   Bu AI, hedefinizin gerçekçiliğini milisaniyeler içinde yüzdesel olarak hesaplar (Örn: *Bu hedefe ulaşma ihtimalin %88*). Hedef çok ulaşılmazsa, arayüzdeki renkler/uyarılar değişerek sizi yormadan yönlendirir.

### 4. Hızlı Ekleme ve Widget'lar (Faz 2 / Gelecekteki İleri Eklenti)
*   **Ana Ekran Araçları (Home Screen Widgets):** Flutter doğrudan UI üzerinden ana ekran (Home Screen) widget'ı üretemese de, araya giren köprü paketleri (Örn: `home_widget` paketi) ve Native kodlar (iOS için Swift/WidgetKit, Android için Kotlin/Glance) yardımıyla bu çok şık bir eklenti olarak yapılabilir.
*   **Pratiklik Hedefi:** Temel uygulama kusursuz oturduktan sonra, iOS/Android ana ekranından direkt uygulamaya veri yollayan bağlantılar entegre edilebilir.

### 5. Profil ve Ayarlar (Oyunlaştırma & Ayar Merkezi)
*   **Seviye (Gamification/Oyunlaştırma) ve Rozetler:** Sıkıcı bir ayarlar sayfası yerine, kullanıcının "Tasarruf/Optimizasyon Puanı" ve seviyesini gösteren bir profil alanı. Hedefi tutturanlara verilen neon rozetler (Örn: "Master of Budgeting", "Zinciri Kırma" vb.).
*   **AI Kişiselleştirme Sınırları:** AI asistanının ses tonunu ayarlama (Örn: Motive Edici, Disiplinli/Sert, Sadece Sayısal Analiz gibi).
*   **Uygulama Temelleri:** Koyu/Açık Tema seçimleri (Gerçi Obsidian Black asıldır ama seçenek konabilir), Veri yedekleme (Google Drive Sync), Bildirim tercihleri, Döviz kurları için baz birim seçimi.
*   **Tasarım Dili:** Tıklanabilir Neumorphic switch'ler (Anahtarlar) ve yuvarlatılmış kartlara gömülü ayar listeleri.
