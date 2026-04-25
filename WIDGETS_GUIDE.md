# FinCast Bileşen (Widget) Rehberi

Bu dosya, `lib/shared/widgets` klasöründeki ortak bileşenlerin ne işe yaradığını ve projede nerelerde kullanıldığını açıklar.

## Ortak Bileşenler (`lib/shared/widgets`)

### 1. CarvedContainer
- **Ne İşe Yarar?**: "Oyulmuş" veya "gömülü" (neumorphic inset) efekti veren bir kapsayıcıdır. Nesnelerin arka planın içine gömülmüş gibi görünmesini sağlar.
- **Nerede Kullanılır?**:
  - `VaultsScreen` içinde boş işlem listesi gösterilirken kullanılan ikonun arka planında.

### 2. FluidAnimatedIcon
- **Ne İşe Yarar?**: İki ikon arasında geçiş yaparken dönme, ölçeklenme ve şeffaflık animasyonları uygular.
- **Nerede Kullanılır?**:
  - `FluidSwitch` içinde durum değişimini görselleştirmek için.

### 3. FluidButton
- **Ne İşe Yarar?**: Dokunulduğunda küçülen (scale) ve gölge derinliği değişen akışkan tasarımlı bir butondur. Cam (glassmorphism) efektini destekler.
- **Nerede Kullanılır?**:
  - Uygulama genelinde ana işlem butonlarında (örn: `AddTransactionSheet`).

### 4. FluidContainer
- **Ne İşe Yarar?**: Tasarım sisteminin temel taşıdır. Glassmorphism (cam efekti), Soft-Depth (yumuşak derinlik) ve Squircle (yuvarlatılmış kare) kavislerini birleştirir.
- **Nerede Kullanılır?**:
  - `FluidButton`, `FluidTextField`, `FluidDialog` gibi hemen hemen tüm modern bileşenlerin temelinde.

### 5. FluidDialog
- **Ne İşe Yarar?**: Estetik, cam efektli ve animasyonlu uyarı/onay pencereleri oluşturur.
- **Nerede Kullanılır?**:
  - İşlem silme onaylarında (`VaultsScreen`), hata mesajlarında ve genel kullanıcı bildirimlerinde.

### 6. FluidSheet
- **Ne İşe Yarar?**: Ekranın altından açılan (bottom sheet) akışkan ve cam efektli panellerdir.
- **Nerede Kullanılır?**:
  - İşlem ekleme (`AddTransactionSheet`), Kasa detayları ve filtreleme ekranlarında.

### 7. FluidSwitch
- **Ne İşe Yarar?**: "Jelly" (jöle) kıvamında animasyona sahip, dokunsal geri bildirimli (haptic) özel bir açma/kapama anahtarıdır.
- **Nerede Kullanılır?**:
  - Tema değişimi (`ThemeRevealButton`) ve ayarlardaki tüm switch'lerde.

### 8. FluidTabSelector
- **Ne İşe Yarar?**: İki veya daha fazla seçenek arasında kayan bir gösterge ile geçiş yapmayı sağlayan tab çubuğudur.
- **Nerede Kullanılır?**:
  - Gelir/Gider geçişlerinde (`TransactionTypeToggle`) ve period seçimlerinde.

### 9. FluidTextField
- **Ne İşe Yarar?**: Odaklanıldığında parlayan, cam dokulu modern metin giriş alanıdır.
- **Nerede Kullanılır?**:
  - İsim, açıklama ve miktar girişlerinin yapıldığı formlarda.

### 10. MembershipOrb
- **Ne İşe Yarar?**: İçinde sıvı varmış gibi hareket eden, 3D görünümlü premium bir küre animasyonudur.
- **Nerede Kullanılır?**:
  - PRO/Premium üyelik tanıtım alanlarında (`DashboardScreen`).

### 11. NeuButton
- **Ne İşe Yarar?**: Klasik neumorphic (fiziksel düğme gibi görünen) basılma etkili butondur.
- **Nerede Kullanılır?**:
  - Neumorphic tasarımlı nümerik klavyelerde (`NeumorphicNumpad`).

### 12. NeuContainer
- **Ne İşe Yarar?**: Dışa çıkık (convex) veya içe çökük (concave/inner shadow) neumorphic alanlar oluşturur.
- **Nerede Kullanılır?**:
  - Eski nesil kart tasarımlarında ve fiziksel derinlik istenen alanlarda.

### 13. NeuTextField
- **Ne İşe Yarar?**: İçe çökük neumorphic zemin üzerine kurulmuş metin giriş alanıdır.
- **Nerede Kullanılır?**:
  - Neumorphic tasarım dilinin tercih edildiği giriş formlarında.

### 14. PrecisionCard
- **Ne İşe Yarar?**: Çok ince kenarlıklı, hafif cam efektli minimalist bir kart bileşenidir.
- **Nerede Kullanılır?**:
  - Ayarlar ekranı öğelerinde ve özet bilgilerinde (`ProfileScreen`).

### 15. PrecisionClickable
- **Ne İşe Yarar?**: Herhangi bir widget'a tıklama özelliği, hafif küçülme efekti ve parlayıp sönme (flash) efekti ekler. `Stack` yapısı optimize edilmiştir.
- **Nerede Kullanılır?**:
  - Liste öğelerinde ve `PrecisionButton`'ın temelinde.

### 16. PrecisionButton
- **Ne İşe Yarar?**: Uygulamanın yeni standart buton tarzıdır. Arka planı olmayan, sadece metin ve parlamadan oluşan (ghost-style) premium bir butondur.
- **Özellikleri**: Olumlu aksiyonlar için renkli, olumsuz aksiyonlar için beyaz metin kullanır.
- **Nerede Kullanılır?**:
  - Tüm alt paneller (sheets) ve diyalog pencerelerinde.

### 16. PremiumGlassCard
- **Ne İşe Yarar?**: Yüksek bulanıklık (blur) değerine sahip, premium cam efektli karttır.
- **Nerede Kullanılır?**:
  - Dashboard üzerindeki ana kartlarda ve vurgulanmak istenen alanlarda.

### 17. SliverAnimationSpacer
- **Ne İşe Yarar?**: Kaydırılabilir listelerin (Sliver) altında boşluk oluşturarak, başlıkların (header) az içerik varken bile tam kapanmasını sağlar.
- **Nerede Kullanılır?**:
  - `CustomScrollView` kullanılan ana listelerin sonunda.

### 18. ThemeRevealButton
- **Ne İşe Yarar?**: Tema değişimini dairesel bir "maske silme" animasyonuyla (circular reveal) gerçekleştiren gelişmiş butondur.
- **Nerede Kullanılır?**:
  - Profil/Ayarlar ekranındaki tema değiştirme alanında.

---

## Özelliğe Özel Bileşenler

Buna ek olarak, her özelliğin kendi klasöründe (`lib/features/.../widgets`) o özelliğe özel bileşenler bulunur:
- **Vaults**: `TransactionCard`, `VaultDetailSheet`, `LiquidBlob`.
- **Transactions**: `FluidNumpad`, `TransactionAmountInput`, `TransactionVaultSelector`.
- **Optimization**: `AiInsightCard`, `LiquidConstraintTube`.
- **Dashboard**: `ExpandableVaultGrid`.
- **Auth**: `FluidFlipCard`.
