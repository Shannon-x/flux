import '../utils/json_utils.dart';

class Plan {
  Plan({
    required this.id,
    required this.name,
    required this.transferEnable,
    this.content,
    this.monthPrice,
    this.quarterPrice,
    this.halfYearPrice,
    this.yearPrice,
    this.twoYearPrice,
    this.threeYearPrice,
    this.onetimePrice,
    this.resetPrice,
    this.resetMethod,
  });

  final int id;
  final String name;
  final int transferEnable;
  final String? content;
  final int? monthPrice;
  final int? quarterPrice;
  final int? halfYearPrice;
  final int? yearPrice;
  final int? twoYearPrice;
  final int? threeYearPrice;
  final int? onetimePrice;
  final int? resetPrice;
  final int? resetMethod;

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: JsonUtils.asInt(json['id']),
      name: JsonUtils.asString(json['name'], defaultValue: 'Plan'),
      // API 返回的 transfer_enable 单位是 GB，需要转换为字节
      transferEnable: JsonUtils.asInt(json['transfer_enable']) * 1024 * 1024 * 1024,
      content: json['content'] is String ? json['content'] as String : null,
      monthPrice: JsonUtils.asIntOrNull(json['month_price']),
      quarterPrice: JsonUtils.asIntOrNull(json['quarter_price']),
      halfYearPrice: JsonUtils.asIntOrNull(json['half_year_price']),
      yearPrice: JsonUtils.asIntOrNull(json['year_price']),
      twoYearPrice: JsonUtils.asIntOrNull(json['two_year_price']),
      threeYearPrice: JsonUtils.asIntOrNull(json['three_year_price']),
      onetimePrice: JsonUtils.asIntOrNull(json['onetime_price']),
      resetPrice: JsonUtils.asIntOrNull(json['reset_price']),
      resetMethod: JsonUtils.asIntOrNull(json['reset_traffic_method']),
    );
  }
}
