import 'dart:math' as math;

import 'constants.dart';
import 'models.dart';

/// Decides what the musketeer is doing, so the character tells the
/// story of the Pomodoro session instead of looping at random:
///
/// * **Ready** (focus not started): waits at the start of the path,
///   stretching now and then.
/// * **Quest** (focus running): travels toward the goal flag in step
///   with the timer — the walk is the session's progress — and stops
///   along the way to fight off "distractions" with sword combos.
/// * **Paused**: takes a hit from a distraction, then waits.
/// * **Victory** (focus finished): jumps and flourishes the sword.
/// * **Camp** (break): heads to the campfire and rests; near the end
///   of the break, walks back to the start for the next quest.
///
/// Pure Dart (no Flutter) so it can be unit-tested. Call [step] once
/// per animation frame with the current timer state.
class CharacterDirector {
  CharacterDirector({math.Random? random}) : _rng = random ?? math.Random();

  final math.Random _rng;

  // ── Output read by the screen each frame ──────────────────────
  Anim anim = Anim.walk;
  int frame = 0;
  double x = -kSize; // enters from off-screen left
  bool facingLeft = false;
  String? bubble;

  bool get isMoving => anim == Anim.walk || anim == Anim.run;

  // ── Internal state ───────────────────────────────────────────
  final List<Anim> _queue = []; // one-shot actions to play in order
  bool _moving = false;
  int _idleLoops = 0;
  int _idleLoopsBeforeAction = 3;
  double _bubbleUntil = 0;
  double _nextChatter = 8;
  bool _announcedReturn = false;

  bool _initialized = false;
  PomodoroPhase _lastPhase = PomodoroPhase.focus;
  bool _lastRunning = false;

  // ── Layout ───────────────────────────────────────────────────
  // Positions are fractions of screen width so they line up with the
  // background painter's campfire (0.68) on every screen size.
  static double startX(double w) => w * 0.04;
  static double goalX(double w) => w - kSize - w * 0.04;
  static double campX(double w) => w * 0.68 - kSize * 0.85;

  /// Where the goal flag stands (its pole), for the background.
  static double goalFlagX(double w) => goalX(w) + kSize * 0.62;

  void step({
    required double screenW,
    required double time,
    required PomodoroPhase phase,
    required bool running,
    required double progress,
    required bool isLongBreak,
  }) {
    if (screenW <= 0) return;

    _handleEvents(time, phase, running, progress, isLongBreak);

    final mode = _modeFor(phase, running, progress);
    final target = _targetFor(mode, screenW, progress);

    if (_queue.isNotEmpty || _isOneShot(anim)) {
      _playOneShot();
    } else if (_shouldMove(mode, target)) {
      _moveToward(target);
    } else {
      _rest(mode, time);
    }

    _chatter(mode, time, isLongBreak);
    if (bubble != null && time >= _bubbleUntil) bubble = null;
  }

  /// Jump straight to where the character should be right now, with
  /// no walking or catch-up — for coming back after the screen wasn't
  /// animating (another page on top, or the app in the background).
  void placeInstantly({
    required double screenW,
    required double time,
    required PomodoroPhase phase,
    required bool running,
    required double progress,
  }) {
    if (screenW <= 0 || !_initialized) return;

    final phaseChanged = phase != _lastPhase;
    final mode = _modeFor(phase, running, progress);

    x = mode == _Mode.paused && !phaseChanged
        ? x
        : _targetFor(mode, screenW, progress);
    facingLeft = false;
    _queue.clear();
    _moving = false;
    _set(Anim.idle);

    // Mark the current state as already seen, so we don't replay a
    // victory or pause reaction for something that happened while away.
    _lastPhase = phase;
    _lastRunning = running;
    _announcedReturn = mode == _Mode.returning;

    if (running) {
      _say(
        time,
        phaseChanged && phase == PomodoroPhase.breakTime
            ? 'Quest done while you were away — rest time!'
            : 'Welcome back! I kept going.',
        3.5,
      );
    }
  }

  // ── Events: react once when the timer changes state ──────────

  void _handleEvents(double time, PomodoroPhase phase, bool running,
      double progress, bool isLongBreak) {
    if (!_initialized) {
      _initialized = true;
      _lastPhase = phase;
      _lastRunning = running;
      _say(time, 'Hello! Ready for a quest?', 4);
      return;
    }

    if (_lastPhase == PomodoroPhase.focus &&
        phase == PomodoroPhase.breakTime) {
      _queue
        ..clear()
        ..addAll([Anim.jump, Anim.attack3, Anim.jump]);
      _say(time, _pick(_victoryLines), 4);
      _announcedReturn = false;
    } else if (_lastPhase == PomodoroPhase.breakTime &&
        phase == PomodoroPhase.focus) {
      _say(time, 'A new quest begins!', 3);
    } else if (running && !_lastRunning) {
      _queue.clear();
      if (phase == PomodoroPhase.focus) {
        _say(time, progress < 0.01 ? 'To adventure!' : 'Back on the road!', 3);
      } else {
        _say(time, isLongBreak ? 'A long rest — well earned.' : 'Rest well.',
            3);
      }
    } else if (!running && _lastRunning) {
      if (phase == PomodoroPhase.focus && progress > 0) {
        _queue
          ..clear()
          ..add(Anim.hurt);
        _say(time, 'Oof, a distraction! I\'ll wait here.', 4);
      } else if (progress > 0) {
        _say(time, 'Taking it easy…', 3);
      }
    }

    _lastPhase = phase;
    _lastRunning = running;
  }

  // ── Mode and target position ─────────────────────────────────

  _Mode _modeFor(PomodoroPhase phase, bool running, double progress) {
    if (phase == PomodoroPhase.focus) {
      if (running) return _Mode.quest;
      return progress < 0.001 ? _Mode.ready : _Mode.paused;
    }
    if (!running && progress > 0) return _Mode.paused;
    return progress < 0.85 ? _Mode.camp : _Mode.returning;
  }

  double _targetFor(_Mode mode, double w, double progress) {
    switch (mode) {
      case _Mode.ready:
      case _Mode.returning:
        return startX(w);
      case _Mode.quest:
        return startX(w) + (goalX(w) - startX(w)) * progress;
      case _Mode.camp:
        return campX(w);
      case _Mode.paused:
        return x;
    }
  }

  bool _shouldMove(_Mode mode, double target) {
    final dist = (target - x).abs();
    if (_moving) return dist > 0.5;
    // While questing, the target creeps forward a fraction of a pixel
    // per second — wait until it's a few steps ahead so the musketeer
    // marches in short, purposeful bursts instead of shuffling.
    final threshold = mode == _Mode.quest && target > x ? 28.0 : 2.0;
    return dist > threshold;
  }

  // ── Behaviors ────────────────────────────────────────────────

  void _moveToward(double target) {
    final dist = target - x;
    final next = dist.abs() > 140 ? Anim.run : Anim.walk;
    if (anim != next) _set(next);
    _moving = true;

    facingLeft = dist < 0;
    final speed = next == Anim.run ? kRunSpeed : kWalkSpeed;
    x += dist.sign * math.min(speed, dist.abs());
    frame = (frame + 1) % animConfig[anim]!.frames;

    if ((target - x).abs() <= 0.5) {
      x = target;
      _moving = false;
      _set(Anim.idle);
    }
  }

  void _playOneShot() {
    if (!_isOneShot(anim)) {
      _set(_queue.removeAt(0));
      return;
    }
    frame++;
    if (frame >= animConfig[anim]!.frames) {
      if (_queue.isNotEmpty) {
        _set(_queue.removeAt(0));
      } else {
        _set(Anim.idle);
      }
    }
  }

  void _rest(_Mode mode, double time) {
    if (anim != Anim.idle) _set(Anim.idle);
    // Face forward along the path, or toward the fire at camp.
    facingLeft = false;

    frame++;
    if (frame < animConfig[Anim.idle]!.frames) return;
    frame = 0;
    _idleLoops++;
    if (_idleLoops < _idleLoopsBeforeAction) return;
    _idleLoops = 0;

    switch (mode) {
      case _Mode.quest:
        // Fight off a distraction: a short random sword combo.
        final combo = 1 + _rng.nextInt(3);
        for (int i = 0; i < combo; i++) {
          _queue.add(_pick([
            Anim.attack1,
            Anim.attack2,
            Anim.attack3,
            Anim.attack4,
          ]));
        }
        if (bubble == null && _rng.nextDouble() < 0.35) {
          _say(time, _pick(_fightLines), 2.5);
        }
        _idleLoopsBeforeAction = 3 + _rng.nextInt(4);
      case _Mode.ready:
        if (_rng.nextDouble() < 0.5) _queue.add(Anim.jump);
        _idleLoopsBeforeAction = 4 + _rng.nextInt(4);
      case _Mode.camp:
      case _Mode.paused:
      case _Mode.returning:
        _idleLoopsBeforeAction = 6;
    }
  }

  void _chatter(_Mode mode, double time, bool isLongBreak) {
    if (mode == _Mode.returning && !_announcedReturn) {
      _announcedReturn = true;
      _say(time, 'Almost time — back to the road!', 3.5);
      return;
    }
    if (time < _nextChatter || bubble != null) return;
    _nextChatter = time + 25 + _rng.nextInt(20);

    final lines = switch (mode) {
      _Mode.ready => _readyLines,
      _Mode.quest => _questLines,
      _Mode.camp => isLongBreak ? _longRestLines : _restLines,
      _Mode.paused => _pausedLines,
      _Mode.returning => null,
    };
    if (lines != null) _say(time, _pick(lines), 3.5);
  }

  // ── Helpers ──────────────────────────────────────────────────

  void _set(Anim next) {
    anim = next;
    frame = 0;
    if (next == Anim.idle) _idleLoops = 0;
  }

  void _say(double time, String text, double seconds) {
    bubble = text;
    _bubbleUntil = time + seconds;
  }

  T _pick<T>(List<T> items) => items[_rng.nextInt(items.length)];

  static bool _isOneShot(Anim a) =>
      a != Anim.idle && a != Anim.walk && a != Anim.run;

  // ── Lines ────────────────────────────────────────────────────

  static const _readyLines = [
    'Tap play and we set off!',
    'The road awaits, friend.',
    'One quest at a time.',
  ];
  static const _questLines = [
    'Halfway is still progress!',
    'Steady steps win the day.',
    'Keep going — I\'m with you!',
    'Eyes on the flag!',
    'Phones are dragons. Ignore them.',
  ];
  static const _fightLines = [
    'Begone, distraction!',
    'Not today!',
    'Stay sharp!',
    'En garde!',
  ];
  static const _victoryLines = [
    'Victory! Quest complete!',
    'We made it! Well fought!',
    'Huzzah! Another one done!',
  ];
  static const _restLines = [
    'Stretch your legs a bit.',
    'Have some water, friend.',
    'Look away from the screen.',
  ];
  static const _longRestLines = [
    'A long rest. You earned it!',
    'Take a real break — walk around.',
  ];
  static const _pausedLines = [
    'I\'ll hold the path for you.',
    'Ready when you are.',
  ];
}

enum _Mode { ready, quest, paused, camp, returning }
