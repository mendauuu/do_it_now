import 'dart:math' as math;

import 'package:do_it_now/musketeer_pomodoro/character_director.dart';
import 'package:do_it_now/musketeer_pomodoro/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const w = 400.0;
  late CharacterDirector d;
  double time = 0;

  void run(int frames,
      {PomodoroPhase phase = PomodoroPhase.focus,
      bool running = false,
      double progress = 0,
      bool isLongBreak = false}) {
    for (int i = 0; i < frames; i++) {
      time += 0.12;
      d.step(
        screenW: w,
        time: time,
        phase: phase,
        running: running,
        progress: progress,
        isLongBreak: isLongBreak,
      );
    }
  }

  setUp(() {
    d = CharacterDirector(random: math.Random(1));
    time = 0;
  });

  test('walks in and waits at the start before a session', () {
    run(200);
    expect(d.x, CharacterDirector.startX(w));
    expect(d.isMoving, isFalse);
  });

  test('travels toward the goal in step with focus progress', () {
    run(200);
    run(300, running: true, progress: 0.5);
    final halfway = CharacterDirector.startX(w) +
        (CharacterDirector.goalX(w) - CharacterDirector.startX(w)) * 0.5;
    expect(d.x, closeTo(halfway, 1));

    run(300, running: true, progress: 1);
    expect(d.x, closeTo(CharacterDirector.goalX(w), 1));
  });

  test('gets hurt and stays put when paused mid-focus', () {
    run(200);
    run(300, running: true, progress: 0.3);
    final before = d.x;
    run(1, progress: 0.3);
    expect(d.anim, Anim.hurt);
    expect(d.bubble, isNotNull);
    run(100, progress: 0.3);
    expect(d.x, before);
  });

  test('jumps straight into place after being away, no catch-up run', () {
    run(200);
    run(300, running: true, progress: 0.1);

    // Came back much later: focus already finished, break underway.
    d.placeInstantly(
      screenW: w,
      time: time,
      phase: PomodoroPhase.breakTime,
      running: true,
      progress: 0.3,
    );
    expect(d.x, CharacterDirector.campX(w));
    expect(d.isMoving, isFalse);

    // And it doesn't replay the victory it missed.
    run(1, phase: PomodoroPhase.breakTime, running: true, progress: 0.3);
    expect(d.anim, isNot(Anim.jump));
    expect(d.x, CharacterDirector.campX(w));
  });

  test('celebrates, rests at camp on break, then heads back', () {
    run(200);
    run(400, running: true, progress: 1);
    run(1, phase: PomodoroPhase.breakTime, running: true, progress: 0);
    expect(d.anim, Anim.jump);

    run(400, phase: PomodoroPhase.breakTime, running: true, progress: 0.4);
    expect(d.x, closeTo(CharacterDirector.campX(w), 1));

    run(400, phase: PomodoroPhase.breakTime, running: true, progress: 0.95);
    expect(d.x, closeTo(CharacterDirector.startX(w), 1));
  });
}
