import 'dart:ui' as ui;

// ── Animation enum ────────────────────────────────────────────

enum Anim { idle, walk, run, jump, hurt, attack1, attack2, attack3, attack4 }

// ── Animation config ──────────────────────────────────────────

class AnimCfg {
  final String asset;
  final int frames;

  const AnimCfg(this.asset, this.frames);
}

const animConfig = <Anim, AnimCfg>{
  Anim.idle: AnimCfg('assets/Musketeer/Idle.png', 5),
  Anim.walk: AnimCfg('assets/Musketeer/Walk.png', 8),
  Anim.run: AnimCfg('assets/Musketeer/Run.png', 8),
  Anim.jump: AnimCfg('assets/Musketeer/Jump.png', 7),
  Anim.hurt: AnimCfg('assets/Musketeer/Hurt.png', 2),
  Anim.attack1: AnimCfg('assets/Musketeer/Attack_1.png', 5),
  Anim.attack2: AnimCfg('assets/Musketeer/Attack_2.png', 4),
  Anim.attack3: AnimCfg('assets/Musketeer/Attack_3.png', 6),
  Anim.attack4: AnimCfg('assets/Musketeer/Attack_4.png', 5),
};

// ── Immutable visual snapshot ────────────────────────────────
// What the sprite painter needs to draw one frame. Rebuilt each time
// the character's animation state advances.

class CharSnap {
  final double x;
  final int frame;
  final int frameCount;
  final ui.Image? image;
  final bool facingLeft;
  final String? bubble; // what the character is saying, if anything

  const CharSnap({
    required this.x,
    required this.frame,
    required this.frameCount,
    required this.image,
    this.facingLeft = false,
    this.bubble,
  });
}

// ── Settings ─────────────────────────────────────────────────
// How much of the scene renders. `off` is the plain solid-color
// background this screen started as; `simple` keeps the sky and
// sun/moon but drops mountains/castle/windmill/wildlife; `full` is
// everything.
enum SceneMode { off, simple, full }

// The scene's season — affects ground/foliage color, mountain snow
// caps, river tint, and which precipitation falls (petals/leaves/
// snow). `summer` is the original look this screen started with.
// Architected as a plain enum + a switch per visual, so adding a
// fifth season later is a matter of extending those switches and the
// settings picker, not redesigning anything.
enum Season { spring, summer, autumn, winter }

// Overrides which half of the day/night cycle is shown, independent
// of the actual Pomodoro phase. `auto` is the original behavior
// (focus = day, break = night); `day`/`night` pin the scene to one
// or the other regardless of phase — e.g. for someone who wants the
// night scene while studying during the day, or vice versa.
enum TimeOfDayMode { auto, day, night }

// How the countdown itself is drawn — see widgets/clock_faces.dart.
enum ClockStyle { ring, dial, hourglass, candle, flip, minimal }

// When the relaxing background sounds play — see audio/ambient_sounds.dart.
enum SoundMode { always, focus, breaks }

// ── Topics ───────────────────────────────────────────────────
// What a session was actually for — "Studying", "Work", or anything
// custom someone adds. Built-in topics can't be deleted; anything
// else the person typed in can be.

class Topic {
  final String id;
  final String name;
  final bool isBuiltIn;

  const Topic({required this.id, required this.name, this.isBuiltIn = false});
}

class PomodoroSettings {
  final int focusMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final SceneMode sceneMode;
  final Season season;
  final TimeOfDayMode timeOfDayMode;
  final String currentTopicId;
  final int dailyGoalMinutes;
  final ClockStyle clockStyle;
  final bool soundsOn; // master switch for background sounds
  final SoundMode soundMode;
  final Map<String, double> soundVolumes; // sound id -> 0..1 (absent = off)

  const PomodoroSettings({
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.sceneMode = SceneMode.full,
    this.season = Season.summer,
    this.timeOfDayMode = TimeOfDayMode.auto,
    this.currentTopicId = 'work',
    this.dailyGoalMinutes = 100,
    this.clockStyle = ClockStyle.ring,
    this.soundsOn = false,
    this.soundMode = SoundMode.always,
    this.soundVolumes = const {},
  });

  int get focusSeconds => focusMinutes * 60;
  int get breakSeconds => breakMinutes * 60;
  int get longBreakSeconds => longBreakMinutes * 60;

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    SceneMode? sceneMode,
    Season? season,
    TimeOfDayMode? timeOfDayMode,
    String? currentTopicId,
    int? dailyGoalMinutes,
    ClockStyle? clockStyle,
    bool? soundsOn,
    SoundMode? soundMode,
    Map<String, double>? soundVolumes,
  }) {
    return PomodoroSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      sceneMode: sceneMode ?? this.sceneMode,
      season: season ?? this.season,
      timeOfDayMode: timeOfDayMode ?? this.timeOfDayMode,
      currentTopicId: currentTopicId ?? this.currentTopicId,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      clockStyle: clockStyle ?? this.clockStyle,
      soundsOn: soundsOn ?? this.soundsOn,
      soundMode: soundMode ?? this.soundMode,
      soundVolumes: soundVolumes ?? this.soundVolumes,
    );
  }
}

// ── Pomodoro phase ───────────────────────────────────────────

enum PomodoroPhase { focus, breakTime }

// ── Completed session (reported outward for persistence) ──────
// Emitted once per finished phase. The screen persists this itself
// (see data/pomodoro_sessions_repository.dart) so nothing is lost
// even if no host app is listening — but it's still also handed to
// the optional onSessionCompleted callback for anything external
// that wants it too.

class CompletedSession {
  final PomodoroPhase phase;
  final int durationSeconds;
  final DateTime completedAt;
  final String? topicId;
  final String? topicName;

  const CompletedSession({
    required this.phase,
    required this.durationSeconds,
    required this.completedAt,
    this.topicId,
    this.topicName,
  });
}

// ── Background snapshot (drives sky/mountains/sun/stars/etc) ─
// What the background painter and the Pomodoro card both need each
// frame. Rebuilding this is cheap — it's just a handful of numbers —
// so it's recomputed every tick rather than tracked incrementally.

class BgSnap {
  final double time; // continuous seconds, always advancing
  final bool isDay; // day/night look — see TimeOfDayMode
  final bool isFocus; // actual Pomodoro phase, independent of isDay
  final double phaseProgress; // 0..1 through the current phase
  final int completedFocusSessions;
  final bool isLongBreak; // every Nth break is the longer one
  final double charX; // for dust puffs behind the character
  final bool isMoving; // walk/run vs idle
  final bool facingLeft; // dust trails behind, whichever way that is
  final double? goalFlagX; // quest destination flag, shown during focus
  final double secondsSinceCelebration; // negative-ish/huge = not celebrating
  final SceneMode sceneMode;
  final Season season;

  const BgSnap({
    required this.time,
    required this.isDay,
    required this.isFocus,
    required this.phaseProgress,
    required this.completedFocusSessions,
    required this.isLongBreak,
    required this.charX,
    required this.isMoving,
    this.facingLeft = false,
    this.goalFlagX,
    required this.secondsSinceCelebration,
    required this.sceneMode,
    required this.season,
  });
}
