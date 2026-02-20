import 'dart:async';
import 'package:flutter/material.dart';

import 'clock_theme.dart';
import 'flip_panel_plus.dart';

class PomodoroTimer extends StatefulWidget {
  final ClockTheme theme;
  final int workDuration; // in minutes
  final int breakDuration; // in minutes

  const PomodoroTimer({
    super.key,
    required this.theme,
    this.workDuration = 25,
    this.breakDuration = 5,
  });

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer>
    with AutomaticKeepAliveClientMixin {
  late final StreamController<int> _minutesController;
  late final StreamController<int> _secondsController;
  late Timer _timer;

  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isWorkSession = true;

  @override
  void initState() {
    super.initState();
    _minutesController = StreamController<int>.broadcast();
    _secondsController = StreamController<int>.broadcast();
    _remainingSeconds = widget.workDuration * 60;
    _updateDisplay();
  }

  @override
  bool get wantKeepAlive => true;

  void _updateDisplay() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    _minutesController.add(minutes);
    _secondsController.add(seconds);
  }

  void _startTimer() {
    if (_isRunning) return;

    _isRunning = true;
    setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _updateDisplay();
      } else {
        _timer.cancel();
        _isRunning = false;
        _switchSession();
      }
    });
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer.cancel();
      _isRunning = false;
      setState(() {});
    }
  }

  void _resetTimer() {
    if (_isRunning) {
      _timer.cancel();
      _isRunning = false;
    }
    _isWorkSession = true;
    _remainingSeconds = widget.workDuration * 60;
    _updateDisplay();
    setState(() {});
  }

  void _switchSession() {
    setState(() {
      _isWorkSession = !_isWorkSession;
      _remainingSeconds =
          _isWorkSession ? widget.workDuration * 60 : widget.breakDuration * 60;
      _updateDisplay();
    });

    // Auto-start next session
    Future.delayed(const Duration(milliseconds: 500), _startTimer);
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
    }
    _minutesController.close();
    _secondsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final baseSize = size.width * 0.45;
    final spacing = baseSize * 0.15;

    return SizedBox.expand(
      child: Container(
        color: widget.theme.backgroundColor,
        child: RotatedBox(
          quarterTurns: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _flipUnit(
                stream: _minutesController.stream,
                value: _remainingSeconds ~/ 60,
                baseSize: baseSize,
              ),
              SizedBox(height: spacing),
              _flipUnit(
                stream: _secondsController.stream,
                value: _remainingSeconds % 60,
                baseSize: baseSize,
              ),
              SizedBox(height: spacing * 0.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.small(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    // High contrast: Bright Blue/Purple when stopped, dark Border color when running
                    backgroundColor: _isRunning
                        ? widget.theme.borderColor
                        : widget.theme.secondHandColor,
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      // Using the darkest background color for the icon creates a "cut-out" look
                      color: widget.theme.backgroundColor,
                    ),
                  ),
                  SizedBox(width: spacing * 0.5),
                  FloatingActionButton.small(
                    onPressed: _resetTimer,
                    // Subdued look: Blends into the theme but stays visible
                    backgroundColor: widget.theme.secondaryBackgroundColor,
                    child: Icon(
                      Icons.refresh,
                      // The icon itself provides the color hint (Blue/Purple)
                      color: widget.theme.secondHandColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flipUnit({
    required Stream<int> stream,
    required int value,
    required double baseSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: baseSize * 2.2,
        height: baseSize * 1.9,
        child: FlipPanelPlus<int>.stream(
          itemStream: stream,
          initValue: value,
          duration: const Duration(milliseconds: 450),
          spacing: baseSize * 0.04,
          direction: FlipDirection.down,
          itemBuilder: (_, v) => _card(v, baseSize),
        ),
      ),
    );
  }

  Widget _card(int value, double baseSize) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(baseSize * 0.1),
      ),
      child: CustomPaint(
        painter: CardPainter(theme: widget.theme),
        child: Center(
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: baseSize * 1.25,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class CardPainter extends CustomPainter {
  final ClockTheme theme;

  CardPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.borderColor.withOpacity(0.4)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
