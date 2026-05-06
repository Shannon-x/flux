/// 世界地图数据：大陆轮廓多边形 + 常用国家经纬度。
///
/// 设计原则:
/// 不追求地理精度,而是为暖调 dotted 风格地图提供可识别的大陆形状。
/// 投影使用最简单的 equirectangular: x = (lng+180)/360, y = (90-lat)/180。
library;

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// 各大陆的简化轮廓多边形(经纬度顺时针)。
/// 多个分量代表岛屿/分隔的陆块。
class WorldGeo {
  WorldGeo._();

  /// 北美大陆主体
  static const List<List<GeoPoint>> continents = [
    // 北美
    [
      GeoPoint(72, -160),
      GeoPoint(70, -141),
      GeoPoint(60, -141),
      GeoPoint(55, -130),
      GeoPoint(48, -124),
      GeoPoint(32, -117),
      GeoPoint(24, -110),
      GeoPoint(20, -103),
      GeoPoint(18, -94),
      GeoPoint(22, -88),
      GeoPoint(28, -82),
      GeoPoint(25, -80),
      GeoPoint(35, -75),
      GeoPoint(45, -66),
      GeoPoint(52, -55),
      GeoPoint(60, -64),
      GeoPoint(67, -82),
      GeoPoint(74, -90),
      GeoPoint(78, -100),
      GeoPoint(75, -125),
      GeoPoint(72, -160),
    ],
    // 格陵兰
    [
      GeoPoint(82, -32),
      GeoPoint(80, -20),
      GeoPoint(72, -22),
      GeoPoint(63, -42),
      GeoPoint(70, -55),
      GeoPoint(78, -60),
      GeoPoint(82, -32),
    ],
    // 南美
    [
      GeoPoint(12, -71),
      GeoPoint(11, -62),
      GeoPoint(5, -52),
      GeoPoint(-5, -35),
      GeoPoint(-23, -40),
      GeoPoint(-34, -56),
      GeoPoint(-50, -68),
      GeoPoint(-55, -68),
      GeoPoint(-50, -75),
      GeoPoint(-35, -72),
      GeoPoint(-18, -71),
      GeoPoint(-5, -81),
      GeoPoint(5, -78),
      GeoPoint(12, -71),
    ],
    // 欧洲(去掉东边界,与亚洲在 60E 衔接)
    [
      GeoPoint(70, -10),
      GeoPoint(60, -8),
      GeoPoint(43, -9),
      GeoPoint(36, -5),
      GeoPoint(36, 5),
      GeoPoint(40, 18),
      GeoPoint(45, 28),
      GeoPoint(52, 35),
      GeoPoint(65, 42),
      GeoPoint(70, 55),
      GeoPoint(72, 30),
      GeoPoint(70, 18),
      GeoPoint(70, -10),
    ],
    // 非洲
    [
      GeoPoint(36, -8),
      GeoPoint(32, 10),
      GeoPoint(30, 25),
      GeoPoint(31, 32),
      GeoPoint(20, 38),
      GeoPoint(12, 43),
      GeoPoint(5, 48),
      GeoPoint(-12, 42),
      GeoPoint(-25, 38),
      GeoPoint(-34, 27),
      GeoPoint(-34, 18),
      GeoPoint(-22, 14),
      GeoPoint(-5, 9),
      GeoPoint(8, 0),
      GeoPoint(15, -16),
      GeoPoint(22, -17),
      GeoPoint(30, -10),
      GeoPoint(36, -8),
    ],
    // 亚洲(从 60E 起)
    [
      GeoPoint(72, 60),
      GeoPoint(72, 100),
      GeoPoint(70, 130),
      GeoPoint(65, 168),
      GeoPoint(58, 162),
      GeoPoint(50, 142),
      GeoPoint(40, 140),
      GeoPoint(33, 132),
      GeoPoint(30, 122),
      GeoPoint(22, 115),
      GeoPoint(10, 108),
      GeoPoint(2, 103),
      GeoPoint(8, 95),
      GeoPoint(15, 92),
      GeoPoint(8, 78),
      GeoPoint(20, 70),
      GeoPoint(25, 60),
      GeoPoint(35, 52),
      GeoPoint(42, 50),
      GeoPoint(50, 45),
      GeoPoint(60, 50),
      GeoPoint(72, 60),
    ],
    // 印度尼西亚 / 马来 (一组岛屿合并近似)
    [
      GeoPoint(2, 96),
      GeoPoint(0, 120),
      GeoPoint(-8, 138),
      GeoPoint(-10, 120),
      GeoPoint(-7, 105),
      GeoPoint(2, 96),
    ],
    // 澳大利亚
    [
      GeoPoint(-12, 132),
      GeoPoint(-12, 142),
      GeoPoint(-22, 152),
      GeoPoint(-37, 150),
      GeoPoint(-37, 140),
      GeoPoint(-32, 115),
      GeoPoint(-22, 113),
      GeoPoint(-15, 125),
      GeoPoint(-12, 132),
    ],
    // 日本 (近似单条)
    [
      GeoPoint(45, 142),
      GeoPoint(40, 141),
      GeoPoint(34, 135),
      GeoPoint(31, 130),
      GeoPoint(34, 132),
      GeoPoint(38, 138),
      GeoPoint(42, 141),
      GeoPoint(45, 142),
    ],
    // 英伦
    [
      GeoPoint(58, -5),
      GeoPoint(54, -2),
      GeoPoint(50, -5),
      GeoPoint(52, 1),
      GeoPoint(58, -5),
    ],
  ];

  /// 国家代码 → 首都(或主要节点城市)的经纬度,用于在地图上落点。
  /// 用首都而不是几何中心,marker 位置更符合直觉(避免 RU 落到西伯利亚、CN 落到四川)。
  static const Map<String, GeoPoint> countries = {
    'CN': GeoPoint(39.9, 116.4),     // 北京
    'JP': GeoPoint(35.7, 139.7),     // 东京
    'KR': GeoPoint(37.6, 127.0),     // 首尔
    'HK': GeoPoint(22.3, 114.2),
    'TW': GeoPoint(25.0, 121.5),     // 台北
    'SG': GeoPoint(1.35, 103.8),
    'MY': GeoPoint(3.14, 101.7),
    'TH': GeoPoint(13.8, 100.5),
    'VN': GeoPoint(21.0, 105.8),     // 河内
    'PH': GeoPoint(14.6, 121.0),     // 马尼拉
    'ID': GeoPoint(-6.2, 106.8),     // 雅加达
    'IN': GeoPoint(28.6, 77.2),      // 新德里
    'AE': GeoPoint(25.2, 55.3),      // 迪拜
    'TR': GeoPoint(41.0, 28.9),      // 伊斯坦布尔
    'RU': GeoPoint(55.75, 37.6),     // 莫斯科
    'UA': GeoPoint(50.45, 30.5),     // 基辅
    'DE': GeoPoint(52.5, 13.4),      // 柏林
    'FR': GeoPoint(48.85, 2.35),     // 巴黎
    'GB': GeoPoint(51.5, -0.13),     // 伦敦
    'NL': GeoPoint(52.37, 4.9),      // 阿姆斯特丹
    'IT': GeoPoint(41.9, 12.5),      // 罗马
    'ES': GeoPoint(40.4, -3.7),      // 马德里
    'PL': GeoPoint(52.23, 21.0),     // 华沙
    'SE': GeoPoint(59.33, 18.07),    // 斯德哥尔摩
    'CH': GeoPoint(47.37, 8.55),     // 苏黎世
    'US': GeoPoint(37.5, -95),       // 美国中心(节点常在两岸)
    'CA': GeoPoint(43.65, -79.4),    // 多伦多
    'MX': GeoPoint(19.4, -99.1),     // 墨西哥城
    'BR': GeoPoint(-23.5, -46.6),    // 圣保罗
    'AR': GeoPoint(-34.6, -58.4),    // 布宜诺斯艾利斯
    'AU': GeoPoint(-33.87, 151.2),   // 悉尼
    'NZ': GeoPoint(-36.85, 174.76),  // 奥克兰
    'ZA': GeoPoint(-26.2, 28.0),     // 约翰内斯堡
    'EG': GeoPoint(30.0, 31.2),      // 开罗
  };

  /// 2-letter (ISO 3166-1 alpha-2) → 3-letter (alpha-3),
  /// 用于跟 GeoJSON 的 feature.id 对齐。仅覆盖 [countries] 表里的国家。
  static const Map<String, String> iso2to3 = {
    'CN': 'CHN', 'JP': 'JPN', 'KR': 'KOR', 'HK': 'HKG', 'TW': 'TWN',
    'SG': 'SGP', 'MY': 'MYS', 'TH': 'THA', 'VN': 'VNM', 'PH': 'PHL',
    'ID': 'IDN', 'IN': 'IND', 'AE': 'ARE', 'TR': 'TUR', 'RU': 'RUS',
    'UA': 'UKR', 'DE': 'DEU', 'FR': 'FRA', 'GB': 'GBR', 'NL': 'NLD',
    'IT': 'ITA', 'ES': 'ESP', 'PL': 'POL', 'SE': 'SWE', 'CH': 'CHE',
    'US': 'USA', 'CA': 'CAN', 'MX': 'MEX', 'BR': 'BRA', 'AR': 'ARG',
    'AU': 'AUS', 'NZ': 'NZL', 'ZA': 'ZAF', 'EG': 'EGY',
  };

  static Set<String> activeIso3From2(Iterable<String> codes2) {
    final out = <String>{};
    for (final c in codes2) {
      final c3 = iso2to3[c];
      if (c3 != null) out.add(c3);
    }
    return out;
  }

  /// 国旗 emoji(按区域指示符 unicode 拼装)。
  static String flagOf(String code) {
    if (code.length != 2) return '';
    final upper = code.toUpperCase();
    final base = 0x1F1E6 - 0x41;
    return String.fromCharCodes([
      base + upper.codeUnitAt(0),
      base + upper.codeUnitAt(1),
    ]);
  }

  /// 国家中文名,展示用。
  static const Map<String, String> countryNamesZh = {
    'CN': '中国',
    'JP': '日本',
    'KR': '韩国',
    'HK': '香港',
    'TW': '台湾',
    'SG': '新加坡',
    'MY': '马来西亚',
    'TH': '泰国',
    'VN': '越南',
    'PH': '菲律宾',
    'ID': '印尼',
    'IN': '印度',
    'AE': '阿联酋',
    'TR': '土耳其',
    'RU': '俄罗斯',
    'UA': '乌克兰',
    'DE': '德国',
    'FR': '法国',
    'GB': '英国',
    'NL': '荷兰',
    'IT': '意大利',
    'ES': '西班牙',
    'PL': '波兰',
    'SE': '瑞典',
    'CH': '瑞士',
    'US': '美国',
    'CA': '加拿大',
    'MX': '墨西哥',
    'BR': '巴西',
    'AR': '阿根廷',
    'AU': '澳大利亚',
    'NZ': '新西兰',
    'ZA': '南非',
    'EG': '埃及',
    'OTHER': '其他',
  };

  /// equirectangular 投影:经纬度 → [0,1] 的 (x, y)
  static (double x, double y) project(double lat, double lng) {
    final x = (lng + 180) / 360;
    // 小幅 squish:缩放 lat 范围到 [-60, 75],让地图上下不那么空
    const minLat = -58.0;
    const maxLat = 78.0;
    final clamped = lat.clamp(minLat, maxLat);
    final y = 1 - (clamped - minLat) / (maxLat - minLat);
    return (x, y);
  }

  /// 从节点名提取国家代码:依次尝试 emoji 国旗 → 显式 2 字母代码 → 中文名/英文关键词。
  static String? detectCountry(String name) {
    if (name.isEmpty) return null;
    // 1. flag emoji
    final runes = name.runes.toList();
    for (var i = 0; i + 1 < runes.length; i++) {
      final a = runes[i];
      final b = runes[i + 1];
      if (a >= 0x1F1E6 && a <= 0x1F1FF && b >= 0x1F1E6 && b <= 0x1F1FF) {
        final code = String.fromCharCodes([
          0x41 + (a - 0x1F1E6),
          0x41 + (b - 0x1F1E6),
        ]);
        if (countries.containsKey(code)) return code;
      }
    }
    // 2. 显式 2 字母代码:扫描所有 [A-Z]{2} 边界,要求两侧不是字母 → 当成代码
    final upper = name.toUpperCase();
    final tokenRe = RegExp(r'(?<![A-Z])([A-Z]{2})(?![A-Z])');
    for (final m in tokenRe.allMatches(upper)) {
      final code = m.group(1)!;
      if (countries.containsKey(code)) return code;
    }
    // 3. 关键词
    const keywords = <String, String>{
      '日本': 'JP', '東京': 'JP', '大阪': 'JP', 'JAPAN': 'JP', 'TOKYO': 'JP', 'OSAKA': 'JP',
      '韩国': 'KR', '韓國': 'KR', 'KOREA': 'KR', 'SEOUL': 'KR',
      '香港': 'HK', 'HONGKONG': 'HK', 'HONG KONG': 'HK',
      '台湾': 'TW', '臺灣': 'TW', 'TAIWAN': 'TW',
      '新加坡': 'SG', 'SINGAPORE': 'SG',
      '马来': 'MY', 'MALAYSIA': 'MY',
      '美国': 'US', 'USA': 'US', 'AMERICA': 'US', 'LOSANGELES': 'US', 'NEWYORK': 'US',
      '加拿大': 'CA', 'CANADA': 'CA',
      '英国': 'GB', '英國': 'GB', 'UK': 'GB', 'LONDON': 'GB',
      '德国': 'DE', '德國': 'DE', 'GERMANY': 'DE',
      '法国': 'FR', 'FRANCE': 'FR',
      '荷兰': 'NL', 'NETHERLANDS': 'NL',
      '俄罗斯': 'RU', 'RUSSIA': 'RU', 'MOSCOW': 'RU',
      '乌克兰': 'UA', 'UKRAINE': 'UA',
      '澳大利亚': 'AU', 'AUSTRALIA': 'AU', 'SYDNEY': 'AU',
      '印度': 'IN', 'INDIA': 'IN',
      '土耳其': 'TR', 'TURKEY': 'TR',
      '巴西': 'BR', 'BRAZIL': 'BR',
      '泰国': 'TH', 'THAILAND': 'TH',
      '越南': 'VN', 'VIETNAM': 'VN',
      '菲律宾': 'PH', 'PHILIPPINES': 'PH',
      '印尼': 'ID', 'INDONESIA': 'ID',
    };
    final upperNoSpace = upper.replaceAll(' ', '');
    for (final entry in keywords.entries) {
      if (upper.contains(entry.key) || upperNoSpace.contains(entry.key.replaceAll(' ', ''))) {
        return entry.value;
      }
    }
    return null;
  }
}
