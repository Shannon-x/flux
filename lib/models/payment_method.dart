import '../utils/json_utils.dart';

class PaymentMethod {
  PaymentMethod({
    required this.id,
    required this.name,
    required this.payment,
    this.icon,
  });

  final int id;
  final String name;
  final String payment;
  final String? icon;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: JsonUtils.asInt(json['id']),
      name: JsonUtils.asString(json['name']),
      payment: JsonUtils.asString(json['payment']),
      icon: json['icon'] is String ? json['icon'] as String : null,
    );
  }
}
