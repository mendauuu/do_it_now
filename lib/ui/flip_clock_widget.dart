import 'dart:async';
import 'package:flutter/material.dart';

import 'clock_theme.dart';
import 'flip_panel_plus.dart';

class FlipClockWidget extends StatefulWidget {
  final ClockTheme theme;

  const FlipClockWidget({super.key, required this.theme});

  @override
  State<FlipClockWidget> createState() => _FlipClockWidgetState();
}

class _FlipClockWidgetState extends State<FlipClockWidget> {
  late final StreamController<int> _minutesController;
  late final StreamController<int> _secondsController;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _minutesController = StreamController<int>.broadcast();
    _secondsController = StreamController<int>.broadcast();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      if (now.minute != _currentTime.minute) {
        _minutesController.add(now.minute);
      }
      _secondsController.add(now.second);
      _currentTime = now;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _minutesController.close();
    _secondsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Use FULL SCREEN to calculate size
    final baseSize = size.width * 0.45;
    final spacing = baseSize * 0.15;

    return SizedBox.expand(
      child: Container(
        color: widget.theme.backgroundColor,
        child: RotatedBox(
          quarterTurns: 1, // vertical clock
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _flipUnit(
                stream: _minutesController.stream,
                value: _currentTime.minute,
                baseSize: baseSize,
              ),
              SizedBox(height: spacing),
              _flipUnit(
                stream: _secondsController.stream,
                value: _currentTime.second,
                baseSize: baseSize,
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
      padding: const EdgeInsets.symmetric(horizontal: 25),
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
