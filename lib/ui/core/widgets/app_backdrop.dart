import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pipes/domain/models/app_settings.dart';

/// Background drawn BEHIND every page.
///  • normal themes  → plain colour
///  • "mix" themes   → gradient bg → bg2
///  • "live" themes  → gradient + a slow, low-contrast animation
/// The game board and all panels are opaque and drawn on top, so the game
/// always stays fully visible.
class AppBackdrop extends StatefulWidget {
  const AppBackdrop({super.key, required this.preset});

  final AppThemePreset preset;

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final List<_Star> _stars;
  Duration _lastFrame = Duration.zero;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _stars = List.generate(
      70,
      (_) => _Star(
        rng.nextDouble(),
        rng.nextDouble() * 0.7,
        0.6 + rng.nextDouble() * 1.4,
        rng.nextDouble() * math.pi * 2,
      ),
    );
    // ~30 fps is plenty for these slow animations and halves the work.
    // A restarted Ticker counts from zero again, so every start resets the
    // frame throttle and continues from the last animation time. (Without
    // this the throttle compared against a stale, larger value and the
    // animation stayed frozen after switching live → normal → live theme.)
    _ticker = createTicker((d) {
      if (d < _lastFrame) _lastFrame = Duration.zero;
      if (d != Duration.zero && (d - _lastFrame).inMilliseconds < 33) return;
      _lastFrame = d;
      _time.value = _timeBase + d.inMicroseconds / 1e6;
    });
    if (widget.preset.live != null) _startTicker();
  }

  double _timeBase = 0;

  void _startTicker() {
    if (_ticker.isActive) return;
    _lastFrame = Duration.zero;
    _timeBase = _time.value;
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant AppBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = widget.preset.live != null;
    if (live) {
      _startTicker();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.preset;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.bg2 == null ? p.bg : null,
          gradient: p.bg2 == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.bg, p.bg2!],
                ),
        ),
        child: p.live == null
            ? const SizedBox.expand()
            : CustomPaint(
                size: Size.infinite,
                painter: _LivePainter(
                  live: p.live!,
                  preset: p,
                  stars: _stars,
                  time: _time,
                ),
              ),
      ),
    );
  }
}

class _Star {
  const _Star(this.x, this.y, this.r, this.phase);
  final double x, y, r, phase;
}

class _LivePainter extends CustomPainter {
  _LivePainter({
    required this.live,
    required this.preset,
    required this.stars,
    required this.time,
  }) : super(repaint: time);

  final LiveBg live;
  final AppThemePreset preset;
  final List<_Star> stars;
  final ValueNotifier<double> time;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    switch (live) {
      case LiveBg.aurora:
        _aurora(canvas, size, time.value);
        break;
      case LiveBg.waves:
        _waves(canvas, size, time.value);
        break;
      case LiveBg.butterfly:
        _butterfly(canvas, size, time.value);
        break;
      case LiveBg.goldfish:
        _goldfish(canvas, size, time.value);
        break;
    }
  }

  // ── Aurora: twinkling stars + three slowly waving light curtains ──
  void _aurora(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    for (final s in stars) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 1.4 + s.phase));
      _paint
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.55 * tw);
      canvas.drawCircle(Offset(s.x * w, s.y * h), s.r, _paint);
    }

    final colors = <Color>[
      preset.accent,
      const Color(0xFF7C4DFF),
      const Color(0xFF40C4FF),
    ];
    for (var k = 0; k < 3; k++) {
      final base = h * (0.16 + k * 0.13);
      final thick = h * 0.26;
      final ph = k * 2.1;
      final top = <Offset>[];
      for (double x = -12; x <= w + 12; x += 12) {
        final y = base +
            math.sin(x * 0.010 + t * 0.55 + ph) * 26 +
            math.sin(x * 0.024 - t * 0.38 + ph * 1.7) * 12;
        top.add(Offset(x, y));
      }
      final path = Path()..moveTo(top.first.dx, top.first.dy);
      for (final o in top.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      for (final o in top.reversed) {
        path.lineTo(o.dx, o.dy + thick);
      }
      path.close();
      final breathe = 0.75 + 0.25 * math.sin(t * 0.6 + ph);
      _paint
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(0, base - 30),
          Offset(0, base + thick + 20),
          [
            colors[k].withValues(alpha: 0.0),
            colors[k].withValues(alpha: 0.30 * breathe),
            colors[k].withValues(alpha: 0.0),
          ],
          const [0.0, 0.35, 1.0],
        );
      canvas.drawPath(path, _paint);
    }
    _paint.shader = null;
  }

  // ── Waves: layered moving waves at the bottom + rising bubbles ──
  void _waves(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // soft sun glow
    _paint
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.radial(
        Offset(w * 0.82, h * 0.10),
        w * 0.55,
        [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Offset.zero & size, _paint);
    _paint.shader = null;

    // bubbles
    for (var i = 0; i < 14; i++) {
      final speed = 14 + (i * 7 % 17);
      final r = 4.0 + (i * 5 % 9);
      final bx = ((i * 0.137 + 0.05) % 1.0) * w;
      final y = h + 20 - ((t * speed + i * 83) % (h + 40));
      final x = bx + math.sin(t * 0.8 + i) * 12;
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = preset.accent.withValues(alpha: 0.28);
      canvas.drawCircle(Offset(x, y), r, _paint);
    }

    // wave layers
    final layers = <(double, double, double, double, Color)>[
      (0.74, 14, 1.10, 0.5, preset.accent.withValues(alpha: 0.10)),
      (0.80, 16, 0.85, -0.7, preset.primary.withValues(alpha: 0.28)),
      (0.86, 12, 1.30, 0.9, preset.accent.withValues(alpha: 0.14)),
      (0.92, 10, 1.00, -1.1, preset.primary.withValues(alpha: 0.42)),
    ];
    for (var k = 0; k < layers.length; k++) {
      final (yf, amp, len, speed, color) = layers[k];
      final path = Path()..moveTo(0, h);
      for (double x = 0; x <= w + 8; x += 8) {
        final y = h * yf +
            math.sin((x / w) * math.pi * 2 / len * 1.6 + t * speed + k) * amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      _paint
        ..style = PaintingStyle.fill
        ..color = color;
      canvas.drawPath(path, _paint);
    }
  }

  // ── Butterfly: one big glowing butterfly drifting across a night sky ──
  void _butterfly(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // floating light motes
    for (final s in stars) {
      final y = ((s.y / 0.7) * h - t * 8 * s.r) % h;
      final x = s.x * w + math.sin(t * 0.6 + s.phase) * 10;
      final pulse = 0.5 + 0.5 * math.sin(t * 1.6 + s.phase);
      _paint
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = preset.accent.withValues(alpha: 0.10 + 0.28 * pulse);
      canvas.drawCircle(Offset(x, y), s.r * 1.1, _paint);
    }

    final r = math.min(w, h) * 0.52;
    final cx = w * (0.5 + 0.22 * math.sin(t * 0.32));
    final cy = h * (0.36 + 0.14 * math.sin(t * 0.47 + 1.0));
    final tilt = 0.22 * math.sin(t * 0.6);
    final f = 0.22 + 0.78 * (0.5 + 0.5 * math.cos(t * 3.0)); // wing flap 0.22..1

    // soft glow behind
    _paint
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        r * 1.15,
        [
          preset.accent.withValues(alpha: 0.20),
          preset.accent.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(Offset(cx, cy), r * 1.15, _paint);
    _paint.shader = null;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tilt);
    for (final side in const [1.0, -1.0]) {
      canvas.save();
      canvas.scale(side * f, 1);
      _wing(canvas, r);
      canvas.restore();
    }
    // body + head + antennae
    _paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE8EAF6).withValues(alpha: 0.92);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, r * 0.05), width: r * 0.07, height: r * 0.56),
      _paint,
    );
    canvas.drawCircle(Offset(0, -r * 0.25), r * 0.045, _paint);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE8EAF6).withValues(alpha: 0.85);
    for (final s in const [-1.0, 1.0]) {
      final a = Path()
        ..moveTo(0, -r * 0.28)
        ..quadraticBezierTo(s * r * 0.08, -r * 0.42, s * r * 0.20, -r * 0.46);
      canvas.drawPath(a, _paint);
    }
    canvas.restore();
  }

  void _wing(Canvas canvas, double r) {
    final upper = Path()
      ..moveTo(r * 0.04, -r * 0.05)
      ..cubicTo(r * 0.35, -r * 0.78, r * 1.0, -r * 0.88, r * 0.95, -r * 0.25)
      ..cubicTo(r * 0.9, r * 0.10, r * 0.45, r * 0.16, r * 0.04, r * 0.02)
      ..close();
    final lower = Path()
      ..moveTo(r * 0.04, r * 0.02)
      ..cubicTo(r * 0.55, 0, r * 0.88, r * 0.30, r * 0.62, r * 0.66)
      ..cubicTo(r * 0.42, r * 0.96, r * 0.12, r * 0.62, r * 0.04, r * 0.16)
      ..close();
    _paint
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(r, -r * 0.4),
        const [Color(0xE64FC3F7), Color(0xE67C4DFF), Color(0xE6FF4081)],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawPath(upper, _paint);
    canvas.drawPath(lower, _paint);
    _paint.shader = null;

    // veins
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.28);
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(r * 0.05, -r * 0.02),
        Offset(r * (0.55 + 0.10 * i), -r * (0.72 - 0.13 * i)),
        _paint,
      );
    }
    // outline
    _paint
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawPath(upper, _paint);
    canvas.drawPath(lower, _paint);
    // spots
    _paint
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(r * 0.72, -r * 0.45), r * 0.075, _paint);
    canvas.drawCircle(Offset(r * 0.55, -r * 0.62), r * 0.045, _paint);
    canvas.drawCircle(Offset(r * 0.48, r * 0.42), r * 0.06, _paint);
  }

  // ── Goldfish: two goldfish swimming in a pond ──
  void _goldfish(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // drifting light patches (caustics)
    for (var i = 0; i < 5; i++) {
      final cx = w * ((i * 0.23 + 0.10 + 0.05 * math.sin(t * 0.3 + i)) % 1.0);
      final cy = h * ((i * 0.37 + 0.20 + 0.04 * math.cos(t * 0.25 + i)) % 1.0);
      _paint
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          w * 0.35,
          [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.0)],
        );
      canvas.drawCircle(Offset(cx, cy), w * 0.35, _paint);
    }
    _paint.shader = null;

    // ripples
    const spots = [Offset(0.30, 0.30), Offset(0.72, 0.58), Offset(0.40, 0.78)];
    for (var i = 0; i < spots.length; i++) {
      final ph = ((t + i * 1.7) % 5.0) / 5.0;
      final c = Offset(spots[i].dx * w, spots[i].dy * h);
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: (1 - ph) * 0.30);
      canvas.drawCircle(c, 12 + ph * 80, _paint);
      canvas.drawCircle(c, 6 + ph * 52, _paint);
    }

    // fish (drawn first so lily pads float above them)
    _fish(canvas, w, h, t, cx: 0.5, cy: 0.48, a: 0.32, b: 0.26, sa: 0.34, sb: 0.27, ph: 0.0,
        body: const Color(0xFFFF6F00), belly: const Color(0xFFFFB300));
    _fish(canvas, w, h, t, cx: 0.5, cy: 0.58, a: 0.30, b: 0.24, sa: 0.29, sb: 0.40, ph: 2.4,
        body: const Color(0xFFFF5252), belly: const Color(0xFFFFCCBC));

    // lily pads + a lotus
    const pads = [
      (0.12, 0.20, 34.0),
      (0.86, 0.32, 40.0),
      (0.18, 0.84, 46.0),
      (0.82, 0.90, 30.0),
    ];
    for (var i = 0; i < pads.length; i++) {
      final (fx, fy, rad) = pads[i];
      final c = Offset(fx * w, fy * h + math.sin(t * 0.8 + i) * 3);
      _paint
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF2E7D32).withValues(alpha: 0.62);
      canvas.drawArc(Rect.fromCircle(center: c, radius: rad), 0.35, math.pi * 2 - 0.7, true, _paint);
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF81C784).withValues(alpha: 0.55);
      canvas.drawArc(Rect.fromCircle(center: c, radius: rad), 0.35, math.pi * 2 - 0.7, false, _paint);
      if (i == 1) {
        _paint
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFF8BBD0).withValues(alpha: 0.9);
        for (var k = 0; k < 6; k++) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(k * math.pi / 3);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(0, -rad * 0.28), width: rad * 0.26, height: rad * 0.5),
            _paint,
          );
          canvas.restore();
        }
        _paint.color = const Color(0xFFFFC107);
        canvas.drawCircle(c, rad * 0.1, _paint);
      }
    }
  }

  void _fish(
    Canvas canvas,
    double w,
    double h,
    double t, {
    required double cx,
    required double cy,
    required double a,
    required double b,
    required double sa,
    required double sb,
    required double ph,
    required Color body,
    required Color belly,
  }) {
    final x = w * (cx + a * math.cos(sa * t + ph));
    final y = h * (cy + b * math.sin(sb * t + ph * 1.3));
    final vx = -a * w * sa * math.sin(sa * t + ph);
    final vy = b * h * sb * math.cos(sb * t + ph * 1.3);
    final heading = math.atan2(vy, vx);
    final len = math.min(w, h) * 0.20;
    final sw = math.sin(t * 5 + ph) * 0.35;

    Path bodyPath() => Path()
      ..moveTo(len * 0.5, 0)
      ..cubicTo(len * 0.35, -len * 0.28, -len * 0.15, -len * 0.25, -len * 0.4, -len * 0.04)
      ..lineTo(-len * 0.4, len * 0.04)
      ..cubicTo(-len * 0.15, len * 0.25, len * 0.35, len * 0.28, len * 0.5, 0)
      ..close();

    // shadow on the pond floor
    canvas.save();
    canvas.translate(x + 10, y + 16);
    canvas.rotate(heading + math.sin(t * 5 + ph) * 0.06);
    _paint
      ..style = PaintingStyle.fill
      ..shader = null
      ..color = Colors.black.withValues(alpha: 0.13);
    canvas.drawPath(bodyPath(), _paint);
    canvas.restore();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(heading + math.sin(t * 5 + ph) * 0.06);

    // flowing tail
    canvas.save();
    canvas.translate(-len * 0.38, 0);
    canvas.rotate(sw);
    final tail = Path()
      ..moveTo(0, 0)
      ..cubicTo(-len * 0.25, -len * 0.35, -len * 0.6, -len * 0.45, -len * 0.55, -len * 0.10)
      ..quadraticBezierTo(-len * 0.45, 0, -len * 0.55, len * 0.10)
      ..cubicTo(-len * 0.6, len * 0.45, -len * 0.25, len * 0.35, 0, 0)
      ..close();
    _paint.color = body.withValues(alpha: 0.72);
    canvas.drawPath(tail, _paint);
    canvas.restore();

    // dorsal fin
    final dorsal = Path()
      ..moveTo(len * 0.25, -len * 0.21)
      ..quadraticBezierTo(0, -len * 0.5, -len * 0.25, -len * 0.17)
      ..close();
    _paint.color = body.withValues(alpha: 0.7);
    canvas.drawPath(dorsal, _paint);

    // body
    _paint.shader = ui.Gradient.linear(
      Offset(-len * 0.4, 0),
      Offset(len * 0.5, 0),
      [body, belly],
    );
    canvas.drawPath(bodyPath(), _paint);
    _paint.shader = null;
    // shine
    _paint.color = Colors.white.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(len * 0.05, -len * 0.1), width: len * 0.42, height: len * 0.1),
      _paint,
    );

    // pectoral fins
    for (final sgn in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(len * 0.18, sgn * len * 0.19);
      canvas.rotate(sgn * (0.5 + 0.25 * math.sin(t * 5 + ph + 1)));
      _paint.color = body.withValues(alpha: 0.75);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-len * 0.08, sgn * len * 0.06), width: len * 0.28, height: len * 0.11),
        _paint,
      );
      canvas.restore();
    }

    // eye
    _paint.color = const Color(0xFF212121);
    canvas.drawCircle(Offset(len * 0.37, -len * 0.07), len * 0.035, _paint);
    _paint.color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(len * 0.38, -len * 0.08), len * 0.012, _paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LivePainter oldDelegate) =>
      oldDelegate.live != live || oldDelegate.preset != preset;
}
