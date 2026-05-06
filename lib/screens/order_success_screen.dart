import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/plan.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Plan plan;
  final String period;
  final String tradeNo;

  const OrderSuccessScreen({
    super.key,
    required this.plan,
    required this.period,
    required this.tradeNo,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getPeriodLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'month_price':
        return l10n?.monthPrice ?? 'Monthly';
      case 'quarter_price':
        return l10n?.quarterPrice ?? 'Quarterly';
      case 'half_year_price':
        return l10n?.halfYearPrice ?? 'Half Yearly';
      case 'year_price':
        return l10n?.yearPrice ?? 'Yearly';
      case 'two_year_price':
        return l10n?.twoYearPrice ?? '2 Years';
      case 'three_year_price':
        return l10n?.threeYearPrice ?? '3 Years';
      case 'onetime_price':
        return l10n?.onetimePrice ?? 'One-time';
      case 'reset_price':
        return l10n?.resetPrice ?? 'Reset Data';
      default:
        return l10n?.subscription ?? 'Subscription';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // 成功图标
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.accent,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 标题
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      l10n?.orderSuccess ?? 'Payment Successful',
                      style: GoogleFonts.notoSerifSc(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n?.yourSubscriptionActivated ??
                          'Your subscription is now active',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // 订单详情卡片
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowFaint,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.purchasedPlan ?? 'Purchased Plan',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.plan.name,
                                  style: GoogleFonts.notoSerifSc(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _getPeriodLabel(context, widget.period),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: AppColors.border, height: 1),
                      ),

                      _buildInfoRow(
                        context,
                        l10n?.traffic ?? 'Traffic',
                        Formatters.formatBytes(widget.plan.transferEnable),
                        Icons.data_usage_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        context,
                        l10n?.order ?? 'Order ID',
                        widget.tradeNo,
                        Icons.receipt_long_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // 主操作按钮
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n?.startUsing ?? 'Start Using',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 16),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
