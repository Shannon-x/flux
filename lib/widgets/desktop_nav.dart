import 'package:flutter/material.dart';
import '../config/brand_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// 暖调桌面侧栏:浮白底 + 衬线 Logo + 胶囊形选中态。
class DesktopNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const DesktopNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo 区域 —— 衬线大字,品牌优先
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                BrandConfig.buildLogoBadge(iconSize: 22, padding: 8),
                const SizedBox(width: 12),
                BrandConfig.buildName(fontSize: 24),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          const SizedBox(height: 16),

          _buildNavItem(
            index: 0,
            icon: Icons.power_settings_new_rounded,
            label: AppLocalizations.of(context)?.connectionControl ?? '连接控制',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.card_giftcard_rounded,
            label: AppLocalizations.of(context)?.subscriptionPlans ?? '订阅方案',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.account_circle_outlined,
            label: AppLocalizations.of(context)?.accountInfo ?? '账户信息',
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'FLUX · v1.0.0',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
