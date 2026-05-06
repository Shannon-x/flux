import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Warm Minimalism 风格的文本右键菜单 / 长按工具栏。
///
/// 默认 AdaptiveTextSelectionToolbar 在 Linux/桌面上是深色 Material 风,
/// 与暖白 + 珊瑚橙的整体调性冲突。这里手写一个奶白卡片 + 珊瑚强调的工具栏,
/// 通过 EditableTextState 提供的 buttonItems 来获取标准动作(复制/粘贴/剪切/全选)。
Widget warmEditableContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return _WarmTextSelectionToolbar(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: editableTextState.contextMenuButtonItems,
  );
}

class _WarmTextSelectionToolbar extends StatelessWidget {
  const _WarmTextSelectionToolbar({
    required this.anchors,
    required this.buttonItems,
  });

  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> buttonItems;

  @override
  Widget build(BuildContext context) {
    if (buttonItems.isEmpty) return const SizedBox.shrink();

    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder: (context, child) => _WarmToolbarFrame(child: child),
      children: [
        for (final item in buttonItems)
          _WarmToolbarButton(
            label: _labelFor(context, item),
            onPressed: item.onPressed,
          ),
      ],
    );
  }

  String _labelFor(BuildContext context, ContextMenuButtonItem item) {
    final localizations = MaterialLocalizations.of(context);
    switch (item.type) {
      case ContextMenuButtonType.copy:
        return localizations.copyButtonLabel;
      case ContextMenuButtonType.cut:
        return localizations.cutButtonLabel;
      case ContextMenuButtonType.paste:
        return localizations.pasteButtonLabel;
      case ContextMenuButtonType.selectAll:
        return localizations.selectAllButtonLabel;
      case ContextMenuButtonType.delete:
        return localizations.deleteButtonTooltip;
      case ContextMenuButtonType.lookUp:
        return localizations.lookUpButtonLabel;
      case ContextMenuButtonType.searchWeb:
        return localizations.searchWebButtonLabel;
      case ContextMenuButtonType.share:
        return localizations.shareButtonLabel;
      case ContextMenuButtonType.liveTextInput:
        return localizations.scanTextButtonLabel;
      case ContextMenuButtonType.custom:
        return item.label ?? '';
    }
  }
}

class _WarmToolbarFrame extends StatelessWidget {
  const _WarmToolbarFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: child,
      ),
    );
  }
}

class _WarmToolbarButton extends StatefulWidget {
  const _WarmToolbarButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_WarmToolbarButton> createState() => _WarmToolbarButtonState();
}

class _WarmToolbarButtonState extends State<_WarmToolbarButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering && enabled
                ? AppColors.accentSoft.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: enabled
                  ? (_hovering ? AppColors.accent : AppColors.textPrimary)
                  : AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选中文本(SelectableText / SelectionArea)的右键工具栏。
Widget warmSelectableContextMenuBuilder(
  BuildContext context,
  SelectableRegionState selectableRegionState,
) {
  return _WarmTextSelectionToolbar(
    anchors: selectableRegionState.contextMenuAnchors,
    buttonItems: selectableRegionState.contextMenuButtonItems,
  );
}

/// 提供给 [TextField.contextMenuBuilder] 的便捷别名。
const EditableTextContextMenuBuilder fluxEditableContextMenuBuilder =
    warmEditableContextMenuBuilder;

/// 一个轻量壳:用于在 MaterialApp.builder 中包一层,
/// 把 [SelectionArea] 的默认菜单也替换成暖调样式。
class WarmSelectionScope extends StatelessWidget {
  const WarmSelectionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      contextMenuBuilder: warmSelectableContextMenuBuilder,
      child: child,
    );
  }
}

