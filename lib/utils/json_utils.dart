/// 宽松类型转换工具,用于解析后端 JSON。
///
/// V2Board 与 Xboard 的不同版本对同一字段会返回不同类型(int / bool / String / num),
/// 直接 `as int?` 在遇到 bool 时会抛 `type 'bool' is not a subtype of type 'int?'`。
/// 这里统一做安全转换,bool 视为 1/0,字符串尝试 parse,失败回退到默认值。
class JsonUtils {
  JsonUtils._();

  static int asInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is bool) return v ? 1 : 0;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static int? asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is bool) return v ? 1 : 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static num asNum(dynamic v, {num defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is num) return v;
    if (v is bool) return v ? 1 : 0;
    if (v is String) return num.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static num? asNumOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is bool) return v ? 1 : 0;
    if (v is String) return num.tryParse(v);
    return null;
  }

  static double asDouble(dynamic v, {double defaultValue = 0.0}) {
    if (v == null) return defaultValue;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is bool) return v ? 1.0 : 0.0;
    if (v is String) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static String asString(dynamic v, {String defaultValue = ''}) {
    if (v == null) return defaultValue;
    if (v is String) return v;
    return v.toString();
  }

  static bool asBool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == '') return false;
    }
    return defaultValue;
  }
}
