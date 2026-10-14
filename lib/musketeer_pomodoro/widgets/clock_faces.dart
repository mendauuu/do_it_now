import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../painters/ring_painter.dart';

/// Every clock style the person can pick, all drawn into the same
/// square box so the Pomodoro card's layout doesn't care which one is
/// showing. [time] is the continuous world clock, for things that
/// move on their own (candle flame, falling sand).
class ClockFace extends StatelessWidget {
  final ClockStyle style;
  final int seconds;
  final double progress; // 0..1 through the current phase
  final bool isDay;
  final bool running;
  final double time;
  final double size;

  const ClockFace({
    super.key,
    required this.style,
    required this.seconds,
    required this.progress,
    required this.isDay,
    required this.running,
    required this.time,
    required this.size,
  });

  Color get accent => isDay ? const Color(0xFFFFD65C) : const Color(0xFF9FD1FF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: switch (style) {
        ClockStyle.ring => _ring(),
        ClockStyle.dial => _dial(),
        ClockStyle.hourglass => _hourglass(),
        ClockStyle.candle => _candle(),
        ClockStyle.flip => _FlipClock(seconds: seconds, progress: progress,
            accent: accent, size: size),
        ClockStyle.minimal => _minimal(),
      },
    );
  }

  Widget _ring() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: RingPainter(progress: progress, color: accent),
        ),
        _Digits(seconds, fontSize: size * 0.25),
      ],
    );
  }

  Widget _dial() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: _DialPainter(remaining: 1 - progress, color: accent),
        ),
        Positioned(
          bottom: size * 0.22,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: size * 0.05, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(size * 0.06),
            ),
            child: _Digits(seconds, fontSize: size * 0.12),
          ),
        ),
      ],
    );
  }

  Widget _hourglass() {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _HourglassPainter(
              progress: progress,
              running: running,
              time: time,
              sand: accent,
            ),
          ),
        ),
        SizedBox(height: size * 0.02),
        _Digits(seconds, fontSize: size * 0.17),
      ],
    );
  }

  Widget _candle() {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _CandlePainter(
              progress: progress,
              time: time,
              lit: progress < 1,
            ),
          ),
        ),
        SizedBox(height: size * 0.02),
        _Digits(seconds, fontSize: size * 0.17),
      ],
    );
  }

  Widget _minimal() {
    final pct = (progress * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Digits(seconds, fontSize: size * 0.3, weight: FontWeight.w300),
        SizedBox(height: size * 0.05),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: size * 0.78,
            height: math.max(4, size * 0.025),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
        SizedBox(height: size * 0.04),
        Text(
          '$pct% done',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: math.max(9, size * 0.06),
            letterSpacing: 1.5,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

String clockStyleLabel(ClockStyle style) => switch (style) {
      ClockStyle.ring => 'Ring',
      ClockStyle.dial => 'Dial',
      ClockStyle.hourglass => 'Hourglass',
      ClockStyle.candle => 'Candle',
      ClockStyle.flip => 'Flip',
      ClockStyle.minimal => 'Minimal',
    };

String formatClock(int totalSeconds) {
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _Digits extends StatelessWidget {
  final int seconds;
  final double fontSize;
  final FontWeight weight;

  const _Digits(this.seconds,
      {required this.fontSize, this.weight = FontWeight.w700});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatClock(seconds),
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: fontSize * 0.04,
        fontFeatures: const [FontFeature.tabularFigures()],
        shadows: const [
          Shadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

// ── Dial ────────────────────────────────────────────────────────
// A "time timer": the colored wedge is the time left, shrinking
// clockwise toward twelve, with compass-style tick marks around it.

class _DialPainter extends CustomPainter {
  final double remaining;
  final Color color;

  _DialPainter({required this.remaining, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    canvas.drawCircle(
        c, r * 0.96, Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawCircle(
      c,
      r * 0.96,
      Paint()
        ..color = const Color(0xFFE8C77A).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.025,
    );

    final wedge = remaining.clamp(0.0, 1.0);
    if (wedge > 0) {
      final rect = Rect.fromCircle(center: c, radius: r * 0.78);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * wedge, true,
          Paint()..color = color.withValues(alpha: 0.85));
    }

    for (int i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final a = -math.pi / 2 + i * 2 * math.pi / 60;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * r * (major ? 0.80 : 0.85),
        c + dir * r * 0.91,
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.9 : 0.45)
          ..strokeWidth = major ? r * 0.025 : r * 0.012
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hand along the wedge's leading edge, plus a brass center knob.
    final a = -math.pi / 2 + 2 * math.pi * wedge;
    canvas.drawLine(
      c,
      c + Offset(math.cos(a), math.sin(a)) * r * 0.74,
      Paint()
        ..color = Colors.white
        ..strokeWidth = r * 0.03
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, r * 0.08, Paint()..color = const Color(0xFFE8C77A));
    canvas.drawCircle(c, r * 0.035, Paint()..color = const Color(0xFF7A5A2E));
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.remaining != remaining || old.color != color;
}

// ── Hourglass ───────────────────────────────────────────────────

class _HourglassPainter extends CustomPainter {
  final double progress;
  final bool running;
  final double time;
  final Color sand;

  _HourglassPainter({
    required this.progress,
    required this.running,
    required this.time,
    required this.sand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = math.min(size.width, h * 0.62);
    final cx = size.width / 2;
    final capH = h * 0.06;
    final top = capH, bottom = h - capH, mid = h / 2;
    final half = w * 0.42, neck = w * 0.045;

    Path bulb(bool upper) {
      final y0 = upper ? top : bottom;
      return Path()
        ..moveTo(cx - half, y0)
        ..lineTo(cx + half, y0)
        ..cubicTo(cx + half, upper ? mid - h * 0.12 : mid + h * 0.12,
            cx + neck, upper ? mid - h * 0.04 : mid + h * 0.04, cx + neck, mid)
        ..lineTo(cx - neck, mid)
        ..cubicTo(cx - neck, upper ? mid - h * 0.04 : mid + h * 0.04,
            cx - half, upper ? mid - h * 0.12 : mid + h * 0.12, cx - half, y0)
        ..close();
    }

    final upper = bulb(true), lower = bulb(false);
    final glass = Paint()..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawPath(upper, glass);
    canvas.drawPath(lower, glass);

    final p = progress.clamp(0.0, 1.0);
    final sandPaint = Paint()..color = sand;
    final bulbH = mid - top;

    // Top: sand sits in the bottom of the bulb, its surface sinking
    // toward the neck as time passes.
    if (p < 1) {
      canvas.save();
      canvas.clipPath(upper);
      final level = mid - bulbH * 0.85 * (1 - p);
      canvas.drawRect(
          Rect.fromLTRB(cx - half, level, cx + half, mid), sandPaint);
      canvas.restore();
    }

    // Bottom: a mound that grows from the floor.
    if (p > 0) {
      canvas.save();
      canvas.clipPath(lower);
      final pileH = bulbH * 0.85 * p;
      final peak = bottom - pileH - h * 0.03;
      canvas.drawPath(
        Path()
          ..moveTo(cx - half, bottom)
          ..lineTo(cx - half, bottom - pileH)
          ..quadraticBezierTo(cx, peak - h * 0.02, cx + half, bottom - pileH)
          ..lineTo(cx + half, bottom)
          ..close(),
        sandPaint,
      );
      canvas.restore();
    }

    // Falling stream, with grains drifting down it.
    if (running && p < 1) {
      final streamBottom = bottom - bulbH * 0.85 * p - h * 0.04;
      canvas.drawLine(
        Offset(cx, mid),
        Offset(cx, streamBottom),
        Paint()
          ..color = sand
          ..strokeWidth = math.max(1.5, w * 0.012),
      );
      for (int i = 0; i < 4; i++) {
        final t = ((time * 2.5 + i / 4) % 1);
        canvas.drawCircle(
          Offset(cx + (i.isEven ? 1 : -1) * w * 0.012,
              mid + (streamBottom - mid) * t),
          math.max(1, w * 0.01),
          sandPaint,
        );
      }
    }

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.015);
    canvas.drawPath(upper, outline);
    canvas.drawPath(lower, outline);

    // Wooden caps and side posts.
    final wood = Paint()..color = const Color(0xFF8B5A2B);
    final capW = half * 2 + w * 0.14;
    for (final y in [0.0, h - capH]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - capW / 2, y, capW, capH),
            Radius.circular(capH * 0.35)),
        wood,
      );
    }
    final post = Paint()
      ..color = const Color(0xFF6B4423)
      ..strokeWidth = math.max(2, w * 0.03)
      ..strokeCap = StrokeCap.round;
    for (final dx in [-1.0, 1.0]) {
      final x = cx + dx * (capW / 2 - w * 0.03);
      canvas.drawLine(Offset(x, capH), Offset(x, h - capH), post);
    }
  }

  @override
  bool shouldRepaint(_HourglassPainter old) =>
      old.progress != progress ||
      old.running != running ||
      old.sand != sand ||
      (running && old.time != time);
}

// ── Candle ──────────────────────────────────────────────────────

class _CandlePainter extends CustomPainter {
  final double progress;
  final double time;
  final bool lit;

  _CandlePainter(
      {required this.progress, required this.time, required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final cx = size.width / 2;
    final candleW = h * 0.2;
    final plateY = h * 0.94;

    // Candle shrinks from tall to a stub as the phase runs out.
    final maxH = h * 0.62, minH = h * 0.07;
    final candleH = minH + (maxH - minH) * (1 - progress.clamp(0.0, 1.0));
    final topY = plateY - candleH;

    // Glow behind everything.
    if (lit) {
      final flicker = 0.85 + 0.15 * math.sin(time * 11);
      final glowC = Offset(cx, topY - h * 0.1);
      canvas.drawCircle(
        glowC,
        h * 0.32 * flicker,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFB347).withValues(alpha: 0.45),
            const Color(0xFFFFB347).withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: glowC, radius: h * 0.32 * flicker)),
      );
    }

    // Brass holder.
    final brass = Paint()..color = const Color(0xFFC9A04A);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, plateY), width: candleW * 2.6, height: h * 0.07),
        brass);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, plateY - h * 0.012),
            width: candleW * 2.1,
            height: h * 0.045),
        Paint()..color = const Color(0xFFE8C77A));

    // Wax body with a soft side highlight.
    final body = Rect.fromLTWH(cx - candleW / 2, topY, candleW, candleH);
    canvas.drawRRect(
      RRect.fromRectAndCorners(body,
          topLeft: Radius.circular(candleW * 0.2),
          topRight: Radius.circular(candleW * 0.2)),
      Paint()
        ..shader = const LinearGradient(colors: [
          Color(0xFFF5E6C8),
          Color(0xFFFFF8E7),
          Color(0xFFE6D2AA),
        ]).createShader(body),
    );

    // A couple of drips that stay near the top as it melts.
    final drip = Paint()..color = const Color(0xFFFFF8E7);
    for (final (dx, len) in [(-0.32, 0.22), (0.28, 0.14)]) {
      final x = cx + candleW * dx;
      final l = math.min(candleH * 0.8, h * len * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - candleW * 0.07, topY, candleW * 0.14, l),
            Radius.circular(candleW * 0.07)),
        drip,
      );
    }

    // Wick.
    canvas.drawLine(
      Offset(cx, topY),
      Offset(cx, topY - h * 0.04),
      Paint()
        ..color = const Color(0xFF3A2E22)
        ..strokeWidth = math.max(1.5, h * 0.012)
        ..strokeCap = StrokeCap.round,
    );

    if (!lit) return;

    // Flame: a teardrop that sways and stretches.
    final sway = math.sin(time * 7) * h * 0.012;
    final stretch = 1 + 0.08 * math.sin(time * 13);
    final base = Offset(cx, topY - h * 0.035);
    final flameH = h * 0.16 * stretch, flameW = h * 0.055;
    Path flame(double scale) => Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
          base.dx - flameW * scale, base.dy - flameH * 0.25 * scale,
          base.dx - flameW * 0.5 * scale + sway, base.dy - flameH * 0.7 * scale,
          base.dx + sway * 1.5, base.dy - flameH * scale)
      ..cubicTo(
          base.dx + flameW * 0.5 * scale + sway, base.dy - flameH * 0.7 * scale,
          base.dx + flameW * scale, base.dy - flameH * 0.25 * scale,
          base.dx, base.dy)
      ..close();

    canvas.drawPath(flame(1), Paint()..color = const Color(0xFFFF8A3D));
    canvas.drawPath(flame(0.62), Paint()..color = const Color(0xFFFFD65C));
    canvas.drawPath(flame(0.3), Paint()..color = const Color(0xFFFFF8E7));
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.progress != progress ||
      old.lit != lit ||
      (lit && old.time != time);
}

// ── Flip clock ──────────────────────────────────────────────────

class _FlipClock extends StatelessWidget {
  final int seconds;
  final double progress;
  final Color accent;
  final double size;

  const _FlipClock({
    required this.seconds,
    required this.progress,
    required this.accent,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    final cardW = size * 0.42;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FlipCard(text: mm, width: cardW),
            SizedBox(
              width: size * 0.1,
              child: Text(
                ':',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _FlipCard(text: ss, width: cardW),
          ],
        ),
        SizedBox(height: size * 0.08),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final label in ['MIN', '', 'SEC'])
              SizedBox(
                width: label.isEmpty ? size * 0.1 : cardW,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: _label(size)),
                ),
              ),
          ],
        ),
        SizedBox(height: size * 0.05),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: cardW * 2 + size * 0.1,
            height: math.max(3, size * 0.018),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _label(double size) => TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: math.max(8, size * 0.045),
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      );
}

class _FlipCard extends StatelessWidget {
  final String text;
  final double width;

  const _FlipCard({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.15;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3049), Color(0xFF241D30)],
        ),
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(
            color: const Color(0xFFE8C77A).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => AnimatedBuilder(
              animation: anim,
              child: child,
              builder: (_, c) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX((1 - anim.value) * math.pi / 2),
                child: c,
              ),
            ),
            child: Text(
              text,
              key: ValueKey(text),
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.6,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // The hinge line across the middle of the card.
          Container(
            height: 1.5,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}
