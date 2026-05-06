import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'flux_loader.dart';

/// 暖调状态消息卡片:浮白胶囊 + 珊瑚色图标。
class StatusMessageCard extends StatelessWidget {
  final String message;
  final bool isLoading;
  final IconData? icon;
  final Color? iconColor;

  const StatusMessageCard({
    super.key,
    required this.message,
    this.isLoading = false,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final accent = iconColor ?? AppColors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowFaint,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: FluxLoader(size: 20, color: accent),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 16,
                color: accent,
              ),
            if (icon != null || isLoading) const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
