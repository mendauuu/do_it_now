import 'package:flutter/material.dart';

import '../models.dart';

/// A bottom sheet for editing [PomodoroSettings]. Purely a form —
/// it doesn't know about SharedPreferences or the running timer,
/// it just hands the finished settings back through [onSave].
class SettingsSheet extends StatefulWidget {
  final PomodoroSettings initialSettings;
  final ValueChanged<PomodoroSettings> onSave;

  const SettingsSheet({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late int _focusMinutes;
  late int _breakMinutes;
  late int _longBreakMinutes;
  late int _sessionsBeforeLongBreak;
  late SceneMode _sceneMode;
  late Season _season;

  @override
  void initState() {
    super.initState();
    _focusMinutes = widget.initialSettings.focusMinutes;
    _breakMinutes = widget.initialSettings.breakMinutes;
    _longBreakMinutes = widget.initialSettings.longBreakMinutes;
    _sessionsBeforeLongBreak = widget.initialSettings.sessionsBeforeLongBreak;
    _sceneMode = widget.initialSettings.sceneMode;
    _season = widget.initialSettings.season;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
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
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Timer settings',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _stepper('Focus', _focusMinutes, 5, 120,
                  (v) => setState(() => _focusMinutes = v)),
              _stepper('Short break', _breakMinutes, 1, 60,
                  (v) => setState(() => _breakMinutes = v)),
              _stepper('Long break', _longBreakMinutes, 1, 60,
                  (v) => setState(() => _longBreakMinutes = v)),
              _stepper(
                'Sessions before long break',
                _sessionsBeforeLongBreak,
                2,
                8,
                (v) => setState(() => _sessionsBeforeLongBreak = v),
                suffix: '',
              ),
              const SizedBox(height: 20),
              Text('Background scene',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Dial the animated scene down (or off) if it\'s more '
                'distracting than motivating during focus time.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<SceneMode>(
                segments: const [
                  ButtonSegment(value: SceneMode.off, label: Text('Off')),
                  ButtonSegment(value: SceneMode.simple, label: Text('Simple')),
                  ButtonSegment(value: SceneMode.full, label: Text('Full')),
                ],
                selected: {_sceneMode},
                onSelectionChanged: (selection) =>
                    setState(() => _sceneMode = selection.first),
              ),
              const SizedBox(height: 20),
              Text('Season', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Changes the ground, foliage, mountain caps, river tint, '
                'and whatever\'s falling from the sky.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<Season>(
                segments: const [
                  ButtonSegment(value: Season.spring, label: Text('Spring')),
                  ButtonSegment(value: Season.summer, label: Text('Summer')),
                  ButtonSegment(value: Season.autumn, label: Text('Autumn')),
                  ButtonSegment(value: Season.winter, label: Text('Winter')),
                ],
                selected: {_season},
                onSelectionChanged: (selection) =>
                    setState(() => _season = selection.first),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  widget.onSave(PomodoroSettings(
                    focusMinutes: _focusMinutes,
                    breakMinutes: _breakMinutes,
                    longBreakMinutes: _longBreakMinutes,
                    sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
                    sceneMode: _sceneMode,
                    season: _season,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged, {
    String suffix = ' min',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$value$suffix',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
