import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FullscreenClock extends StatefulWidget {
  final VoidCallback onFlipBack;
  const FullscreenClock({super.key, required this.onFlipBack});

  @override
  State<FullscreenClock> createState() => _FullscreenClockState();
}

class _FullscreenClockState extends State<FullscreenClock> {
  late Timer _timer;
  DateTime time = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => time = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');

    return Container(
      height: 600, // FlipCard height
      width: 360,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              onPressed: widget.onFlipBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Safe horizontal row with FittedBox
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _timeBox(h),
                      const SizedBox(width: 8),
                      const Text(
                        ':',
                        style: TextStyle(fontSize: 80, color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      _timeBox(m),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s,
                  style: const TextStyle(fontSize: 48, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.clockBox,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.clockBorder, width: 2),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
