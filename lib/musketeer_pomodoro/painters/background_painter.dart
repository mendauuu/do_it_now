import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';
import '../scenery_data.dart';

// ── Background Painter ────────────────────────────────────────
// Sky → stars → sun/moon → far mountains (snow cap in winter) →
// mid mountains + castle → clouds (always) → birds (day) / bats
// (night) → precipitation (season-dependent) → near mountains +
// windmill → ground (grass/bush/tree, seasonally colored) → path
// → river (icy tint in winter) → dust trail → campfire + fireflies
// (night) → confetti (on session completion, fires in every scene
// mode).
//
// Cut on review: a shooting star and a jumping fish that fired every
// 5–7 seconds — too frequent to read as special, just background
// noise — and falling leaves during the day, which read as autumn in
// what's otherwise a green summer scene.

class BackgroundPainter extends CustomPainter {
  final BgSnap bg;

  const BackgroundPainter(this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    // Route transitions (this screen sliding in) can paint one frame
    // before layout settles, when the CustomPaint's size is still
    // 0x0. Several methods below divide/modulo by size.width or
    // size.height (e.g. the river's sparkle loop) — on a 0 size that
    // produces NaN, which crashes with "Offset argument contained a
    // NaN value." There's nothing to draw on a zero-size canvas
    // anyway, so just skip the frame.
    if (size.width <= 0 || size.height <= 0) return;

    if (bg.sceneMode == SceneMode.off) {
      // Back to exactly what this screen looked like before any of
      // the scenery existed — a flat, distraction-free background.
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color =
              bg.isDay ? const Color(0xFFF4E8D0) : const Color(0xFF232136),
      );
      _maybePaintConfetti(canvas, size);
      return;
    }

    _paintSky(canvas, size);

    if (bg.sceneMode == SceneMode.full && !bg.isDay) _paintStars(canvas, size);

    _paintCelestialBody(canvas, size);

    if (bg.sceneMode == SceneMode.simple) {
      // Some atmosphere (sky + sun/moon) without the busier set
      // pieces and wildlife — still stands on solid ground.
      _paintGround(canvas, size);
      _paintPath(canvas, size);
      _maybePaintConfetti(canvas, size);
      return;
    }

    // Far mountains.
    const farBaseFrac = 0.58, farAmp = 34.0, farFreq = 0.006;
    final farOffset = bg.time * 3;
    _paintMountainLayer(
      canvas,
      size,
      baseHeightFrac: farBaseFrac,
      amplitude: farAmp,
      frequency: farFreq,
      xOffset: farOffset,
      color: _mountainColor(0),
      snowCapInWinter: true,
    );

    // Mid mountains, with a castle sitting on the ridge.
    const midBaseFrac = 0.66, midAmp = 46.0, midFreq = 0.009;
    final midOffset = bg.time * 7;
    _paintMountainLayer(
      canvas,
      size,
      baseHeightFrac: midBaseFrac,
      amplitude: midAmp,
      frequency: midFreq,
      xOffset: midOffset,
      color: _mountainColor(1),
      snowCapInWinter: true,
    );

    final castleX = size.width * 0.22;
    final castleBase = Offset(
      castleX,
      _ridgeY(
        size,
        baseHeightFrac: midBaseFrac,
        amplitude: midAmp,
        frequency: midFreq,
        xOffset: midOffset,
        x: castleX,
      ),
    );
    _paintCastle(canvas, size, castleBase);

    // Clouds drift both day and night (moonlit and translucent at
    // night) so the sky never goes still.
    _paintClouds(canvas, size);
    _paintSunsetCloudMass(canvas, size);

    if (bg.isDay) {
      _paintBirds(canvas, size);
    } else {
      _paintBats(canvas, size);
    }

    _paintPrecipitation(canvas, size);

    // Near mountains, with a windmill on the ridge.
    const nearBaseFrac = 0.76, nearAmp = 30.0, nearFreq = 0.013;
    final nearOffset = bg.time * 13;
    _paintMountainLayer(
      canvas,
      size,
      baseHeightFrac: nearBaseFrac,
      amplitude: nearAmp,
      frequency: nearFreq,
      xOffset: nearOffset,
      color: _mountainColor(2),
    );

    final windmillX = size.width * 0.80;
    final windmillBase = Offset(
      windmillX,
      _ridgeY(
        size,
        baseHeightFrac: nearBaseFrac,
        amplitude: nearAmp,
        frequency: nearFreq,
        xOffset: nearOffset,
        x: windmillX,
      ),
    );
    _paintWindmill(canvas, size, windmillBase);

    _paintGround(canvas, size);
    _paintPath(canvas, size);
    _paintRiver(canvas, size);

    final flagX = bg.goalFlagX;
    if (flagX != null) _paintGoalFlag(canvas, size, flagX);

    if (bg.isMoving) _paintDust(canvas, size);

    // The campfire is where the musketeer rests on breaks, so it's lit
    // for every break — and always at night, for atmosphere.
    if (!bg.isDay || !bg.isFocus) _paintCampfire(canvas, size);
    if (!bg.isDay) _paintFireflies(canvas, size);

    _maybePaintConfetti(canvas, size);
  }

  // Fires in every scene mode, including off/simple — it's a reward
  // signal for finishing a session, not ambient decoration, so
  // dialling the scene down shouldn't silence it too.
  void _maybePaintConfetti(Canvas canvas, Size size) {
    if (bg.secondsSinceCelebration >= 0 &&
        bg.secondsSinceCelebration < kCelebrationDuration) {
      _paintConfetti(
        canvas,
        size,
        bg.secondsSinceCelebration / kCelebrationDuration,
      );
    }
  }

  // ── Sky ─────────────────────────────────────────────────────

  List<Color> _skyColors() {
    if (bg.isDay) {
      const sunrise = [Color(0xFFFFE29A), Color(0xFFFFB199)];
      const noon = [Color(0xFF7EC8FF), Color(0xFFBEEBFF)];
      const sunset = [Color(0xFFFF9A5A), Color(0xFF6C4B8C)];

      if (bg.phaseProgress < 0.5) {
        final t = bg.phaseProgress / 0.5;
        return [
          Color.lerp(sunrise[0], noon[0], t)!,
          Color.lerp(sunrise[1], noon[1], t)!,
        ];
      } else {
        final t = (bg.phaseProgress - 0.5) / 0.5;
        return [
          Color.lerp(noon[0], sunset[0], t)!,
          Color.lerp(noon[1], sunset[1], t)!,
        ];
      }
    } else {
      const duskNight = [Color(0xFF1B1E3D), Color(0xFF33234F)];
      const deepNight = [Color(0xFF0B0E2A), Color(0xFF201035)];
      final t = bg.phaseProgress;
      return [
        Color.lerp(duskNight[0], deepNight[0], t)!,
        Color.lerp(duskNight[1], deepNight[1], t)!,
      ];
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: _skyColors(),
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // ── Stars ───────────────────────────────────────────────────

  void _paintStars(Canvas canvas, Size size) {
    for (int i = 0; i < kStarSeeds.length; i++) {
      final seed = kStarSeeds[i];
      final pos = Offset(seed.dx * size.width, seed.dy * size.height);
      final twinkle =
          (0.4 + 0.6 * (0.5 + 0.5 * math.sin(bg.time * 1.6 + i * 0.7)))
              .clamp(0.0, 1.0);
      final radius = 1.0 + (i % 3) * 0.5;

      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = Colors.white.withOpacity(twinkle * 0.9),
      );
    }
  }

  // ── Sun / Moon ──────────────────────────────────────────────

  Offset _celestialPosition(Size size) {
    final x = size.width * bg.phaseProgress;
    final arcHeight = size.height * 0.32;
    final y = size.height * 0.16 +
        (1 - math.sin(bg.phaseProgress * math.pi)) * arcHeight;
    return Offset(x, y);
  }

  void _paintCelestialBody(Canvas canvas, Size size) {
    final pos = _celestialPosition(size);

    if (bg.isDay) {
      _paintGlow(canvas, pos, 70, const Color(0xFFFFE9A8), 0.5);
      canvas.drawCircle(pos, 26, Paint()..color = const Color(0xFFFFD65C));
    } else {
      _paintGlow(canvas, pos, 56, const Color(0xFFE7E9FF), 0.4);
      canvas.drawCircle(pos, 22, Paint()..color = const Color(0xFFEDEFFA));

      final crater = Paint()..color = const Color(0xFFD3D6EC);
      canvas.drawCircle(pos + const Offset(-6, -4), 4, crater);
      canvas.drawCircle(pos + const Offset(7, 5), 3, crater);
      canvas.drawCircle(pos + const Offset(2, -8), 2.5, crater);
    }
  }

  // A radial-gradient "glow" instead of a blurred circle. Flutter's
  // MaskFilter.blur triggers a real blur pass on the GPU/CPU every
  // time it's drawn — cheap once, but this scene draws well over a
  // dozen glowing shapes every single frame (sun/moon, two torches,
  // the campfire, a dozen fireflies), and that adds up to dropped
  // frames on real phones. A gradient fades out analytically with
  // no extra raster pass, so it's effectively free by comparison —
  // same soft look, much lighter on the frame budget.
  void _paintGlow(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  // ── Mountains ───────────────────────────────────────────────

  Color _mountainColor(int layer) {
    const dayColors = [Color(0xFFB9A7D9), Color(0xFF8F7CB8), Color(0xFF5B4B7A)];
    const nightColors = [
      Color(0xFF2B2750),
      Color(0xFF1F1B3D),
      Color(0xFF141130)
    ];
    return (bg.isDay ? dayColors : nightColors)[layer];
  }

  void _paintMountainLayer(
    Canvas canvas,
    Size size, {
    required double baseHeightFrac,
    required double amplitude,
    required double frequency,
    required double xOffset,
    required Color color,
    bool snowCapInWinter = false,
  }) {
    final path = Path()..moveTo(0, size.height);
    final ridgePoints = <Offset>[];
    const step = 12.0;

    // Walk in fixed steps, but snap the last sample exactly onto
    // size.width instead of stopping short of it (size.width isn't
    // always a multiple of `step`). Stopping short used to leave the
    // path jumping straight down to the bottom-right corner instead
    // of following the ridge all the way to the edge — a visible
    // diagonal gap on the right side of the screen.
    double x = 0;
    while (true) {
      final sampleX = x < size.width ? x : size.width;
      final sampleY = _ridgeY(
        size,
        baseHeightFrac: baseHeightFrac,
        amplitude: amplitude,
        frequency: frequency,
        xOffset: xOffset,
        x: sampleX,
      );
      path.lineTo(sampleX, sampleY);
      ridgePoints.add(Offset(sampleX, sampleY));
      if (sampleX >= size.width) break;
      x += step;
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color);

    if (snowCapInWinter && bg.season == Season.winter) {
      final snowPath = Path()
        ..moveTo(ridgePoints.first.dx, ridgePoints.first.dy);
      for (final p in ridgePoints.skip(1)) {
        snowPath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        snowPath,
        Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  // Ridge formula shared by the mountain fill above and by set
  // pieces (castle, windmill) that need to sit exactly on the ridge.
  double _ridgeY(
    Size size, {
    required double baseHeightFrac,
    required double amplitude,
    required double frequency,
    required double xOffset,
    required double x,
  }) {
    final baseY = size.height * baseHeightFrac;
    final wx = x + xOffset;
    final ridge = amplitude *
        (0.6 * math.sin(wx * frequency) +
            0.4 * math.sin(wx * frequency * 2.3 + 1.3));
    return baseY - ridge;
  }

  // ── Castle ──────────────────────────────────────────────────

  void _paintCastle(Canvas canvas, Size size, Offset base) {
    final stone = bg.isDay ? const Color(0xFF7B7191) : const Color(0xFF241F3D);
    final stoneDark =
        bg.isDay ? const Color(0xFF645B79) : const Color(0xFF1A1730);

    canvas.drawRect(
      Rect.fromLTWH(base.dx - 34, base.dy - 26, 68, 26),
      Paint()..color = stone,
    );

    for (int i = 0; i < 5; i++) {
      final x = base.dx - 34 + i * 14;
      canvas.drawRect(
          Rect.fromLTWH(x, base.dy - 32, 8, 6), Paint()..color = stone);
    }

    canvas.drawRect(
      Rect.fromLTWH(base.dx - 44, base.dy - 52, 18, 52),
      Paint()..color = stoneDark,
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx + 26, base.dy - 46, 18, 46),
      Paint()..color = stoneDark,
    );

    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 46, base.dy - 52)
        ..lineTo(base.dx - 35, base.dy - 68)
        ..lineTo(base.dx - 24, base.dy - 52)
        ..close(),
      Paint()..color = stoneDark.withOpacity(0.9),
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + 24, base.dy - 46)
        ..lineTo(base.dx + 35, base.dy - 62)
        ..lineTo(base.dx + 46, base.dy - 46)
        ..close(),
      Paint()..color = stoneDark.withOpacity(0.9),
    );

    final poleTop = Offset(base.dx - 35, base.dy - 68);
    canvas.drawLine(
      poleTop,
      poleTop - const Offset(0, 14),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );

    final wave = math.sin(bg.time * 4) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(poleTop.dx, poleTop.dy - 14)
        ..lineTo(poleTop.dx + 12 + wave, poleTop.dy - 11)
        ..lineTo(poleTop.dx, poleTop.dy - 8)
        ..close(),
      Paint()..color = const Color(0xFFC1443B),
    );

    if (!bg.isDay) {
      _drawTorch(canvas, Offset(base.dx - 34, base.dy - 26));
      _drawTorch(canvas, Offset(base.dx + 30, base.dy - 26));
    } else {
      final chimneyTop = Offset(base.dx + 34, base.dy - 54);
      canvas.drawRect(
        Rect.fromLTWH(chimneyTop.dx - 3, chimneyTop.dy, 6, 8),
        Paint()..color = stoneDark,
      );
      _paintChimneySmoke(canvas, chimneyTop);
    }
  }

  void _paintChimneySmoke(Canvas canvas, Offset chimneyTop) {
    for (int i = 0; i < 4; i++) {
      final t = ((bg.time * 0.5 + i * 0.7) % 3.0) / 3.0;
      final sx = chimneyTop.dx + math.sin(bg.time * 1.5 + i) * (4 + t * 10);
      final sy = chimneyTop.dy - t * 40;
      final op = (1 - t).clamp(0.0, 1.0) * 0.5;
      final r = 3 + t * 6;

      canvas.drawCircle(
          Offset(sx, sy), r, Paint()..color = Colors.white.withOpacity(op));
    }
  }

  void _drawTorch(Canvas canvas, Offset base) {
    canvas.drawLine(
      base,
      base - const Offset(0, 10),
      Paint()
        ..color = const Color(0xFF3A2E22)
        ..strokeWidth = 2,
    );

    final flicker = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(bg.time * 10 + base.dx));
    final glowCenter = base - const Offset(0, 12);

    _paintGlow(canvas, glowCenter, 9, const Color(0xFFFFA940), flicker * 0.85);
    canvas.drawCircle(
      glowCenter,
      2,
      Paint()..color = const Color(0xFFFFF3C4).withOpacity(flicker),
    );
  }

  // ── Windmill ────────────────────────────────────────────────

  void _paintWindmill(Canvas canvas, Size size, Offset base) {
    final towerColor =
        bg.isDay ? const Color(0xFF8B6F52) : const Color(0xFF3A2E22);

    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 10, base.dy)
        ..lineTo(base.dx - 6, base.dy - 46)
        ..lineTo(base.dx + 6, base.dy - 46)
        ..lineTo(base.dx + 10, base.dy)
        ..close(),
      Paint()..color = towerColor,
    );

    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 8, base.dy - 44)
        ..lineTo(base.dx, base.dy - 58)
        ..lineTo(base.dx + 8, base.dy - 44)
        ..close(),
      Paint()..color = towerColor.withOpacity(0.9),
    );

    final hub = Offset(base.dx, base.dy - 50);
    final bladeColor =
        bg.isDay ? const Color(0xFFE9DFC8) : const Color(0xFF4A4438);
    final angle = bg.time * 1.2;

    canvas.save();
    canvas.translate(hub.dx, hub.dy);
    canvas.rotate(angle);

    final bladePaint = Paint()
      ..color = bladeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final a = (math.pi / 2) * i;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a) * 26, math.sin(a) * 26),
        bladePaint,
      );
    }

    canvas.restore();
  }

  // ── Clouds (day and night) ───────────────────────────────────
  // Two-tone (lit top + shadowed underside) instead of flat white, so
  // they pick up the same warm glow a real sunlit cloud gets near
  // sunrise/sunset — brightest and whitest at noon, gold-to-ember at
  // the edges of the day phase, pale and dim at night.

  // 0 at noon, 1 at the far edges of the day phase (sunrise/sunset).
  double get _sunEdginess =>
      (1 - math.sin(bg.phaseProgress * math.pi)).clamp(0.0, 1.0);

  Color get _cloudLitColor {
    if (!bg.isDay) return Colors.white.withOpacity(0.14);
    return Color.lerp(
      Colors.white,
      const Color(0xFFFFB25E),
      _sunEdginess * 0.85,
    )!
        .withOpacity(0.92);
  }

  Color get _cloudShadowColor {
    if (!bg.isDay) return Colors.white.withOpacity(0.05);
    return Color.lerp(
      const Color(0xFFC3CBDD),
      const Color(0xFF6B3A2E),
      _sunEdginess * 0.9,
    )!
        .withOpacity(0.85);
  }

  void _paintClouds(Canvas canvas, Size size) {
    final lit = _cloudLitColor;
    final shadow = _cloudShadowColor;

    for (final c in kClouds) {
      final x = (bg.time * c.speed + c.phase) % (size.width + 300) - 150;
      final y = size.height * c.yf;
      _drawCloudPuff(canvas, Offset(x, y), c.scale, lit, shadow);
    }
  }

  void _drawCloudPuff(
    Canvas canvas,
    Offset center,
    double scale,
    Color lit,
    Color shadow,
  ) {
    // Shadowed base, offset slightly down, drawn first so only its
    // lower edge peeks out from under the lit puffs above it.
    final shadowPaint = Paint()..color = shadow;
    canvas.drawCircle(center + Offset(0, 7 * scale), 18 * scale, shadowPaint);
    canvas.drawCircle(
        center + Offset(20 * scale, 11 * scale), 14 * scale, shadowPaint);
    canvas.drawCircle(
        center + Offset(-20 * scale, 12 * scale), 13 * scale, shadowPaint);

    final litPaint = Paint()..color = lit;
    canvas.drawCircle(center, 18 * scale, litPaint);
    canvas.drawCircle(
        center + Offset(20 * scale, 4 * scale), 14 * scale, litPaint);
    canvas.drawCircle(
        center + Offset(-20 * scale, 5 * scale), 13 * scale, litPaint);
    canvas.drawCircle(
        center + Offset(6 * scale, -8 * scale), 12 * scale, litPaint);
  }

  // ── Dramatic sunset cloud mass ─────────────────────────────────
  // A single tall, glowing cumulus tower that builds up through the
  // back half of the day phase and fades out once night sets in —
  // the "sunlit storm cloud" look, not just small puffs.

  void _paintSunsetCloudMass(Canvas canvas, Size size) {
    if (!bg.isDay) return;

    final t = ((bg.phaseProgress - 0.55) / 0.45).clamp(0.0, 1.0);
    if (t <= 0) return;

    final baseX = size.width * 0.74;
    final baseY = size.height * 0.36;
    final glow =
        Color.lerp(const Color(0xFFFFD38A), const Color(0xFFFF7A33), t)!;
    final shadow =
        Color.lerp(const Color(0xFF7A5566), const Color(0xFF32202A), t)!;
    final opacity = t * 0.9;

    // A soft halo drawn first, behind the mass, like sunlight
    // bleeding around its edge.
    canvas.drawCircle(
      Offset(baseX, baseY),
      46,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withOpacity(opacity * 0.35), glow.withOpacity(0)],
        ).createShader(
          Rect.fromCircle(center: Offset(baseX, baseY), radius: 46),
        ),
    );

    const puffs = [
      Offset(0, 10),
      Offset(-16, 2),
      Offset(18, 4),
      Offset(-8, -12),
      Offset(12, -16),
      Offset(-20, -18),
      Offset(2, -26),
      Offset(22, -22),
    ];

    for (int i = 0; i < puffs.length; i++) {
      final o = puffs[i];
      final r = 22.0 - i * 1.2;
      canvas.drawCircle(
        Offset(baseX + o.dx, baseY + o.dy + 7),
        r,
        Paint()..color = shadow.withOpacity(opacity * 0.85),
      );
    }

    for (int i = 0; i < puffs.length; i++) {
      final o = puffs[i];
      final r = 20.0 - i * 1.1;
      canvas.drawCircle(
        Offset(baseX + o.dx, baseY + o.dy),
        r,
        Paint()..color = glow.withOpacity(opacity),
      );
    }
  }

  // ── Birds (day) ─────────────────────────────────────────────

  void _paintBirds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final b in kBirds) {
      final x = (bg.time * b.speed + b.phase) % (size.width + 100) - 50;
      final y = size.height * b.baseYf +
          math.sin(bg.time * b.bobSpeed + b.phase) * b.bobAmp;
      final flap = 4 + 3 * math.sin(bg.time * 6 + b.phase);

      final path = Path()
        ..moveTo(x - 8, y)
        ..quadraticBezierTo(x - 4, y - flap, x, y)
        ..quadraticBezierTo(x + 4, y - flap, x + 8, y);

      canvas.drawPath(path, paint);
    }
  }

  // ── Bats (night) ────────────────────────────────────────────

  void _paintBats(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF15131F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (final b in kBats) {
      final x = (bg.time * b.speed + b.phase) % (size.width + 100) - 50;
      final y = size.height * b.baseYf +
          math.sin(bg.time * b.bobSpeed + b.phase) * b.bobAmp +
          math.sin(bg.time * 3.7 + b.phase) * 6; // erratic bat jitter
      final flap = 6 + 5 * math.sin(bg.time * 9 + b.phase).abs();

      final path = Path()
        ..moveTo(x - 10, y)
        ..quadraticBezierTo(x - 5, y - flap, x, y - 2)
        ..quadraticBezierTo(x + 5, y - flap, x + 10, y);

      canvas.drawPath(path, paint);
    }
  }

  // ── Precipitation (season-dependent) ──────────────────────────
  // One shared particle layout (kPrecipitation), styled differently
  // per season: falling snow in winter, drifting leaves in autumn,
  // petals in spring. Summer stays clear — it's the baseline look
  // this screen started with, no need to add anything to it.

  void _paintPrecipitation(Canvas canvas, Size size) {
    if (bg.season == Season.summer) return;

    List<Color> colors;
    double speedMultiplier;
    double opacity;
    bool oval;

    switch (bg.season) {
      case Season.autumn:
        colors = const [
          Color(0xFFE0A339),
          Color(0xFFD1683A),
          Color(0xFFC9862E)
        ];
        speedMultiplier = 1.3;
        opacity = 0.85;
        oval = true;
        break;
      case Season.spring:
        colors = const [
          Color(0xFFFCD9E6),
          Color(0xFFFFFFFF),
          Color(0xFFF7C6DC)
        ];
        speedMultiplier = 0.6;
        opacity = 0.8;
        oval = true;
        break;
      case Season.winter:
        colors = const [Colors.white];
        speedMultiplier = 0.45;
        opacity = 0.9;
        oval = false;
        break;
      case Season.summer:
        return; // unreachable — guarded above, kept for switch exhaustiveness
    }

    for (int i = 0; i < kPrecipitation.length; i++) {
      final p = kPrecipitation[i];
      final speed = p.speed * speedMultiplier;
      final y = (bg.time * speed + p.phase * 300) % (size.height + 40) - 20;
      final x = p.xf * size.width + math.sin(bg.time * 1.2 + p.phase) * p.sway;

      canvas.save();
      canvas.translate(x, y);

      if (oval) {
        canvas.rotate(bg.time * 2 + p.phase);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: p.size * 2, height: p.size),
          Paint()..color = colors[i % colors.length].withOpacity(opacity),
        );
      } else {
        canvas.drawCircle(
          Offset.zero,
          p.size * 0.6,
          Paint()..color = colors[0].withOpacity(opacity),
        );
      }

      canvas.restore();
    }
  }

  // ── Fireflies (night) ───────────────────────────────────────

  void _paintFireflies(Canvas canvas, Size size) {
    for (final f in kFireflies) {
      final x = f.xf * size.width + math.sin(bg.time * 0.5 + f.phase) * 10;
      final y = f.yf * size.height + math.cos(bg.time * 0.7 + f.phase) * 8;
      final glowOpacity =
          (0.3 + 0.7 * (0.5 + 0.5 * math.sin(bg.time * 3 + f.phase)))
              .clamp(0.0, 1.0);
      final pos = Offset(x, y);

      _paintGlow(canvas, pos, 8, const Color(0xFFDFFF8C), glowOpacity * 0.6);
      canvas.drawCircle(
        pos,
        1.6,
        Paint()..color = const Color(0xFFF3FFC2).withOpacity(glowOpacity),
      );
    }
  }

  // ── Campfire (night) ────────────────────────────────────────

  void _paintCampfire(Canvas canvas, Size size) {
    final groundTop = size.height * 0.84;
    final base = Offset(size.width * 0.68, groundTop);

    canvas.drawRect(
      Rect.fromCenter(center: base + const Offset(0, -2), width: 20, height: 4),
      Paint()..color = const Color(0xFF4A2F1D),
    );

    final flicker = 0.7 + 0.3 * (0.5 + 0.5 * math.sin(bg.time * 12));
    _paintGlow(canvas, base - const Offset(0, 6), 30 * flicker,
        const Color(0xFFFF8A3D), 0.28);

    final wob = math.sin(bg.time * 14) * 2;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 6, base.dy - 4)
        ..quadraticBezierTo(base.dx + wob, base.dy - 22, base.dx, base.dy - 4)
        ..quadraticBezierTo(
            base.dx - wob, base.dy - 14, base.dx - 6, base.dy - 4)
        ..close(),
      Paint()..color = const Color(0xFFFF6A1F),
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 3, base.dy - 4)
        ..quadraticBezierTo(
            base.dx + wob * 0.6, base.dy - 14, base.dx, base.dy - 4)
        ..close(),
      Paint()..color = const Color(0xFFFFD24C),
    );

    for (int i = 0; i < 4; i++) {
      final t = ((bg.time * 0.9 + i * 0.6) % 2.0) / 2.0;
      final ex = base.dx + math.sin(bg.time * 3 + i) * 6;
      final ey = base.dy - 8 - t * 36;
      final op = (1 - t).clamp(0.0, 1.0) * 0.9;

      canvas.drawCircle(Offset(ex, ey), 1.6,
          Paint()..color = const Color(0xFFFFC46B).withOpacity(op));
    }
  }

  // ── Cobblestone path (where the character walks) ─────────────

  void _paintPath(Canvas canvas, Size size) {
    final pathY = size.height - 44;
    final pathColor =
        bg.isDay ? const Color(0xFFB8A98C) : const Color(0xFF2E2B24);

    canvas.drawRect(
      Rect.fromLTWH(0, pathY - 6, size.width, 12),
      Paint()..color = pathColor.withOpacity(0.5),
    );

    final stoneColor =
        bg.isDay ? const Color(0xFFA0906F) : const Color(0xFF231F1A);

    for (double x = 0; x <= size.width; x += 22) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, pathY), width: 14, height: 6),
        Paint()..color = stoneColor.withOpacity(0.6),
      );
    }
  }

  // ── Goal flag (focus quest destination) ─────────────────────
  // Where the musketeer is headed during a focus session — reaching
  // it is finishing the session, so the walk itself reads as progress.

  void _paintGoalFlag(Canvas canvas, Size size, double x) {
    final baseY = size.height - 44;
    const poleH = 46.0;
    final top = Offset(x, baseY - poleH);

    canvas.drawLine(
      Offset(x, baseY),
      top,
      Paint()
        ..color = const Color(0xFF5A4632)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(top, 2.5, Paint()..color = const Color(0xFFE8C77A));

    // Pennant ripples gently in the wind.
    final wave = math.sin(bg.time * 4) * 2.5;
    canvas.drawPath(
      Path()
        ..moveTo(x + 1, top.dy + 2)
        ..quadraticBezierTo(
            x + 12, top.dy + 4 + wave, x + 24, top.dy + 9 + wave * 0.6)
        ..quadraticBezierTo(x + 12, top.dy + 14 - wave, x + 1, top.dy + 17)
        ..close(),
      Paint()..color = const Color(0xFFC1443B),
    );

    // Small mound so the pole looks planted.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, baseY), width: 16, height: 5),
      Paint()..color = const Color(0xFF5A4632).withValues(alpha: 0.5),
    );
  }

  // ── River ───────────────────────────────────────────────────

  void _paintRiver(Canvas canvas, Size size) {
    final riverTop = size.height * 0.905;
    final path = Path()..moveTo(0, riverTop);

    const step = 10.0;
    double x = 0;
    while (true) {
      final sx = x < size.width ? x : size.width;
      path.lineTo(sx, riverTop + math.sin(sx * 0.02 + bg.time * 0.5) * 4);
      if (sx >= size.width) break;
      x += step;
    }
    for (double x = size.width; x >= 0; x -= step) {
      final y = riverTop + 20 + math.sin(x * 0.02 + bg.time * 0.5) * 4;
      path.lineTo(x, y);
    }
    path.close();

    final riverColor = bg.season == Season.winter
        ? (bg.isDay ? const Color(0xFFCFE3ED) : const Color(0xFF3A5568))
        : (bg.isDay ? const Color(0xFF5FAEDB) : const Color(0xFF1B3550));
    canvas.drawPath(path, Paint()..color = riverColor.withOpacity(0.85));

    for (int i = 0; i < 8; i++) {
      final sx = (i * 97 + bg.time * 40) % size.width;
      final sy = riverTop +
          10 +
          math.sin(sx * 0.02 + bg.time * 0.5) * 4 +
          math.sin(bg.time * 3 + i) * 2;
      final op =
          (0.3 + 0.7 * (0.5 + 0.5 * math.sin(bg.time * 5 + i))).clamp(0.0, 1.0);

      canvas.drawCircle(
          Offset(sx, sy), 1.4, Paint()..color = Colors.white.withOpacity(op));
    }
  }

  // ── Dust trail (behind a moving character) ───────────────────

  void _paintDust(Canvas canvas, Size size) {
    // Dust kicks up behind the heels, whichever way they're heading.
    final dir = bg.facingLeft ? -1.0 : 1.0;
    final footX = bg.charX + kSize / 2 - dir * 40;
    final footY = size.height - 46;

    for (int i = 0; i < 5; i++) {
      final t = ((bg.time * 70 + i * 14) % 70) / 70;
      final x = footX - dir * t * 40;
      final y = footY - t * 6;
      final opacity = (1 - t).clamp(0.0, 1.0) * 0.5;

      canvas.drawCircle(
        Offset(x, y),
        3 + t * 3,
        Paint()..color = Colors.brown.withOpacity(opacity),
      );
    }
  }

  // ── Confetti (focus session complete) ─────────────────────────

  void _paintConfetti(Canvas canvas, Size size, double t) {
    const colors = [
      Colors.redAccent,
      Colors.amber,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
    ];
    final opacity = (1 - t).clamp(0.0, 1.0);

    for (final c in kConfetti) {
      final x = c.xf * size.width + math.sin(c.phase + t * 10) * c.vxAmp;
      final y = size.height * 0.22 + t * c.vy * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + c.phase);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 3),
        Paint()
          ..color =
              colors[c.colorIdx.toInt() % colors.length].withOpacity(opacity),
      );
      canvas.restore();
    }
  }

  // ── Ground ──────────────────────────────────────────────────

  // Picks a value per season without hand-writing every season ×
  // day/night combination separately — see _nightAdjust below for
  // how the day-lit base gets darkened for night.
  T _bySeasonValue<T>({
    required T spring,
    required T summer,
    required T autumn,
    required T winter,
  }) {
    switch (bg.season) {
      case Season.spring:
        return spring;
      case Season.summer:
        return summer;
      case Season.autumn:
        return autumn;
      case Season.winter:
        return winter;
    }
  }

  Color _nightAdjust(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
        .toColor();
  }

  Color get _groundColorBase => _bySeasonValue(
        spring: const Color(0xFF7CC06B),
        summer: const Color(0xFF6FA85B),
        autumn: const Color(0xFFB07A2E),
        winter: const Color(0xFFF2F5F8),
      );
  Color get _groundColor =>
      bg.isDay ? _groundColorBase : _nightAdjust(_groundColorBase);

  Color get _groundColorDarkBase => _bySeasonValue(
        spring: const Color(0xFF5FA24C),
        summer: const Color(0xFF5C8F4B),
        autumn: const Color(0xFF8C651F),
        winter: const Color(0xFFD7E1EA),
      );
  Color get _groundColorDark =>
      bg.isDay ? _groundColorDarkBase : _nightAdjust(_groundColorDarkBase);

  Color get _foliageColorBase => _bySeasonValue(
        spring: const Color(0xFFF3A6C7),
        summer: const Color(0xFF3F7A3B),
        autumn: const Color(0xFFD46A2B),
        winter: const Color(0xFFE8EEF3),
      );
  Color get _foliageColor =>
      bg.isDay ? _foliageColorBase : _nightAdjust(_foliageColorBase);

  Color get _trunkColorBase => bg.season == Season.winter
      ? const Color(0xFF5A4A3E)
      : const Color(0xFF6B4A32);
  Color get _trunkColor =>
      bg.isDay ? _trunkColorBase : _nightAdjust(_trunkColorBase);

  void _paintGround(Canvas canvas, Size size) {
    final groundTop = size.height * 0.84;

    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, size.width, size.height),
      Paint()..color = _groundColor,
    );

    if (bg.season == Season.winter) {
      // Soft snow speckle instead of grass blades.
      final snowPaint = Paint()..color = _groundColorDark.withOpacity(0.7);
      for (double x = 4; x <= size.width; x += 18) {
        final y = groundTop + 6 + (x % 3) * 4;
        canvas.drawCircle(Offset(x, y), 1.6, snowPaint);
      }
    } else {
      final tuftPaint = Paint()
        ..color = _groundColorDark
        ..strokeWidth = 2;

      for (double x = 0; x <= size.width; x += 14) {
        final sway = math.sin(bg.time * 2 + x * 0.1) * 3;
        final h = 6 + 4 * (0.5 + 0.5 * math.sin(x * 0.3));
        canvas.drawLine(
          Offset(x, groundTop),
          Offset(x + sway, groundTop - h),
          tuftPaint,
        );
      }
    }

    _drawBush(canvas, Offset(size.width * 0.12, groundTop));
    _drawTree(canvas, Offset(size.width * 0.5, groundTop));
    _drawBush(canvas, Offset(size.width * 0.88, groundTop));
  }

  void _drawBush(Canvas canvas, Offset base) {
    final paint = Paint()..color = _foliageColor;
    canvas.drawCircle(base + const Offset(-10, -10), 12, paint);
    canvas.drawCircle(base + const Offset(6, -14), 14, paint);
    canvas.drawCircle(base + const Offset(16, -6), 10, paint);
  }

  void _drawTree(Canvas canvas, Offset base) {
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 4, base.dy - 26, 8, 26),
      Paint()..color = _trunkColor,
    );

    final leafPaint = Paint()..color = _foliageColor;
    canvas.drawCircle(base + const Offset(0, -38), 22, leafPaint);
    canvas.drawCircle(base + const Offset(-16, -28), 16, leafPaint);
    canvas.drawCircle(base + const Offset(16, -28), 16, leafPaint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter old) => true;
}
