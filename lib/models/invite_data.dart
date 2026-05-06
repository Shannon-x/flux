import '../utils/json_utils.dart';

class InviteFetchData {
  final List<InviteCode> codes;
  final InviteStat stat;

  InviteFetchData({
    required this.codes,
    required this.stat,
  });

  factory InviteFetchData.fromJson(Map<String, dynamic> json) {
    return InviteFetchData(
      codes: (json['codes'] as List<dynamic>?)
              ?.map((e) => InviteCode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stat: InviteStat.fromList(json['stat'] as List<dynamic>? ?? []),
    );
  }
}

class InviteStat {
  final int registeredUsers;
  final num validCommission;
  final num pendingCommission;
  final num commissionRate;
  final num availableCommission;

  InviteStat({
    required this.registeredUsers,
    required this.validCommission,
    required this.pendingCommission,
    required this.commissionRate,
    required this.availableCommission,
  });

  factory InviteStat.fromList(List<dynamic> list) {
    if (list.length < 5) {
      return InviteStat(
        registeredUsers: 0,
        validCommission: 0,
        pendingCommission: 0,
        commissionRate: 0,
        availableCommission: 0,
      );
    }
    return InviteStat(
      registeredUsers: JsonUtils.asInt(list[0]),
      validCommission: JsonUtils.asNum(list[1]),
      pendingCommission: JsonUtils.asNum(list[2]),
      commissionRate: JsonUtils.asNum(list[3]),
      availableCommission: JsonUtils.asNum(list[4]),
    );
  }
}

class InviteCode {
  final int id;
  final int userId;
  final String code;
  final int status;
  final int pv;
  final int createdAt;
  final int updatedAt;

  InviteCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.status,
    required this.pv,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      id: JsonUtils.asInt(json['id']),
      userId: JsonUtils.asInt(json['user_id']),
      code: JsonUtils.asString(json['code']),
      status: JsonUtils.asInt(json['status']),
      pv: JsonUtils.asInt(json['pv']),
      createdAt: JsonUtils.asInt(json['created_at']),
      updatedAt: JsonUtils.asInt(json['updated_at']),
    );
  }
}

class InviteDetail {
  final int id;
  final int commissionStatus; // 0待确认1发放中2有效3无效
  final num commissionBalance;
  final int createdAt;
  final int updatedAt;

  InviteDetail({
    required this.id,
    required this.commissionStatus,
    required this.commissionBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InviteDetail.fromJson(Map<String, dynamic> json) {
    return InviteDetail(
      id: JsonUtils.asInt(json['id']),
      commissionStatus: JsonUtils.asInt(json['commission_status']),
      commissionBalance: JsonUtils.asNum(json['commission_balance']),
      createdAt: JsonUtils.asInt(json['created_at']),
      updatedAt: JsonUtils.asInt(json['updated_at']),
    );
  }
}
