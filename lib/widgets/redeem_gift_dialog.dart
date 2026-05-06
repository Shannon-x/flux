import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../services/v2board_api.dart';
import 'flux_loader.dart';
import 'warm_context_menu.dart';

/// 暖调兑换礼品卡对话框:浮白卡片 + 衬线标题 + 珊瑚主按钮。
class RedeemGiftDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const RedeemGiftDialog({super.key, required this.onSuccess});

  @override
  State<RedeemGiftDialog> createState() => _RedeemGiftDialogState();
}

class _RedeemGiftDialogState extends State<RedeemGiftDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final api = V2BoardApi();
      final success = await api.redeemGiftCard(code);

      if (success) {
        await api.getUserInfo();

        if (mounted) {
          widget.onSuccess();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.redeemSuccess ?? 'Redeem success'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() => _errorText = AppLocalizations.of(context)?.invalidCode ?? 'Invalid code');
      }
    } catch (e) {
      setState(() => _errorText =
          '${AppLocalizations.of(context)?.redeemFailed ?? "Redeem failed"}: ${e.toString().replaceAll("Exception:", "")}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n?.redeemGiftCard ?? 'Redeem Gift Card',
                  style: GoogleFonts.notoSerifSc(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.enterCode ?? 'Enter your code',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _controller,
                  contextMenuBuilder: warmEditableContextMenuBuilder,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    hintText: 'ABCD-1234-EFGH-5678',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 1.4,
                      ),
                    ),
                    errorText: _errorText,
                    errorStyle: const TextStyle(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: FluxLoader(size: 20, color: Colors.white),
                              )
                            : Text(
                                l10n?.redeemNow ?? 'Redeem Now',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
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
    );
  }
}
