import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 暖调极简背景:奶白底 + 极淡珊瑚光晕,呼吸感而非科技感。
class AnimatedMeshBackground extends StatefulWidget {
  final Widget child;
  const AnimatedMeshBackground({super.key, required this.child});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _MeshPainter(animationValue: _controller.value),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double animationValue;
  _MeshPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 极淡的暖光晕,只用来打破奶白底的均匀,不喧宾夺主
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    void drawBlob(Offset center, double radius, Color color, double phase) {
      final offset = Offset(
        math.sin(animationValue * 2 * math.pi + phase) * 30,
        math.cos(animationValue * 2 * math.pi + phase) * 24,
      );
      paint.color = color;
      canvas.drawCircle(center + offset, radius, paint);
    }

    // 右上:珊瑚浅
    drawBlob(
      Offset(size.width * 0.85, size.height * 0.18),
      220,
      const Color(0xFFE9C4B8).withValues(alpha: 0.45),
      0,
    );
    // 左下:暖米色
    drawBlob(
      Offset(size.width * 0.15, size.height * 0.85),
      260,
      const Color(0xFFE6DFD3).withValues(alpha: 0.55),
      math.pi,
    );
    // 中央:更淡的奶咖
    drawBlob(
      Offset(size.width * 0.5, size.height * 0.55),
      300,
      const Color(0xFFEDE6DA).withValues(alpha: 0.35),
      math.pi / 2,
    );
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
