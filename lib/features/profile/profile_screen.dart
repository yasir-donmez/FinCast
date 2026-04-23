import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/subscription_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../shared/widgets/fluid_sheet.dart';
import '../../shared/widgets/fluid_button.dart';
import '../../shared/widgets/fluid_dialog.dart';
import '../../core/providers/settings_provider.dart';
import '../dashboard/dashboard_providers.dart';
import '../../shared/widgets/theme_reveal_button.dart';
import '../../shared/widgets/fluid_switch.dart';
import '../../shared/widgets/fluid_animated_icon.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  // Keys to track section title positions
  final _preferencesKey = GlobalKey();
  final _dataAiKey = GlobalKey();
  final _managementKey = GlobalKey();
  final _supportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset = _scrollController.offset;
          });
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final activeColor = ref.watch(rotaryColorProvider);
    final subscription = ref.watch(subscriptionServiceProvider);

    return Stack(
      children: [
        // 1. PARALLAX BACKGROUND
        Positioned(
          top: 400 - (_scrollOffset * 0.3),
          left: -150 - (_scrollOffset * 0.1),
          child: _LiquidBlob(
            color: AppColors.getSecondary(context).withValues(alpha: 0.08),
            size: 500,
          ),
        ),

        SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 2. CREATIVE HEADER
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProfileHeaderDelegate(
                  expandedHeight: 180.0,
                  collapsedHeight: 80.0,
                  l10n: l10n,
                  activeColor: activeColor,
                  isPro: subscription.isPro,
                  onTogglePro: () async {
                    final currentPro = ref
                        .read(subscriptionServiceProvider)
                        .isPro;
                    await ref
                        .read(subscriptionServiceProvider)
                        .setProStatus(!currentPro);
                  },
                ),
              ),

              // 3. SECTIONS
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLarge,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 10),

                    // Membership Plan Card
                    _buildMembershipCard(
                      l10n: l10n,
                      isPro: subscription.isPro,
                      activeColor: activeColor,
                      onTap: () async {
                        final currentPro = ref
                            .read(subscriptionServiceProvider)
                            .isPro;
                        await ref
                            .read(subscriptionServiceProvider)
                            .setProStatus(!currentPro);
                      },
                    ),

                    const SizedBox(height: 30),
                    _buildPremiumSectionTitle(
                      l10n.preferences,
                      activeColor,
                      key: _preferencesKey,
                    ),
                    const SizedBox(height: 12),

                    ThemeRevealButton(activeColor: activeColor),

                    _buildFloatingSetting(
                      icon: Icons.language_rounded,
                      title: l10n.language,
                      trailing: _getLanguageName(settings.languageCode),
                      onTap: () =>
                          _showLanguagePicker(settings.languageCode, l10n),
                      activeColor: activeColor,
                    ),
                    _buildFloatingToggle(
                      icon: Icons.notifications_active_rounded,
                      title: l10n.aiNotifications,
                      value: settings.isAiNotificationsEnabled,
                      onChanged: (val) => ref
                          .read(settingsProvider.notifier)
                          .toggleAiNotifications(val),
                      activeColor: activeColor,
                      activeIcon: Icons.notifications_active_rounded,
                      inactiveIcon: Icons.notifications_off_rounded,
                    ),

                    const SizedBox(height: 40),

                    _buildPremiumSectionTitle(
                      l10n.dataAndAiSettings,
                      activeColor,
                      key: _dataAiKey,
                    ),
                    const SizedBox(height: 16),
                    _buildDataRetentionCloud(
                      l10n,
                      settings.dataRetentionDays,
                      activeColor,
                    ),

                    const SizedBox(height: 40),

                    _buildPremiumSectionTitle(
                      l10n.dataManagement,
                      AppColors.getSecondary(context),
                      key: _managementKey,
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingSetting(
                      icon: Icons.cloud_upload_rounded,
                      title: l10n.driveBackup,
                      onTap: () => _showComingSoon(l10n.driveBackup, l10n),
                      activeColor: AppColors.getSecondary(context),
                      isAction: true,
                    ),
                    _buildFloatingSetting(
                      icon: Icons.table_view_rounded,
                      title: l10n.exportExcel,
                      onTap: () => _showComingSoon(l10n.exportExcel, l10n),
                      activeColor: AppColors.getSecondary(context),
                      isAction: true,
                    ),

                    const SizedBox(height: 40),

                    _buildPremiumSectionTitle(
                      l10n.support,
                      AppColors.getPrimary(context),
                      key: _supportKey,
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingSetting(
                      icon: Icons.support_agent_rounded,
                      title: l10n.contact,
                      onTap: _launchEmail,
                      activeColor: AppColors.getPrimary(context),
                      isAction: true,
                    ),
                    _buildFloatingSetting(
                      icon: Icons.info_outline_rounded,
                      title: l10n.about,
                      trailing: "v1.0.0",
                      onTap: () => _showAboutDialog(l10n),
                      activeColor: AppColors.getPrimary(context),
                    ),

                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard({
    required AppLocalizations l10n,
    required bool isPro,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: activeColor.withValues(alpha: isPro ? 0.3 : 0.05),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPro
                          ? Icons.workspace_premium_rounded
                          : Icons.person_outline_rounded,
                      color: activeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro ? "FinCast PRO" : "Free Plan",
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.membershipPlan,
                          style: TextStyle(
                            color: AppColors.getTextSecondary(
                              context,
                            ).withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro)
                    Text(
                      l10n.upgrade,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Icon(Icons.verified_rounded, color: activeColor, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSectionTitle(
    String title,
    Color activeColor, {
    Key? key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: activeColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 20,
            height: 2,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSetting({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
    required Color activeColor,
    bool isAction = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(
                  context,
                ).withValues(alpha: isAction ? 0.08 : 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16), // Squirclish
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: FluidAnimatedIcon(
                      isActive: true, // Sabit ikonlar için giriş animasyonu tetiklesin
                      activeIcon: icon,
                      inactiveIcon: icon,
                      color: activeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (trailing == null && !isAction)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.getTextSecondary(
                        context,
                      ).withValues(alpha: 0.3),
                    ),
                  if (isAction)
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: activeColor.withValues(alpha: 0.5),
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    IconData? activeIcon,
    IconData? inactiveIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16), // Squirclish
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: activeIcon != null && inactiveIcon != null
                      ? FluidAnimatedIcon(
                          isActive: value,
                          activeIcon: activeIcon,
                          inactiveIcon: inactiveIcon,
                          color: activeColor,
                          size: 22,
                        )
                      : Icon(icon, color: activeColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FluidSwitch(
                  value: value,
                  activeColor: activeColor,
                  onChanged: onChanged,
                  activeIcon: activeIcon,
                  inactiveIcon: inactiveIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRetentionCloud(
    AppLocalizations l10n,
    int currentDays,
    Color activeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            l10n.dataRetentionDesc,
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _retentionBubble(l10n.oneMonth, 30, currentDays, activeColor),
            _retentionBubble(l10n.threeMonths, 90, currentDays, activeColor),
            _retentionBubble(l10n.sixMonths, 180, currentDays, activeColor),
            _retentionBubble(l10n.oneYear, 365, currentDays, activeColor),
            _retentionBubble(l10n.infinite, -1, currentDays, activeColor),
          ],
        ),
      ],
    );
  }

  Widget _retentionBubble(
    String label,
    int days,
    int currentDays,
    Color activeColor,
  ) {
    final isActive = currentDays == days;
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setDataRetention(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor
              : AppColors.getSurface(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
          border: Border.all(
            color: isActive
                ? activeColor
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.black
                : AppColors.getTextSecondary(context),
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(AppLocalizations l10n) {
    final activeColor = ref.read(rotaryColorProvider);
    FluidSheet.show(
      context: context,
      title: 'FinCast',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Icon(Icons.auto_awesome_rounded, color: activeColor, size: 72),
          const SizedBox(height: 24),
          Text(
            l10n.aboutFinCast,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              height: 1.6,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "v1.0.0 • Made with ❤️",
            style: TextStyle(
              color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showComingSoon(String feature, AppLocalizations l10n) {
    showFluidDialog(
      context: context,
      title: Text(feature),
      content: Text("\n${l10n.comingSoon}"),
      actions: [
        TextButton(
          child: Text(l10n.ok),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'destek@fincast.app',
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
      case 'tr':
        return "Türkçe";
      case 'en':
        return "English";
      case 'de':
        return "Deutsch";
      case 'es':
        return "Español";
      case 'fr':
        return "Français";
      case 'pt':
        return "Português";
      case 'it':
        return "Italiano";
      case 'ja':
        return "日本語";
      default:
        return "Türkçe";
    }
  }

  String _getLanguageCode(String name) {
    switch (name) {
      case 'Türkçe':
        return 'tr';
      case 'English':
        return 'en';
      case 'Deutsch':
        return 'de';
      case 'Español':
        return 'es';
      case 'Français':
        return 'fr';
      case 'Português':
        return 'pt';
      case 'Italiano':
        return 'it';
      case '日本語':
        return 'ja';
      default:
        return 'tr';
    }
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
    int tempIndex = languages.indexOf(_getLanguageName(currentCode));
    final activeColor = ref.read(rotaryColorProvider);

    FluidSheet.show(
      context: context,
      title: l10n.selectLanguage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: CupertinoPicker(
              itemExtent: 45,
              onSelectedItemChanged: (i) => tempIndex = i,
              scrollController: FixedExtentScrollController(
                initialItem: tempIndex,
              ),
              children: languages
                  .map(
                    (l) => Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          FluidButton(
            onTap: () {
              ref
                  .read(settingsProvider.notifier)
                  .setLanguage(_getLanguageCode(languages[tempIndex]));
              Navigator.pop(context);
            },
            width: double.infinity,
            color: activeColor,
            child: Text(
              l10n.save,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}

// --- CREATIVE ETCHED LIQUID TEXT ---

class _EtchedLiquidText extends StatefulWidget {
  final double progress;
  final Color activeColor;
  final String text;
  final double fontSize;

  const _EtchedLiquidText({
    required this.progress,
    required this.activeColor,
    required this.text,
    this.fontSize = 44,
  });

  @override
  State<_EtchedLiquidText> createState() => _EtchedLiquidTextState();
}

class _EtchedLiquidTextState extends State<_EtchedLiquidText>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.fontSize * 8, widget.fontSize * 2.2),
          painter: _EtchedLiquidPainter(
            progress: widget.progress,
            activeColor: widget.activeColor,
            text: widget.text,
            fontSize: widget.fontSize,
            waveValue: _waveController.value,
            context: context,
          ),
        );
      },
    );
  }
}

class _EtchedLiquidPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final String text;
  final double fontSize;
  final double waveValue;
  final BuildContext context;

  _EtchedLiquidPainter({
    required this.progress,
    required this.activeColor,
    required this.text,
    required this.fontSize,
    required this.waveValue,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      color: AppColors.getTextPrimary(context),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final textRect = Rect.fromCenter(
      center: center,
      width: textPainter.width,
      height: textPainter.height,
    );

    canvas.saveLayer(textRect.inflate(50), Paint());

    // 1. RIM HIGHLIGHT
    final bezelTP = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: AppColors.getLightShadow(context).withValues(alpha: 0.4),
          shadows: [
            Shadow(
              color: AppColors.getLightShadow(context).withValues(alpha: 0.2),
              offset: const Offset(0.5, 0.7),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bezelTP.paint(canvas, textRect.topLeft + const Offset(0.5, 0.7));

    // 2. INNER WALL SHADOW
    final darkTP = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(color: Colors.black.withValues(alpha: 0.7)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    darkTP.paint(canvas, textRect.topLeft + const Offset(-0.8, -1.0));

    // 3. ETCHED BASE
    final baseTP = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: AppColors.getInnerSurface(context).withValues(alpha: 1.0),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0.2, 0.2),
              blurRadius: 1.5,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    baseTP.paint(canvas, textRect.topLeft);

    if (progress > 0) {
      final double liquidLevel =
          textRect.bottom + 20 - (textRect.height * progress * 1.5);
      final Path wavePath = Path();
      wavePath.moveTo(textRect.left - 60, liquidLevel);
      for (double x = textRect.left - 60; x <= textRect.right + 60; x++) {
        final double wave1 =
            math.sin((x / 18) + (waveValue * 2 * math.pi)) * (fontSize * 0.15);
        final double wave2 =
            math.sin((x / 10) - (waveValue * 2 * math.pi)) * (fontSize * 0.05);
        wavePath.lineTo(x, liquidLevel + wave1 + wave2);
      }

      final Paint surfacePaint = Paint()
        ..color = activeColor.withValues(alpha: (0.9 * progress).clamp(0, 0.9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * 0.08
        ..blendMode = BlendMode.srcATop;
      canvas.drawPath(wavePath, surfacePaint);

      final Path submergedPath = Path.from(wavePath);
      submergedPath.lineTo(textRect.right + 60, textRect.bottom + 100);
      submergedPath.lineTo(textRect.left - 60, textRect.bottom + 100);
      submergedPath.close();

      final Paint eraserPaint = Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.black;
      canvas.drawPath(submergedPath, eraserPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EtchedLiquidPainter old) =>
      old.progress != progress ||
      old.waveValue != waveValue ||
      old.activeColor != activeColor;
}

// --- PREMIUM HEADER DELEGATE ---

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final AppLocalizations l10n;
  final Color activeColor;
  final bool isPro;
  final VoidCallback onTogglePro;

  _ProfileHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.l10n,
    required this.activeColor,
    required this.isPro,
    required this.onTogglePro,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double rawProgress = shrinkOffset / (maxExtent - minExtent);
    final double progress = rawProgress.clamp(0.0, 1.0);

    return ClipRect(
      child: Container(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            // 1. THE ORIGINAL NAME WIDGET (DO NOT TOUCH LOGIC)
            Positioned(
              top: 64 - (shrinkOffset * 0.4),
              child: Opacity(
                opacity: (1.0 - (progress > 0.8 ? (progress - 0.8) * 5 : 0.0))
                    .clamp(0.0, 1.0),
                child: _EtchedLiquidText(
                  progress: progress,
                  activeColor: activeColor,
                  text: "Yasir Dönmez",
                  fontSize: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;
  @override
  double get minExtent => collapsedHeight;
  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return isPro != oldDelegate.isPro || activeColor != oldDelegate.activeColor;
  }
}

class _LiquidBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _LiquidBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
