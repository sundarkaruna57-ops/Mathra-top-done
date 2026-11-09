import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';

/// One particle (or one bolt / ring / rainbow – everything is a "particle").
class _P {
  _P({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.phase,
    required this.c,
    this.g = 0,
    this.sw = 0,
    this.drag = 0,
    this.rot = 0,
    this.vrot = 0,
    this.r = 0,
    this.pts,
  });

  double x, y, vx, vy;
  double size;
  double life;
  double age = 0;
  double phase;
  int c; // colour index (wrapped by the palette length)
  double g; // gravity px/s²
  double sw; // sideways sway px/s
  double drag; // velocity damping per second
  double rot, vrot;
  double r; // radius (spiral) / trail length (meteor, matrix)
  List<Offset>? pts; // lightning bolt

  bool get dead => age >= life;

  /// Fade in at the start, fade out at the end.
  double get fade {
    final i = (age / 0.25).clamp(0.0, 1.0);
    final o = ((life - age) / 0.5).clamp(0.0, 1.0);
    return i * o;
  }

  /// Fade out only (used by explosions that must be visible at once).
  double get fadeOut => ((life - age) / 0.6).clamp(0.0, 1.0);
}

/// Draws one of the 20 [FxKind] effects over the whole area.
/// Set [active] to start spawning; when it turns false the effect stops
/// spawning and the remaining particles finish by themselves.
class FxOverlay extends StatefulWidget {
  const FxOverlay({super.key, required this.active, required this.kind});

  final bool active;
  final FxKind kind;

  @override
  State<FxOverlay> createState() => _FxOverlayState();
}

class _FxOverlayState extends State<FxOverlay>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  final List<_P> _ps = [];
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _time = 0;
  double _acc = 0;
  double _flash = 0; // lightning screen flash 0..1
  Size _size = Size.zero;

  static const int _maxParticles = 420;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant FxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _ps.clear();
      _acc = 0;
      _flash = 0;
    }
    if (widget.active && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ───────────────────────── helpers ─────────────────────────

  double _r(double a, double b) => a + _rng.nextDouble() * (b - a);

  _P _mk({
    double x = 0,
    double y = 0,
    double vx = 0,
    double vy = 0,
    double size = 10,
    double life = 5,
    double g = 0,
    double sw = 0,
    double drag = 0,
    double rot = 0,
    double vrot = 0,
    double r = 0,
    int? c,
    List<Offset>? pts,
  }) {
    return _P(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      size: size,
      life: life,
      phase: _rng.nextDouble() * math.pi * 2,
      c: c ?? _rng.nextInt(1000),
      g: g,
      sw: sw,
      drag: drag,
      rot: rot,
      vrot: vrot,
      r: r,
      pts: pts,
    );
  }

  double _rate(FxKind k) {
    switch (k) {
      case FxKind.fireworks:
        return 0.9;
      case FxKind.sparkles:
        return 18;
      case FxKind.bubbles:
        return 7;
      case FxKind.snow:
        return 22;
      case FxKind.hearts:
        return 6;
      case FxKind.starBurst:
        return 0.9;
      case FxKind.balloons:
        return 2.2;
      case FxKind.coins:
        return 13;
      case FxKind.leaves:
        return 8;
      case FxKind.sakura:
        return 12;
      case FxKind.lightning:
        return 0.9;
      case FxKind.rainbow:
        return 0.35;
      case FxKind.ripples:
        return 2.2;
      case FxKind.spiral:
        return 14;
      case FxKind.meteors:
        return 4;
      case FxKind.fireflies:
        return 12;
      case FxKind.disco:
        return 7;
      case FxKind.matrix:
        return 16;
      case FxKind.bokeh:
        return 3;
      case FxKind.pulse:
        return 0.9;
      case FxKind.aurora:
        return 0.6;
      case FxKind.warp:
        return 70;
      case FxKind.rain:
        return 90;
      case FxKind.embers:
        return 28;
      case FxKind.lanterns:
        return 1.6;
      case FxKind.butterflies:
        return 1.4;
      case FxKind.lasers:
        return 3.2;
      case FxKind.sunrays:
        return 0.45;
      case FxKind.notes:
        return 6;
      case FxKind.glitch:
        return 9;
    }
  }

  void _burst({
    required double cx,
    required double cy,
    required int n,
    required double minSp,
    required double maxSp,
    required double minSize,
    required double maxSize,
    required double g,
    required double drag,
    required bool spin,
  }) {
    final c0 = _rng.nextInt(8);
    for (var i = 0; i < n; i++) {
      final ang = math.pi * 2 * i / n + _r(-0.1, 0.1);
      final sp = _r(minSp, maxSp);
      _ps.add(_mk(
        x: cx,
        y: cy,
        vx: math.cos(ang) * sp,
        vy: math.sin(ang) * sp,
        size: _r(minSize, maxSize),
        life: _r(1.0, 1.7),
        g: g,
        drag: drag,
        rot: _r(0, math.pi),
        vrot: spin ? _r(-4, 4) : 0,
        c: c0 + (_rng.nextInt(4) == 0 ? 1 : 0),
      ));
    }
  }

  void _spawn() {
    final w = _size.width;
    final h = _size.height;
    switch (widget.kind) {
      case FxKind.fireworks:
        _burst(
          cx: _r(0.15, 0.85) * w,
          cy: _r(0.1, 0.5) * h,
          n: 34 + _rng.nextInt(12),
          minSp: 90,
          maxSp: 260,
          minSize: 2.2,
          maxSize: 4,
          g: 140,
          drag: 1.6,
          spin: false,
        );
        break;
      case FxKind.starBurst:
        _burst(
          cx: _r(0.25, 0.75) * w,
          cy: _r(0.2, 0.55) * h,
          n: 14,
          minSp: 120,
          maxSp: 330,
          minSize: 7,
          maxSize: 15,
          g: 80,
          drag: 1.2,
          spin: true,
        );
        break;
      case FxKind.sparkles:
        _ps.add(_mk(
          x: _r(0, w),
          y: _r(0, h),
          size: _r(7, 18),
          life: _r(0.7, 1.5),
          rot: _r(0, math.pi),
          vrot: _r(-1, 1),
        ));
        break;
      case FxKind.bubbles:
        _ps.add(_mk(
          x: _r(0, w),
          y: h + 30,
          vy: -_r(50, 120),
          size: _r(8, 26),
          sw: _r(10, 28),
          life: 30,
        ));
        break;
      case FxKind.snow:
        _ps.add(_mk(
          x: _r(-20, w + 20),
          y: -20,
          vy: _r(40, 110),
          size: _r(2.5, 6),
          sw: _r(8, 22),
          life: 40,
        ));
        break;
      case FxKind.hearts:
        _ps.add(_mk(
          x: _r(0, w),
          y: h + 30,
          vy: -_r(70, 150),
          size: _r(10, 24),
          sw: _r(10, 25),
          life: 30,
        ));
        break;
      case FxKind.balloons:
        _ps.add(_mk(
          x: _r(0.05, 0.95) * w,
          y: h + 50,
          vy: -_r(90, 170),
          size: _r(26, 44),
          sw: _r(8, 20),
          life: 40,
        ));
        break;
      case FxKind.coins:
        _ps.add(_mk(
          x: _r(0, w),
          y: -30,
          vy: _r(170, 330),
          g: 40,
          size: _r(12, 22),
          life: 40,
        ));
        break;
      case FxKind.leaves:
        _ps.add(_mk(
          x: _r(0, w),
          y: -30,
          vy: _r(50, 110),
          sw: _r(25, 55),
          size: _r(8, 16),
          rot: _r(0, math.pi * 2),
          vrot: _r(-2, 2),
          life: 40,
        ));
        break;
      case FxKind.sakura:
        _ps.add(_mk(
          x: _r(0, w),
          y: -30,
          vy: _r(45, 100),
          sw: _r(20, 45),
          size: _r(5, 9),
          rot: _r(0, math.pi * 2),
          vrot: _r(-1.5, 1.5),
          life: 40,
        ));
        break;
      case FxKind.lightning:
        final pts = <Offset>[];
        var px = _r(0.15, 0.85) * w;
        var py = 0.0;
        final endY = _r(0.55, 0.9) * h;
        pts.add(Offset(px, py));
        while (py < endY) {
          py += _r(28, 48);
          px += _r(-22, 22);
          pts.add(Offset(px, py));
        }
        _ps.add(_mk(size: 3, life: 0.5, pts: pts));
        _flash = 0.55;
        break;
      case FxKind.rainbow:
        if (_ps.length < 2) {
          _ps.add(_mk(
            x: _r(0.35, 0.65) * w,
            y: _r(0.78, 0.92) * h,
            size: w * _r(0.5, 0.62),
            life: 3.4,
          ));
        }
        break;
      case FxKind.ripples:
        _ps.add(_mk(
          x: _r(0.1, 0.9) * w,
          y: _r(0.1, 0.9) * h,
          size: _r(70, 150),
          life: _r(1.3, 2.0),
        ));
        break;
      case FxKind.spiral:
        for (var k = 0; k < 3; k++) {
          _ps.add(_mk(
            size: _r(2.5, 5),
            life: 3.2,
            rot: _time * 5 + k * math.pi * 2 / 3,
            vrot: 1.2,
            vx: _r(95, 120), // radial speed
          ));
        }
        break;
      case FxKind.meteors:
        _ps.add(_mk(
          x: _r(0.2, 1.2) * w,
          y: -20,
          vx: -_r(300, 520),
          vy: _r(380, 620),
          size: _r(2, 4),
          r: _r(70, 140),
          life: 40,
        ));
        break;
      case FxKind.fireflies:
        _ps.add(_mk(
          x: _r(0, w),
          y: _r(0, h),
          vx: _r(-14, 14),
          vy: _r(-14, 14),
          sw: _r(8, 20),
          size: _r(2, 4),
          life: _r(4, 7),
        ));
        break;
      case FxKind.disco:
        _ps.add(_mk(
          x: _r(0, w),
          y: _r(0, h),
          size: _r(30, 80),
          life: _r(0.5, 1.0),
        ));
        break;
      case FxKind.matrix:
        final cols = (w / 16).floor().clamp(1, 1000);
        _ps.add(_mk(
          x: _rng.nextInt(cols) * 16.0 + 8,
          y: -10,
          vy: _r(240, 520),
          size: 7,
          r: 12,
          life: 40,
        ));
        break;
      case FxKind.bokeh:
        _ps.add(_mk(
          x: _r(0, w),
          y: _r(0.1, 1.0) * h,
          vy: -_r(8, 26),
          size: _r(24, 80),
          life: _r(5, 9),
        ));
        break;
      case FxKind.pulse:
        _ps.add(_mk(
          x: w / 2,
          y: h * 0.45,
          size: math.max(w, h) * 0.85,
          life: 1.9,
        ));
        break;
      case FxKind.aurora:
        if (_ps.length < 4) {
          _ps.add(_mk(y: _r(0.05, 0.45) * h, size: _r(90, 170), life: _r(5, 8)));
        }
        break;
      case FxKind.warp:
        final wAng = _r(0, math.pi * 2);
        final wSp = _r(40, 90);
        _ps.add(_mk(
          x: w / 2 + math.cos(wAng) * 6,
          y: h / 2 + math.sin(wAng) * 6,
          vx: math.cos(wAng) * wSp,
          vy: math.sin(wAng) * wSp,
          size: _r(0.8, 2.2),
          life: 4,
        ));
        break;
      case FxKind.rain:
        _ps.add(_mk(
          x: _r(-60, w + 60),
          y: -30,
          vx: -_r(100, 160),
          vy: _r(700, 1000),
          size: _r(1, 1.8),
          r: _r(14, 26),
          life: 8,
        ));
        break;
      case FxKind.embers:
        _ps.add(_mk(
          x: _r(0, w),
          y: h + 10,
          vx: _r(-10, 10),
          vy: -_r(60, 160),
          sw: _r(15, 40),
          size: _r(1.5, 3.5),
          life: _r(2.5, 4.5),
        ));
        break;
      case FxKind.lanterns:
        _ps.add(_mk(
          x: _r(0.05, 0.95) * w,
          y: h + 40,
          vy: -_r(35, 80),
          sw: _r(8, 18),
          size: _r(22, 38),
          life: 40,
        ));
        break;
      case FxKind.butterflies:
        final fromLeft = _rng.nextBool();
        _ps.add(_mk(
          x: fromLeft ? -30 : w + 30,
          y: _r(0.15, 0.85) * h,
          vx: fromLeft ? _r(35, 75) : -_r(35, 75),
          vy: _r(-20, 20),
          sw: _r(20, 45),
          size: _r(10, 18),
          life: 40,
        ));
        break;
      case FxKind.lasers:
        _ps.add(_mk(
          x: _r(0.1, 0.9) * w,
          y: h + 10,
          rot: _r(-0.5, 0.5),
          vrot: _r(-1.2, 1.2),
          size: _r(2, 4),
          life: _r(1.4, 2.6),
        ));
        break;
      case FxKind.sunrays:
        if (_ps.length < 2) {
          _ps.add(_mk(
            x: w / 2,
            y: -h * 0.05,
            size: math.max(w, h) * _r(1.1, 1.5),
            rot: _r(0, math.pi),
            vrot: _r(0.15, 0.35),
            life: 5,
          ));
        }
        break;
      case FxKind.notes:
        _ps.add(_mk(
          x: _r(0, w),
          y: h + 30,
          vy: -_r(50, 120),
          sw: _r(20, 35),
          size: _r(12, 22),
          life: 30,
        ));
        break;
      case FxKind.glitch:
        for (var k = 0; k <= _rng.nextInt(3); k++) {
          _ps.add(_mk(
            x: _r(0, w * 0.5),
            y: _r(0, h),
            r: _r(w * 0.2, w * 0.9),
            size: _r(3, 24),
            life: _r(0.1, 0.32),
          ));
        }
        break;
    }
  }

  void _step(_P p, double dt) {
    // Once the effect is switched off, everything wraps up quickly.
    p.age += widget.active ? dt : dt * 5;
    if (widget.kind == FxKind.spiral) {
      p.r += p.vx * dt;
      p.rot += p.vrot * dt;
      p.x = _size.width / 2 + math.cos(p.rot) * p.r;
      p.y = _size.height * 0.4 + math.sin(p.rot) * p.r;
      return;
    }
    if (widget.kind == FxKind.warp) {
      final k = 1 + dt * 2.2;
      p.vx *= k;
      p.vy *= k;
    }
    p.vy += p.g * dt;
    if (p.drag > 0) {
      final k = math.exp(-p.drag * dt);
      p.vx *= k;
      p.vy *= k;
    }
    final sway = p.sw == 0 ? 0.0 : math.sin(p.age * 1.7 + p.phase) * p.sw;
    p.x += (p.vx + sway) * dt;
    p.y += p.vy * dt;
    p.rot += p.vrot * dt;
  }

  bool _gone(_P p) {
    if (p.dead) return true;
    final w = _size.width;
    final h = _size.height;
    return p.y > h + 200 || p.y < -300 || p.x < -250 || p.x > w + 250;
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;

    if (widget.active && _size.height > 0) {
      _acc += dt * _rate(widget.kind);
      while (_acc >= 1) {
        _acc -= 1;
        if (_ps.length < _maxParticles) _spawn();
      }
    }

    for (final p in _ps) {
      _step(p, dt);
    }
    _ps.removeWhere(_gone);

    if (_flash > 0) _flash = math.max(0, _flash - dt * 2.4);

    if (!widget.active && _ps.isEmpty && _flash <= 0) {
      _ticker.stop();
      _last = Duration.zero;
    }
    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);
          return ClipRect(
            child: CustomPaint(
              size: Size.infinite,
              painter: _FxPainter(
                kind: widget.kind,
                ps: _ps,
                time: () => _time,
                flash: () => _flash,
                repaint: _repaint,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── painter ─────────────────────────

const List<Color> _rainbow = [
  Color(0xFFFF5252),
  Color(0xFFFF9800),
  Color(0xFFFFEB3B),
  Color(0xFF4CAF50),
  Color(0xFF00BCD4),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFFE91E63),
];

List<Color> _palette(FxKind k) {
  switch (k) {
    case FxKind.hearts:
      return const [
        Color(0xFFFF5C8A),
        Color(0xFFFF2E63),
        Color(0xFFF48FB1),
        Color(0xFFE91E63),
      ];
    case FxKind.coins:
      return const [Color(0xFFFFD54F), Color(0xFFFFCA28), Color(0xFFFFB300)];
    case FxKind.leaves:
      return const [
        Color(0xFF66BB6A),
        Color(0xFF9CCC65),
        Color(0xFFFFB74D),
        Color(0xFFF57C00),
        Color(0xFF8D6E63),
      ];
    case FxKind.sakura:
      return const [Color(0xFFF8BBD0), Color(0xFFF48FB1), Color(0xFFFCE4EC)];
    case FxKind.snow:
      return const [Color(0xFFFFFFFF), Color(0xFFE3F2FD)];
    case FxKind.bubbles:
      return const [Color(0xFF4DD0E1), Color(0xFF81D4FA), Color(0xFFB39DDB)];
    case FxKind.sparkles:
      return [
        const Color(0xFFFFD54F),
        const Color(0xFFFFFFFF),
        AppColors.accent,
        const Color(0xFFFFF59D),
      ];
    case FxKind.fireflies:
      return const [Color(0xFFFFEE58), Color(0xFFC6FF00), Color(0xFFFFCA28)];
    case FxKind.matrix:
      return const [Color(0xFF00E676), Color(0xFF00C853), Color(0xFF69F0AE)];
    case FxKind.meteors:
      return const [Color(0xFFFFFFFF), Color(0xFF80D8FF), Color(0xFFFFF59D)];
    case FxKind.lightning:
      return const [Color(0xFFFFFFFF), Color(0xFF80D8FF)];
    case FxKind.ripples:
      return [AppColors.accent, const Color(0xFF26C6DA), const Color(0xFF7C4DFF)];
    case FxKind.pulse:
      return [AppColors.accent, const Color(0xFFFF4081)];
    case FxKind.bokeh:
      return [
        AppColors.accent,
        const Color(0xFFFFD54F),
        const Color(0xFFFF80AB),
        const Color(0xFF80D8FF),
        const Color(0xFFB388FF),
      ];
    case FxKind.fireworks:
    case FxKind.starBurst:
    case FxKind.balloons:
    case FxKind.rainbow:
    case FxKind.spiral:
      return _rainbow;
    case FxKind.aurora:
      return [
        const Color(0xFF00E676),
        const Color(0xFF1DE9B6),
        const Color(0xFF7C4DFF),
        AppColors.accent,
      ];
    case FxKind.warp:
      return const [Color(0xFFFFFFFF), Color(0xFF80D8FF), Color(0xFFB388FF)];
    case FxKind.rain:
      return const [Color(0xFF64B5F6), Color(0xFF90CAF9), Color(0xFF42A5F5)];
    case FxKind.embers:
      return const [
        Color(0xFFFF6D00),
        Color(0xFFFF9100),
        Color(0xFFFFD600),
        Color(0xFFFF3D00),
      ];
    case FxKind.lanterns:
      return const [Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFFF6F00)];
    case FxKind.butterflies:
      return const [
        Color(0xFFFF80AB),
        Color(0xFF80D8FF),
        Color(0xFFFFD740),
        Color(0xFFB388FF),
        Color(0xFF69F0AE),
      ];
    case FxKind.lasers:
      return const [
        Color(0xFFFF1744),
        Color(0xFF00E5FF),
        Color(0xFF76FF03),
        Color(0xFFD500F9),
      ];
    case FxKind.sunrays:
      return const [Color(0xFFFFD54F), Color(0xFFFFF176)];
    case FxKind.glitch:
      return const [Color(0xFF00E5FF), Color(0xFF76FF03), Color(0xFFD500F9)];
    case FxKind.notes:
    case FxKind.disco:
      return _rainbow;
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.kind,
    required this.ps,
    required this.time,
    required this.flash,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final FxKind kind;
  final List<_P> ps;
  final double Function() time;
  final double Function() flash;
  final Paint _paint = Paint();

  static Color _al(Color c, double a) => c.withValues(alpha: a.clamp(0.0, 1.0));

  // ignore: unused_element_parameter
  void _fill(Canvas canvas, Color c, void Function() draw) {
    _paint
      ..style = PaintingStyle.fill
      ..color = c
      ..maskFilter = null;
    draw();
  }

  Path _star(double rOuter, double rInner, int points) {
    final path = Path();
    final n = points * 2;
    for (var i = 0; i < n; i++) {
      final rad = i.isEven ? rOuter : rInner;
      final ang = -math.pi / 2 + i * math.pi / points;
      final pt = Offset(math.cos(ang) * rad, math.sin(ang) * rad);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path..close();
  }

  Path _heart(double s) {
    return Path()
      ..moveTo(0, s * 0.45)
      ..cubicTo(-s * 1.0, -s * 0.1, -s * 0.55, -s * 0.75, 0, -s * 0.25)
      ..cubicTo(s * 0.55, -s * 0.75, s * 1.0, -s * 0.1, 0, s * 0.45)
      ..close();
  }

  Path _leaf(double s) {
    return Path()
      ..moveTo(0, -s)
      ..quadraticBezierTo(s * 0.9, -s * 0.2, 0, s)
      ..quadraticBezierTo(-s * 0.9, -s * 0.2, 0, -s)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pal = _palette(kind);

    for (final p in ps) {
      final col = pal[p.c % pal.length];
      switch (kind) {
        case FxKind.fireworks:
          _drawSpark(canvas, p, col, p.fadeOut);
          break;
        case FxKind.starBurst:
          _drawStar(canvas, p, col, p.fadeOut, 5, 0.45);
          break;
        case FxKind.sparkles:
          _drawSparkle(canvas, p, col);
          break;
        case FxKind.bubbles:
          _drawBubble(canvas, p, col, p.fade);
          break;
        case FxKind.snow:
          _drawSnow(canvas, p, col, p.fade);
          break;
        case FxKind.hearts:
          _drawHeart(canvas, p, col, p.fade);
          break;
        case FxKind.balloons:
          _drawBalloon(canvas, p, col, p.fade);
          break;
        case FxKind.coins:
          _drawCoin(canvas, p, col, p.fade);
          break;
        case FxKind.leaves:
          _drawLeaf(canvas, p, col, p.fade);
          break;
        case FxKind.sakura:
          _drawSakura(canvas, p, col, p.fade);
          break;
        case FxKind.lightning:
          _drawBolt(canvas, p, col);
          break;
        case FxKind.rainbow:
          _drawRainbow(canvas, p);
          break;
        case FxKind.ripples:
          _drawRipple(canvas, p, col);
          break;
        case FxKind.spiral:
          _drawSpark(canvas, p, col, p.fade);
          break;
        case FxKind.meteors:
          _drawMeteor(canvas, p, col, p.fade);
          break;
        case FxKind.fireflies:
          _drawFirefly(canvas, p, col, p.fade);
          break;
        case FxKind.disco:
          _drawDisco(canvas, p, col);
          break;
        case FxKind.matrix:
          _drawMatrix(canvas, p, col, p.fade);
          break;
        case FxKind.bokeh:
          _drawBokeh(canvas, p, col, p.fade);
          break;
        case FxKind.pulse:
          _drawPulse(canvas, p, col);
          break;
        case FxKind.aurora:
          _drawAurora(canvas, p, col, size);
          break;
        case FxKind.warp:
          _drawWarp(canvas, p, col);
          break;
        case FxKind.rain:
          _drawRain(canvas, p, col);
          break;
        case FxKind.embers:
          _drawEmber(canvas, p, col);
          break;
        case FxKind.lanterns:
          _drawLantern(canvas, p, col, p.fade);
          break;
        case FxKind.butterflies:
          _drawButterfly(canvas, p, col, p.fade);
          break;
        case FxKind.lasers:
          _drawLaser(canvas, p, col, size);
          break;
        case FxKind.sunrays:
          _drawSunrays(canvas, p, col);
          break;
        case FxKind.notes:
          _drawNote(canvas, p, col, p.fade);
          break;
        case FxKind.glitch:
          _drawGlitch(canvas, p, col);
          break;
      }
    }

    final f = flash();
    if (f > 0) {
      _fill(canvas, _al(const Color(0xFFFFFFE0), f * 0.6),
          () => canvas.drawRect(Offset.zero & size, _paint));
    }
  }

  // ── individual shapes ──

  void _drawSpark(Canvas canvas, _P p, Color col, double a) {
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, a * 0.25), () => canvas.drawCircle(o, p.size * 2.4, _paint));
    _fill(canvas, _al(col, a), () => canvas.drawCircle(o, p.size, _paint));
  }

  void _drawStar(Canvas canvas, _P p, Color col, double a, int pts, double inner) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rot);
    _fill(canvas, _al(col, a), () => canvas.drawPath(_star(p.size, p.size * inner, pts), _paint));
    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, _P p, Color col) {
    final s = math.sin(math.pi * (p.age / p.life).clamp(0.0, 1.0));
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rot + p.age * p.vrot);
    _fill(canvas, _al(col, 0.25 * s),
        () => canvas.drawCircle(Offset.zero, p.size * s * 0.9, _paint));
    _fill(canvas, _al(col, s),
        () => canvas.drawPath(_star(p.size * s, p.size * s * 0.22, 4), _paint));
    canvas.restore();
  }

  void _drawBubble(Canvas canvas, _P p, Color col, double a) {
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, a * 0.14), () => canvas.drawCircle(o, p.size, _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _al(col, a * 0.75);
    canvas.drawCircle(o, p.size, _paint);
    _fill(canvas, _al(const Color(0xFFFFFFFF), a * 0.85),
        () => canvas.drawCircle(o + Offset(-p.size * 0.35, -p.size * 0.35), p.size * 0.18, _paint));
  }

  void _drawSnow(Canvas canvas, _P p, Color col, double a) {
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, a), () => canvas.drawCircle(o, p.size, _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _al(const Color(0xFF90CAF9), a * 0.8);
    canvas.drawCircle(o, p.size, _paint);
  }

  void _drawHeart(Canvas canvas, _P p, Color col, double a) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(math.sin(p.age * 2 + p.phase) * 0.3);
    _fill(canvas, _al(col, a), () => canvas.drawPath(_heart(p.size), _paint));
    _fill(canvas, _al(const Color(0xFFFFFFFF), a * 0.5),
        () => canvas.drawCircle(Offset(-p.size * 0.35, -p.size * 0.2), p.size * 0.12, _paint));
    canvas.restore();
  }

  void _drawBalloon(Canvas canvas, _P p, Color col, double a) {
    final s = p.size;
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(math.sin(p.age * 1.4 + p.phase) * 0.12);
    // string
    final string = Path()
      ..moveTo(0, s * 0.62)
      ..quadraticBezierTo(math.sin(p.age * 2 + p.phase) * 7, s * 0.95, 0, s * 1.3);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = null
      ..color = _al(const Color(0xFF9E9E9E), a * 0.8);
    canvas.drawPath(string, _paint);
    // body
    final body = Rect.fromCenter(center: Offset.zero, width: s * 0.82, height: s);
    _fill(canvas, _al(col, a), () => canvas.drawOval(body, _paint));
    // knot
    final knot = Path()
      ..moveTo(0, s * 0.5)
      ..lineTo(-s * 0.07, s * 0.62)
      ..lineTo(s * 0.07, s * 0.62)
      ..close();
    _fill(canvas, _al(col, a), () => canvas.drawPath(knot, _paint));
    // shine
    _fill(
      canvas,
      _al(const Color(0xFFFFFFFF), a * 0.4),
      () => canvas.drawOval(
        Rect.fromCenter(center: Offset(-s * 0.15, -s * 0.2), width: s * 0.16, height: s * 0.28),
        _paint,
      ),
    );
    canvas.restore();
  }

  void _drawCoin(Canvas canvas, _P p, Color col, double a) {
    final wFactor = math.cos(p.age * 5 + p.phase).abs().clamp(0.12, 1.0);
    final rect = Rect.fromCenter(
      center: Offset(p.x, p.y),
      width: p.size * wFactor,
      height: p.size,
    );
    _fill(canvas, _al(col, a), () => canvas.drawOval(rect, _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _al(const Color(0xFFB26A00), a);
    canvas.drawOval(rect, _paint);
    if (wFactor > 0.4) {
      canvas.drawOval(rect.deflate(p.size * 0.18 * wFactor), _paint..strokeWidth = 1);
    }
  }

  void _drawLeaf(Canvas canvas, _P p, Color col, double a) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rot);
    _fill(canvas, _al(col, a), () => canvas.drawPath(_leaf(p.size), _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _al(const Color(0xFF000000), a * 0.25);
    canvas.drawLine(Offset(0, -p.size), Offset(0, p.size), _paint);
    canvas.restore();
  }

  void _drawSakura(Canvas canvas, _P p, Color col, double a) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rot);
    _fill(canvas, _al(col, a), () {
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.rotate(i * math.pi * 2 / 5);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -p.size * 0.6),
            width: p.size * 0.9,
            height: p.size * 1.1,
          ),
          _paint,
        );
        canvas.restore();
      }
    });
    _fill(canvas, _al(const Color(0xFFFFC107), a), () => canvas.drawCircle(Offset.zero, p.size * 0.22, _paint));
    canvas.restore();
  }

  void _drawBolt(Canvas canvas, _P p, Color col) {
    final pts = p.pts;
    if (pts == null || pts.length < 2) return;
    final life = (p.age / p.life).clamp(0.0, 1.0);
    final flick = (p.age % 0.14) < 0.07 ? 1.0 : 0.45;
    final a = flick * (1 - life);
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    _paint
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = _al(const Color(0xFF80D8FF), a * 0.7);
    canvas.drawPath(path, _paint);
    _paint
      ..maskFilter = null
      ..strokeWidth = 2.6
      ..color = _al(const Color(0xFFFFFFFF), a);
    canvas.drawPath(path, _paint);
  }

  void _drawRainbow(Canvas canvas, _P p) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final sweep = Curves.easeOutCubic.transform((t / 0.45).clamp(0.0, 1.0));
    final a = (t < 0.75 ? 1.0 : (1 - t) / 0.25) * 0.85;
    final bw = p.size * 0.07;
    for (var i = 0; i < 7; i++) {
      final radius = p.size - i * bw;
      _paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..maskFilter = null
        ..strokeWidth = bw + 0.8
        ..color = _al(_rainbow[i], a);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(p.x, p.y), radius: radius),
        math.pi,
        math.pi * sweep,
        false,
        _paint,
      );
    }
  }

  void _drawRipple(Canvas canvas, _P p, Color col) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final e = Curves.easeOut.transform(t);
    final a = 1 - t;
    _paint
      ..style = PaintingStyle.stroke
      ..maskFilter = null
      ..strokeWidth = 3 * a + 0.8
      ..color = _al(col, a * 0.9);
    canvas.drawCircle(Offset(p.x, p.y), p.size * e, _paint);
    _paint
      ..strokeWidth = 1.6 * a + 0.5
      ..color = _al(col, a * 0.6);
    canvas.drawCircle(Offset(p.x, p.y), p.size * e * 0.62, _paint);
  }

  void _drawMeteor(Canvas canvas, _P p, Color col, double a) {
    final len = math.sqrt(p.vx * p.vx + p.vy * p.vy);
    if (len == 0) return;
    final dx = p.vx / len;
    final dy = p.vy / len;
    const n = 10;
    for (var i = 0; i < n; i++) {
      final k = i / n;
      final o = Offset(p.x - dx * p.r * k, p.y - dy * p.r * k);
      _fill(canvas, _al(col, a * (1 - k) * 0.9),
          () => canvas.drawCircle(o, p.size * (1 - k * 0.7), _paint));
    }
    _fill(canvas, _al(col, a * 0.25), () => canvas.drawCircle(Offset(p.x, p.y), p.size * 3, _paint));
  }

  void _drawFirefly(Canvas canvas, _P p, Color col, double a) {
    final pulse = 0.5 + 0.5 * math.sin(p.age * 3 + p.phase);
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, a * pulse * 0.28), () => canvas.drawCircle(o, p.size * 4, _paint));
    _fill(canvas, _al(col, a * (0.4 + 0.6 * pulse)), () => canvas.drawCircle(o, p.size, _paint));
  }

  void _drawDisco(Canvas canvas, _P p, Color col) {
    final s = math.sin(math.pi * (p.age / p.life).clamp(0.0, 1.0));
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, s * 0.5), () => canvas.drawCircle(o, p.size * (0.7 + 0.3 * s), _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _al(const Color(0xFFFFFFFF), s * 0.7);
    canvas.drawCircle(o, p.size * (0.7 + 0.3 * s), _paint);
  }

  void _drawMatrix(Canvas canvas, _P p, Color col, double a) {
    final seg = p.size * 1.5;
    final n = p.r.round();
    for (var i = 0; i < n; i++) {
      final k = i / n;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(p.x, p.y - i * seg),
          width: p.size * 0.8,
          height: p.size * 1.1,
        ),
        const Radius.circular(2),
      );
      final c = i == 0 ? const Color(0xFFE8FFF0) : col;
      _fill(canvas, _al(c, a * (1 - k) * 0.9), () => canvas.drawRRect(rect, _paint));
    }
  }

  void _drawBokeh(Canvas canvas, _P p, Color col, double a) {
    final o = Offset(p.x, p.y);
    final pulse = 0.85 + 0.15 * math.sin(p.age * 1.5 + p.phase);
    _fill(canvas, _al(col, a * 0.18), () => canvas.drawCircle(o, p.size * pulse, _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _al(col, a * 0.4);
    canvas.drawCircle(o, p.size * pulse, _paint);
  }

  void _drawPulse(Canvas canvas, _P p, Color col) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final e = Curves.easeOutQuad.transform(t);
    final a = 1 - t;
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, a * 0.09), () => canvas.drawCircle(o, p.size * e, _paint));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * a + 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = _al(col, a * 0.55);
    canvas.drawCircle(o, p.size * e, _paint);
    _paint
      ..strokeWidth = 8 * a + 1
      ..color = _al(col, a * 0.4);
    canvas.drawCircle(o, p.size * e * 0.7, _paint);
    _paint.maskFilter = null;
  }

  // ───────── 10 more effects ─────────

  void _drawAurora(Canvas canvas, _P p, Color col, Size size) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final a = math.sin(math.pi * t);
    const step = 14.0;
    final top = <Offset>[];
    for (double x = -step; x <= size.width + step; x += step) {
      final y = p.y +
          math.sin(x * 0.012 + p.age * 1.1 + p.phase) * 22 +
          math.sin(x * 0.027 - p.age * 0.7) * 10;
      top.add(Offset(x, y));
    }
    final path = Path()..moveTo(top.first.dx, top.first.dy);
    for (final o in top.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    for (final o in top.reversed) {
      path.lineTo(o.dx, o.dy + p.size);
    }
    path.close();
    _paint
      ..style = PaintingStyle.fill
      ..maskFilter = null
      ..shader = ui.Gradient.linear(
        Offset(0, p.y - 30),
        Offset(0, p.y + p.size + 30),
        [_al(col, 0), _al(col, a * 0.5), _al(col, 0)],
        const [0.0, 0.35, 1.0],
      );
    canvas.drawPath(path, _paint);
    _paint.shader = null;
  }

  void _drawWarp(Canvas canvas, _P p, Color col) {
    final sp = math.sqrt(p.vx * p.vx + p.vy * p.vy);
    if (sp == 0) return;
    final dx = p.vx / sp;
    final dy = p.vy / sp;
    final len = (sp * 0.05).clamp(2.0, 90.0);
    final a = (p.age / 0.5).clamp(0.0, 1.0);
    _paint
      ..style = PaintingStyle.stroke
      ..maskFilter = null
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (p.size * (1 + sp / 450)).clamp(0.8, 4.5)
      ..color = _al(col, a);
    canvas.drawLine(Offset(p.x - dx * len, p.y - dy * len), Offset(p.x, p.y), _paint);
  }

  void _drawRain(Canvas canvas, _P p, Color col) {
    final sp = math.sqrt(p.vx * p.vx + p.vy * p.vy);
    if (sp == 0) return;
    final dx = p.vx / sp;
    final dy = p.vy / sp;
    _paint
      ..style = PaintingStyle.stroke
      ..maskFilter = null
      ..strokeCap = StrokeCap.round
      ..strokeWidth = p.size
      ..color = _al(col, 0.6);
    canvas.drawLine(Offset(p.x - dx * p.r, p.y - dy * p.r), Offset(p.x, p.y), _paint);
  }

  void _drawEmber(Canvas canvas, _P p, Color col) {
    final k = (1 - p.age / p.life).clamp(0.0, 1.0);
    final flick = 0.7 + 0.3 * math.sin(p.age * 18 + p.phase);
    final o = Offset(p.x, p.y);
    _fill(canvas, _al(col, k * 0.28 * flick), () => canvas.drawCircle(o, p.size * 4 * k + 1, _paint));
    _fill(canvas, _al(col, k * flick), () => canvas.drawCircle(o, p.size * (0.5 + 0.5 * k), _paint));
  }

  void _drawLantern(Canvas canvas, _P p, Color col, double a) {
    final s = p.size;
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(math.sin(p.age * 1.2 + p.phase) * 0.08);
    _fill(canvas, _al(col, a * 0.22), () => canvas.drawCircle(Offset.zero, s * 1.5, _paint));
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.8, height: s),
      Radius.circular(s * 0.22),
    );
    _fill(canvas, _al(col, a * 0.92), () => canvas.drawRRect(body, _paint));
    _fill(
      canvas,
      _al(const Color(0xFFFFF3C4), a * 0.55),
      () => canvas.drawOval(
        Rect.fromCenter(center: Offset(0, s * 0.05), width: s * 0.42, height: s * 0.62),
        _paint,
      ),
    );
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _al(const Color(0xFF8D4B00), a * 0.7);
    canvas.drawLine(Offset(-s * 0.4, -s * 0.5), Offset(s * 0.4, -s * 0.5), _paint);
    canvas.drawLine(Offset(-s * 0.4, s * 0.5), Offset(s * 0.4, s * 0.5), _paint);
    canvas.restore();
  }

  void _drawButterfly(Canvas canvas, _P p, Color col, double a) {
    final s = p.size;
    final flap = 0.25 + 0.75 * math.sin(p.age * 10 + p.phase).abs();
    final yy = p.y + math.sin(p.age * 2 + p.phase) * 18;
    canvas.save();
    canvas.translate(p.x, yy);
    canvas.rotate(math.sin(p.age * 2 + p.phase) * 0.2);
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(flap, 1);
      _fill(canvas, _al(col, a * 0.9), () {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(side * s * 0.5, -s * 0.3), width: s * 0.9, height: s * 1.0),
          _paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(side * s * 0.4, s * 0.4), width: s * 0.65, height: s * 0.7),
          _paint,
        );
      });
      _fill(
        canvas,
        _al(const Color(0xFFFFFFFF), a * 0.45),
        () => canvas.drawCircle(Offset(side * s * 0.55, -s * 0.35), s * 0.14, _paint),
      );
      canvas.restore();
    }
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _al(const Color(0xFF37474F), a);
    canvas.drawLine(Offset(0, -s * 0.45), Offset(0, s * 0.6), _paint);
    canvas.restore();
  }

  void _drawLaser(Canvas canvas, _P p, Color col, Size size) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final a = math.sin(math.pi * t);
    final len = size.height * 1.5;
    final end = Offset(p.x + math.sin(p.rot) * len, p.y - math.cos(p.rot) * len);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..strokeWidth = p.size * 4
      ..color = _al(col, a * 0.35);
    canvas.drawLine(Offset(p.x, p.y), end, _paint);
    _paint
      ..maskFilter = null
      ..strokeWidth = p.size
      ..color = _al(col, a * 0.95);
    canvas.drawLine(Offset(p.x, p.y), end, _paint);
  }

  void _drawSunrays(Canvas canvas, _P p, Color col) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final a = math.sin(math.pi * t) * 0.22;
    final o = Offset(p.x, p.y);
    final path = Path();
    const rays = 9;
    for (var i = 0; i < rays; i++) {
      final ang = p.rot + i * math.pi * 2 / rays;
      const half = 0.11;
      path
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + math.cos(ang - half) * p.size, o.dy + math.sin(ang - half) * p.size)
        ..lineTo(o.dx + math.cos(ang + half) * p.size, o.dy + math.sin(ang + half) * p.size)
        ..close();
    }
    _paint
      ..style = PaintingStyle.fill
      ..maskFilter = null
      ..shader = ui.Gradient.radial(o, p.size, [_al(col, a), _al(col, 0)]);
    canvas.drawPath(path, _paint);
    _paint.shader = null;
  }

  void _drawNote(Canvas canvas, _P p, Color col, double a) {
    final s = p.size;
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(math.sin(p.age * 2 + p.phase) * 0.25);
    final c = _al(col, a);
    _paint
      ..style = PaintingStyle.fill
      ..maskFilter = null
      ..color = c;
    if (p.c.isEven) {
      // single eighth note
      canvas.save();
      canvas.translate(0, s * 0.5);
      canvas.rotate(-0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.9, height: s * 0.62), _paint);
      canvas.restore();
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(s * 0.4, s * 0.42), Offset(s * 0.4, -s * 0.85), _paint);
      final flag = Path()
        ..moveTo(s * 0.4, -s * 0.85)
        ..quadraticBezierTo(s * 1.0, -s * 0.5, s * 0.8, -s * 0.05);
      canvas.drawPath(flag, _paint);
    } else {
      // two beamed notes
      for (final dx in const [-0.45, 0.55]) {
        canvas.save();
        canvas.translate(s * dx, s * (dx < 0 ? 0.55 : 0.35));
        canvas.rotate(-0.4);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.8, height: s * 0.55), _paint);
        canvas.restore();
      }
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.11
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(-s * 0.12, s * 0.48), Offset(-s * 0.12, -s * 0.8), _paint);
      canvas.drawLine(Offset(s * 0.88, s * 0.28), Offset(s * 0.88, -s * 1.0), _paint);
      canvas.drawLine(Offset(-s * 0.12, -s * 0.8), Offset(s * 0.88, -s * 1.0), _paint..strokeWidth = s * 0.2);
    }
    canvas.restore();
  }

  void _drawGlitch(Canvas canvas, _P p, Color col) {
    final t = (p.age / p.life).clamp(0.0, 1.0);
    final a = (1 - t) * 0.5;
    _fill(canvas, _al(col, a),
        () => canvas.drawRect(Rect.fromLTWH(p.x, p.y, p.r, p.size), _paint));
    _fill(canvas, _al(const Color(0xFFFF1744), a * 0.7),
        () => canvas.drawRect(Rect.fromLTWH(p.x + 7, p.y + 1.5, p.r, p.size), _paint));
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => true;
}

// ───────────────────────── settings preview ─────────────────────────

/// Small preview box (Settings page) for one particle effect.
class FxPreview extends StatefulWidget {
  const FxPreview({super.key, required this.kind, required this.button});

  final FxKind kind;
  final Widget Function(bool running, VoidCallback toggle) button;

  @override
  State<FxPreview> createState() => _FxPreviewState();
}

class _FxPreviewState extends State<FxPreview> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: FxOverlay(active: _running, kind: widget.kind),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        widget.button(_running, () => setState(() => _running = !_running)),
      ],
    );
  }
}
