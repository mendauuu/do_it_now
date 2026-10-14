import 'package:do_it_now/musketeer_pomodoro/audio/ambient_sounds.dart';
import 'package:do_it_now/musketeer_pomodoro/models.dart';
import 'package:do_it_now/musketeer_pomodoro/widgets/sound_mixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mixer lays out on a narrow phone with every sound on',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var settings = PomodoroSettings(
      soundsOn: true,
      soundVolumes: {for (final s in ambientSounds) s.id: 0.5},
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(36),
          child: StatefulBuilder(
            builder: (_, setState) => SoundMixer(
              settings: settings,
              onChanged: (next) => setState(() => settings = next),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Tapping a sound removes it from the mix.
    await tester.tap(find.text('Rain'));
    await tester.pumpAndSettle();
    expect(settings.soundVolumes.containsKey('rain'), isFalse);

    // A quick mix replaces the selection.
    await tester.ensureVisible(find.text('Forest walk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forest walk'));
    await tester.pumpAndSettle();
    expect(settings.soundVolumes.keys.toSet(), {'forest', 'birds', 'creek'});
  });
}
