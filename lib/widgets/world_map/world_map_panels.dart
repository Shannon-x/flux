import 'package:flutter/material.dart';

import '../../models/server_node.dart';
import '../../theme/app_colors.dart';
import '../warm_context_menu.dart';
import 'world_geo.dart';

/// 一个国家的节点聚合。
class CountryGroup {
  CountryGroup({
    required this.code,
    required this.nodes,
  });

  final String code; // 'JP' / 'US' / 'OTHER'
  final List<ServerNode> nodes;

  String get name => WorldGeo.countryNamesZh[code] ?? code;
  String get flag => code == 'OTHER' ? '🌐' : WorldGeo.flagOf(code);
  int get count => nodes.length;

  /// 该组中最快的延迟。null 表示尚未测速。
  int? get bestLatency {
    final values = nodes.map((n) => n.latency).whereType<int>().toList();
    if (values.isEmpty) return null;
    values.sort();
    return values.first;
  }
}

/// 把 ServerNode 列表按国家分组。
List<CountryGroup> groupNodesByCountry(List<ServerNode> nodes) {
  final map = <String, List<ServerNode>>{};
  for (final node in nodes) {
    final code = WorldGeo.detectCountry(node.name) ?? 'OTHER';
    map.putIfAbsent(code, () => []).add(node);
  }
  final groups = map.entries
      .map((e) => CountryGroup(code: e.key, nodes: e.value))
      .toList();
  // 排序: 已知国家在前,OTHER 最后,内部按节点数降序
  groups.sort((a, b) {
    if (a.code == 'OTHER' && b.code != 'OTHER') return 1;
    if (b.code == 'OTHER' && a.code != 'OTHER') return -1;
    return b.count.compareTo(a.count);
  });
  return groups;
}

/// ---------- 左侧国家/节点面板 ----------

class NodeListPanel extends StatefulWidget {
  const NodeListPanel({
    super.key,
    required this.groups,
    required this.totalCount,
    required this.selectedNodeId,
    required this.onNodeSelected,
    required this.onFastestPressed,
  });

  final List<CountryGroup> groups;
  final int totalCount;
  final String? selectedNodeId;
  final void Function(ServerNode node) onNodeSelected;
  final VoidCallback onFastestPressed;

  @override
  State<NodeListPanel> createState() => _NodeListPanelState();
}

class _NodeListPanelState extends State<NodeListPanel> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _expandedCountries = <String>{};
  String _query = '';
  int _selectedNav = 0; // 0=国家 1=高级
  int _protocolTab = 0; // 0=全部 1=VLESS 2=VMESS 3=TROJAN

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<CountryGroup> get _filteredGroups {
    if (_query.isEmpty && _protocolTab == 0) return widget.groups;
    return widget.groups
        .map((group) {
          final filtered = group.nodes.where((n) {
            final matchesQuery = _query.isEmpty ||
                n.name.toLowerCase().contains(_query.toLowerCase());
            final matchesProto = switch (_protocolTab) {
              1 => n.protocol == 'vless',
              2 => n.protocol == 'vmess',
              3 => n.protocol == 'trojan',
              _ => true,
            };
            return matchesQuery && matchesProto;
          }).toList();
          return CountryGroup(code: group.code, nodes: filtered);
        })
        .where((g) => g.count > 0)
        .toList();
  }

  int _protocolCount(String? proto) {
    int c = 0;
    for (final group in widget.groups) {
      for (final n in group.nodes) {
        if (proto == null || n.protocol == proto) c++;
      }
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildNavButton(
            icon: Icons.public,
            label: '国家',
            shortcut: 'Ctrl+2',
            selected: _selectedNav == 0,
            onTap: () => setState(() => _selectedNav = 0),
          ),
          const SizedBox(height: 4),
          _buildNavButton(
            icon: Icons.tune,
            label: '高级设置',
            shortcut: 'Ctrl+3',
            selected: _selectedNav == 1,
            onTap: () => setState(() => _selectedNav = 1),
          ),
          const SizedBox(height: 12),
          if (_selectedNav == 0) ...[
            _buildProtocolTabs(),
            const SizedBox(height: 12),
            Expanded(child: _buildCountryList()),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  '高级设置',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.search,
                size: 16, color: AppColors.textSecondary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                contextMenuBuilder: warmEditableContextMenuBuilder,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, height: 1.0),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '搜索...',
                  hintStyle:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Ctrl+F',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required String shortcut,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accentSoft.withValues(alpha: 0.55)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color:
                        selected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolTabs() {
    final entries = [
      ('全部', _protocolCount(null)),
      ('VLESS', _protocolCount('vless')),
      ('VMESS', _protocolCount('vmess')),
      ('TROJAN', _protocolCount('trojan')),
    ];
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final (label, count) = entries[i];
          final selected = _protocolTab == i;
          return GestureDetector(
            onTap: () => setState(() => _protocolTab = i),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountryList() {
    final groups = _filteredGroups;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        // 总数 + 视图切换占位
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Text(
                '国家 (${groups.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Icon(Icons.view_list,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Icon(Icons.refresh,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.6)),
            ],
          ),
        ),
        // "最快国家" 行
        _FastestRow(
          totalCount: widget.totalCount,
          fastestLatency:
              groups.expand((g) => g.nodes).map((n) => n.latency).whereType<int>().fold<int?>(
            null,
            (best, v) => best == null || v < best ? v : best,
          ),
          onTap: widget.onFastestPressed,
        ),
        const SizedBox(height: 4),
        for (final group in groups)
          _CountryTile(
            group: group,
            expanded: _expandedCountries.contains(group.code),
            selectedNodeId: widget.selectedNodeId,
            onToggle: () => setState(() {
              if (!_expandedCountries.add(group.code)) {
                _expandedCountries.remove(group.code);
              }
            }),
            onNodeSelected: widget.onNodeSelected,
          ),
      ],
    );
  }
}

class _FastestRow extends StatelessWidget {
  const _FastestRow({
    required this.totalCount,
    required this.fastestLatency,
    required this.onTap,
  });

  final int totalCount;
  final int? fastestLatency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt, size: 14, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '最快国家',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (fastestLatency != null)
                Text(
                  '${fastestLatency}ms',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                '$totalCount',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.group,
    required this.expanded,
    required this.selectedNodeId,
    required this.onToggle,
    required this.onNodeSelected,
  });

  final CountryGroup group;
  final bool expanded;
  final String? selectedNodeId;
  final VoidCallback onToggle;
  final void Function(ServerNode) onNodeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(group.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (group.bestLatency != null) ...[
                    Text(
                      '${group.bestLatency}ms',
                      style: TextStyle(
                        fontSize: 11,
                        color: _latencyColor(group.bestLatency!),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${group.count}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 16,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 24, right: 4, bottom: 4),
                  child: Column(
                    children: [
                      for (final node in group.nodes)
                        _NodeRow(
                          node: node,
                          selected: node.name == selectedNodeId,
                          onTap: () => onNodeSelected(node),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.node,
    required this.selected,
    required this.onTap,
  });

  final ServerNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentSoft.withValues(alpha: 0.4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (node.latency != null)
                Text(
                  '${node.latency}ms',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _latencyColor(node.latency!),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _latencyColor(int ms) {
  if (ms < 100) return AppColors.success;
  if (ms < 200) return AppColors.warning;
  return AppColors.danger;
}

/// ---------- 右侧图标导航栏 ----------

class IconNavRail extends StatelessWidget {
  const IconNavRail({
    super.key,
    required this.items,
    required this.bottomItem,
  });

  final List<IconNavItem> items;
  final IconNavItem bottomItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          for (final item in items) _IconNavCell(item: item),
          const Spacer(),
          _IconNavCell(item: bottomItem),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class IconNavItem {
  const IconNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
}

class _IconNavCell extends StatefulWidget {
  const _IconNavCell({required this.item});
  final IconNavItem item;

  @override
  State<_IconNavCell> createState() => _IconNavCellState();
}

class _IconNavCellState extends State<_IconNavCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.accentSoft.withValues(alpha: 0.45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: _hover ? AppColors.accent : AppColors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _hover ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- 底部连接信息条 ----------

class ConnectionInfoBar extends StatelessWidget {
  const ConnectionInfoBar({
    super.key,
    required this.protected,
    this.ip,
    this.country,
    this.isp,
  });

  final bool protected;
  final String? ip;
  final String? country;
  final String? isp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 左侧:状态点 + 文字 + 提示语
          _statusIndicator(),
          const Spacer(),
          // 右侧:IP / 国家 / ISP 三列
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoColumn('您的 IP 地址', ip ?? '— — — — — —'),
              const SizedBox(width: 28),
              _infoColumn('国家', country ?? '—'),
              const SizedBox(width: 28),
              _infoColumn('提供商', isp ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator() {
    final color = protected ? AppColors.success : AppColors.danger;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          protected ? '已保护' : '未保护',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          protected ? '· 当前连接已加密' : '· 当前连接不安全，建议立即连接以保护隐私。',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
