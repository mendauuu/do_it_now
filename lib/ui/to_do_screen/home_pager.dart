import 'package:do_it_now/ui/to_do_screen/fullscreen_clock/fullscreen_clock.dart';
import 'package:do_it_now/ui/to_do_screen/to_do_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import '../theme/app_colors.dart';

class TodoClockFlip extends StatefulWidget {
  const TodoClockFlip({super.key});

  @override
  State<TodoClockFlip> createState() => _TodoClockFlipState();
}

class _TodoClockFlipState extends State<TodoClockFlip> {
  final FlipCardController _controller = FlipCardController();

  void _flip() => _controller.flipcard();

  void _onVerticalSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity.abs() > 300) {
      _flip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onVerticalDragEnd: _onVerticalSwipe,
        child: Center(
          child: FlipCard(
            controller: _controller,
            axis: FlipAxis.vertical,
            rotateSide: RotateSide.right,
            frontWidget: TodoPage(onFlip: _flip),
            backWidget: FullscreenClock(onFlipBack: _flip),
          ),
        ),
      ),
    );
  }
}
