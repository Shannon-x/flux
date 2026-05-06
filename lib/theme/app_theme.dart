import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Warm Minimalism 主题
/// 奶白底 + 珊瑚橙强调 + 衬线展示标题 + 无衬线正文。
/// 函数名保留 `dark()` 以兼容 main.dart 调用,实际为 light brightness 暖调主题。
class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.light(useMaterial3: true);

    // 衬线展示字体(Noto Serif SC) —— 标题、Display
    TextStyle serif(double size, FontWeight weight, {Color? color, double? height, double? letter}) {
      return GoogleFonts.notoSerifSc(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: letter,
      );
    }

    // 无衬线正文字体(Noto Sans SC)
    TextStyle sans(double size, FontWeight weight, {Color? color, double? height, double? letter}) {
      return GoogleFonts.notoSansSc(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: letter,
      );
    }

    final textTheme = GoogleFonts.notoSansScTextTheme(base.textTheme).copyWith(
      // Display:Hero 标题
      displayLarge: serif(40, FontWeight.w700, height: 1.2),
      displayMedium: serif(32, FontWeight.w700, height: 1.25),
      displaySmall: serif(26, FontWeight.w600, height: 1.3),

      // Headline:页面/卡片大标题
      headlineLarge: serif(24, FontWeight.w600, height: 1.3),
      headlineMedium: serif(20, FontWeight.w600, height: 1.35),
      headlineSmall: serif(18, FontWeight.w600, height: 1.4),

      // Title:子标题
      titleLarge: sans(18, FontWeight.w600, height: 1.4),
      titleMedium: sans(16, FontWeight.w600, height: 1.45),
      titleSmall: sans(14, FontWeight.w600, color: AppColors.textSecondary, height: 1.5),

      // Body:正文 —— 中文行高 1.75
      bodyLarge: sans(16, FontWeight.w400, height: 1.75),
      bodyMedium: sans(14, FontWeight.w400, color: AppColors.textSecondary, height: 1.7),
      bodySmall: sans(12, FontWeight.w400, color: AppColors.textSecondary, height: 1.6),

      // Label:按钮、tag
      labelLarge: sans(14, FontWeight.w600, letter: 0.2),
      labelMedium: sans(12, FontWeight.w500, color: AppColors.textSecondary, letter: 0.2),
      labelSmall: sans(11, FontWeight.w500, color: AppColors.textSecondary, letter: 0.4),
    );

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,

      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentSoft,
        onPrimaryContainer: AppColors.accent,
        secondary: AppColors.accentWarm,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceAlt,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.danger,
        onError: Colors.white,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
      ),

      textTheme: textTheme,
      primaryTextTheme: textTheme,

      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: serif(20, FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: sans(14, FontWeight.w400, color: AppColors.textSecondary),
        hintStyle: sans(14, FontWeight.w400, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // 胶囊形主按钮
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: sans(15, FontWeight.w600, color: Colors.white, letter: 0.2),
          elevation: 0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: sans(15, FontWeight.w600, color: Colors.white, letter: 0.2),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.border, width: 1),
          textStyle: sans(14, FontWeight.w600, letter: 0.2),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const StadiumBorder(),
          textStyle: sans(14, FontWeight.w600),
        ),
      ),

      // 胶囊形 Chip / 标签
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.accentSoft,
        secondarySelectedColor: AppColors.accentSoft,
        disabledColor: AppColors.surfaceAlt,
        labelStyle: sans(12, FontWeight.w500, color: AppColors.textPrimary),
        secondaryLabelStyle: sans(12, FontWeight.w600, color: AppColors.accent),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
        side: BorderSide.none,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        titleTextStyle: serif(20, FontWeight.w600),
        contentTextStyle: sans(14, FontWeight.w400, color: AppColors.textSecondary, height: 1.7),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: sans(14, FontWeight.w500, color: AppColors.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.border),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        circularTrackColor: AppColors.surfaceAlt,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: sans(12, FontWeight.w400, color: AppColors.background),
      ),
    );
  }
}
