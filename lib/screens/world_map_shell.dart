import 'package:flutter/material.dart';

import '../config/brand_config.dart';
import '../models/server_node.dart';
import '../theme/app_colors.dart';
import '../widgets/world_map/interactive_world_map.dart';
import '../widgets/world_map/world_geo.dart';
import '../widgets/world_map/world_map_panels.dart';

/// 三栏世界地图风格的桌面主壳。
///
/// 左:节点列表面板  中:地图 + 连接按钮  右:图标快捷栏。
class WorldMapShell extends StatefulWidget {
  const WorldMapShell({
    super.key,
    required this.nodes,
    required this.selectedNode,
    required this.isConnected,
    required this.isConnecting,
    required this.statusMessage,
    required this.onConnectPressed,
    required this.onNodeSelected,
    required this.onPickFastest,
    required this.onOpenAccount,
    required this.onOpenInvite,
    required this.onOpenPlans,
    required this.onOpenSupport,
    required this.onOpenSettings,
    this.publicIp,
    this.publicCountry,
    this.publicIsp,
  });

  final List<ServerNode> nodes;
  final ServerNode? selectedNode;
  final bool isConnected;
  final bool isConnecting;
  final String statusMessage;

  final VoidCallback onConnectPressed;
  final void Function(ServerNode node) onNodeSelected;
  final VoidCallback onPickFastest;

  final VoidCallback onOpenAccount;
  final VoidCallback onOpenInvite;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenSettings;

  final String? publicIp;
  final String? publicCountry;
  final String? publicIsp;

  @override
  State<WorldMapShell> createState() => _WorldMapShellState();
}

class _WorldMapShellState extends State<WorldMapShell> {
  @override
  Widget build(BuildContext context) {
    final groups = groupNodesByCountry(widget.nodes);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 左:节点列表
          NodeListPanel(
            groups: groups,
            totalCount: widget.nodes.length,
            selectedNodeId: widget.selectedNode?.name,
            onNodeSelected: widget.onNodeSelected,
            onFastestPressed: widget.onPickFastest,
          ),
          _verticalDivider(),
          // 中:地图 + 连接按钮
          Expanded(
            child: _CenterMapPane(
              nodes: widget.nodes,
              selectedNode: widget.selectedNode,
              isConnected: widget.isConnected,
              isConnecting: widget.isConnecting,
              statusMessage: widget.statusMessage,
              onConnectPressed: widget.onConnectPressed,
              publicIp: widget.publicIp,
              publicCountry: widget.publicCountry,
              publicIsp: widget.publicIsp,
            ),
          ),
          _verticalDivider(),
          // 右:图标栏
          IconNavRail(
            items: [
              IconNavItem(
                icon: Icons.article_outlined,
                label: '规则',
                onTap: () {},
              ),
              IconNavItem(
                icon: Icons.bolt_outlined,
                label: '套餐',
                onTap: widget.onOpenPlans,
              ),
              IconNavItem(
                icon: Icons.chat_bubble_outline,
                label: '在线客服',
                onTap: widget.onOpenSupport,
              ),
              IconNavItem(
                icon: Icons.group_outlined,
                label: '我的邀请',
                onTap: widget.onOpenInvite,
              ),
              IconNavItem(
                icon: Icons.account_circle_outlined,
                label: '账户',
                onTap: widget.onOpenAccount,
              ),
            ],
            bottomItem: IconNavItem(
              icon: Icons.settings_outlined,
              label: '设置',
              onTap: widget.onOpenSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        color: AppColors.border.withValues(alpha: 0.5),
      );
}

class _CenterMapPane extends StatelessWidget {
  const _CenterMapPane({
    required this.nodes,
    required this.selectedNode,
    required this.isConnected,
    required this.isConnecting,
    required this.statusMessage,
    required this.onConnectPressed,
    required this.publicIp,
    required this.publicCountry,
    required this.publicIsp,
  });

  final List<ServerNode> nodes;
  final ServerNode? selectedNode;
  final bool isConnected;
  final bool isConnecting;
  final String statusMessage;
  final VoidCallback onConnectPressed;
  final String? publicIp;
  final String? publicCountry;
  final String? publicIsp;

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final selectedCountry = selectedNode == null
        ? null
        : WorldGeo.detectCountry(selectedNode!.name);
    final headerCountries = nodes
        .map((n) => WorldGeo.detectCountry(n.name))
        .whereType<String>()
        .toSet()
        .toList();

    // active 国家高亮:所有有节点的国家(2 字母 → 3 字母 ISO 与 GeoJSON 对齐)
    final activeIso3 = WorldGeo.activeIso3From2(headerCountries);

    // 选中节点 → 自动居中到对应首都
    GeoPoint? focus;
    if (selectedCountry != null) {
      focus = WorldGeo.countries[selectedCountry];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.95),
            AppColors.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 地图层:edge-to-edge 填满,只在底部留 ConnectionInfoBar 的位置
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: InteractiveWorldMap(
                markers: markers,
                activeIso3: activeIso3,
                focusLat: focus?.lat,
                focusLng: focus?.lng,
                focusZoom: 3.2,
                initialZoom: 1.6,
              ),
            ),
          ),
          // 顶部:品牌 + 标题
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: _buildHeader(selectedCountry, headerCountries),
          ),
          // 中央:连接按钮
          Center(
            child: _ConnectButton(
              isConnected: isConnected,
              isConnecting: isConnecting,
              onPressed: onConnectPressed,
            ),
          ),
          // 底部:连接信息条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ConnectionInfoBar(
              protected: isConnected,
              ip: publicIp,
              country: publicCountry,
              isp: publicIsp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String? selectedCountryCode, List<String> allCountries) {
    final flag = selectedCountryCode != null
        ? WorldGeo.flagOf(selectedCountryCode)
        : '🌐';
    final title = selectedNode?.name ?? '最快服务器';

    return Column(
      children: [
        // 顶左:品牌
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              BrandConfig.buildLogoBadge(iconSize: 18, padding: 6),
              const SizedBox(width: 10),
              BrandConfig.buildName(fontSize: 16),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // 中:标题
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 副标题:从哪些国家自动选择
        if (allCountries.length > 1 && selectedNode == null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '自动选择自 ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
              for (final code in allCountries.take(5))
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    WorldGeo.flagOf(code),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              if (allCountries.length > 5)
                Text(
                  '+${allCountries.length - 5}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  List<MapMarker> _buildMarkers() {
    // 每国一个 marker:统计节点数,选中国家高亮
    final perCountryCount = <String, int>{};
    for (final node in nodes) {
      final code = WorldGeo.detectCountry(node.name);
      if (code == null) continue;
      if (!WorldGeo.countries.containsKey(code)) continue;
      perCountryCount[code] = (perCountryCount[code] ?? 0) + 1;
    }

    final selectedCode = selectedNode == null
        ? null
        : WorldGeo.detectCountry(selectedNode!.name);

    final out = <MapMarker>[];
    perCountryCount.forEach((code, count) {
      final base = WorldGeo.countries[code]!;
      final isSelected = selectedCode == code;
      out.add(MapMarker(
        lat: base.lat,
        lng: base.lng,
        color: isSelected ? AppColors.accent : AppColors.accentWarm,
        count: count,
        selected: isSelected,
      ));
    });

    // You: 默认放在中国附近,真实 IP 进来后再覆盖
    out.add(const MapMarker(
      lat: 35,
      lng: 110,
      color: AppColors.accent,
      size: 5,
      pulse: true,
      label: 'YOU',
    ));

    return out;
  }
}

class _ConnectButton extends StatefulWidget {
  const _ConnectButton({
    required this.isConnected,
    required this.isConnecting,
    required this.onPressed,
  });

  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onPressed;

  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton>
    with SingleTickerProviderStateMixin {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.isConnecting
        ? '连接中…'
        : widget.isConnected
            ? '断开'
            : '连接';
    final bg = widget.isConnected ? AppColors.success : AppColors.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.isConnecting ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 168,
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: _hover ? 0.45 : 0.3),
                blurRadius: _hover ? 32 : 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isConnecting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
