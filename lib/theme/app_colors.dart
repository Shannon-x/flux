import 'package:flutter/material.dart';

/// Warm Minimalism 调色板
/// 奶白底 + 珊瑚橙强调 + 深棕灰文字。
/// 字段名沿用旧版以保持二进制兼容,值改为暖调极简语义。
class AppColors {
  // 表面层:从最远到最近
  static const Color background = Color(0xFFF5F3EF);   // 奶白底
  static const Color surface = Color(0xFFFAF8F4);      // 浮白卡片
  static const Color surfaceAlt = Color(0xFFEDEAE4);   // 凹陷表面 / 输入框

  // 强调色:珊瑚橙(赤土)
  static const Color accent = Color(0xFFC94F2E);       // 主强调:CTA、链接、icon 高光
  static const Color accentSoft = Color(0xFFF0D9D1);   // 浅珊瑚:tag 背景、选中态
  static const Color accentWarm = Color(0xFFD97757);   // 中间档:hover/次级高亮

  // 文字层级
  static const Color textPrimary = Color(0xFF2A2520);  // 深棕灰主文字
  static const Color textSecondary = Color(0xFF7A7470); // 次文字 / 元数据

  // 分隔与轮廓
  static const Color border = Color(0xFFDBD7D0);

  // 语义色(与暖色调和谐的版本)
  static const Color danger = Color(0xFFC0392B);
  static const Color warning = Color(0xFFD9853B);
  static const Color success = Color(0xFF6F8F6A);

  /// 极淡的暖色阴影 —— 浅色主题用棕调而不是黑调,否则界面发脏
  static Color get shadowSoft => const Color(0xFF2A2520).withValues(alpha: 0.06);
  static Color get shadowFaint => const Color(0xFF2A2520).withValues(alpha: 0.03);

  /// 仅在极少数装饰场景使用 —— 暖白卡片的细腻渐变
  static const LinearGradient heroGlow = LinearGradient(
    colors: [
      Color(0xFFFAF8F4),
      Color(0xFFF0EDE6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlow = LinearGradient(
    colors: [
      Color(0xFFFAF8F4),
      Color(0xFFF3F0EA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
