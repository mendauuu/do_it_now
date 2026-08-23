import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/clock_theme.dart';
import '../../widgets/flip_panel_plus.dart';

enum _PomodoroMode { work, shortBreak, longBreak }

class PomodoroTimer extends StatefulWidget {
  final ClockTheme theme;
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;

  const PomodoroTimer({
    super.key,
    required this.theme,
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
  });

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final StreamController<int> _minutesCtrl;
  late final StreamController<int> _secondsCtrl;
  Timer? _timer;
  Timer? _hideTimer;

  int _remainingSeconds = 0;
  bool _isRunning = false;
  _PomodoroMode _mode = _PomodoroMode.work;
  int _completedPomodoros = 0;
  bool _isHorizontal = false;

  // Controls are shown ONLY when timer is NOT running.
  // While running: hidden. Tap → show for 2.5 s then hide again.
  bool _controlsVisible = true;

  late AnimationController _progressCtrl;
  late AnimationController _overlayCtrl; // fades all overlay UI
  late Animation<double> _overlayFade;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _minutesCtrl = StreamController<int>.broadcast();
    _secondsCtrl = StreamController<int>.broadcast();
    _progressCtrl = AnimationController(vsync: this);
    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // starts visible
    );
    _overlayFade =
        CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeInOut);
    _resetToMode(_mode, silent: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    _minutesCtrl.close();
    _secondsCtrl.close();
    _progressCtrl.dispose();
    _overlayCtrl.dispose();
    super.dispose();
  }

  // ── Duration ───────────────────────────────────────────────────────────────

  int _durationFor(_PomodoroMode m) => switch (m) {
        _PomodoroMode.work => widget.workDuration * 60,
        _PomodoroMode.shortBreak => widget.shortBreakDuration * 60,
        _PomodoroMode.longBreak => widget.longBreakDuration * 60,
      };

  // ── Timer control ──────────────────────────────────────────────────────────

  void _resetToMode(_PomodoroMode mode, {bool silent = false}) {
    _timer?.cancel();
    _hideTimer?.cancel();
    _mode = mode;
    _remainingSeconds = _durationFor(mode);
    _isRunning = false;
    _progressCtrl.value = 1.0;
    _controlsVisible = true;
    _overlayCtrl.forward(); // always show controls when stopped
    if (!silent) setState(() {});
    _pushDisplay();
  }

  void _pushDisplay() {
    _minutesCtrl.add(_remainingSeconds ~/ 60);
    _secondsCtrl.add(_remainingSeconds % 60);
  }

  void _start() {
    if (_isRunning) return;
    final total = _durationFor(_mode).toDouble();
    setState(() => _isRunning = true);
    // Hide controls immediately when timer starts
    _hideOverlay();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _progressCtrl.value = _remainingSeconds / total;
        _pushDisplay();
      } else {
        _onSessionComplete();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _hideTimer?.cancel();
    setState(() => _isRunning = false);
    _showOverlay(); // show controls when paused
  }

  void _reset() => _resetToMode(_mode);

  void _onSessionComplete() {
    _timer?.cancel();
    _hideTimer?.cancel();
    HapticFeedback.heavyImpact();
    if (_mode == _PomodoroMode.work) {
      _completedPomodoros++;
      final next = _completedPomodoros % 4 == 0
          ? _PomodoroMode.longBreak
          : _PomodoroMode.shortBreak;
      _showSnack('Pomodoro done! 🎉 Take a break.');
      Future.delayed(
          const Duration(milliseconds: 600), () => _resetToMode(next));
    } else {
      _showSnack('Break over! Back to work 💪');
      Future.delayed(const Duration(milliseconds: 600),
          () => _resetToMode(_PomodoroMode.work));
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: widget.theme.accentColor,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Overlay visibility ─────────────────────────────────────────────────────

  void _showOverlay() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _overlayCtrl.forward();
  }

  void _hideOverlay() {
    setState(() => _controlsVisible = false);
    _overlayCtrl.reverse();
  }

  /// Tap while running → show for 2.5 s then hide again.
  /// Tap while already showing → hide immediately.
  void _onTapScreen() {
    if (!_isRunning)
      return; // not running → controls always visible, do nothing
    if (_controlsVisible) {
      _hideTimer?.cancel();
      _hideOverlay();
    } else {
      _showOverlay();
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _isRunning) _hideOverlay();
      });
    }
  }

  void _toggleOrientation() {
    _hideTimer?.cancel();
    setState(() {
      _isHorizontal = !_isHorizontal;
      // Keep current visibility state — if running keep hidden
      _controlsVisible = !_isRunning;
    });
    if (!_isRunning) {
      _overlayCtrl.value = 1.0;
    }
  }

  // ── Colors ─────────────────────────────────────────────────────────────────

  Color get _modeColor => switch (_mode) {
        _PomodoroMode.work => widget.theme.secondHandColor,
        _PomodoroMode.shortBreak => widget.theme.successColor,
        _PomodoroMode.longBreak => widget.theme.infoColor,
      };

  String get _modeLabel => switch (_mode) {
        _PomodoroMode.work => 'Focus',
        _PomodoroMode.shortBreak => 'Short Break',
        _PomodoroMode.longBreak => 'Long Break',
      };

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox.expand(
      child: ColoredBox(
        color: widget.theme.backgroundColor,
        child: LayoutBuilder(
          builder: (_, bc) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTapScreen,
            child: _isHorizontal ? _buildHorizontal(bc) : _buildVertical(bc),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VERTICAL  (phone sideways, PageView rotated 90°)
  //
  // bc.maxWidth  ≈ screen height  (~800 px)
  // bc.maxHeight ≈ screen width   (~360 px)
  //
  // The clock fills the WHOLE screen.
  // Controls are a Stack overlay — they don't steal space from the clock.
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildVertical(BoxConstraints bc) {
    final maxAvailableWidth = bc.maxWidth * 0.92;
    const panelGap = 16.0;
    final usableSpace = maxAvailableWidth - panelGap;
    final calculatedBase = usableSpace / 4.3;
    final baseSize = calculatedBase.clamp(40.0, 240.0);

    return RotatedBox(
      quarterTurns: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. CLOCK ─────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _flipUnit(
                  stream: _minutesCtrl.stream,
                  value: _remainingSeconds ~/ 60,
                  baseSize: baseSize,
                ),
                const SizedBox(height: panelGap),
                _flipUnit(
                  stream: _secondsCtrl.stream,
                  value: _remainingSeconds % 60,
                  baseSize: baseSize,
                ),
              ],
            ),
          ),

          // ── 2. OVERLAY: mode label + dots (top) ───────────────────────────
          if (!_isRunning || _controlsVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _overlayFade,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: RotatedBox(
                    quarterTurns: 0,
                    child: SafeArea(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              _modeTabs(),
                              // const SizedBox(height: 8),
                              // _pomodoroDots(),
                            ],
                          ),
                          // const SizedBox(height: 4),
                          // Row(
                          //   mainAxisSize: MainAxisSize.min,
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     const SizedBox(height: 10),
                          //     // _modeTabs(),
                          //     const SizedBox(height: 8),
                          //     _pomodoroDots(),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── 3. OVERLAY: action controls bar (bottom) ──────────────────────
          // HIDES EVERYTHING when the timer is running, unless user taps screen
          if (!_isRunning || _controlsVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RotatedBox(
                quarterTurns: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      FadeTransition(
                        opacity: _overlayFade,
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: _btn(
                            icon: Icons.replay_rounded,
                            color: widget.theme.secondaryTextColor,
                            bg: widget.theme.secondaryBackgroundColor
                                .withValues(alpha: 0.8),
                            size: 44,
                            onTap: _reset,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Play/Pause Button
                      _btn(
                        icon: _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: widget.theme.backgroundColor,
                        bg: _modeColor,
                        size: 64,
                        onTap: _isRunning ? _pause : _start,
                      ),
                      const SizedBox(width: 16),

                      // Skip Button
                      FadeTransition(
                        opacity: _overlayFade,
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: _btn(
                            icon: Icons.skip_next_rounded,
                            color: widget.theme.secondaryTextColor,
                            bg: widget.theme.secondaryBackgroundColor
                                .withValues(alpha: 0.8),
                            size: 44,
                            onTap: _onSessionComplete,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 4. OVERLAY: orientation toggle + tomato count (top-right) ─────
          if (!_isRunning || _controlsVisible)
            Positioned(
              top: 8,
              right: 8,
              child: FadeTransition(
                opacity: _overlayFade,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: RotatedBox(
                    quarterTurns: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // _tomatoCount(),
                        // const SizedBox(width: 8),
                        _btn(
                          icon: Icons.crop_landscape_rounded,
                          color: widget.theme.secondaryTextColor,
                          bg: widget.theme.secondaryBackgroundColor
                              .withValues(alpha: 0.7),
                          size: 34,
                          onTap: _toggleOrientation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── 5. Hidden Layout Interaction Subtitle Hint ───────────────────
          if (_isRunning && !_controlsVisible)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: RotatedBox(
                quarterTurns: -1,
                child: Center(
                  child: Text(
                    'Tap for controls',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.theme.secondaryTextColor
                          .withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HORIZONTAL  (portrait, no rotation needed)
  //
  // bc.maxHeight ≈ full screen height (~800 px)
  // Clock fills most of the height. Controls are a small strip at the bottom.
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHorizontal(BoxConstraints bc) {
    // Use 92% of the wide screen width for the clock area
    final maxAvailableWidth = bc.maxWidth * 0.92;

    // We have 2 cards side-by-side + 1 gap.
    // Total width ratio = 2.1 (card 1 width) + 2.1 (card 2 width) = 4.2
    const panelGap = 24.0;
    final usableWidth = maxAvailableWidth - panelGap;
    final calculatedBase = usableWidth / 4.2;

    // Clamp safely, but allow a massive size for landscape screens
    final baseSize = calculatedBase.clamp(40.0, 320.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. THE GIANT CLOCK (Side-by-Side Horizon Format) ───────────
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _flipUnit(
                stream: _minutesCtrl.stream,
                value: _remainingSeconds ~/ 60,
                baseSize: baseSize,
              ),
              SizedBox(width: panelGap),
              _flipUnit(
                stream: _secondsCtrl.stream,
                value: _remainingSeconds % 60,
                baseSize: baseSize,
              ),
            ],
          ),
        ),

        // ── 2. TOP OVERLAY: Mode Indicator Tags ─────────────────────────
        if (!_isRunning || _controlsVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _overlayFade,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _modeTabs(),
                        const SizedBox(height: 6),
                        // _pomodoroDots(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── 3. TOP-RIGHT OVERLAY: Secondary Icons ────────────────────────
        if (!_isRunning || _controlsVisible)
          Positioned(
            top: 12,
            right: 12,
            child: FadeTransition(
              opacity: _overlayFade,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // _tomatoCount(),
                      // const SizedBox(width: 10),
                      _btn(
                        icon: Icons
                            .crop_portrait_rounded, // Changed to portrait icon for toggle
                        color: widget.theme.secondaryTextColor,
                        bg: widget.theme.secondaryBackgroundColor
                            .withValues(alpha: 0.7),
                        size: 36,
                        onTap: _toggleOrientation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── 4. BOTTOM OVERLAY: Playback Action Bar ───────────────────────
        // Kept outside of conditional blocks so the user can always tap to pause
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _overlayFade,
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btn(
                        icon: Icons.replay_rounded,
                        color: widget.theme.secondaryTextColor,
                        bg: widget.theme.secondaryBackgroundColor
                            .withValues(alpha: 0.8),
                        size: 46,
                        onTap: _reset,
                      ),
                      const SizedBox(width: 24),
                      _btn(
                        icon: _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: widget.theme.backgroundColor,
                        bg: _modeColor,
                        size: 68,
                        onTap: _isRunning ? _pause : _start,
                      ),
                      const SizedBox(width: 24),
                      _btn(
                        icon: Icons.skip_next_rounded,
                        color: widget.theme.secondaryTextColor,
                        bg: widget.theme.secondaryBackgroundColor
                            .withValues(alpha: 0.8),
                        size: 46,
                        onTap: _onSessionComplete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── 5. CLEAN BOTTOM HINT: Subtitle notice ────────────────────────
        if (_isRunning && !_controlsVisible)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Tap screen for controls',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _modeTabs() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeTab('Focus', _PomodoroMode.work),
          const SizedBox(width: 8),
          _modeTab('Short', _PomodoroMode.shortBreak),
          const SizedBox(width: 8),
          _modeTab('Long', _PomodoroMode.longBreak),
        ],
      );

  Widget _pomodoroDots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final filled = i < (_completedPomodoros % 4);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: filled ? 10 : 7,
            height: filled ? 10 : 7,
            decoration: BoxDecoration(
              color: filled
                  ? widget.theme.secondHandColor
                  : widget.theme.borderColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          );
        }),
      );

  Widget _modeTab(String label, _PomodoroMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => _resetToMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              selected ? _modeColor.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: selected
                ? _modeColor
                : widget.theme.borderColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _modeColor : widget.theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _tomatoCount() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.theme.secondHandColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.theme.secondHandColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$_completedPomodoros 🍅',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.theme.secondHandColor,
          ),
        ),
      );

  /// Ring drawn via CustomPaint around the child — adds no layout constraints.
  Widget _progressRing({required Widget child, double ringPad = 12}) {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(
          progress: _progressCtrl.value,
          color: _modeColor,
          trackColor: widget.theme.borderColor.withValues(alpha: 0.1),
        ),
        child: Padding(
          padding: EdgeInsets.all(ringPad),
          child: child,
        ),
      ),
    );
  }

  Widget _colonSeparator(double base) => Padding(
        padding: EdgeInsets.symmetric(horizontal: base * 0.12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _dot(),
          SizedBox(height: base * 0.3),
          _dot(),
        ]),
      );

  Widget _dot() => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: _modeColor, shape: BoxShape.circle),
      );

  Widget _btn({
    required IconData icon,
    required Color color,
    required Color bg,
    required double size,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: size >= 55
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    )
                  ]
                : null,
          ),
          child: Icon(icon, color: color, size: size * 0.46),
        ),
      );

  Widget _flipUnit({
    required Stream<int> stream,
    required int value,
    required double baseSize,
  }) {
    final s = baseSize.clamp(36.0, 220.0);
    return SizedBox(
      width: s * 2.1,
      height: s * 2.15, // Increased from 1.75 to 2.15 to make it taller
      child: FlipPanelPlus<int>.stream(
        itemStream: stream,
        initValue: value,
        duration: const Duration(milliseconds: 480),
        spacing: s * 0.04,
        direction: FlipDirection.down,
        itemBuilder: (_, v) => _flipCard(v, s),
      ),
    );
  }

  Widget _flipCard(int value, double s) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(s * 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: widget.theme.borderColor.withValues(alpha: 0.1),
        ),
      ),
      child: CustomPaint(
        painter: _CardLinePainter(theme: widget.theme),
        child: Center(
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: s *
                  1.35, // Slightly increased font size to match the taller card
              fontWeight: FontWeight.w900,
              color: widget.theme.textColor,
              letterSpacing: 3,
              // Removed height: 1 to allow the text to center properly in the taller box
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ring painter ───────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter(
      {required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide / 2) - 4;
    const s = -3.14159 / 2;
    const f = 2 * 3.14159;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), s, f, false, track);

    if (progress > 0) {
      final arc = Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), s, f * progress, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.color != color;
}

// ── Card line painter ──────────────────────────────────────────────────────────

class _CardLinePainter extends CustomPainter {
  final ClockTheme theme;
  _CardLinePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = theme.borderColor.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
