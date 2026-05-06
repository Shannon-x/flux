import 'package:flutter/material.dart';
import '../config/brand_config.dart';
import '../theme/app_colors.dart';

/// 暖调首页标题:衬线大字 + 胶囊副标。
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        children: [
          BrandConfig.buildName(fontSize: 44),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              BrandConfig.tagline,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
