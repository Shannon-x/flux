import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 暖调极简卡片:轻微悬停反馈,无呼吸光晕。
/// 浅色主题下"呼吸光"会显脏,改成静态的浮白卡 + 暖色描边。
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final bool enableHover;
  final bool enableBreathing; // 保留参数,语义改为"是否高亮描边"
  final Duration animationDuration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.enableHover = true,
    this.enableBreathing = false,
    this.animationDuration = const Duration(milliseconds: 220),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    if (!widget.enableHover) return;
    if (_isHovered == v) return;
    setState(() => _isHovered = v);
    v ? _hoverController.forward() : _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.enableBreathing || _isHovered;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _setHover(true) : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _setHover(false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.onTap != null ? () => _setHover(false) : null,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: highlight ? AppColors.accent : AppColors.border,
                    width: highlight ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? AppColors.shadowSoft
                          : AppColors.shadowFaint,
                      blurRadius: _isHovered ? 28 : 18,
                      offset: Offset(0, _isHovered ? 12 : 6),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
