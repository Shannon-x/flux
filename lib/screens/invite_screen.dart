import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/v2board_api.dart';
import '../models/invite_data.dart';
import '../theme/app_colors.dart';
import '../widgets/flux_loader.dart';
import 'package:share_plus/share_plus.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen>
    with SingleTickerProviderStateMixin {
  bool _isGenerating = false;
  late Future<Map<String, dynamic>> _inviteDataFuture;
  late AnimationController _animController;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Lazy loading: 仅在页面构建时才加载数据
    _inviteDataFuture = _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final api = V2BoardApi();
    final data = await api.fetchInviteData();
    final details = await api.fetchInviteDetails();
    return {'data': data, 'details': details};
  }

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    try {
      final api = V2BoardApi();
      await api.generateInviteCode();
      // Reload data
      setState(() {
        _inviteDataFuture = _loadData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.generateFailed ?? "Generation failed"}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.inviteManagement ?? 'Invite Management',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _inviteDataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppLocalizations.of(context)?.loadNodesFailed ?? "Loading failed"}: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.accentWarm),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _inviteDataFuture = _loadData();
                    }),
                    child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: FluxLoader(showTips: true));
          }

          final inviteData = snapshot.data!['data'] as InviteFetchData;
          final details = snapshot.data!['details'] as List<InviteDetail>;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _inviteDataFuture = _loadData();
              });
              await _inviteDataFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(inviteData.stat),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    AppLocalizations.of(context)?.myInviteCode ??
                        'My Invite Code',
                  ),
                  const SizedBox(height: 12),
                  _buildCodesList(inviteData.codes),
                  const SizedBox(height: 16),
                  _buildGenerateButton(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    AppLocalizations.of(context)?.inviteHistory ??
                        'Invite History',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailsList(details),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSerifSc(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildStatsGrid(InviteStat stat) {
    return Column(
      children: [
        // 1. 财务主卡:浮白底 + 衬线大数字
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowFaint,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.accent,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)
                                    ?.pendingCommission ??
                                'Available Commission',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¥${stat.availableCommission}',
                      style: GoogleFonts.notoSerifSc(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.border,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMiniStat(
                    AppLocalizations.of(context)?.pendingCommission ??
                        'Pending',
                    '¥${stat.pendingCommission}',
                  ),
                  const SizedBox(height: 12),
                  _buildMiniStat(
                    AppLocalizations.of(context)?.totalCommission ?? 'Total',
                    '¥${stat.validCommission}',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. 业绩卡:浮白底
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPerformanceItem(
                Icons.people_outline_rounded,
                '${stat.registeredUsers}',
                AppLocalizations.of(context)?.registeredUsers ?? 'Users',
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.border,
              ),
              _buildPerformanceItem(
                Icons.percent_rounded,
                '${stat.commissionRate}%',
                AppLocalizations.of(context)?.commissionPercentage ?? 'Rate',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodesList(List<InviteCode> codes) {
    if (codes.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)?.noInviteData ?? 'No invite codes',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: codes.map((code) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.code,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context)?.createdAt ?? "创建于"}: ${_formatDate(code.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      // Hardcoded domain as per feedback
                      const domain = 'https://www.fluxhub.cc';
                      final url = '$domain/#/register?code=${code.code}';
                      Share.share('Check out Flux VPN! $url');
                    },
                    icon: const Icon(Icons.share_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: FluxLoader(size: 20, color: Colors.white),
              )
            : Text(
                AppLocalizations.of(context)?.generateCode ?? 'Generate Code',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  Widget _buildDetailsList(List<InviteDetail> details) {
    if (details.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            AppLocalizations.of(context)?.noInviteHistory ?? 'No records',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final item = details[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCommissionStatusText(item.commissionStatus),
                    style: TextStyle(
                      color: _getCommissionStatusColor(item.commissionStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '+${item.commissionBalance}元',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getCommissionStatusText(int status) {
    switch (status) {
      case 0:
        return '待确认';
      case 1:
        return '发放中';
      case 2:
        return '有效';
      case 3:
        return '无效';
      default:
        return '未知';
    }
  }

  Color _getCommissionStatusColor(int status) {
    switch (status) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.accentWarm;
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}
