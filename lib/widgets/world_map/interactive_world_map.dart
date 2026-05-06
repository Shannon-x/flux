import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'natural_earth_projection.dart';
import 'world_geo_data.dart';

/// 单个地图标记。
/// 现在采用"国家级聚合"渲染:每个国家产生一个 marker,[count] 是该国节点数,
/// [selected] 决定是否高亮 + pulse。`label == 'YOU'` 是用户自己的位置(独立样式)。
class MapMarker {
  const MapMarker({
    required this.lat,
    required this.lng,
    this.color,
    this.size = 4,
    this.pulse = false,
    this.label,
    this.count = 1,
    this.selected = false,
  });

  final double lat;
  final double lng;
  final Color? color;
  final double size;
  final bool pulse;
  final String? label;
  final int count;
  final bool selected;
}

/// 可拖拽 + 滚轮/捏合缩放的世界地图。
///
/// 新特性:
///  - [activeIso3]:有节点的国家用强色填,其它国家用极淡色,达到"只显示特定国家"的视觉效果
///  - [focusLat]/[focusLng]:外部传入"应居中的位置",变化时自动 800ms tween zoom+pan
///  - cluster offset:同位置多个 marker 在屏幕空间扇形展开,不重叠
class InteractiveWorldMap extends StatefulWidget {
  const InteractiveWorldMap({
    super.key,
    required this.markers,
    this.activeIso3 = const {},
    this.focusLat,
    this.focusLng,
    this.focusZoom = 3.0,
    this.initialZoom = 1.4,
    this.minZoom = 0.8,
    this.maxZoom = 10.0,
    this.showGraticule = true,
  });

  final List<MapMarker> markers;
  final Set<String> activeIso3;
  final double? focusLat;
  final double? focusLng;
  final double focusZoom;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool showGraticule;

  @override
  State<InteractiveWorldMap> createState() => _InteractiveWorldMapState();
}

class _InteractiveWorldMapState extends State<InteractiveWorldMap>
    with TickerProviderStateMixin {
  // 当前视图变换。
  late double _zoom = widget.initialZoom;
  Offset _pan = Offset.zero;

  // 用户最近一次手动操作的时间;在 didUpdateWidget 自动 focus 时,
  // 如果用户最近 2 秒内有过手动操作,跳过自动 focus,尊重用户意图。
  DateTime _lastManualAt = DateTime.fromMillisecondsSinceEpoch(0);

  late final AnimationController _phaseTicker;
  late final AnimationController _viewAnim;
  Tween<double>? _zoomTween;
  Tween<Offset>? _panTween;

  List<GeoCountry>? _geo;

  // 触控板 / 触摸捏合状态
  double _gestureStartZoom = 1.0;
  Offset _gestureStartPan = Offset.zero;
  Offset _gestureFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _phaseTicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _viewAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addListener(_applyViewAnim);

    _loadGeo();
  }

  Future<void> _loadGeo() async {
    final cached = WorldGeoData.cachedSync;
    if (cached != null) {
      setState(() => _geo = cached);
    } else {
      final data = await WorldGeoData.load();
      if (!mounted) return;
      setState(() => _geo = data);
    }
    // 加载完成后再应用初始 focus
    _maybeAnimateToFocus();
  }

  @override
  void didUpdateWidget(covariant InteractiveWorldMap old) {
    super.didUpdateWidget(old);
    if (widget.focusLat != old.focusLat ||
        widget.focusLng != old.focusLng ||
        widget.focusZoom != old.focusZoom) {
      _maybeAnimateToFocus();
    }
  }

  @override
  void dispose() {
    _phaseTicker.dispose();
    _viewAnim.dispose();
    super.dispose();
  }

  void _maybeAnimateToFocus() {
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size == null || size.isEmpty) return;
    // 用户刚刚手动调整过 → 不打断
    if (DateTime.now().difference(_lastManualAt).inMilliseconds < 2000) return;

    if (widget.focusLat == null || widget.focusLng == null) {
      // 无目标 → 平滑回到 1× 居中
      _animateView(targetZoom: 1.0, targetPan: Offset.zero, size: size);
      return;
    }
    final target = _panForFocus(
      widget.focusLat!,
      widget.focusLng!,
      widget.focusZoom,
      size,
    );
    _animateView(targetZoom: widget.focusZoom, targetPan: target, size: size);
  }

  /// 计算让 (lat,lng) 在 zoom 下落到屏幕中心所需的 pan。
  Offset _panForFocus(double lat, double lng, double zoom, Size size) {
    final p = NaturalEarth1Projection.project(lng, lat);
    final scaleX = size.width / (NaturalEarth1Projection.xMax * 2);
    final scaleY = size.height / (NaturalEarth1Projection.yMax * 2);
    final base = math.min(scaleX, scaleY) * zoom;
    // 屏幕坐标 = size/2 + pan + (px*base, -py*base)
    // 想让该点 = size/2 → pan = -(px*base, -py*base) = (-px*base, py*base)
    return Offset(-p.$1 * base, p.$2 * base);
  }

  void _animateView({
    required double targetZoom,
    required Offset targetPan,
    required Size size,
  }) {
    _zoomTween = Tween<double>(begin: _zoom, end: targetZoom);
    _panTween = Tween<Offset>(begin: _pan, end: targetPan);
    _viewAnim.forward(from: 0);
  }

  void _applyViewAnim() {
    final t = Curves.easeOutCubic.transform(_viewAnim.value);
    final zt = _zoomTween;
    final pt = _panTween;
    if (zt == null || pt == null) return;
    setState(() {
      _zoom = zt.transform(t);
      _pan = pt.transform(t);
    });
  }

  void _markManual() {
    _lastManualAt = DateTime.now();
    if (_viewAnim.isAnimating) _viewAnim.stop();
  }

  void _onScroll(PointerScrollEvent ev) {
    final size = (context.findRenderObject() as RenderBox?)?.size;
    if (size == null) return;
    _markManual();
    final delta = -ev.scrollDelta.dy;
    final factor = math.pow(1.0015, delta).toDouble();
    _zoomAround(ev.localPosition, factor, size);
  }

  void _zoomAround(Offset focal, double factor, Size size) {
    final old = _zoom;
    final next = (old * factor).clamp(widget.minZoom, widget.maxZoom);
    final actual = next / old;
    if (actual == 1.0) return;
    setState(() {
      _pan = focal - (focal - _pan) * actual;
      _zoom = next;
      _clampPan(size);
    });
  }

  void _clampPan(Size size) {
    // 横向不限制(支持无限滚动);纵向限制在世界高度内 + 缓冲
    final extraY = size.height * (_zoom - 1) / 2 + 80;
    _pan = Offset(
      _pan.dx,
      _pan.dy.clamp(-extraY, extraY),
    );
  }

  void _onScaleStart(ScaleStartDetails d) {
    _markManual();
    _gestureStartZoom = _zoom;
    _gestureStartPan = _pan;
    _gestureFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final size = (context.findRenderObject() as RenderBox?)?.size;
    if (size == null) return;
    _markManual();
    final newZoom = (_gestureStartZoom * d.scale)
        .clamp(widget.minZoom, widget.maxZoom);
    final factor = newZoom / _gestureStartZoom;
    setState(() {
      _zoom = newZoom;
      final focalDelta = d.localFocalPoint - _gestureFocal;
      _pan = _gestureFocal -
          (_gestureFocal - _gestureStartPan) * factor +
          focalDelta;
      _clampPan(size);
    });
  }

  void _onDoubleTapDown(TapDownDetails d) {
    final size = (context.findRenderObject() as RenderBox?)?.size;
    if (size == null) return;
    _markManual();
    if (_zoom < 2.0) {
      _zoomAround(d.localPosition, 2.5, size);
    } else {
      setState(() {
        _zoom = 1.0;
        _pan = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Listener(
        onPointerSignal: (ev) {
          if (ev is PointerScrollEvent) _onScroll(ev);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onDoubleTapDown: _onDoubleTapDown,
          onDoubleTap: () {},
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: AnimatedBuilder(
              animation: _phaseTicker,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MapPainter(
                    countries: _geo,
                    markers: widget.markers,
                    activeIso3: widget.activeIso3,
                    zoom: _zoom,
                    pan: _pan,
                    showGraticule: widget.showGraticule,
                    phase: _phaseTicker.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.countries,
    required this.markers,
    required this.activeIso3,
    required this.zoom,
    required this.pan,
    required this.showGraticule,
    required this.phase,
  });

  final List<GeoCountry>? countries;
  final List<MapMarker> markers;
  final Set<String> activeIso3;
  final double zoom;
  final Offset pan;
  final bool showGraticule;
  final double phase;

  late double _baseScale;
  late double _cx;
  late double _cy;

  void _initFit(Size size) {
    final scaleX = size.width / (NaturalEarth1Projection.xMax * 2);
    final scaleY = size.height / (NaturalEarth1Projection.yMax * 2);
    _baseScale = math.min(scaleX, scaleY) * zoom;
    _cx = size.width / 2 + pan.dx;
    _cy = size.height / 2 + pan.dy;
  }

  Offset _project(double lng, double lat) {
    final p = NaturalEarth1Projection.project(lng, lat);
    return Offset(_cx + p.$1 * _baseScale, _cy - p.$2 * _baseScale);
  }

  /// 一个完整世界(经度跨度 360°)在屏幕上的像素宽度。
  double get _worldWidth =>
      2 * NaturalEarth1Projection.xMax * _baseScale;

  /// 当前 pan 下,要渲染哪些经度副本(为了无限横向滚动)。
  /// 副本编号 0 = 原位,±1 = 东/西边相邻一个世界,以此类推。
  Iterable<int> _visibleCopies(Size size) sync* {
    final w = _worldWidth;
    if (w <= 0) {
      yield 0;
      return;
    }
    // 屏幕上原位世界的中心 x 像素 = size.width/2 + pan.dx;
    // 副本 c 的中心 x = 上述 + c*w。可见条件:中心 ± w/2 与屏幕相交。
    final centerX = size.width / 2 + pan.dx;
    final low = ((-w / 2 - centerX) / w).floor();
    final high = ((size.width + w / 2 - centerX) / w).ceil();
    for (int c = low; c <= high; c++) {
      yield c;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _initFit(size);

    final copies = _visibleCopies(size).toList();
    final w = _worldWidth;

    // === Pass 1:海洋(底色) + 边缘氤氲发光 ===
    for (final c in copies) {
      canvas.save();
      canvas.translate(c * w, 0);
      _drawOceanGlow(canvas);
      _drawOcean(canvas, size);
      canvas.restore();
    }
    // === Pass 2:经纬线 ===
    if (showGraticule) {
      for (final c in copies) {
        canvas.save();
        canvas.translate(c * w, 0);
        _drawGraticule(canvas);
        canvas.restore();
      }
    }
    // === Pass 3:国家轮廓 ===
    for (final c in copies) {
      canvas.save();
      canvas.translate(c * w, 0);
      _drawCountries(canvas);
      canvas.restore();
    }

    // === Pass 4:连接弧线(跨副本最短路径) ===
    final you = markers.where((m) => m.label == 'YOU').firstOrNull;
    final sel = markers.where((m) => m.selected).firstOrNull;
    if (you != null && sel != null) {
      _drawConnection(canvas, you, sel);
    }

    // === Pass 5:非选中 bubble、选中 bubble、YOU(每副本依次画) ===
    for (final c in copies) {
      canvas.save();
      canvas.translate(c * w, 0);
      for (final m in markers) {
        if (m.label == 'YOU') continue;
        if (m.selected) continue;
        _drawCountryBubble(canvas, m);
      }
      for (final m in markers) {
        if (m.selected) _drawCountryBubble(canvas, m);
      }
      for (final m in markers) {
        if (m.label == 'YOU') _drawSelfMarker(canvas, m);
      }
      canvas.restore();
    }
  }

  /// 海洋(地球轮廓)的边缘氤氲光晕,提供"3D 球体"的氛围感。
  void _drawOceanGlow(Canvas canvas) {
    final outline = Path();
    const steps = 90;
    for (int i = 0; i <= steps; i++) {
      final lat = -90.0 + 180.0 * i / steps;
      final pt = _project(-180, lat);
      if (i == 0) {
        outline.moveTo(pt.dx, pt.dy);
      } else {
        outline.lineTo(pt.dx, pt.dy);
      }
    }
    for (int i = 0; i <= steps; i++) {
      final lat = 90.0 - 180.0 * i / steps;
      final pt = _project(180, lat);
      outline.lineTo(pt.dx, pt.dy);
    }
    outline.close();
    // 多层 Gaussian blur 模拟 atmosphere
    for (final entry in const [
      [22.0, 0.10],
      [12.0, 0.14],
      [5.0, 0.18],
    ]) {
      canvas.drawPath(
        outline,
        Paint()
          ..color = AppColors.accent.withValues(alpha: entry[1])
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, entry[0]),
      );
    }
  }

  void _drawOcean(Canvas canvas, Size size) {
    final outline = Path();
    const steps = 90;
    for (int i = 0; i <= steps; i++) {
      final lat = -90.0 + 180.0 * i / steps;
      final pt = _project(-180, lat);
      if (i == 0) {
        outline.moveTo(pt.dx, pt.dy);
      } else {
        outline.lineTo(pt.dx, pt.dy);
      }
    }
    for (int i = 0; i <= steps; i++) {
      final lat = 90.0 - 180.0 * i / steps;
      final pt = _project(180, lat);
      outline.lineTo(pt.dx, pt.dy);
    }
    outline.close();
    canvas.drawPath(
      outline,
      Paint()..color = const Color(0xFFEDE8DF),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.border.withValues(alpha: 0.55)
        ..strokeWidth = 0.8,
    );
  }

  void _drawGraticule(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.textSecondary.withValues(alpha: 0.07)
      ..strokeWidth = 0.5;
    for (int lng = -180; lng <= 180; lng += 30) {
      final path = Path();
      for (int i = 0; i <= 60; i++) {
        final lat = -90 + i * 3.0;
        final p = _project(lng.toDouble(), lat);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    for (int lat = -80; lat <= 80; lat += 20) {
      final path = Path();
      for (int i = 0; i <= 120; i++) {
        final lng = -180 + i * 3.0;
        final p = _project(lng, lat.toDouble());
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCountries(Canvas canvas) {
    final list = countries;
    if (list == null || list.isEmpty) return;

    // Active vs inactive 国家用不同的填色 + 边线,达到"只显示特定国家"的视觉效果。
    final inactiveFill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE9E2D3); // 比海洋稍亮的死水色,几乎融入背景
    final inactiveStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.textSecondary.withValues(alpha: 0.18)
      ..strokeWidth = math.max(0.45, 0.55 / math.pow(zoom, 0.4)).toDouble()
      ..strokeJoin = StrokeJoin.round;

    final activeFill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFAF6EE); // 强反差奶白
    final activeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.accent.withValues(alpha: 0.55)
      ..strokeWidth = math.max(0.7, 0.9 / math.pow(zoom, 0.3)).toDouble()
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // 选中国家投影(仅 active),营造"浮起"立体感
    final shadowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // 三遍画:1) inactive  2) active 投影  3) active 填充+描边
    for (var pass = 0; pass < 3; pass++) {
      for (final c in list) {
        final isActive = activeIso3.contains(c.id);
        if (pass == 0 && isActive) continue;
        if (pass != 0 && !isActive) continue;

        for (final ring in c.rings) {
          if (ring.length < 4) continue;
          final path = Path();
          for (int i = 0; i < ring.length; i += 2) {
            final pt = _project(ring[i], ring[i + 1]);
            if (i == 0) {
              path.moveTo(pt.dx, pt.dy);
            } else {
              path.lineTo(pt.dx, pt.dy);
            }
          }
          path.close();

          if (pass == 0) {
            canvas.drawPath(path, inactiveFill);
            canvas.drawPath(path, inactiveStroke);
          } else if (pass == 1) {
            // 投影:同 path 偏移 + blur
            canvas.save();
            canvas.translate(0, 1.6);
            canvas.drawPath(path, shadowPaint);
            canvas.restore();
          } else {
            canvas.drawPath(path, activeFill);
            canvas.drawPath(path, activeStroke);
          }
        }
      }
    }
  }

  /// 国家气泡的半径:节点越多越大,但封顶 18px。
  double _bubbleRadius(int count) {
    final r = 9.0 + math.sqrt(count.toDouble()) * 1.7;
    return r.clamp(9.0, 18.0);
  }

  /// 国家级聚合气泡:一个圆 + 节点数字。选中态加 pulse 与强色。
  void _drawCountryBubble(Canvas canvas, MapMarker m) {
    final pos = _project(m.lng, m.lat);
    final r = _bubbleRadius(m.count);
    final color = m.selected
        ? AppColors.accent
        : (m.color ?? AppColors.accentWarm);

    if (m.selected || m.pulse) {
      final t = phase;
      canvas.drawCircle(
        pos,
        r + 14 * t,
        Paint()..color = color.withValues(alpha: (1 - t) * 0.32),
      );
      canvas.drawCircle(
        pos,
        r + 7 * t,
        Paint()..color = color.withValues(alpha: (1 - t) * 0.18),
      );
    }
    // 投影 + 白色描边
    canvas.drawCircle(
      pos.translate(0, 1.5),
      r + 0.5,
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawCircle(pos, r + 1.6, Paint()..color = AppColors.surface);
    canvas.drawCircle(pos, r, Paint()..color = color);
    // 高光
    canvas.drawCircle(
      pos.translate(-r * 0.32, -r * 0.32),
      r * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );

    // 数字徽章:N=1 时不画(避免到处都是 "1")
    if (m.count > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${m.count}',
          style: TextStyle(
            color: Colors.white,
            fontSize: r * (m.count >= 100 ? 0.72 : 0.88),
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );
    }
  }

  /// 用户自己位置的小图钉(独立样式 + "You" 文本)。
  void _drawSelfMarker(Canvas canvas, MapMarker m) {
    final pos = _project(m.lng, m.lat);
    final r = m.size;
    final color = m.color ?? AppColors.accent;

    if (m.pulse) {
      final t = phase;
      canvas.drawCircle(
        pos,
        r + 18 * t,
        Paint()..color = color.withValues(alpha: (1 - t) * 0.40),
      );
      canvas.drawCircle(
        pos,
        r + 9 * t,
        Paint()..color = color.withValues(alpha: (1 - t) * 0.22),
      );
    }
    canvas.drawCircle(pos, r + 2, Paint()..color = AppColors.surface);
    canvas.drawCircle(pos, r, Paint()..color = color);
    canvas.drawCircle(
      pos.translate(-r * 0.3, -r * 0.3),
      r * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    _drawLabel(
      canvas,
      pos.translate(0, -(r + 8)),
      'You',
      anchor: _LabelAnchor.bottom,
    );
  }

  void _drawLabel(Canvas canvas, Offset pos, String text,
      {_LabelAnchor anchor = _LabelAnchor.bottom}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.0,
          shadows: [
            Shadow(
              color: AppColors.surface,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    Offset draw;
    switch (anchor) {
      case _LabelAnchor.bottom:
        draw = Offset(pos.dx - tp.width / 2, pos.dy - tp.height);
        break;
      case _LabelAnchor.top:
        draw = Offset(pos.dx - tp.width / 2, pos.dy);
        break;
    }
    tp.paint(canvas, draw);
  }

  void _drawConnection(Canvas canvas, MapMarker you, MapMarker sel) {
    final a = _project(you.lng, you.lat);
    var bCenter = _project(sel.lng, sel.lat);
    // 跨副本最短路径:如果 |dx| > worldWidth/2,把 b 移到对面副本
    final w = _worldWidth;
    if (w > 0) {
      final dxRaw = bCenter.dx - a.dx;
      if (dxRaw.abs() > w / 2) {
        final shift = dxRaw > 0 ? -w : w;
        bCenter = bCenter.translate(shift, 0);
      }
    }
    final dxFull = bCenter.dx - a.dx;
    final dyFull = bCenter.dy - a.dy;
    final lenFull = math.sqrt(dxFull * dxFull + dyFull * dyFull);
    if (lenFull < 4) return;
    final shrink = _bubbleRadius(sel.count) + 2;
    final t = (lenFull - shrink) / lenFull;
    final b = Offset(a.dx + dxFull * t, a.dy + dyFull * t);
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 4) return;
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final ctrl = Offset(mid.dx, mid.dy - dist * 0.28);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);

    final dashPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, path, dashPaint);

    final metric = path.computeMetrics().first;
    final headDist = metric.length * phase;
    final tailLen = metric.length * 0.18;
    final tailStart = math.max(0.0, headDist - tailLen);
    final tail = metric.extractPath(tailStart, headDist);
    canvas.drawPath(
      tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          a, b,
          [
            AppColors.accent.withValues(alpha: 0),
            AppColors.accent.withValues(alpha: 0.85),
          ],
        ),
    );
    final tan = metric.getTangentForOffset(headDist);
    if (tan != null) {
      final p = tan.position;
      canvas.drawCircle(p, 7, Paint()..color = AppColors.accent.withValues(alpha: 0.32));
      canvas.drawCircle(p, 4.5, Paint()..color = AppColors.accent.withValues(alpha: 0.7));
      canvas.drawCircle(p, 2.4, Paint()..color = Colors.white);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dashWidth = 5, double gapWidth = 5}) {
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = math.min(dist + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.countries != countries ||
      old.markers != markers ||
      old.activeIso3 != activeIso3 ||
      old.zoom != zoom ||
      old.pan != pan ||
      old.phase != phase ||
      old.showGraticule != showGraticule;
}

enum _LabelAnchor { bottom, top }
