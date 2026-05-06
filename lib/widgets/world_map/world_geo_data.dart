import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class GeoCountry {
  GeoCountry({required this.id, required this.name, required this.rings});
  final String id;
  final String name;

  /// 每条 ring = 一段 lng/lat 平铺数组 [lng0, lat0, lng1, lat1, ...]。
  /// 多 ring(MultiPolygon)展平到同一 list,各自封闭。
  final List<List<double>> rings;
}

class WorldGeoData {
  WorldGeoData._();

  static List<GeoCountry>? _cached;
  static List<GeoCountry>? get cachedSync => _cached;

  static Future<List<GeoCountry>> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/maps/countries.geo.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List;
    final out = <GeoCountry>[];
    for (final f in features) {
      final id = (f['id'] ?? '') as String;
      final props = (f['properties'] as Map?) ?? const {};
      final name = (props['name'] ?? id) as String;
      final geom = f['geometry'] as Map<String, dynamic>?;
      if (geom == null) continue;
      final type = geom['type'] as String;
      final coords = geom['coordinates'] as List;
      final rings = <List<double>>[];
      if (type == 'Polygon') {
        _addPolygon(coords, rings);
      } else if (type == 'MultiPolygon') {
        for (final poly in coords) {
          _addPolygon(poly as List, rings);
        }
      }
      out.add(GeoCountry(id: id, name: name, rings: rings));
    }
    _cached = out;
    return out;
  }

  static void _addPolygon(List polygon, List<List<double>> out) {
    for (final ring in polygon) {
      final pts = <double>[];
      for (final pt in ring as List) {
        pts.add((pt[0] as num).toDouble());
        pts.add((pt[1] as num).toDouble());
      }
      out.add(pts);
    }
  }
}
