import 'package:do_it_now/musketeer_pomodoro/models.dart';
import 'package:do_it_now/musketeer_pomodoro/widgets/clock_faces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final style in ClockStyle.values) {
    for (final size in [230.0, 210.0, 80.0]) {
      for (final progress in [0.0, 0.5, 1.0]) {
        testWidgets('$style renders at $size, progress $progress',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Center(
              child: ClockFace(
                style: style,
                seconds: 754,
                progress: progress,
                isDay: true,
                running: true,
                time: 3.2,
                size: size,
              ),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
