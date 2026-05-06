import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/notice.dart';
import '../services/user_data_service.dart';
import '../services/v2ray_service.dart';
import '../theme/app_colors.dart';
import 'invite_screen.dart';
import '../widgets/fade_in_widget.dart';

class HomeDashboard extends StatefulWidget {
  final VoidCallback onConnectPressed;
  final Future<void> Function()? onReconnectRequested;
  final bool isConnected;
  final bool isConnecting;
  final String statusMessage;

  const HomeDashboard({
    super.key,
    required this.onConnectPressed,
    this.onReconnectRequested,
    required this.isConnected,
    this.isConnecting = false,
    this.statusMessage = '',
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    // 延迟检查公告
    Future.delayed(const Duration(seconds: 1), _checkNotice);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.isConnecting;
    final showPulse = true; // 开启呼吸动画

    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 800),
      offset: const Offset(0, 30),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _glowController]),
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_pulse.value);
              final glowT = _glowAnimation.value;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 30,
                    ), // Resized from 60 to fit smaller screens
                    // 连接按钮容器
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          // 主阴影
                          BoxShadow(
                            color: AppColors.accent.withValues(
                              alpha: isBusy ? 0.4 : (0.2 + 0.3 * t),
                            ),
                            blurRadius: isBusy ? 40 : (35 + 25 * t),
                            spreadRadius: isBusy ? 3 : (1 + 2 * t),
                            offset: const Offset(0, 15),
                          ),
                          // 光晕效果
                          if (showPulse)
                            BoxShadow(
                              color: AppColors.accent.withValues(
                                alpha: 0.15 * t,
                              ),
                              blurRadius: 60 + 40 * t,
                              spreadRadius: 8 * t,
                              offset: const Offset(0, 10),
                            ),
                          // 动态光晕
                          BoxShadow(
                            color: AppColors.accent.withValues(
                              alpha:
                                  0.1 *
                                  (0.5 + 0.5 * math.sin(glowT * math.pi * 2)),
                            ),
                            blurRadius: 50,
                            spreadRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 柔和静态光晕，不做缩放
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.12),
                                  AppColors.accent.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          // 主按钮
                          Transform.scale(
                            scale: 1.0,
                            child: _buildHeroButton(t, glowT),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 代理模式选择器 (移到连接按钮下方)
                    _buildProxyModeButton(context),

                    const SizedBox(height: 8),
                    // 状态文本 - 带打字机效果
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.statusMessage,
                        key: ValueKey(widget.statusMessage),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isBusy
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // 服务优势展示
                    const SizedBox(height: 12),
                    _buildFeatureRow(context),
                    const SizedBox(height: 12),
                    _buildInviteBanner(context),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProxyModeButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _showProxySettingsDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppColors.accent.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.proxySettings ?? 'Proxy Mode',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showProxySettingsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    var routingMode = V2rayService().routingMode;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowSoft,
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题
                          Text(
                            l10n?.routingMode ?? 'Routing Mode',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 规则模式
                          _buildModeCard(
                            icon: Icons.alt_route_rounded,
                            title: l10n?.ruleMode ?? 'Smart',
                            isSelected: routingMode == ProxyRoutingMode.rule,
                            onTap: () async {
                              if (routingMode == ProxyRoutingMode.rule) {
                                Navigator.pop(context);
                                return;
                              }
                              V2rayService().setRoutingMode(
                                ProxyRoutingMode.rule,
                              );
                              Navigator.pop(context);
                              await _requestReconnectIfNeeded();
                            },
                          ),
                          const SizedBox(height: 10),
                          // 全局模式
                          _buildModeCard(
                            icon: Icons.public_rounded,
                            title: l10n?.globalMode ?? 'Global',
                            isSelected: routingMode == ProxyRoutingMode.global,
                            onTap: () async {
                              if (routingMode == ProxyRoutingMode.global) {
                                Navigator.pop(context);
                                return;
                              }
                              V2rayService().setRoutingMode(
                                ProxyRoutingMode.global,
                              );
                              Navigator.pop(context);
                              await _requestReconnectIfNeeded();
                            },
                          ),
                          // TUN 模式（仅桌面端）
                          if (!Platform.isAndroid && !Platform.isIOS) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.router_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n?.tunMode ?? 'TUN Mode',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          l10n?.tunModeDesc ?? 'Experimental',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatefulBuilder(
                                    builder: (context, setTunState) {
                                      var tunEnabled =
                                          V2rayService().tunEnabled;
                                      return Switch(
                                        value: tunEnabled,
                                        activeColor: AppColors.accent,
                                        onChanged: (val) async {
                                          setTunState(() => tunEnabled = val);
                                          await V2rayService().setTunEnabled(val);
                                          await _requestReconnectIfNeeded();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestReconnectIfNeeded() async {
    if (!widget.isConnected) return;
    if (widget.onReconnectRequested != null) {
      await widget.onReconnectRequested!();
      return;
    }
    widget.onConnectPressed();
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onConnectPressed();
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withOpacity(0.35)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: AppColors.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context) {
    // 使用 LayoutBuilder 响应式布局：桌面端 4 列，移动端 2 列
    return LayoutBuilder(
      builder: (context, constraints) {
        // 简单判断：如果宽度大于 600 则视为桌面/宽屏
        final isDesktop = constraints.maxWidth > 600;
        final crossAxisCount = isDesktop ? 4 : 2;
        final childAspectRatio = isDesktop ? 2.5 : 2.4;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildFeatureTile(
              context,
              Icons.hub_rounded,
              AppLocalizations.of(context)?.ixpAccess ?? 'IXP Access',
              AppLocalizations.of(context)?.fastRouting ?? 'Fast Routing',
            ),
            _buildFeatureTile(
              context,
              Icons.speed_rounded,
              AppLocalizations.of(context)?.highSpeed ?? 'High Speed',
              AppLocalizations.of(context)?.instant4k ?? '4K Instant',
            ),
            _buildFeatureTile(
              context,
              Icons.security_rounded,
              AppLocalizations.of(context)?.noLogs ?? 'No Logs',
              AppLocalizations.of(context)?.privacyProtection ?? 'Privacy',
            ),
            _buildFeatureTile(
              context,
              Icons.lock_rounded,
              AppLocalizations.of(context)?.strongEncryption ?? 'Encryption',
              'AES-256',
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton(double t, double glowT) {
    final isBusy = widget.isConnecting;
    final l10n = AppLocalizations.of(context);
    final label = widget.isConnected
        ? (l10n?.disconnect ?? 'Disconnect')
        : (isBusy
              ? (l10n?.connecting ?? 'Connecting')
              : (l10n?.connect ?? 'Connect'));
    final icon = widget.isConnected ? Icons.power : Icons.power_settings_new;

    final fillColor = widget.isConnected
        ? AppColors.accent
        : (isBusy ? AppColors.accentWarm : AppColors.surface);
    final textColor =
        widget.isConnected || isBusy ? Colors.white : AppColors.textPrimary;
    final dotColor = widget.isConnected
        ? Colors.white
        : (isBusy ? AppColors.accentWarm : AppColors.success);

    return GestureDetector(
      onTap: isBusy ? null : widget.onConnectPressed,
      child: SizedBox(
        width: 240,
        height: 68,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: fillColor,
            border: Border.all(
              color: widget.isConnected || isBusy
                  ? Colors.transparent
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isConnected
                    ? AppColors.accent.withValues(alpha: 0.28)
                    : AppColors.shadowFaint,
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 18,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkNotice() async {
    try {
      final userDataService = UserDataService();
      final data = await userDataService.getNotices();

      if (data.isEmpty) return;

      // 取最新的一条公告
      final latestNotice = Notice.fromJson(data.first);

      final prefs = await SharedPreferences.getInstance();
      final lastReadId = prefs.getInt('last_read_notice_id') ?? 0;

      if (latestNotice.id > lastReadId) {
        if (!mounted) return;
        _showNoticeDialog(latestNotice);
      }
    } catch (e) {
      debugPrint('Fetching notice failed: $e');
    }
  }

  Widget _buildInviteBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InviteScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.inviteFriendsTitle ?? '邀请有礼',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context)?.inviteFriendsSubtitle ??
                        '邀请好友加入，获取丰厚奖励',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  void _showNoticeDialog(Notice notice) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox(); // 这里的 builder 不重要，主要看 transitionBuilder
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 使用弹簧曲线
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: LogNoticeDialog(notice: notice),
          ),
        );
      },
    );
  }
}

class LogNoticeDialog extends StatelessWidget {
  final Notice notice;

  const LogNoticeDialog({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头部图片或装饰
              if (notice.imgUrl != null && notice.imgUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Image.network(
                    notice.imgUrl!,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 20),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 32,
                      color: AppColors.accent,
                    ),
                  ),
                ),

              // 标题和内容
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Text(
                          notice.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.75,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('last_read_notice_id', notice.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.gotIt ?? '我知道了',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
