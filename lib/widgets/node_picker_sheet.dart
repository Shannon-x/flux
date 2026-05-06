import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/server_node.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';
import 'flux_loader.dart';

/// 暖调节点选择面板:奶白底 + 衬线标题 + 浮白节点条目。
class NodePickerSheet extends StatefulWidget {
  final ValueChanged<ServerNode> onNodeSelected;

  const NodePickerSheet({super.key, required this.onNodeSelected});

  @override
  State<NodePickerSheet> createState() => _NodePickerSheetState();
}

class _NodePickerSheetState extends State<NodePickerSheet> {
  final _subscriptionService = SubscriptionService();
  List<ServerNode> _nodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  Future<void> _loadNodes({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      final nodes = await _subscriptionService.fetchNodes(forceRefresh: force);
      if (mounted) {
        setState(() {
          _nodes = nodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              if (_isLoading)
                const Expanded(child: Center(child: FluxLoader(size: 30)))
              else if (_nodes.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.noNodes ??
                          'No Nodes Available',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: _nodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildNodeItem(context, _nodes[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.selectNode ?? 'Select Node',
                style: GoogleFonts.notoSerifSc(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _loadNodes(force: true),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context)?.refresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(BuildContext context, ServerNode node) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.pop(context);
          widget.onNodeSelected(node);
        },
        highlightColor: AppColors.accentSoft.withValues(alpha: 0.4),
        splashColor: AppColors.accentSoft,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            node.protocol.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (node.latency != null) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getLatencyColor(node.latency!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${node.latency}ms',
                            style: TextStyle(
                              color: _getLatencyColor(node.latency!),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency < 100) return AppColors.success;
    if (latency < 300) return AppColors.warning;
    return AppColors.danger;
  }
}
