import 'package:flutter/material.dart';
import '../models/server_node.dart';
import '../theme/app_colors.dart';
import '../utils/node_utils.dart';

/// 暖调节点信息卡片:浮白底 + 珊瑚强调 + 延迟语义色。
class NodeInfoCard extends StatelessWidget {
  final ServerNode node;

  const NodeInfoCard({
    super.key,
    required this.node,
  });

  Color _latencyColor(int latency) {
    if (latency < 100) return AppColors.success;
    if (latency < 300) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowFaint,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    NodeUtils.extractCountry(node.name, context: context),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            if (node.latency != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 16,
                      color: _latencyColor(node.latency!),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${node.latency}ms',
                      style: TextStyle(
                        fontSize: 13,
                        color: _latencyColor(node.latency!),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
