import '../utils/json_utils.dart';

class UserSubscribe {
  UserSubscribe({
    required this.planId,
    required this.token,
    required this.expiredAt,
    required this.upload,
    required this.download,
    required this.transferEnable,
    required this.email,
    required this.subscribeUrl,
  });

  final int planId;
  final String token;
  final int expiredAt;
  final int upload;
  final int download;
  final int transferEnable;
  final String email;
  final String subscribeUrl;

  factory UserSubscribe.fromJson(Map<String, dynamic> json) {
    return UserSubscribe(
      planId: JsonUtils.asInt(json['plan_id']),
      token: JsonUtils.asString(json['token']),
      expiredAt: JsonUtils.asInt(json['expired_at']),
      upload: JsonUtils.asInt(json['u']),
      download: JsonUtils.asInt(json['d']),
      transferEnable: JsonUtils.asInt(json['transfer_enable']),
      email: JsonUtils.asString(json['email']),
      subscribeUrl: JsonUtils.asString(json['subscribe_url']),
    );
  }
}
