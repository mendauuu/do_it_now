import 'dart:ui';

// ── Background "life" definitions ─────────────────────────────
// Fixed, deterministic layouts (golden-ratio spacing) so stars/
// clouds/birds/bats/fireflies/precipitation/confetti look naturally
// scattered without needing a Random() seed kept around. Only
// BackgroundPainter reads these.

final List<Offset> kStarSeeds = List.generate(40, (i) {
  final x = (i * 0.6180339887) % 1.0;
  final y = (i * 0.4114328) % 0.55;
  return Offset(x, y);
});

class CloudDef {
  final double yf, scale, speed, phase;
  const CloudDef(this.yf, this.scale, this.speed, this.phase);
}

const List<CloudDef> kClouds = [
  CloudDef(0.12, 1.0, 14, 0),
  CloudDef(0.22, 0.7, 10, 140),
  CloudDef(0.08, 1.3, 18, 320),
  CloudDef(0.30, 0.55, 9, 520),
];

class BirdDef {
  final double baseYf, speed, bobSpeed, bobAmp, phase;
  const BirdDef(
      this.baseYf, this.speed, this.bobSpeed, this.bobAmp, this.phase);
}

const List<BirdDef> kBirds = [
  BirdDef(0.16, 55, 2.0, 8, 0),
  BirdDef(0.21, 46, 2.6, 6, 90),
  BirdDef(0.11, 62, 1.7, 10, 220),
];

// Bats stand in for birds at night — same shape of data, jitterier
// flight and a different wing silhouette when drawn.
const List<BirdDef> kBats = [
  BirdDef(0.14, 40, 3.0, 12, 30),
  BirdDef(0.19, 34, 3.6, 10, 160),
  BirdDef(0.24, 46, 2.8, 14, 260),
];

class FireflyDef {
  final double xf, yf, phase;
  const FireflyDef(this.xf, this.yf, this.phase);
}

final List<FireflyDef> kFireflies = List.generate(12, (i) {
  final xf = (i * 0.618) % 1.0;
  final yf = 0.80 + ((i * 0.271) % 0.13);
  return FireflyDef(xf, yf, i * 1.3);
});

// One particle layout, reused for whichever precipitation the
// current season calls for (snow in winter, leaves in autumn, petals
// in spring — summer stays clear). Only the color/shape/speed the
// painter applies differs per season, not the underlying positions.
class PrecipitationDef {
  final double xf, speed, sway, phase, size;
  const PrecipitationDef(this.xf, this.speed, this.sway, this.phase, this.size);
}

final List<PrecipitationDef> kPrecipitation = List.generate(14, (i) {
  final xf = (i * 0.618) % 1.0;
  return PrecipitationDef(
    xf,
    14 + (i % 4) * 5,
    8 + (i % 3) * 4,
    i * 0.9,
    3 + (i % 3).toDouble(),
  );
});

class ConfettiDef {
  final double xf, vy, vxAmp, colorIdx, phase;
  const ConfettiDef(this.xf, this.vy, this.vxAmp, this.colorIdx, this.phase);
}

final List<ConfettiDef> kConfetti = List.generate(24, (i) {
  final xf = (i * 0.37) % 1.0;
  return ConfettiDef(
    xf,
    60 + (i % 5) * 20,
    20 + (i % 4) * 10,
    (i % 5).toDouble(),
    i * 0.5,
  );
});
