import '../utils/json_utils.dart';

class UserInfo {
  UserInfo({
    required this.email,
    required this.transferEnable,
    required this.expiredAt,
    required this.balance,
    required this.planId,
    this.avatarUrl,
    this.uuid,
  });

  final String email;
  final int transferEnable;
  final int expiredAt;
  final int balance;
  final int planId;
  final String? avatarUrl;
  final String? uuid;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      email: JsonUtils.asString(json['email']),
      transferEnable: JsonUtils.asInt(json['transfer_enable']),
      expiredAt: JsonUtils.asInt(json['expired_at']),
      balance: JsonUtils.asInt(json['balance']),
      planId: JsonUtils.asInt(json['plan_id']),
      avatarUrl: json['avatar_url'] is String ? json['avatar_url'] as String : null,
      uuid: json['uuid'] is String ? json['uuid'] as String : null,
    );
  }
}
