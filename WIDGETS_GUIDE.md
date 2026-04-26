# FinCast Tasarım Sistemi (Precision Design System)

Bu dosya, `lib/shared/widgets` klasöründeki profesyonel bileşenlerin ne işe yaradığını ve projede nerelerde kullanıldığını açıklar. Tüm bileşenler **Precision** (Hassasiyet) teması altında standartlaştırılmıştır.

## Ortak Bileşenler (`lib/shared/widgets`)

### 1. PrecisionSurface
- **Ne İşe Yarar?**: Tasarım sisteminin temel taşıdır. Glassmorphism (cam efekti), Squircle kavisler ve Soft-Depth (yumuşak derinlik) özelliklerini barındıran ana kapsayıcıdır.
- **Eski Adı**: `FluidContainer`

### 2. PrecisionSheet
- **Ne İşe Yarar?**: Ekranın altından açılan, akıcı animasyonlu ve cam efektli paneldir. Klavye açıldığında otomatik olarak kendini yukarı kaydırır.
- **Eski Adı**: `FluidSheet`

### 3. PrecisionToggle
- **Ne İşe Yarar?**: "Jelly" (jöle) animasyonlu, dokunsal geri bildirimli modern açma/kapama anahtarıdır.
- **Eski Adı**: `FluidSwitch`

### 4. PrecisionSegmentedControl
- **Ne İşe Yarar?**: Birden fazla seçenek arasında kayan bir gösterge ile geçiş yapmayı sağlayan kontrol çubuğudur.
- **Eski Adı**: `FluidTabSelector`

### 5. PrecisionButton
- **Ne İşe Yarar?**: Minimalist, arka planı olmayan (ghost-style) premium butondur. Vurgu rengiyle parlar.

### 6. PrecisionAction
- **Ne İşe Yarar?**: Herhangi bir nesneye tıklama özelliği, hafif küçülme ve parlama efekti ekleyen temel etkileşim sarmalayıcısıdır.
- **Eski Adı**: `PrecisionClickable`

### 7. PrecisionGlassCard
- **Ne İşe Yarar?**: Yüksek blur değerine sahip, premium cam efektli kart bileşenidir.
- **Eski Adı**: `PremiumGlassCard`

### 8. PrecisionInput
- **Ne İşe Yarar?**: Odaklanıldığında parlayan, cam dokulu modern metin giriş alanıdır.

### 9. PrecisionPicker
- **Ne İşe Yarar?**: "Slot Machine" tarzı dairesel seçim bileşenidir.

### 10. PrecisionDialog
- **Ne İşe Yarar?**: Ekranın ortasında beliren cam efektli onay ve uyarı pencereleridir.

### 11. PrecisionIconButton
- **Ne İşe Yarar?**: Minimalist, sadece ikon ve parlamadan oluşan buton.

### 12. PrecisionInset
- **Ne İşe Yarar?**: İçeri gömülmüş (inner shadow) efekti veren neumorphic kapsayıcıdır.
- **Eski Adı**: `CarvedContainer`

### 13. PrecisionThemeToggle
- **Ne İşe Yarar?**: Tema değişimini dairesel bir "reveal" animasyonuyla gerçekleştiren özel kontrol.
- **Eski Adı**: `ThemeRevealButton`

### 14. PrecisionMembershipOrb
- **Ne İşe Yarar?**: 3D görünümlü, hareketli premium küre animasyonu.
- **Eski Adı**: `MembershipOrb`

### 15. PrecisionAnimatedIcon
- **Ne İşe Yarar?**: İki ikon arasında yumuşak rotasyon ve ölçeklenme ile geçiş yapar.
- **Eski Adı**: `FluidAnimatedIcon`

---

## Özelliğe Özel Bileşenler
- **Vaults**: `PrecisionTransactionCard`, `PrecisionDetailSheet`, `PrecisionBlob`.
- **Transactions**: `PrecisionAmountInput`.
- **Optimization**: `PrecisionInsightCard`, `PrecisionReactorButton`, `PrecisionConstraintTube`.
- **Dashboard**: `PrecisionVaultGrid`.
- **Auth**: `PrecisionFlipCard`, `PrecisionBackground`, `PrecisionWave`.
