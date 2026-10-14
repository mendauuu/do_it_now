import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws a single frame from a horizontal sprite sheet (128×128 per
/// frame) with no smoothing, so the pixel art stays crisp.
class SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frame;
  final int frameCount;
  final bool flip; // mirror horizontally to face left

  const SpritePainter({
    required this.image,
    required this.frame,
    required this.frameCount,
    this.flip = false,
  });

  // Every Musketeer frame is 128 × 128.
  static const double _fw = 128;
  static const double _fh = 128;

  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      image,

      // Source frame
      Rect.fromLTWH(
        frame * _fw,
        0,
        _fw,
        _fh,
      ),

      // Destination
      Offset.zero & size,

      _paint,
    );
  }

  @override
  bool shouldRepaint(SpritePainter old) {
    return old.frame != frame ||
        old.image != image ||
        old.frameCount != frameCount ||
        old.flip != flip;
  }
}
