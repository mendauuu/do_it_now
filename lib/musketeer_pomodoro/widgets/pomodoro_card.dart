import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import 'clock_faces.dart';

/// The glass FOCUS/BREAK card: phase label, countdown ring, session
/// count, and play/pause/reset controls.
///
/// While running it collapses down to just the ring so the scene
/// isn't cluttered — tap it to bring the full card back. Everything
/// it needs comes in through the constructor, so it doesn't know or
/// care that its data ultimately comes from a Ticker upstream.
class PomodoroCard extends StatelessWidget {
  final ValueListenable<BgSnap> bgListenable;
  final ValueListenable<int> clockListenable;
  final bool running;
  final bool showControls;
  final VoidCallback onRevealControls;
  final VoidCallback onToggleRunning;
  final VoidCallback onReset;
  final ClockStyle clockStyle;
  final VoidCallback? onCycleClockStyle; // long-press the clock

  const PomodoroCard({
    super.key,
    required this.bgListenable,
    required this.clockListenable,
    required this.running,
    required this.showControls,
    required this.onRevealControls,
    required this.onToggleRunning,
    required this.onReset,
    this.clockStyle = ClockStyle.ring,
    this.onCycleClockStyle,
  });

  Widget _face(BgSnap bg, int seconds, double size) {
    return GestureDetector(
      onLongPress: onCycleClockStyle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ClockFace(
          key: ValueKey(clockStyle),
          style: clockStyle,
          seconds: seconds,
          progress: bg.phaseProgress,
          isDay: bg.isDay,
          running: running,
          time: bg.time,
          size: size,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Both branches are driven by the listenables so the numbers
    // actually tick every second instead of freezing.
    return ValueListenableBuilder<BgSnap>(
      valueListenable: bgListenable,
      builder: (_, bg, __) {
        return ValueListenableBuilder<int>(
          valueListenable: clockListenable,
          builder: (_, seconds, __) {
            if (running && !showControls) {
              return GestureDetector(
                onTap: onRevealControls,
                child: _face(bg, seconds, 230),
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    // Warm gold-tinted glass instead of plain white —
                    // reads like it belongs to the same sunset world
                    // as the sky and clouds behind it, day or night.
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: bg.isDay
                          ? [
                              Colors.white.withOpacity(0.22),
                              const Color(0xFFCB8A4A).withOpacity(0.16),
                            ]
                          : [
                              Colors.white.withOpacity(0.14),
                              const Color(0xFF3A3560).withOpacity(0.18),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFE8C77A).withOpacity(0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bg.isFocus
                            ? 'FOCUS'
                            : (bg.isLongBreak ? 'LONG BREAK' : 'BREAK'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _Flourish(),
                      const SizedBox(height: 10),
                      _face(bg, seconds, 210),
                      const SizedBox(height: 8),
                      Text(
                        'Sessions completed: ${bg.completedFocusSessions}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CircleIconButton(
                            icon: running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onTap: onToggleRunning,
                          ),
                          const SizedBox(width: 20),
                          _CircleIconButton(
                            icon: Icons.refresh_rounded,
                            onTap: onReset,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A small gold line-diamond-line flourish — the kind of understated
/// decorative divider a wax seal or an old map legend would use.
/// Purely cosmetic, sized to sit between the phase label and the ring.
class _Flourish extends StatelessWidget {
  const _Flourish();

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: 28,
      height: 1,
      color: const Color(0xFFE8C77A).withOpacity(0.65),
    );
    final diamond = Transform.rotate(
      angle: 0.785398, // 45°
      child: Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8C77A).withOpacity(0.85),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [line, diamond, line],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8C77A).withOpacity(0.28),
      shape: CircleBorder(
        side: BorderSide(color: const Color(0xFFE8C77A).withOpacity(0.5)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
