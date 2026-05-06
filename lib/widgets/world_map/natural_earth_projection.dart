import 'dart:math' as math;

/// D3 d3-geo-projection 中的 geoNaturalEarth1。
class NaturalEarth1Projection {
  NaturalEarth1Projection._();

  static (double x, double y) project(double lngDeg, double latDeg) {
    final lambda = lngDeg * math.pi / 180;
    final phi = latDeg * math.pi / 180;
    final phi2 = phi * phi;
    final phi4 = phi2 * phi2;
    final x = lambda *
        (0.8707 -
            0.131979 * phi2 +
            phi4 * (-0.013791 + phi4 * (0.003971 * phi2 - 0.001529 * phi4)));
    final y = phi *
        (1.007226 +
            phi2 * (0.015085 +
                phi4 * (-0.044475 + 0.028874 * phi2 - 0.005916 * phi4)));
    return (x, y);
  }

  static const double xMax = 2.7349;
  static const double yMax = 1.4263;
}
