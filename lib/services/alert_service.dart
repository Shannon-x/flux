import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// 应用内提醒服务
/// 用于流量提醒、套餐到期提醒等 (弹窗形式)
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  /// 上次显示提醒的时间 key
  static const String _lastTrafficAlertKey = 'last_traffic_alert';
  static const String _lastExpiryAlertKey = 'last_expiry_alert';
  
  /// 最小提醒间隔 (小时)
  static const int _alertIntervalHours = 24;

  /// 检查订阅状态并显示提醒弹窗
  /// 返回是否显示了弹窗
  Future<bool> checkAndShowAlert({
    required BuildContext context,
    required int usedBytes,
    required int totalBytes,
    required int expiredAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    final expireDate = DateTime.fromMillisecondsSinceEpoch(expiredAt * 1000);
    final daysLeft = expireDate.difference(now).inDays;
    final usagePercent = totalBytes > 0 ? usedBytes / totalBytes : 0.0;

    // 检查是否需要显示流量提醒
    if (usagePercent >= 0.8) {
      final lastAlert = prefs.getInt(_lastTrafficAlertKey) ?? 0;
      final lastAlertTime = DateTime.fromMillisecondsSinceEpoch(lastAlert);
      
      if (now.difference(lastAlertTime).inHours >= _alertIntervalHours) {
        await prefs.setInt(_lastTrafficAlertKey, now.millisecondsSinceEpoch);
        if (context.mounted) {
          await _showTrafficAlert(context, usagePercent);
          return true;
        }
      }
    }

    // 检查是否需要显示到期提醒
    if (daysLeft <= 3) {
      final lastAlert = prefs.getInt(_lastExpiryAlertKey) ?? 0;
      final lastAlertTime = DateTime.fromMillisecondsSinceEpoch(lastAlert);
      
      if (now.difference(lastAlertTime).inHours >= _alertIntervalHours) {
        await prefs.setInt(_lastExpiryAlertKey, now.millisecondsSinceEpoch);
        if (context.mounted) {
          await _showExpiryAlert(context, daysLeft);
          return true;
        }
      }
    }

    return false;
  }

  /// 显示流量提醒弹窗
  Future<void> _showTrafficAlert(BuildContext context, double usagePercent) async {
    final percentInt = (usagePercent * 100).toInt();
    final isExhausted = usagePercent >= 1.0;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isExhausted ? Icons.error_outline : Icons.warning_amber_rounded,
              color: isExhausted ? AppColors.danger : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(
              isExhausted ? '流量已用尽' : '流量提醒',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          isExhausted 
              ? '您的流量已全部用完，请续费或购买新套餐以继续使用服务。'
              : '您的流量已使用 $percentInt%，请注意用量。',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  /// 显示到期提醒弹窗
  Future<void> _showExpiryAlert(BuildContext context, int daysLeft) async {
    final isExpired = daysLeft <= 0;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isExpired ? Icons.error_outline : Icons.access_time,
              color: isExpired ? AppColors.danger : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(
              isExpired ? '套餐已到期' : '套餐即将到期',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          isExpired 
              ? '您的套餐已到期，请续费以继续使用服务。'
              : '您的套餐将在 $daysLeft 天后到期，请及时续费。',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
  
  /// 重置提醒状态 (用于测试)
  Future<void> resetAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastTrafficAlertKey);
    await prefs.remove(_lastExpiryAlertKey);
  }
}
