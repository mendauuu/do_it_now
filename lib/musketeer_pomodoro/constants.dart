// Tunable constants for the Musketeer Pomodoro scene. Nothing here
// has any behavior of its own — it's just the dials other files read.

// ── Sprite ───────────────────────────────────────────────────

const double kSize = 128.0;

// Walk speed
const double kWalkSpeed = 4.0;

// Run speed
const double kRunSpeed = 8.0;

// Animation frame speed
const int kMsPerFrame = 120;

// How many times Idle animation repeats
const int kIdleLoops = 2;

// ── Pomodoro ─────────────────────────────────────────────────
// Durations themselves now live in PomodoroSettings (models.dart) —
// they're user-configurable, so hardcoding them here would just be a
// second, easily-forgotten source of truth.

// How long the confetti burst lasts after finishing a focus session
const double kCelebrationDuration = 2.5;
