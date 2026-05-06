import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// 品牌配置 — 改这一处即可全局替换应用名称、Logo 与字体。
///
/// 三种 Logo 形态自由切换:
///   1. Material 图标(默认): 设置 [logoIcon],保持 [logoAsset] 为 null。
///   2. PNG / JPG / WebP: 把图片放到 assets/branding/ 下,在
///      pubspec.yaml 的 flutter.assets 加上该路径,然后把
///      [logoAsset] 设为 'assets/branding/your_logo.png'。
///   3. 单色矢量: 用 Material 图标即可,或自行扩展支持 SVG。
class BrandConfig {
  BrandConfig._();

  /// 应用显示名(出现在 splash / 登录页 / 顶栏 / 关于弹窗 / 窗口标题)
  static const String appName = 'Flux';

  /// 应用副标语(出现在 splash 与 home header 的胶囊里)
  static const String tagline = '安全 · 克制 · 流畅';

  /// Logo 图片资源路径。设为 null 则使用 [logoIcon]。
  /// 例: 'assets/branding/logo.png'
  static const String? logoAsset = null;

  /// 默认 Material 图标(在 logoAsset 为 null 时使用)
  static const IconData logoIcon = Icons.blur_on;

  /// 应用名字体。默认使用衬线字体(Noto Serif SC)体现暖调极简感。
  /// 传 null 则使用主题默认字体。
  static TextStyle nameStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0.5,
    double height = 1.1,
  }) {
    return GoogleFonts.notoSerifSc(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// 构建 Logo 部件 — 优先用 [logoAsset],否则降级到 [logoIcon]。
  static Widget buildLogo({double size = 48, Color? color}) {
    if (logoAsset != null && logoAsset!.isNotEmpty) {
      return Image.asset(
        logoAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(logoIcon, size: size, color: color ?? AppColors.accent),
      );
    }
    return Icon(logoIcon, size: size, color: color ?? AppColors.accent);
  }

  /// 构建带圆角软背景的小型 Logo 块(用于桌面侧边栏顶部)
  static Widget buildLogoBadge({double iconSize = 22, double padding = 8}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: buildLogo(size: iconSize, color: AppColors.accent),
    );
  }

  /// 构建应用名文字
  static Widget buildName({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0.5,
  }) {
    return Text(
      appName,
      style: nameStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
