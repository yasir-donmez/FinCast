import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/subscription_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/neu_container.dart';
import '../../core/providers/settings_provider.dart';

/// Kullanıcının ve uygulamanın genel ayarlarını içeren
/// Premium "Kişisel CFO" Ayarlar Ekranı (Settings / Profile)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final selectedLanguageName = _getLanguageName(settings.languageCode);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.paddingMedium),

            // 1. ÜST: Profil Kartı
            _buildProfileCard(l10n),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 2. TERCİHLER & UYGULAMA GRUBU
            _buildSectionHeader(l10n.preferences),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                children: [
                  _buildNavSetting(
                    icon: Icons.palette_rounded,
                    title: l10n.themeMode,
                    trailingText: _getThemeModeName(settings.themeModeIndex, l10n),
                    onTap: () => _showThemePicker(settings.themeModeIndex, l10n),
                  ),
                  _buildDivider(),
                  _buildNavSetting(
                    icon: Icons.language_rounded,
                    title: l10n.language,
                    trailingText: selectedLanguageName,
                    onTap: () => _showLanguagePicker(settings.languageCode, l10n),
                  ),
                  _buildDivider(),
                  _buildToggleSetting(
                    icon: Icons.notifications_active_rounded,
                    title: l10n.aiNotifications,
                    value: settings.isAiNotificationsEnabled,
                    onChanged: (val) => ref.read(settingsProvider.notifier).toggleAiNotifications(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 3.5 VERİ & AI GRUBU
            _buildSectionHeader(l10n.dataAndAiSettings),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.getSecondary(context), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.dataRetention, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(l10n.dataRetentionDesc, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 11, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _retentionChip(l10n.oneMonth, 30, settings.dataRetentionDays),
                      _retentionChip(l10n.threeMonths, 90, settings.dataRetentionDays),
                      _retentionChip(l10n.sixMonths, 180, settings.dataRetentionDays),
                      _retentionChip(l10n.oneYear, 365, settings.dataRetentionDays),
                      _retentionChip(l10n.infinite, -1, settings.dataRetentionDays),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 4. VERİ YÖNETİMİ
            _buildSectionHeader(l10n.dataManagement),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                children: [
                  _buildActionSetting(
                    icon: Icons.cloud_upload_rounded,
                    title: l10n.driveBackup,
                    onTap: () => _showComingSoon(l10n.driveBackup, l10n),
                  ),
                  _buildDivider(),
                  _buildActionSetting(
                    icon: Icons.table_view_rounded,
                    title: l10n.exportExcel,
                    onTap: () => _showComingSoon(l10n.exportExcel, l10n),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXLarge),

            // 5. DESTEK & HAKKINDA GRUBU
            _buildSectionHeader(l10n.support),
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: AppSizes.radiusLarge,
              child: Column(
                children: [
                  _buildActionSetting(
                    icon: Icons.support_agent_rounded,
                    title: l10n.contact,
                    onTap: _launchEmail,
                  ),
                  _buildDivider(),
                  _buildNavSetting(
                    icon: Icons.info_outline_rounded,
                    title: l10n.about,
                    trailingText: "v1.0.0",
                    onTap: () => _showAboutDialog(l10n),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppLocalizations l10n) {
    final subscription = ref.watch(subscriptionServiceProvider);
    
    return NeuContainer(
      borderRadius: AppSizes.radiusLarge,
      child: Row(
        children: [
          NeuContainer(
            width: 60,
            height: 60,
            borderRadius: 30,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Yasir Dönmez",
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: () async {
                    if (subscription.isPro) {
                      // Geliştirici Kısa Yolu: Uzun basınca aboneliği sıfırla
                      await ref.read(subscriptionServiceProvider).setProStatus(false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abonelik sıfırlandı (Ücretsiz Sürüm)')),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: subscription.isPro 
                              ? AppColors.getPrimary(context).withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          subscription.isPro ? "PRO" : "FREE",
                          style: TextStyle(
                            color: subscription.isPro ? AppColors.getPrimary(context) : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subscription.isPro ? l10n.memberPremium : "Standart Kullanıcı",
                        style: TextStyle(
                          color: subscription.isPro 
                              ? AppColors.getPrimary(context) 
                              : AppColors.getTextSecondary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.getTextSecondary(context), size: 20),
            onPressed: () => _showComingSoon(l10n.editProfile, l10n),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature, AppLocalizations l10n) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(feature),
        content: Text("\n${l10n.comingSoon}"),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NeuContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.getPrimary(context), size: 48),
            const SizedBox(height: 16),
            Text(
              "FinCast",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context)),
            ),
            Text("v1.0.0", style: TextStyle(color: AppColors.getTextSecondary(context))),
            const SizedBox(height: 16),
            Text(
              l10n.aboutFinCast,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.getTextPrimary(context), height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppColors.getPrimary(context),
                child: Text(l10n.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'destek@fincast.app',
      query: 'subject=FinCast Destek Talebi',
    );
    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta uygulaması bulunamadı.')),
        );
      }
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'tr': return "Türkçe";
      case 'en': return "English";
      case 'de': return "Deutsch";
      case 'es': return "Español";
      case 'fr': return "Français";
      case 'pt': return "Português";
      case 'it': return "Italiano";
      case 'ja': return "日本語";
      default: return "Türkçe";
    }
  }

  String _getLanguageCode(String name) {
    switch (name) {
      case "Türkçe": return 'tr';
      case "English": return 'en';
      case "Deutsch": return 'de';
      case "Español": return 'es';
      case "Français": return 'fr';
      case "Português": return 'pt';
      case "Italiano": return 'it';
      case "日本語": return 'ja';
      default: return 'tr';
    }
  }

  String _getThemeModeName(int index, AppLocalizations l10n) {
    switch (index) {
      case 0: return l10n.themeSystem;
      case 1: return l10n.themeLight;
      case 2: return l10n.themeDark;
      default: return l10n.themeSystem;
    }
  }

  Widget _retentionChip(String label, int days, int currentDays) {
    final isActive = currentDays == days;
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setDataRetention(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.getSecondary(context).withValues(alpha: 0.15) : AppColors.getInnerSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.getSecondary(context) : AppColors.getDarkShadow(context).withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.getSecondary(context) : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.getSurface(context).withValues(alpha: 0.5),
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
    );
  }

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
          Icon(icon, color: AppColors.getPrimary(context), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 14,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.getPrimary(context),
            inactiveTrackColor: AppColors.getDarkShadow(context).withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

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
            Icon(icon, color: AppColors.getTextSecondary(context), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 14,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextSecondary(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

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
            Icon(icon, color: AppColors.getSecondary(context), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(String currentCode, AppLocalizations l10n) {
    final List<String> languages = [
      "Türkçe",
      "English",
      "Deutsch",
      "Español",
      "Français",
      "Português",
      "Italiano",
      "日本語",
    ];
    final currentName = _getLanguageName(currentCode);
    int tempSelectedIndex = languages.indexOf(currentName);
    if (tempSelectedIndex == -1) tempSelectedIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              SizedBox(
                height: 200,
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
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                          fontSize: 18,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.getPrimary(context),
                  onPressed: () async {
                    final selectedName = languages[tempSelectedIndex];
                    final selectedCode = _getLanguageCode(selectedName);
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 300));
                    ref.read(settingsProvider.notifier).setLanguage(selectedCode);
                  },
                  child: Text(
                    l10n.save,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(int currentIndex, AppLocalizations l10n) {
    final List<String> themeOptions = [
      l10n.themeSystem,
      l10n.themeLight,
      l10n.themeDark,
    ];
    final List<IconData> themeIcons = [
      Icons.brightness_auto_rounded,
      Icons.light_mode_rounded,
      Icons.dark_mode_rounded,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        int tempSelectedIndex = currentIndex;
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(builderContext),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.getTextSecondary(builderContext).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Text(
                    l10n.themeMode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(builderContext),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  ...List.generate(themeOptions.length, (index) {
                    final isSelected = tempSelectedIndex == index;
                    return GestureDetector(
                      onTap: () => setSheetState(() => tempSelectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.getPrimary(builderContext).withValues(alpha: 0.1)
                              : AppColors.getInnerSurface(builderContext),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.getPrimary(builderContext)
                                : AppColors.getDarkShadow(builderContext).withValues(alpha: 0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              themeIcons[index],
                              color: isSelected
                                  ? AppColors.getPrimary(builderContext)
                                  : AppColors.getTextSecondary(builderContext),
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                themeOptions[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.getTextPrimary(builderContext)
                                      : AppColors.getTextSecondary(builderContext),
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSelected ? 1.0 : 0.0,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.getPrimary(builderContext),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSizes.paddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.getPrimary(builderContext),
                      onPressed: () async {
                        Navigator.pop(builderContext);
                        await Future.delayed(const Duration(milliseconds: 300));
                        ref.read(settingsProvider.notifier).setThemeMode(tempSelectedIndex);
                      },
                      child: Text(
                        l10n.save,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}
