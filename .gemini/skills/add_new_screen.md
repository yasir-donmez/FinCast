# Skill: Yeni Bir Ekran/Sayfa Eklemek (Workflow)

Yapay zeka (AI) olarak, projeye yeni bir sayfa (screen) eklenmesi istendiğinde şu adımları referans alarak işlemi tamamla:

1. **Dosya İskeletini Oluştur:**
   `lib/screens/` veya özellik klasörü (feature folder) altında `yeni_sayfa_adi.dart` isimli dosyayı oluştur. `ConsumerWidget` veya `ConsumerStatefulWidget` kullan.
   
2. **Boş Layout'u Hazırla (Premium Temel):**
   Bütün yeni ekranları bir `Scaffold` ile sarmala. `.clinerules` tasarım standartlarındaki gibi premium bir koyu arka plan (background color) ayarlayıp, esnek bir gövde inşa et.

3. **Gerekli İhtiyaçları Belirle (Provider / Logic):**
   Eğer bu ekranda özgün bir veri tutulacaksa, sayfanın içine kod yazmadan önce `lib/providers/` altında bu ekranın logic'ini (Controller) yönetecek olan Provider'ı oluştur ve sayfaya bağla.

4. **Kullanıcı Etkileşimlerini Hazırla:**
   Sadece statik tasarımlar koyma. Etkileşim gerektiren noktalara dokunma hissiyatlı (Haptic Feedback) GestureDetector'lar/Inkwell'ler yerleştir.

5. **İletişim & Onay:**
   Taslağı tamamladığında, geliştiriciye (kullanıcıya) son durum hakkında rapor ver ve route dosyasında nerelerin güncellenmesi gerektiğini belirt/veya kendin yap.
