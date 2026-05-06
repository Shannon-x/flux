import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/server_node.dart';
import '../theme/app_colors.dart';
import '../utils/node_utils.dart';
import '../services/v2ray_service.dart';
import 'connection_button.dart' show ConnectionButtonStatus;

/// 暖调主页连接视图:奶白底 + 珊瑚胶囊按钮 + 浮白节点条。
class HomeConnectionView extends StatefulWidget {
  final ConnectionButtonStatus status;
  final VoidCallback? onConnectTap;
  final bool isLoading;
  final ServerNode? selectedNode;

  const HomeConnectionView({
    super.key,
    required this.status,
    required this.onConnectTap,
    this.isLoading = false,
    this.selectedNode,
  });

  @override
  State<HomeConnectionView> createState() => _HomeConnectionViewState();
}

class _HomeConnectionViewState extends State<HomeConnectionView>
    with TickerProviderStateMixin {
  double _buttonScale = 1.0;
  late AnimationController _loopController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.status == ConnectionButtonStatus.connecting || widget.isLoading) {
      _loopController.repeat();
    }
    V2rayService().loadTunState();
  }

  @override
  void didUpdateWidget(HomeConnectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasBusy = oldWidget.isLoading ||
        oldWidget.status == ConnectionButtonStatus.connecting;
    final isBusy =
        widget.isLoading || widget.status == ConnectionButtonStatus.connecting;
    if (wasBusy != isBusy) {
      if (isBusy) {
        _loopController.repeat();
      } else {
        _loopController.stop();
        _loopController.reset();
      }
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) =>
      setState(() => _buttonScale = 0.96);
  void _handleTapUp(TapUpDetails details) =>
      setState(() => _buttonScale = 1.0);
  void _handleTapCancel() => setState(() => _buttonScale = 1.0);

  @override
  Widget build(BuildContext context) {
    final isBusy =
        widget.isLoading || widget.status == ConnectionButtonStatus.connecting;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final style = widget.isLoading &&
            widget.status == ConnectionButtonStatus.disconnected
        ? _StatusStyle(
            accent: AppColors.textSecondary,
            action: AppLocalizations.of(context)?.syncing ?? 'Syncing',
          )
        : _statusStyle(context, widget.status);
    if (reduceMotion && _loopController.isAnimating) {
      _loopController.stop();
    } else if (!reduceMotion &&
        (widget.isLoading ||
            widget.status == ConnectionButtonStatus.connecting) &&
        !_loopController.isAnimating) {
      _loopController.repeat();
    }
    final buttonDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    final textDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    final isConnected = widget.status == ConnectionButtonStatus.connected;
    final isError = widget.status == ConnectionButtonStatus.error;

    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth =
            (constraints.maxWidth * 0.68).clamp(220.0, 320.0);
        final indicatorTarget =
            widget.status == ConnectionButtonStatus.connecting ? 1.0 : 0.0;

        // 主按钮的填充色:连接态珊瑚 / 其他态浮白
        final buttonFill = isConnected
            ? AppColors.accent
            : (isError ? AppColors.danger : AppColors.surface);
        final buttonTextColor = isConnected || isError
            ? Colors.white
            : AppColors.textPrimary;
        final buttonBorderColor = isConnected || isError
            ? Colors.transparent
            : AppColors.border;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: _getStatusText(context, widget.status),
              button: true,
              enabled: true,
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onTap: widget.onConnectTap,
                child: AnimatedScale(
                  scale: _buttonScale,
                  duration: buttonDuration,
                  curve: Curves.easeOutCubic,
                  child: RepaintBoundary(
                    child: AnimatedContainer(
                      duration: buttonDuration,
                      curve: Curves.easeOutCubic,
                      width: buttonWidth,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: buttonFill,
                        border: Border.all(color: buttonBorderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: isConnected
                                ? AppColors.accent.withValues(alpha: 0.22)
                                : AppColors.shadowFaint,
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isBusy && !reduceMotion)
                            _buildBusyEffects(style, buttonWidth),
                          Positioned(
                            bottom: 12,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: indicatorTarget),
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Container(
                                  width: (buttonWidth - 80) * value,
                                  height: 1.2,
                                  decoration: BoxDecoration(
                                    color: style.accent.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: textDuration,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                                child: _buildIndicator(
                                  style,
                                  isBusy,
                                  reduceMotion,
                                  buttonTextColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              AnimatedSwitcher(
                                duration: textDuration,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  style.action,
                                  key: ValueKey(style.action),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: buttonTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // 节点信息胶囊
            SizedBox(
              height: 52,
              child: AnimatedOpacity(
                duration: textDuration,
                opacity: widget.selectedNode != null ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: widget.selectedNode == null,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.selectedNode != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.public_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  NodeUtils.extractCountry(
                                    widget.selectedNode!.name,
                                    context: context,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (widget.selectedNode!.latency != null) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${widget.selectedNode!.latency}ms',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _latencyColor(
                                            widget.selectedNode!.latency!),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildProxyModeSelector(context),
          ],
        );
      },
    );
  }

  Widget _buildProxyModeSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProxySettingsDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.proxySettings ?? 'Proxy Mode',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProxySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        var routingMode = V2rayService().routingMode;
        bool tunEnabled = V2rayService().tunEnabled;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                AppLocalizations.of(context)?.proxySettings ?? 'Proxy Settings',
                style: GoogleFonts.notoSerifSc(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.routingMode ?? 'Routing Mode',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRadioOption(
                    title: AppLocalizations.of(context)?.ruleMode ?? 'Rule Mode',
                    value: ProxyRoutingMode.rule,
                    groupValue: routingMode,
                    onChanged: (val) {
                      setState(() => routingMode = val);
                      V2rayService().setRoutingMode(val);
                    },
                  ),
                  _buildRadioOption(
                    title: AppLocalizations.of(context)?.globalMode ??
                        'Global Mode',
                    value: ProxyRoutingMode.global,
                    groupValue: routingMode,
                    onChanged: (val) {
                      setState(() => routingMode = val);
                      V2rayService().setRoutingMode(val);
                    },
                  ),
                  if (!Platform.isIOS && !Platform.isAndroid) ...[
                    const Divider(color: AppColors.border, height: 24),
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)?.tunMode ?? 'Tun Mode',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        '全局流量代理',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      value: tunEnabled,
                      activeColor: AppColors.accent,
                      activeTrackColor:
                          AppColors.accent.withValues(alpha: 0.4),
                      inactiveThumbColor: AppColors.textSecondary,
                      inactiveTrackColor: AppColors.border,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() => tunEnabled = val);
                        V2rayService().setTunEnabled(val);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)?.close ?? 'Done',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption({
    required String title,
    required ProxyRoutingMode value,
    required ProxyRoutingMode groupValue,
    required ValueChanged<ProxyRoutingMode> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? AppColors.accent : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(BuildContext context, ConnectionButtonStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case ConnectionButtonStatus.connected:
        return l10n?.connected ?? 'Connected';
      case ConnectionButtonStatus.connecting:
        return l10n?.connecting ?? 'Connecting...';
      case ConnectionButtonStatus.error:
        return l10n?.connectionFailed ?? 'Connection Failed';
      default:
        return l10n?.clickToConnect ?? 'Click to Connect';
    }
  }

  _StatusStyle _statusStyle(BuildContext context, ConnectionButtonStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case ConnectionButtonStatus.connected:
        return _StatusStyle(
          accent: Colors.white,
          action: l10n?.disconnect ?? 'Disconnect',
        );
      case ConnectionButtonStatus.connecting:
        return _StatusStyle(
          accent: AppColors.accentWarm,
          action: l10n?.connecting ?? 'Connecting',
        );
      case ConnectionButtonStatus.error:
        return _StatusStyle(
          accent: Colors.white,
          action: l10n?.retry ?? 'Retry',
        );
      default:
        return _StatusStyle(
          accent: AppColors.accent,
          action: l10n?.connect ?? 'Connect',
        );
    }
  }

  Color _latencyColor(int latency) {
    if (latency < 100) return AppColors.success;
    if (latency < 300) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _buildIndicator(
    _StatusStyle style,
    bool isBusy,
    bool reduceMotion,
    Color textColor,
  ) {
    final showCheck = widget.status == ConnectionButtonStatus.connected;
    final base = AnimatedContainer(
      key: ValueKey(showCheck),
      duration: const Duration(milliseconds: 180),
      width: showCheck ? 18 : 12,
      height: showCheck ? 18 : 12,
      decoration: BoxDecoration(
        color: showCheck ? Colors.white : style.accent,
        borderRadius: BorderRadius.circular(showCheck ? 6 : 999),
      ),
      child: showCheck
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.accent,
            )
          : null,
    );
    if (!isBusy || reduceMotion) {
      return base;
    }
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse =
            0.94 + 0.06 * math.sin(_loopController.value * math.pi * 2);
        return Transform.scale(
          scale: pulse,
          child: child,
        );
      },
      child: base,
    );
  }

  Widget _buildBusyEffects(_StatusStyle style, double buttonWidth) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _loopController,
          builder: (context, child) {
            final t = _loopController.value;
            final sweepOffset = (t * 2 - 1) * buttonWidth;
            return Transform.translate(
              offset: Offset(sweepOffset, 0),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      AppColors.accent.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color accent;
  final String action;

  const _StatusStyle({
    required this.accent,
    required this.action,
  });
}
