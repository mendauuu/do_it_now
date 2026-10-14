import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/ambient_sounds.dart';
import '../models.dart';
import '../screens/app_theme.dart';

/// The relaxing-sounds controls: master switch, one-tap mixes, a tile
/// per sound with its own volume, and when to play. Purely a form —
/// the caller saves the settings and decides what's audible.
class SoundMixer extends StatelessWidget {
  final PomodoroSettings settings;
  final ValueChanged<PomodoroSettings> onChanged;

  const SoundMixer({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  Map<String, double> get _volumes => settings.soundVolumes;

  void _change(PomodoroSettings next) {
    HapticFeedback.selectionClick();
    onChanged(next);
  }

  void _toggleSound(String id) {
    final volumes = Map<String, double>.from(_volumes);
    if (volumes.containsKey(id)) {
      volumes.remove(id);
    } else {
      volumes[id] = 0.5;
    }
    // Picking a sound while everything's muted clearly means "I want
    // to hear this", so switch sounds on too.
    _change(settings.copyWith(
      soundVolumes: volumes,
      soundsOn: volumes.isNotEmpty ? true : settings.soundsOn,
    ));
  }

  void _setVolume(String id, double v) {
    onChanged(settings.copyWith(soundVolumes: {..._volumes, id: v}));
  }

  bool _isMixActive(SoundMix mix) =>
      mix.volumes.length == _volumes.length &&
      mix.volumes.keys.every(_volumes.containsKey);

  @override
  Widget build(BuildContext context) {
    final active = _volumes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MasterSwitch(
          on: settings.soundsOn,
          activeCount: active,
          onChanged: (v) => _change(settings.copyWith(
            soundsOn: v,
            // Turning on with nothing picked would be silent — start
            // with a gentle default mix instead.
            soundVolumes:
                v && _volumes.isEmpty ? soundMixes[1].volumes : null,
          )),
        ),
        const SizedBox(height: 16),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: settings.soundsOn ? 1 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Label('Quick mixes'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: soundMixes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final mix = soundMixes[i];
                    final selected = _isMixActive(mix);
                    return _MixChip(
                      mix: mix,
                      selected: selected,
                      onTap: () => _change(settings.copyWith(
                        soundVolumes: mix.volumes,
                        soundsOn: true,
                      )),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: _Label('Sounds')),
                  if (active > 0)
                    GestureDetector(
                      onTap: () =>
                          _change(settings.copyWith(soundVolumes: const {})),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Clear all',
                            style: TextStyle(
                                color: kAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
              LayoutBuilder(
                builder: (_, constraints) {
                  const gap = 10.0;
                  final tileW = (constraints.maxWidth - gap) / 2;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final sound in ambientSounds)
                        SizedBox(
                          width: tileW,
                          child: _SoundTile(
                            sound: sound,
                            volume: _volumes[sound.id],
                            onTap: () => _toggleSound(sound.id),
                            onVolume: (v) => _setVolume(sound.id, v),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const _Label('Play during'),
              Row(
                children: [
                  for (final (mode, label, icon) in const [
                    (SoundMode.always, 'Always', Icons.all_inclusive_rounded),
                    (
                      SoundMode.focus,
                      'Focus',
                      Icons.local_fire_department_rounded
                    ),
                    (SoundMode.breaks, 'Breaks', Icons.coffee_rounded),
                  ]) ...[
                    if (mode != SoundMode.always) const SizedBox(width: 8),
                    Expanded(
                      child: _ModeTile(
                        label: label,
                        icon: icon,
                        selected: settings.soundMode == mode,
                        onTap: () =>
                            _change(settings.copyWith(soundMode: mode)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                switch (settings.soundMode) {
                  SoundMode.always => 'Plays whenever the app is open.',
                  SoundMode.focus => 'Plays only while a focus session runs.',
                  SoundMode.breaks => 'Plays only while a break runs.',
                },
                style: const TextStyle(color: kInkFaint, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: kInk, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

class _MasterSwitch extends StatelessWidget {
  final bool on;
  final int activeCount;
  final ValueChanged<bool> onChanged;

  const _MasterSwitch({
    required this.on,
    required this.activeCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: on
              ? kAccent.withValues(alpha: 0.14)
              : kBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(on ? Icons.headphones_rounded : Icons.headset_off_rounded,
                color: on ? kAccent : kInkFaint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Relaxing sounds',
                      style:
                          TextStyle(color: kInk, fontWeight: FontWeight.w700)),
                  Text(
                    !on
                        ? 'Off'
                        : activeCount == 0
                            ? 'Pick a sound below'
                            : '$activeCount '
                                '${activeCount == 1 ? 'sound' : 'sounds'} '
                                'in your mix',
                    style: const TextStyle(color: kInkFaint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              activeThumbColor: Colors.white,
              activeTrackColor: kAccent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _MixChip extends StatelessWidget {
  final SoundMix mix;
  final bool selected;
  final VoidCallback onTap;

  const _MixChip(
      {required this.mix, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? kAccent : kBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(mix.icon,
                size: 18, color: selected ? Colors.white : kAccent),
            const SizedBox(width: 6),
            Text(
              mix.name,
              style: TextStyle(
                color: selected ? Colors.white : kInk,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  final AmbientSound sound;
  final double? volume; // null = not in the mix
  final VoidCallback onTap;
  final ValueChanged<double> onVolume;

  const _SoundTile({
    required this.sound,
    required this.volume,
    required this.onTap,
    required this.onVolume,
  });

  @override
  Widget build(BuildContext context) {
    final on = volume != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
        decoration: BoxDecoration(
          color: on
              ? sound.color.withValues(alpha: 0.16)
              : kBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: on ? sound.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: on ? sound.color : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(sound.icon,
                      size: 20, color: on ? Colors.white : sound.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sound.label,
                    style: TextStyle(
                      color: kInk,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (on)
                  Text('${(volume! * 100).round()}',
                      style: const TextStyle(color: kInkFaint, fontSize: 11)),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: on
                  ? SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: sound.color,
                        inactiveTrackColor:
                            sound.color.withValues(alpha: 0.2),
                        thumbColor: sound.color,
                        overlayShape: SliderComponentShape.noOverlay,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: SizedBox(
                        height: 30,
                        child: Slider(
                          value: volume!,
                          min: 0.05,
                          max: 1,
                          onChanged: onVolume,
                        ),
                      ),
                    )
                  : const SizedBox(height: 6, width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kAccent : kBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20, color: selected ? Colors.white : kInkFaint),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kInk,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
