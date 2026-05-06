import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/server_node.dart';
import '../utils/node_utils.dart';
import '../theme/app_colors.dart';

/// 节点列表面板组件 - 优化版
/// 使用 AnimatedContainer 和预构建列表避免展开时卡顿
class NodeListPanel extends StatefulWidget {
  final List<ServerNode> nodes;
  final ServerNode? selectedNode;
  final ValueChanged<ServerNode> onNodeSelected;
  final bool isExpanded;
  final VoidCallback onToggle;

  const NodeListPanel({
    super.key,
    required this.nodes,
    required this.selectedNode,
    required this.onNodeSelected,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<NodeListPanel> createState() => _NodeListPanelState();
}

class _NodeListPanelState extends State<NodeListPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NodeListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 面板头部
        _buildHeader(context),

        // 可展开的列表内容 - 使用 SizeTransition 更流畅
        SizeTransition(
          sizeFactor: _heightAnimation,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: _buildNodeList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accent.withValues(alpha: 0.1),
          highlightColor: AppColors.accent.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceAlt.withValues(alpha: 0.8),
                  AppColors.surface.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isExpanded
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 图标
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.dns_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                // 标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.nodeList ?? '节点列表',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.nodes.length} ${AppLocalizations.of(context)?.nodesAvailable ?? "个可用"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 展开箭头
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 3.14159,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFaint,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            // 头部作为第一个 sliver，会随列表滚动
            SliverToBoxAdapter(
              child: _buildListHeader(context),
            ),
            // 节点列表
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNodeItem(
                  context,
                  widget.nodes[index],
                  index,
                ),
                childCount: widget.nodes.length,
              ),
            ),
            // 底部留白
            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),
          ],
        ),
      ),
    );
  }

  /// 列表内的头部（会随列表滚动）
  Widget _buildListHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_list_bulleted_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '${AppLocalizations.of(context)?.selectNode ?? "选择节点"} (${widget.nodes.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(BuildContext context, ServerNode node, int index) {
    final isSelected = node == widget.selectedNode;
    final country = NodeUtils.extractCountry(node.name, context: context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNodeSelected(node),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // 选中状态指示器
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // 节点名称
              Expanded(
                child: Text(
                  country,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 延迟标签
              _buildLatencyBadge(node.latency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatencyBadge(int? latency) {
    if (latency == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          AppLocalizations.of(context)?.untested ?? '—',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    Color color;
    if (latency < 100) {
      color = AppColors.success;
    } else if (latency < 300) {
      color = AppColors.warning;
    } else {
      color = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${latency}ms',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
