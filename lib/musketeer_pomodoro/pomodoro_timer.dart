import 'models.dart';

/// Pure state machine for the Pomodoro timer — no Flutter, no
/// Ticker, no widgets. Everything time-related goes through [now]
/// (defaults to DateTime.now) so tests can fake the clock instead of
/// actually waiting, or trying to fast-forward a real Ticker to prove
/// backgrounding doesn't lose time.
class PomodoroTimer {
  PomodoroSettings settings;
  final DateTime Function() now;

  /// Fired once per finished phase, with what just ended (not what's
  /// starting next). Assign this after construction.
  void Function(CompletedSession session)? onSessionCompleted;

  PomodoroTimer({
    required this.settings,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    _remainingSeconds = settings.focusSeconds;
    _breakDurationSeconds = settings.breakSeconds;
  }

  PomodoroPhase _phase = PomodoroPhase.focus;
  late int _remainingSeconds;
  late int _breakDurationSeconds;
  bool _running = false;
  int _completedFocusSessions = 0;
  DateTime? _phaseEndTime;

  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get running => _running;
  int get completedFocusSessions => _completedFocusSessions;

  bool get isLongBreak =>
      _phase == PomodoroPhase.breakTime &&
      _breakDurationSeconds == settings.longBreakSeconds;

  double get phaseProgress {
    final total = _phase == PomodoroPhase.focus
        ? settings.focusSeconds
        : _breakDurationSeconds;
    if (total <= 0) return 1.0;
    return (1 - (_remainingSeconds / total)).clamp(0.0, 1.0);
  }

  void start() {
    if (_running) return;
    _running = true;
    _phaseEndTime = now().add(Duration(seconds: _remainingSeconds));
  }

  void pause() {
    _running = false;
    _phaseEndTime = null;
  }

  void reset() {
    _running = false;
    _phaseEndTime = null;
    _remainingSeconds = _phase == PomodoroPhase.focus
        ? settings.focusSeconds
        : _breakDurationSeconds;
  }

  /// Call this periodically (e.g. once a second from a Ticker). Safe
  /// to call more or less often than that, or after an arbitrarily
  /// long gap — it always recomputes from [now] rather than assuming
  /// how much time passed since the last call, so a single call after
  /// the app sat backgrounded for ten minutes still lands on the
  /// correct remaining time (and switches phase if it should have
  /// already), instead of quietly losing that time.
  void tick() {
    if (!_running) return;

    final endTime = _phaseEndTime;
    if (endTime == null) return;

    final remaining = endTime.difference(now()).inSeconds;
    _remainingSeconds = remaining < 0 ? 0 : remaining;

    if (_remainingSeconds <= 0) {
      _switchPhase();
    }
  }

  /// Apply new settings. If nothing is actively counting down, the
  /// current phase's remaining time snaps to the new numbers right
  /// away; if it's running, the change only takes effect starting the
  /// next phase, so an active countdown never jumps around underneath
  /// the person watching it.
  void updateSettings(PomodoroSettings newSettings) {
    settings = newSettings;
    if (!_running) {
      _breakDurationSeconds = newSettings.breakSeconds;
      _remainingSeconds = _phase == PomodoroPhase.focus
          ? newSettings.focusSeconds
          : _breakDurationSeconds;
    }
  }

  void _switchPhase() {
    // Capture what just finished before any of this gets overwritten
    // below for the next phase.
    final finishedPhase = _phase;
    final finishedDuration = finishedPhase == PomodoroPhase.focus
        ? settings.focusSeconds
        : _breakDurationSeconds;

    if (_phase == PomodoroPhase.focus) {
      _completedFocusSessions++;
      _phase = PomodoroPhase.breakTime;
      _breakDurationSeconds =
          _completedFocusSessions % settings.sessionsBeforeLongBreak == 0
              ? settings.longBreakSeconds
              : settings.breakSeconds;
      _remainingSeconds = _breakDurationSeconds;
    } else {
      _phase = PomodoroPhase.focus;
      _remainingSeconds = settings.focusSeconds;
    }
    // Still running into the next phase, so its end time starts now.
    _phaseEndTime = now().add(Duration(seconds: _remainingSeconds));

    onSessionCompleted?.call(CompletedSession(
      phase: finishedPhase,
      durationSeconds: finishedDuration,
      completedAt: now(),
    ));
  }
}
