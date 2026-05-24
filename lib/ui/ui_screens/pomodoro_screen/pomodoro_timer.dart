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
  // ── Streams ────────────────────────────────────────────────────────────────
  late final StreamController<int> _minutesCtrl;
  late final StreamController<int> _secondsCtrl;
  Timer? _timer;
  Timer? _hideTimer; // auto-hide controls after 3 s of inactivity

  // ── Timer state ────────────────────────────────────────────────────────────
  int _remainingSeconds = 0;
  bool _isRunning = false;
  _PomodoroMode _mode = _PomodoroMode.work;
  int _completedPomodoros = 0;
  bool _isHorizontal = false;

  // ── UI state ───────────────────────────────────────────────────────────────
  // Vertical mode: controls/dots are hidden while timer runs; tap to reveal.
  bool _controlsVisible = true;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _progressCtrl;
  late AnimationController _controlsFadeCtrl;
  late Animation<double> _controlsFade;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _minutesCtrl = StreamController<int>.broadcast();
    _secondsCtrl = StreamController<int>.broadcast();

    _progressCtrl = AnimationController(vsync: this);

    _controlsFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _controlsFade = CurvedAnimation(
      parent: _controlsFadeCtrl,
      curve: Curves.easeInOut,
    );

    _resetToMode(_mode, silent: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    _minutesCtrl.close();
    _secondsCtrl.close();
    _progressCtrl.dispose();
    _controlsFadeCtrl.dispose();
    super.dispose();
  }

  // ── Timer logic ────────────────────────────────────────────────────────────

  int _durationFor(_PomodoroMode mode) => switch (mode) {
        _PomodoroMode.work => widget.workDuration * 60,
        _PomodoroMode.shortBreak => widget.shortBreakDuration * 60,
        _PomodoroMode.longBreak => widget.longBreakDuration * 60,
      };

  void _resetToMode(_PomodoroMode mode, {bool silent = false}) {
    _timer?.cancel();
    _mode = mode;
    _remainingSeconds = _durationFor(mode);
    _isRunning = false;
    _progressCtrl.value = 1.0;
    if (!silent) setState(() {});
    _pushDisplay();
    _showControls(); // always show controls when mode resets
  }

  void _pushDisplay() {
    _minutesCtrl.add(_remainingSeconds ~/ 60);
    _secondsCtrl.add(_remainingSeconds % 60);
  }

  void _start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    final total = _durationFor(_mode).toDouble();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _progressCtrl.value = _remainingSeconds / total;
        _pushDisplay();
      } else {
        _onSessionComplete();
      }
    });
    // Auto-hide controls 2 s after starting (vertical mode only)
    if (!_isHorizontal) _scheduleHide();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _showControls(); // always reveal on pause
  }

  void _reset() => _resetToMode(_mode);

  void _onSessionComplete() {
    _timer?.cancel();
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

  // ── Controls visibility ────────────────────────────────────────────────────

  void _showControls() {
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
      _controlsFadeCtrl.forward();
    }
    // If timer is running, schedule auto-hide again
    if (_isRunning) _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isRunning && !_isHorizontal) {
        setState(() => _controlsVisible = false);
        _controlsFadeCtrl.reverse();
      }
    });
  }

  void _onTapScreen() {
    if (_isHorizontal) return;
    if (_controlsVisible && _isRunning) {
      // Already visible → hide immediately
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
      _controlsFadeCtrl.reverse();
    } else {
      _showControls();
    }
  }

  void _toggleOrientation() {
    setState(() {
      _isHorizontal = !_isHorizontal;
      _controlsVisible = true;
    });
    _controlsFadeCtrl.value = 1.0;
    _hideTimer?.cancel();
  }

  // ── Mode color / label ─────────────────────────────────────────────────────

  Color get _modeColor => switch (_mode) {
        _PomodoroMode.work => widget.theme.secondHandColor,
        _PomodoroMode.shortBreak => widget.theme.successColor,
        _PomodoroMode.longBreak => widget.theme.infoColor,
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
  // VERTICAL LAYOUT
  // Phone is held sideways — PageView has rotated the whole screen 90°.
  // bc.maxWidth  = physical screen height  (~800 px)
  // bc.maxHeight = physical screen width   (~360 px)
  //
  // Strategy: make the flip panels fill as much height as possible.
  // Controls and mode dots slide in/out on tap.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildVertical(BoxConstraints bc) {
    // Everything is rendered rotated 90°, so "height" below means
    // the physical horizontal extent of the phone.
    //
    // We want the two flip panels to use almost all available height.
    // Reserve only a small footer for the play button (shown always).
    const playBtnH = 70.0; // always-visible play/pause button row
    const ringPad = 20.0; // ring padding each side
    const panelGap = 6.0; // gap between minute & second panel
    const extraPad = 12.0; // small top padding

    final availH = bc.maxHeight - playBtnH - ringPad * 2 - panelGap - extraPad;
    final panelH = availH / 2;
    final baseSize = (panelH / 1.75).clamp(32.0, 130.0);

    return RotatedBox(
      quarterTurns: 1,
      child: Stack(
        children: [
          // ── Full-screen ring + panels ──────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: extraPad),
              _progressRing(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _flipUnit(
                        stream: _minutesCtrl.stream,
                        value: _remainingSeconds ~/ 60,
                        baseSize: baseSize),
                    SizedBox(height: panelGap),
                    _flipUnit(
                        stream: _secondsCtrl.stream,
                        value: _remainingSeconds % 60,
                        baseSize: baseSize),
                  ],
                ),
              ),
              // Always-visible play/pause + orientation toggle
              SizedBox(
                height: playBtnH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotatedBox(
                      quarterTurns: -1,
                      child: _controlBtn(
                        icon: _isHorizontal
                            ? Icons.stay_current_portrait_rounded
                            : Icons.stay_current_landscape_rounded,
                        color: widget.theme.secondaryTextColor,
                        bgColor: widget.theme.secondaryBackgroundColor,
                        onTap: _toggleOrientation,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 16),
                    RotatedBox(
                      quarterTurns: -1,
                      child: _controlBtn(
                        icon: _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: widget.theme.backgroundColor,
                        bgColor: _modeColor,
                        onTap: _isRunning ? _pause : _start,
                        size: 56,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tomato count — always visible
                    RotatedBox(
                      quarterTurns: -1,
                      child: _tomatoCount(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Overlay: mode tabs + dots + extra controls (auto-hide) ─────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _controlsFade,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _modeAndDots(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Overlay: extra controls bottom (reset + skip) ─────────────
          Positioned(
            bottom: playBtnH + 4,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _controlsFade,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotatedBox(
                      quarterTurns: -1,
                      child: _controlBtn(
                        icon: Icons.refresh_rounded,
                        color: widget.theme.secondaryTextColor,
                        bgColor: widget.theme.secondaryBackgroundColor,
                        onTap: _reset,
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 12),
                    RotatedBox(
                      quarterTurns: -1,
                      child: _controlBtn(
                        icon: Icons.skip_next_rounded,
                        color: widget.theme.secondaryTextColor,
                        bgColor: widget.theme.secondaryBackgroundColor,
                        onTap: _onSessionComplete,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hint text: "Tap to show controls" ─────────────────────────
          if (!_controlsVisible)
            Positioned(
              bottom: playBtnH + 6,
              left: 0,
              right: 0,
              child: RotatedBox(
                quarterTurns: -1,
                child: Center(
                  child: Text(
                    'Tap to show controls',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.theme.secondaryTextColor
                          .withValues(alpha: 0.5),
                      letterSpacing: 0.4,
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
  // HORIZONTAL LAYOUT  (portrait, no rotation)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHorizontal(BoxConstraints bc) {
    const controlsH = 64.0;
    const dotsH = 68.0;
    const gapH = 16.0;

    final panelH = (bc.maxHeight - controlsH - dotsH - gapH * 4)
        .clamp(60.0, double.infinity);
    final baseSize = (panelH / 1.75).clamp(30.0, 110.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: gapH),
        _modeAndDots(),
        SizedBox(height: gapH),
        _progressRing(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _flipUnit(
                  stream: _minutesCtrl.stream,
                  value: _remainingSeconds ~/ 60,
                  baseSize: baseSize),
              _colonSeparator(baseSize),
              _flipUnit(
                  stream: _secondsCtrl.stream,
                  value: _remainingSeconds % 60,
                  baseSize: baseSize),
            ],
          ),
        ),
        SizedBox(height: gapH),
        _controls(),
        SizedBox(height: gapH),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED SUB-WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _colonSeparator(double baseSize) => Padding(
        padding: EdgeInsets.symmetric(horizontal: baseSize * 0.15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(),
            SizedBox(height: baseSize * 0.35),
            _dot(),
          ],
        ),
      );

  Widget _dot() => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: _modeColor, shape: BoxShape.circle),
      );

  Widget _modeAndDots() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _modeTab('Focus', _PomodoroMode.work),
            const SizedBox(width: 8),
            _modeTab('Short', _PomodoroMode.shortBreak),
            const SizedBox(width: 8),
            _modeTab('Long', _PomodoroMode.longBreak),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < (_completedPomodoros % 4);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: filled ? 12 : 8,
              height: filled ? 12 : 8,
              decoration: BoxDecoration(
                color: filled
                    ? widget.theme.secondHandColor
                    : widget.theme.borderColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _modeTab(String label, _PomodoroMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => _resetToMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

  Widget _progressRing({required Widget child}) {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(
          progress: _progressCtrl.value,
          color: _modeColor,
          trackColor: widget.theme.borderColor.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  /// Full horizontal controls row (used in horizontal mode only)
  Widget _controls() {
    final bg = widget.theme.secondaryBackgroundColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _controlBtn(
          icon: _isHorizontal
              ? Icons.stay_current_portrait_rounded
              : Icons.stay_current_landscape_rounded,
          color: widget.theme.secondaryTextColor,
          bgColor: bg,
          onTap: _toggleOrientation,
          size: 36,
        ),
        const SizedBox(width: 10),
        _controlBtn(
          icon: Icons.refresh_rounded,
          color: widget.theme.secondaryTextColor,
          bgColor: bg,
          onTap: _reset,
          size: 44,
        ),
        const SizedBox(width: 12),
        _controlBtn(
          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: widget.theme.backgroundColor,
          bgColor: _modeColor,
          onTap: _isRunning ? _pause : _start,
          size: 58,
        ),
        const SizedBox(width: 12),
        _controlBtn(
          icon: Icons.skip_next_rounded,
          color: widget.theme.secondaryTextColor,
          bgColor: bg,
          onTap: _onSessionComplete,
          size: 44,
        ),
        const SizedBox(width: 10),
        _tomatoCount(),
      ],
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.theme.secondHandColor,
          ),
        ),
      );

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: size >= 50
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: size * 0.46),
      ),
    );
  }

  Widget _flipUnit({
    required Stream<int> stream,
    required int value,
    required double baseSize,
  }) {
    final s = baseSize.clamp(28.0, 130.0);
    return SizedBox(
      width: s * 2.0,
      height: s * 1.75,
      child: FlipPanelPlus<int>.stream(
        itemStream: stream,
        initValue: value,
        duration: const Duration(milliseconds: 450),
        spacing: s * 0.04,
        direction: FlipDirection.down,
        itemBuilder: (_, v) => _flipCard(v, s),
      ),
    );
  }

  Widget _flipCard(int value, double baseSize) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(baseSize * 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CardLinePainter(theme: widget.theme),
        child: Center(
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: baseSize * 1.15,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
              letterSpacing: 2,
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 5;
    const start = -3.14159 / 2;
    const full = 2 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      full,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        full * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
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
        ..color = theme.borderColor.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
