import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'flux_loader.dart';

enum ConnectionButtonStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// 暖调连接按钮:大圆形 + 极淡光晕(连接态珊瑚橙),与品牌色一致。
class ConnectionButton extends StatelessWidget {
  final ConnectionButtonStatus status;
  final VoidCallback? onTap;
  final bool isLoading;
  final Animation<double> pulseAnimation;

  const ConnectionButton({
    super.key,
    required this.status,
    required this.onTap,
    required this.pulseAnimation,
    this.isLoading = false,
  });

  Color get _accent {
    switch (status) {
      case ConnectionButtonStatus.connected:
        return AppColors.accent;
      case ConnectionButtonStatus.connecting:
        return AppColors.accentWarm;
      case ConnectionButtonStatus.error:
        return AppColors.danger;
      case ConnectionButtonStatus.disconnected:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case ConnectionButtonStatus.connected:
        return l10n?.connected ?? 'Connected';
      case ConnectionButtonStatus.connecting:
        return l10n?.connecting ?? 'Connecting...';
      case ConnectionButtonStatus.error:
        return l10n?.error ?? 'Error';
      case ConnectionButtonStatus.disconnected:
        return l10n?.disconnected ?? 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final scale = status == ConnectionButtonStatus.connected
                  ? 1.0 + (pulseAnimation.value * 0.04)
                  : 1.0;

              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈极淡光晕(仅连接态)
                    if (status == ConnectionButtonStatus.connected)
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.18),
                              accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),

                    // 主按钮:浮白圆 + 暖色描边
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status == ConnectionButtonStatus.connected
                            ? AppColors.accentSoft
                            : AppColors.surface,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: status == ConnectionButtonStatus.connected
                                ? accent.withValues(alpha: 0.18)
                                : AppColors.shadowFaint,
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isLoading
                            ? FluxLoader(size: 36, color: accent)
                            : Icon(
                                status == ConnectionButtonStatus.connected
                                    ? Icons.power_rounded
                                    : Icons.power_settings_new_rounded,
                                size: 56,
                                color: accent,
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // 胶囊形状态标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: status == ConnectionButtonStatus.connected
                ? AppColors.accentSoft
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Builder(
            builder: (context) => Text(
              _getStatusText(context),
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.4,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
