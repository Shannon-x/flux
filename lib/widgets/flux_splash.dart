import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/brand_config.dart';
import '../theme/app_colors.dart';

/// 暖调启动动画:奶白底 + 极淡珊瑚光晕 + 衬线 Flux 文字。
class FluxSplash extends StatefulWidget {
  final VoidCallback? onReady;

  const FluxSplash({super.key, this.onReady});

  @override
  State<FluxSplash> createState() => _FluxSplashState();
}

class _FluxSplashState extends State<FluxSplash> with TickerProviderStateMixin {
  late final AnimationController _fluidController;
  late final AnimationController _logoController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
  }

  @override
  void dispose() {
    _fluidController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _fluidController,
              builder: (context, child) {
                final t = _fluidController.value;
                final time = t * math.pi * 2;

                return Stack(
                  children: [
                    _buildGlow(
                      size: 320,
                      opacity: 0.55 + 0.15 * math.sin(time),
                      offsetX: math.sin(time * 0.7) * 60,
                      offsetY: math.cos(time * 0.5) * 40 - 80,
                      scale: 1.0 + 0.1 * math.sin(time * 0.8),
                      color: const Color(0xFFE9C4B8),
                    ),
                    _buildGlow(
                      size: 280,
                      opacity: 0.45 + 0.15 * math.cos(time + 1.0),
                      offsetX: math.cos(time * 0.6 + 2.0) * 70,
                      offsetY: math.sin(time * 0.4 + 1.0) * 50 + 90,
                      scale: 1.0 + 0.12 * math.cos(time * 0.9 + 0.5),
                      color: const Color(0xFFE6DFD3),
                    ),
                    _buildGlow(
                      size: 220,
                      opacity: 0.35 + 0.1 * math.sin(time * 1.5 + 2.0),
                      offsetX: math.sin(time * 0.9 + math.pi) * 50,
                      offsetY: math.cos(time * 0.7 + 1.57) * 40,
                      scale: 1.0 + 0.18 * math.sin(time * 1.1 + 1.0),
                      color: const Color(0xFFEDE6DA),
                    ),
                  ],
                );
              },
            ),

            // Flux 文字
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BrandConfig.buildLogo(size: 96),
                          const SizedBox(height: 24),
                          BrandConfig.buildName(
                            fontSize: 64,
                            letterSpacing: 2,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'WARM · MINIMAL',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow({
    required double size,
    required double opacity,
    required double offsetX,
    required double offsetY,
    required double scale,
    required Color color,
  }) {
    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: opacity * 0.6),
                    color.withValues(alpha: opacity * 0.25),
                    color.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
