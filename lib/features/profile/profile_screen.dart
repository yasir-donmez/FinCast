import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/neu_container.dart';

/// Kullanıcının ve uygulamanın genel ayarlarını içeren
/// Premium "Kişisel CFO" Ayarlar Ekranı (Settings / Profile)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Örnek Ayar Durumları (İleride Riverpod / SharedPreferences'a bağlanacak)
  bool _isDarkMode = true;
  bool _isAiNotificationsEnabled = true;
  bool _isBiometricEnabled = false;
  String _selectedLanguage = "Türkçe";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.paddingMedium),

            // 1. ÜST: Profil Kartı (Yetişkin / Profesyonel Tasarım)
            NeuContainer(
              borderRadius: AppSizes.radiusLarge,
              child: Row(
                children: [
                  NeuContainer(
                    width: 60,
                    height: 60,
                    borderRadius: 30, // Tam yuvarlak avatar yuvası
                    isInnerShadow: true,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          'https://i.pravatar.cc/150?img=11',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingLarge),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Yasir Dönmez",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "FinCast Premium", // Rozet yerine ciddi statü
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profili Düzenle (Küçük İleri Oku veya Kalem)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 2. TERCİHLER & UYGULAMA GRUBU
            _buildSectionHeader("TERCİHLER & UYGULAMA"),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                children: [
                  _buildToggleSetting(
                    icon: Icons.dark_mode_rounded,
                    title: "Karanlık Tema",
                    value: _isDarkMode,
                    onChanged: (val) => setState(() => _isDarkMode = val),
                  ),
                  _buildDivider(),
                  _buildNavSetting(
                    icon: Icons.language_rounded,
                    title: "Uygulama Dili",
                    trailingText: _selectedLanguage,
                    onTap: _showLanguagePicker,
                  ),
                  _buildDivider(),
                  _buildToggleSetting(
                    icon: Icons.notifications_active_rounded,
                    title: "AI Asistan Uyarıları",
                    value: _isAiNotificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _isAiNotificationsEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 3. GÜVENLİK & VERİ GRUBU
            _buildSectionHeader("GÜVENLİK & VERİ"),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                children: [
                  _buildToggleSetting(
                    icon: Icons.fingerprint_rounded,
                    title: "Biyometrik Kilit (FaceID)",
                    value: _isBiometricEnabled,
                    onChanged: (val) =>
                        setState(() => _isBiometricEnabled = val),
                  ),
                  _buildDivider(),
                  _buildActionSetting(
                    icon: Icons.cloud_upload_rounded,
                    title: "Verileri Drive'a Yedekle",
                    onTap: () {
                      // Yedekleme İşlemi (İpucu: Snackbar gösterilebilir)
                    },
                  ),
                  _buildDivider(),
                  _buildActionSetting(
                    icon: Icons.download_rounded,
                    title: "Tüm Verileri Dışa Aktar (CSV)",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 4. DESTEK & HAKKINDA GRUBU
            _buildSectionHeader("DESTEK"),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                children: [
                  _buildActionSetting(
                    icon: Icons.support_agent_rounded,
                    title: "FinCast ile İletişim",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildNavSetting(
                    icon: Icons.info_outline_rounded,
                    title: "Uygulama Hakkında",
                    trailingText: "v1.0.0",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // BottomNav payı
          ],
        ),
      ),
    );
  }

  // Grupların (Güvenlik, Tercihler vs) başlık yazısı
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // Gruplar (Kartlar) içindeki ayırıcı çizgi
  Widget _buildDivider() {
    return Divider(
      color: AppColors.surface.withValues(alpha: 0.5),
      height: 1,
      thickness: 1,
      indent: 56, // İkondan sonrası için hizalı
      endIndent: 16,
    );
  }

  // AÇ/KAPA (Toggle) Ayar Satırı
  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          // iOS Tarzı Şık Cupertino Switch
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.darkShadow.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // YÖNLENDİREN (Tıklanabilir İleri İzli) Ayar Satırı
  Widget _buildNavSetting({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // TIKLANABİLİR AKSİYON (Sadece Buton) Ayar Satırı
  Widget _buildActionSetting({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // IOS Alarm Picker Tarzı "Dil Seçici" Alt Penceresi (Bottom Sheet)
  void _showLanguagePicker() {
    final List<String> languages = [
      "Türkçe",
      "English",
      "Deutsch",
      "Español",
      "Français",
    ];
    int tempSelectedIndex = languages.indexOf(_selectedLanguage);
    if (tempSelectedIndex == -1) tempSelectedIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Arka plan tamamen Neumorphic Container'a kalsın
      builder: (context) {
        return NeuContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Uygulama Dili Seçin",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              SizedBox(
                height: 200, // Picker yüksekliği
                child: CupertinoPicker(
                  itemExtent: 40,
                  magnification: 1.2,
                  useMagnifier: true,
                  scrollController: FixedExtentScrollController(
                    initialItem: tempSelectedIndex,
                  ),
                  onSelectedItemChanged: (index) {
                    tempSelectedIndex = index;
                  },
                  children: languages.map((lang) {
                    return Center(
                      child: Text(
                        lang,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              // Onay Butonu
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: () {
                    setState(() {
                      _selectedLanguage = languages[tempSelectedIndex];
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Kaydet",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
