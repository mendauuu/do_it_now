import 'package:flutter_test/flutter_test.dart';

import 'package:do_it_now/musketeer_pomodoro/models.dart';
import 'package:do_it_now/musketeer_pomodoro/pomodoro_timer.dart';

// A tiny controllable clock so tests can jump time forward instantly
// instead of actually waiting, and can simulate "the app sat
// backgrounded for N minutes" as a single jump rather than a real
// gap in wall-clock time.
class _FakeClock {
  DateTime _now;
  _FakeClock(this._now);

  DateTime call() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

void main() {
  group('PomodoroTimer — phase transitions', () {
    test('starts in focus with the configured focus duration', () {
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 25, breakMinutes: 5),
      );

      expect(timer.phase, PomodoroPhase.focus);
      expect(timer.remainingSeconds, 25 * 60);
      expect(timer.running, isFalse);
      expect(timer.completedFocusSessions, 0);
    });

    test('a finished focus phase switches to break and counts the session', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(
            focusMinutes: 1, breakMinutes: 1, longBreakMinutes: 5),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(seconds: 60));
      timer.tick();

      expect(timer.phase, PomodoroPhase.breakTime);
      expect(timer.completedFocusSessions, 1);
      expect(timer.remainingSeconds, 60); // 1 break minute
    });

    test('a finished break switches back to focus without counting a session',
        () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 1, breakMinutes: 1),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(seconds: 60));
      timer.tick(); // focus -> break
      clock.advance(const Duration(seconds: 60));
      timer.tick(); // break -> focus

      expect(timer.phase, PomodoroPhase.focus);
      expect(timer.completedFocusSessions, 1); // unchanged by the break ending
    });

    test('reports the finished phase and its duration via onSessionCompleted',
        () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 1, breakMinutes: 2),
        now: clock.call,
      );

      final completed = <CompletedSession>[];
      timer.onSessionCompleted = completed.add;

      timer.start();
      clock.advance(const Duration(seconds: 60));
      timer.tick();

      expect(completed, hasLength(1));
      expect(completed.single.phase, PomodoroPhase.focus);
      expect(completed.single.durationSeconds, 60);
    });

    test('pause stops the countdown; resuming does not lose the remaining time',
        () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 10),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(minutes: 4));
      timer.tick();
      expect(timer.remainingSeconds, 6 * 60);

      timer.pause();
      clock.advance(const Duration(minutes: 30)); // time passes while paused
      expect(timer.remainingSeconds, 6 * 60); // untouched — tick() is a no-op

      timer.start(); // resumes with whatever was left
      clock.advance(const Duration(minutes: 1));
      timer.tick();
      expect(timer.remainingSeconds, 5 * 60);
    });

    test(
        'reset returns the current phase to its full duration and stops running',
        () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 10),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(minutes: 3));
      timer.tick();

      timer.reset();

      expect(timer.running, isFalse);
      expect(timer.remainingSeconds, 10 * 60);
    });
  });

  group('PomodoroTimer — long-break cadence', () {
    test('every 4th completed focus session gets the long break', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(
          focusMinutes: 1,
          breakMinutes: 1,
          longBreakMinutes: 5,
          sessionsBeforeLongBreak: 4,
        ),
        now: clock.call,
      );

      final isLongBreakAfterSession = <bool>[];

      for (var session = 1; session <= 8; session++) {
        timer.start(); // focus
        clock.advance(const Duration(seconds: 60));
        timer.tick(); // -> break
        isLongBreakAfterSession.add(timer.isLongBreak);

        // Finish the break (long or short) to get back to focus for
        // the next loop iteration.
        timer.start();
        clock.advance(Duration(seconds: timer.remainingSeconds));
        timer.tick();
      }

      expect(
        isLongBreakAfterSession,
        [false, false, false, true, false, false, false, true],
      );
    });

    test('sessionsBeforeLongBreak is configurable', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(
          focusMinutes: 1,
          breakMinutes: 1,
          longBreakMinutes: 5,
          sessionsBeforeLongBreak: 2,
        ),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(seconds: 60));
      timer.tick();
      expect(timer.isLongBreak, isFalse, reason: 'session 1 of 2');

      timer.start();
      clock.advance(const Duration(seconds: 60));
      timer.tick(); // break -> focus
      timer.start();
      clock.advance(const Duration(seconds: 60));
      timer.tick(); // focus -> break
      expect(timer.isLongBreak, isTrue, reason: 'session 2 of 2');
    });
  });

  group('PomodoroTimer — background-resume accuracy', () {
    test(
        'a single tick after a long gap reflects the real elapsed time, '
        'not one tick worth of progress', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 25),
        now: clock.call,
      );

      timer.start();

      // Simulate the app sitting backgrounded for 10 minutes — no
      // tick() calls happen while backgrounded, then one fires the
      // moment it's foregrounded again.
      clock.advance(const Duration(minutes: 10));
      timer.tick();

      expect(timer.remainingSeconds, 15 * 60);
    });

    test('a gap long enough to finish the phase switches it in one tick', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 25, breakMinutes: 5),
        now: clock.call,
      );
      timer.start();

      // Backgrounded for way longer than the whole focus session.
      clock.advance(const Duration(minutes: 40));
      timer.tick();

      expect(timer.phase, PomodoroPhase.breakTime);
      expect(timer.completedFocusSessions, 1);
    });

    test('remaining time never goes negative on an overshoot', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 1),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(minutes: 5));
      timer.tick();

      expect(timer.remainingSeconds, greaterThanOrEqualTo(0));
    });

    test('tick() is a no-op while paused, regardless of how much time passes',
        () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 10),
        now: clock.call,
      );

      // Never started — tick() should do nothing.
      clock.advance(const Duration(hours: 2));
      timer.tick();

      expect(timer.remainingSeconds, 10 * 60);
      expect(timer.phase, PomodoroPhase.focus);
    });
  });

  group('PomodoroTimer — settings updates', () {
    test('updateSettings snaps the countdown immediately when not running', () {
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 25),
      );

      timer.updateSettings(const PomodoroSettings(focusMinutes: 50));

      expect(timer.remainingSeconds, 50 * 60);
    });

    test('updateSettings does not disturb an active countdown', () {
      final clock = _FakeClock(DateTime(2026));
      final timer = PomodoroTimer(
        settings: const PomodoroSettings(focusMinutes: 25),
        now: clock.call,
      );

      timer.start();
      clock.advance(const Duration(minutes: 5));
      timer.tick();
      expect(timer.remainingSeconds, 20 * 60);

      // Changing the setting mid-flight shouldn't yank 20:00 to 50:00.
      timer.updateSettings(const PomodoroSettings(focusMinutes: 50));
      expect(timer.remainingSeconds, 20 * 60);
    });
  });
}
