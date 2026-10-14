import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'audio/ambient_sounds.dart';
import 'character_director.dart';
import 'constants.dart';
import 'data/pomodoro_sessions_repository.dart';
import 'data/settings_repository.dart';
import 'data/topics_repository.dart';
import 'models.dart';
import 'painters/background_painter.dart';
import 'painters/sprite_painter.dart';
import 'pomodoro_timer.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/clock_faces.dart';
import 'widgets/pomodoro_card.dart';
import 'widgets/sound_mixer.dart';

// ── Screen ───────────────────────────────────────────────────

class MusketeerAnimationScreen extends StatefulWidget {
  // Called once per finished phase (focus or break) with what just
  // happened, in addition to the screen persisting it locally itself
  // (see PomodoroSessionsRepository). Optional — this is an extra
  // hook for a host app that wants its own copy of the data too, not
  // something the screen's own correctness depends on.
  final ValueChanged<CompletedSession>? onSessionCompleted;

  const MusketeerAnimationScreen({super.key, this.onSessionCompleted});

  @override
  State<MusketeerAnimationScreen> createState() =>
      _MusketeerAnimationScreenState();
}

class _MusketeerAnimationScreenState extends State<MusketeerAnimationScreen>
    with SingleTickerProviderStateMixin {
  // ── Ticker ──────────────────────────────────────────────────

  // Whether the play/pause/reset row is visible. Auto-hides while
  // running for a clean full-screen clock; tap the clock to bring
  // it back, and it always reappears when paused.
  bool _showPomodoroControls = true;

  late final Ticker _ticker;

  Duration? _lastTick;
  Duration _elapsed = Duration.zero;

  // How much wall-clock time has accumulated since the last time we
  // bothered to call _pomodoroTimer.tick() — throttles that call to
  // roughly once a second instead of every animation frame.
  Duration _secondAccum = Duration.zero;

  // Continuous ambient clock — drives clouds/birds/bats/stars/
  // fireflies regardless of whether the Pomodoro timer is running.
  double _worldTime = 0;

  // World time at which the last focus session finished, for the
  // confetti burst. Starts far in the past so nothing shows at launch.
  double _lastCelebrationTime = -1000;

  // ── Animation state (sprite) ─────────────────────────────────

  // Decides what the musketeer does each frame based on the timer —
  // see character_director.dart for the story it tells.
  final _director = CharacterDirector();

  // Screen width
  double _screenW = 0;

  // ── Pomodoro state ───────────────────────────────────────────

  // Loaded from their repositories in initState; these defaults only
  // matter for the very first frame before those loads resolve.
  PomodoroSettings _settings = const PomodoroSettings();
  List<Topic> _topics = TopicsRepository.builtInTopics;

  final _settingsRepository = SettingsRepository();
  final _topicsRepository = TopicsRepository();
  final _sessionsRepository = PomodoroSessionsRepository();

  // The actual phase/countdown/long-break logic lives in this plain,
  // testable class — see pomodoro_timer.dart. This screen just drives
  // it from a Ticker and reflects its state into the UI.
  late final PomodoroTimer _pomodoroTimer;

  // ── Loaded images ───────────────────────────────────────────

  final Map<Anim, ui.Image?> _images = {
    for (final animation in Anim.values) animation: null,
  };

  // ── Notifiers ────────────────────────────────────────────────

  late final ValueNotifier<CharSnap> _notifier;
  late final ValueNotifier<BgSnap> _bgNotifier;
  late final ValueNotifier<int> _clockNotifier;

  // ── Init ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pomodoroTimer = PomodoroTimer(settings: _settings)
      ..onSessionCompleted = _handleSessionCompleted;

    _notifier = ValueNotifier(_snapshot());
    _bgNotifier = ValueNotifier(_bgSnapshot());
    _clockNotifier = ValueNotifier(_pomodoroTimer.remainingSeconds);

    _loadAll();
    _loadSettings();
    _loadTopics();

    _ticker = createTicker(_onTick)..start();
  }

  void _handleSessionCompleted(CompletedSession session) {
    // Tag the session with whatever topic is currently selected
    // before it goes anywhere — PomodoroTimer itself doesn't know
    // topics exist, on purpose (it's a pure state machine).
    final topicName = _topics
        .firstWhere(
          (t) => t.id == _settings.currentTopicId,
          orElse: () => TopicsRepository.builtInTopics.first,
        )
        .name;
    final tagged = CompletedSession(
      phase: session.phase,
      durationSeconds: session.durationSeconds,
      completedAt: session.completedAt,
      topicId: _settings.currentTopicId,
      topicName: topicName,
    );

    // Confetti alone means nothing if the phone's face-down or the
    // screen's locked — this is the part that actually tells someone
    // a session ended, regardless of whether they're looking.
    if (tagged.phase == PomodoroPhase.focus) {
      HapticFeedback.heavyImpact();
      _lastCelebrationTime = _worldTime; // triggers the confetti burst
    } else {
      HapticFeedback.mediumImpact();
    }
    SystemSound.play(SystemSoundType.alert);

    // Always saved locally, regardless of whether anything external
    // is listening — see class doc above.
    _sessionsRepository.record(tagged);
    widget.onSessionCompleted?.call(tagged);
  }

  Future<void> _loadSettings() async {
    final loaded = await _settingsRepository.load();
    if (!mounted) return;

    setState(() {
      _settings = loaded;
      // PomodoroTimer itself only snaps the countdown onto the new
      // numbers if nothing is actively running, so a mid-session
      // load can't yank the timer around.
      _pomodoroTimer.updateSettings(loaded);
    });
    _clockNotifier.value = _pomodoroTimer.remainingSeconds;
    _syncAudio(force: true);
  }

  Future<void> _loadTopics() async {
    final loaded = await _topicsRepository.loadAll();
    if (!mounted) return;
    setState(() => _topics = loaded);
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // SettingsScreen saves as changes happen rather than returning a
    // result, so the simplest way to pick up whatever changed —
    // durations, scene, season, topic, or the topic list itself — is
    // to just reload everything once it's popped.
    _loadSettings();
    _loadTopics();
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  // ── Image loading ───────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([
      for (final entry in animConfig.entries)
        _loadOne(entry.key, entry.value.asset),
    ]);
  }

  Future<void> _loadOne(Anim key, String path) async {
    try {
      final data = await rootBundle.load(path);

      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );

      final img = (await codec.getNextFrame()).image;

      if (!mounted) return;

      _images[key] = img;

      _notifier.value = _snapshot();
    } catch (e) {
      debugPrint('Failed to load $path: $e');
    }
  }

  // ── Ticker ──────────────────────────────────────────────────

  void _onTick(Duration ts) {
    final prev = _lastTick;

    _lastTick = ts;

    if (prev == null) return;

    final delta = ts - prev;

    // A long gap means the ticker was paused — another page was on
    // top, or the app was in the background. Don't replay that time
    // as animation frames (that's what made the musketeer sprint to
    // catch up); jump straight to where things should be instead.
    if (delta > const Duration(milliseconds: 500)) {
      _resumeAfterGap();
      return;
    }

    _elapsed += delta;
    _worldTime += delta.inMicroseconds / 1e6;

    if (_pomodoroTimer.running) {
      _secondAccum += delta;

      if (_secondAccum >= const Duration(seconds: 1)) {
        _secondAccum -= const Duration(seconds: 1);

        // PomodoroTimer.tick() recomputes remaining time from the
        // wall clock itself (see pomodoro_timer.dart) — this call
        // just needs to happen roughly once a second, it doesn't
        // need to track how much time actually passed.
        _pomodoroTimer.tick();
        _clockNotifier.value = _pomodoroTimer.remainingSeconds;
      }
    }

    if (_elapsed.inMilliseconds >= kMsPerFrame) {
      _elapsed -= const Duration(milliseconds: kMsPerFrame);

      _advance();
    }

    _syncAudio();

    // Ambient background repaints every frame (smooth clouds/birds/
    // bats/stars/fireflies/dust/confetti) even when the timer itself
    // is paused.
    _bgNotifier.value = _bgSnapshot();
  }

  void _resumeAfterGap() {
    _elapsed = Duration.zero;
    _secondAccum = Duration.zero;

    // The timer works from the wall clock, so one tick lands it on the
    // right remaining time (and phase) no matter how long we were away.
    if (_pomodoroTimer.running) {
      _pomodoroTimer.tick();
      _clockNotifier.value = _pomodoroTimer.remainingSeconds;
    }

    _director.placeInstantly(
      screenW: _screenW,
      time: _worldTime,
      phase: _pomodoroTimer.phase,
      running: _pomodoroTimer.running,
      progress: _pomodoroTimer.phaseProgress,
    );
    _notifier.value = _snapshot();
    _bgNotifier.value = _bgSnapshot();
  }

  // ── Pomodoro controls ─────────────────────────────────────────

  void _toggleRunning() {
    setState(() {
      if (_pomodoroTimer.running) {
        _pomodoroTimer.pause();
      } else {
        _pomodoroTimer.start();
      }
      // Hide the card while running for a clean look; always show
      // it again the moment it's paused so controls stay reachable.
      _showPomodoroControls = !_pomodoroTimer.running;
    });
  }

  void _resetPomodoro() {
    setState(() {
      _pomodoroTimer.reset();
      _showPomodoroControls = true;
      _secondAccum = Duration.zero;
    });

    _clockNotifier.value = _pomodoroTimer.remainingSeconds;
  }

  // ── Relaxing sounds ─────────────────────────────────────────

  // Whether the mix should be audible right now, per the person's
  // "play during" choice — re-checked every frame so phase changes and
  // pause/resume fade sounds in and out on their own.
  bool _audioShouldPlay() {
    if (!_settings.soundsOn || _settings.soundVolumes.isEmpty) return false;
    final running = _pomodoroTimer.running;
    return switch (_settings.soundMode) {
      SoundMode.always => true,
      SoundMode.focus =>
        running && _pomodoroTimer.phase == PomodoroPhase.focus,
      SoundMode.breaks =>
        running && _pomodoroTimer.phase == PomodoroPhase.breakTime,
    };
  }

  bool _audioPlaying = false;

  void _syncAudio({bool force = false}) {
    final play = _audioShouldPlay();
    if (!force && play == _audioPlaying) return;
    _audioPlaying = play;
    AmbientPlayer.instance.apply(play ? _settings.soundVolumes : const {});
  }

  Future<void> _openSoundMixer() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4E8D0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A7860).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SoundMixer(
                    settings: _settings,
                    onChanged: (next) {
                      setState(() => _settings = next);
                      setSheetState(() {});
                      _settingsRepository.save(next);
                      // Preview the mix while the sheet is open, even if
                      // "play during" wouldn't normally allow it now.
                      AmbientPlayer.instance.apply(
                          next.soundsOn ? next.soundVolumes : const {});
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    _syncAudio(force: true);
  }

  // Long-press the clock to try the next style without opening
  // settings; it's saved like any other setting.
  void _cycleClockStyle() {
    final styles = ClockStyle.values;
    final next = styles[(_settings.clockStyle.index + 1) % styles.length];
    HapticFeedback.selectionClick();
    setState(() => _settings = _settings.copyWith(clockStyle: next));
    _settingsRepository.save(_settings);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Clock style: ${clockStyleLabel(next)}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
  }

  void _revealControls() {
    setState(() => _showPomodoroControls = true);
  }

  BgSnap _bgSnapshot() {
    final isFocus = _pomodoroTimer.phase == PomodoroPhase.focus;
    final isDay = switch (_settings.timeOfDayMode) {
      TimeOfDayMode.auto => isFocus,
      TimeOfDayMode.day => true,
      TimeOfDayMode.night => false,
    };

    return BgSnap(
      time: _worldTime,
      isDay: isDay,
      isFocus: isFocus,
      phaseProgress: _pomodoroTimer.phaseProgress,
      completedFocusSessions: _pomodoroTimer.completedFocusSessions,
      isLongBreak: _pomodoroTimer.isLongBreak,
      charX: _director.x,
      isMoving: _director.isMoving,
      facingLeft: _director.facingLeft,
      goalFlagX: isFocus && _screenW > 0
          ? CharacterDirector.goalFlagX(_screenW)
          : null,
      secondsSinceCelebration: _worldTime - _lastCelebrationTime,
      sceneMode: _settings.sceneMode,
      season: _settings.season,
    );
  }

  // ── Character ───────────────────────────────────────────────

  void _advance() {
    _director.step(
      screenW: _screenW,
      time: _worldTime,
      phase: _pomodoroTimer.phase,
      running: _pomodoroTimer.running,
      progress: _pomodoroTimer.phaseProgress,
      isLongBreak: _pomodoroTimer.isLongBreak,
    );

    // Update only the painted subtree.
    _notifier.value = _snapshot();
  }

  CharSnap _snapshot() {
    return CharSnap(
      x: _director.x,
      frame: _director.frame,
      frameCount: animConfig[_director.anim]!.frames,
      image: _images[_director.anim],
      facingLeft: _director.facingLeft,
      bubble: _director.bubble,
    );
  }

  // ── Dispose ────────────────────────────────────────────────

  @override
  void dispose() {
    _ticker.dispose();
    AmbientPlayer.instance.stopAll();

    _notifier.dispose();
    _bgNotifier.dispose();
    _clockNotifier.dispose();

    for (final img in _images.values) {
      img?.dispose();
    }

    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E8D0),
      body: LayoutBuilder(
        builder: (_, constraints) {
          _screenW = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Scenic background: sky, sun/moon, mountains, castle,
              // windmill, river, clouds, birds/bats, campfire,
              // fireflies, ground, dust trail, confetti.
              Positioned.fill(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<BgSnap>(
                    valueListenable: _bgNotifier,
                    builder: (_, bg, __) => CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: BackgroundPainter(bg),
                    ),
                  ),
                ),
              ),

              // Musketeer sprite + speech bubble.
              ValueListenableBuilder<CharSnap>(
                valueListenable: _notifier,
                builder: (_, snap, __) {
                  if (snap.image == null) return const SizedBox.shrink();

                  return Positioned(
                    left: snap.x,
                    bottom: 40,
                    width: kSize,
                    height: kSize,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: SpritePainter(
                          image: snap.image!,
                          frame: snap.frame,
                          frameCount: snap.frameCount,
                          flip: snap.facingLeft,
                        ),
                      ),
                    ),
                  );
                },
              ),
              ValueListenableBuilder<CharSnap>(
                valueListenable: _notifier,
                builder: (_, snap, __) {
                  const bubbleW = 190.0;
                  // Follow the character but never slide off-screen.
                  final center = (snap.x + kSize / 2).clamp(
                      bubbleW / 2 + 8,
                      math.max(bubbleW / 2 + 8,
                          constraints.maxWidth - bubbleW / 2 - 8));

                  return Positioned(
                    left: center - bubbleW / 2,
                    bottom: 40 + kSize * 0.72,
                    width: bubbleW,
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                            alignment: Alignment.bottomCenter,
                            child: child,
                          ),
                        ),
                        child: snap.bubble == null
                            ? const SizedBox.shrink()
                            : _SpeechBubble(
                                key: ValueKey(snap.bubble),
                                text: snap.bubble!,
                              ),
                      ),
                    ),
                  );
                },
              ),

              // Pomodoro clock overlay.
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: PomodoroCard(
                      bgListenable: _bgNotifier,
                      clockListenable: _clockNotifier,
                      running: _pomodoroTimer.running,
                      showControls: _showPomodoroControls,
                      onRevealControls: _revealControls,
                      onToggleRunning: _toggleRunning,
                      onReset: _resetPomodoro,
                      clockStyle: _settings.clockStyle,
                      onCycleClockStyle: _cycleClockStyle,
                    ),
                  ),
                ),
              ),

              // Analytics entry point, mirrored on the other corner
              // from settings so neither competes with the clock.
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white70),
                    onPressed: _openAnalytics,
                  ),
                ),
              ),

              // Relaxing sounds — next to settings, opens a quick mixer.
              Positioned(
                top: 0,
                right: 44,
                child: SafeArea(
                  child: IconButton(
                    tooltip: 'Relaxing sounds',
                    icon: Icon(
                      _settings.soundsOn && _settings.soundVolumes.isNotEmpty
                          ? Icons.music_note_rounded
                          : Icons.music_off_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _openSoundMixer,
                  ),
                ),
              ),

              // Settings entry point — deliberately small and in a
              // corner so it doesn't compete with the clock for
              // attention.
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: _openSettings,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A small parchment-colored speech bubble with a tail pointing down
/// at the musketeer.
class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({super.key, required this.text});

  static const _fill = Color(0xFFFFF8E7);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8C77A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A3B2A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
        CustomPaint(size: const Size(14, 8), painter: _BubbleTailPainter()),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -1.5)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -1.5)
      ..close();
    canvas.drawPath(path, Paint()..color = _SpeechBubble._fill);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..color = const Color(0xFFE8C77A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => false;
}
