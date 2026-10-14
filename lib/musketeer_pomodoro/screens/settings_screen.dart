import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings_repository.dart';
import '../data/topics_repository.dart';
import '../models.dart';
import '../audio/ambient_sounds.dart';
import '../widgets/clock_faces.dart';
import '../widgets/sound_mixer.dart';
import 'app_theme.dart';
import 'section_card.dart';

/// Full settings screen — durations, background scene, season, and
/// topic management. Owns its own persistence (SettingsRepository,
/// TopicsRepository) and saves as changes happen rather than behind
/// a single "Save" button, so leaving this screen never loses
/// anything and the caller doesn't need to know or care what changed.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepository = SettingsRepository();
  final _topicsRepository = TopicsRepository();
  final _newTopicController = TextEditingController();

  PomodoroSettings _settings = const PomodoroSettings();
  List<Topic> _topics = TopicsRepository.builtInTopics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newTopicController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsRepository.load();
    final topics = await _topicsRepository.loadAll();
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _topics = topics;
      _loading = false;
    });
  }

  Future<void> _update(
      PomodoroSettings Function(PomodoroSettings) change) async {
    HapticFeedback.selectionClick();
    final updated = change(_settings);
    setState(() => _settings = updated);
    await _settingsRepository.save(updated);
  }

  Future<void> _addTopic() async {
    final name = _newTopicController.text.trim();
    if (name.isEmpty) return;

    if (_topics.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
      _showMessage('"$name" is already a topic');
      return;
    }

    final topic = await _topicsRepository.add(name);
    _newTopicController.clear();
    if (!mounted) return;
    setState(() => _topics = [..._topics, topic]);
    // A freshly added topic is almost always the one about to be used.
    await _update((s) => s.copyWith(currentTopicId: topic.id));
  }

  Future<void> _deleteTopic(Topic topic) async {
    await _topicsRepository.delete(topic.id);
    if (!mounted) return;

    setState(() => _topics = _topics.where((t) => t.id != topic.id).toList());
    _showMessage('Removed "${topic.name}"');

    // The deleted topic can't stay selected — fall back to the first
    // built-in one.
    if (_settings.currentTopicId == topic.id) {
      await _update((s) => s.copyWith(
            currentTopicId: TopicsRepository.builtInTopics.first.id,
          ));
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ));
  }

  void _applyPreset(_Preset preset) {
    _update((s) => s.copyWith(
          focusMinutes: preset.focus,
          breakMinutes: preset.shortBreak,
          longBreakMinutes: preset.longBreak,
          sessionsBeforeLongBreak: preset.sessions,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kInk),
        title: const Text('Settings',
            style: TextStyle(color: kInk, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground, kBackgroundDeep],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kAccent))
              : GestureDetector(
                  // Tapping anywhere outside the topic field closes the
                  // keyboard instead of leaving it hanging open.
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _ScenePreview(settings: _settings),
                      const SizedBox(height: 16),
                      _buildTimerCard(),
                      const SizedBox(height: 16),
                      _buildClockStyleCard(),
                      const SizedBox(height: 16),
                      _buildSoundsCard(),
                      const SizedBox(height: 16),
                      _buildSceneCard(),
                      const SizedBox(height: 16),
                      _buildSeasonCard(),
                      const SizedBox(height: 16),
                      _buildTimeOfDayCard(),
                      const SizedBox(height: 16),
                      _buildTopicCard(),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Changes save automatically',
                          style: TextStyle(color: kInkFaint, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ── Timer ─────────────────────────────────────────────────────

  Widget _buildTimerCard() {
    return SectionCard(
      title: 'Timer',
      icon: Icons.timer_outlined,
      subtitle: 'Pick a preset or fine-tune each length below.',
      children: [
        Row(
          children: [
            for (final preset in _Preset.all) ...[
              if (preset != _Preset.all.first) const SizedBox(width: 8),
              Expanded(
                child: _PresetTile(
                  preset: preset,
                  selected: preset.matches(_settings),
                  onTap: () => _applyPreset(preset),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _Stepper(
          icon: Icons.local_fire_department_rounded,
          label: 'Focus',
          value: _settings.focusMinutes,
          min: 5,
          max: 120,
          step: 5,
          onChanged: (v) => _update((s) => s.copyWith(focusMinutes: v)),
        ),
        _Stepper(
          icon: Icons.coffee_rounded,
          label: 'Short break',
          value: _settings.breakMinutes,
          min: 1,
          max: 60,
          onChanged: (v) => _update((s) => s.copyWith(breakMinutes: v)),
        ),
        _Stepper(
          icon: Icons.self_improvement_rounded,
          label: 'Long break',
          value: _settings.longBreakMinutes,
          min: 1,
          max: 60,
          onChanged: (v) => _update((s) => s.copyWith(longBreakMinutes: v)),
        ),
        _Stepper(
          icon: Icons.flag_rounded,
          label: 'Daily goal',
          value: _settings.dailyGoalMinutes,
          min: 15,
          max: 600,
          step: 15,
          onChanged: (v) => _update((s) => s.copyWith(dailyGoalMinutes: v)),
        ),
        _Stepper(
          icon: Icons.repeat_rounded,
          label: 'Long break every',
          value: _settings.sessionsBeforeLongBreak,
          min: 2,
          max: 8,
          suffix: _settings.sessionsBeforeLongBreak == 1
              ? 'session'
              : 'sessions',
          onChanged: (v) =>
              _update((s) => s.copyWith(sessionsBeforeLongBreak: v)),
        ),
      ],
    );
  }

  // ── Relaxing sounds ───────────────────────────────────────────

  Widget _buildSoundsCard() {
    return SectionCard(
      title: 'Relaxing sounds',
      icon: Icons.music_note_rounded,
      subtitle: 'Mix nature sounds to help you focus or unwind. You\'ll hear '
          'your mix while you adjust it here.',
      children: [
        SoundMixer(
          settings: _settings,
          onChanged: (next) {
            // No haptic here — the mixer already gives one per tap, and
            // volume sliders call this on every drag step.
            setState(() => _settings = next);
            _settingsRepository.save(next);
            AmbientPlayer.instance
                .apply(next.soundsOn ? next.soundVolumes : const {});
          },
        ),
      ],
    );
  }

  // ── Clock style ───────────────────────────────────────────────

  Widget _buildClockStyleCard() {
    return SectionCard(
      title: 'Clock style',
      icon: Icons.watch_later_outlined,
      subtitle: 'How your countdown looks. Tip: long-press the clock on the '
          'main screen to switch quickly.',
      children: [
        _ClockStylePicker(
          selected: _settings.clockStyle,
          isDay: _settings.timeOfDayMode != TimeOfDayMode.night,
          onSelected: (v) => _update((s) => s.copyWith(clockStyle: v)),
        ),
      ],
    );
  }

  // ── Scene / season / time of day ──────────────────────────────

  Widget _buildSceneCard() {
    return SectionCard(
      title: 'Background scene',
      icon: Icons.landscape_outlined,
      subtitle: 'Turn the animation down if it distracts you while focusing.',
      children: [
        _OptionGrid<SceneMode>(
          selected: _settings.sceneMode,
          onSelected: (v) => _update((s) => s.copyWith(sceneMode: v)),
          options: const [
            _Option(SceneMode.off, 'Off', Icons.hide_image_outlined,
                Color(0xFF8A7860)),
            _Option(SceneMode.simple, 'Simple', Icons.wb_twilight_rounded,
                Color(0xFF5FAEDB)),
            _Option(SceneMode.full, 'Full', Icons.castle_outlined,
                Color(0xFF6FA85B)),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonCard() {
    return SectionCard(
      title: 'Season',
      icon: Icons.eco_outlined,
      subtitle: 'Changes the ground, trees, mountains, river, and what falls '
          'from the sky.',
      children: [
        _OptionGrid<Season>(
          selected: _settings.season,
          onSelected: (v) => _update((s) => s.copyWith(season: v)),
          options: [
            for (final season in Season.values)
              _Option(season, _seasonLabel(season), _seasonIcon(season),
                  _seasonColor(season)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeOfDayCard() {
    return SectionCard(
      title: 'Day & night',
      icon: Icons.brightness_6_outlined,
      subtitle: _timeOfDayHint(_settings.timeOfDayMode),
      children: [
        _OptionGrid<TimeOfDayMode>(
          selected: _settings.timeOfDayMode,
          onSelected: (v) => _update((s) => s.copyWith(timeOfDayMode: v)),
          options: const [
            _Option(TimeOfDayMode.auto, 'Auto', Icons.sync_rounded,
                Color(0xFFD46A2B)),
            _Option(TimeOfDayMode.day, 'Day', Icons.wb_sunny_rounded,
                Color(0xFFE8A92E)),
            _Option(TimeOfDayMode.night, 'Night', Icons.nightlight_round,
                Color(0xFF5B4F9E)),
          ],
        ),
      ],
    );
  }

  // ── Topics ────────────────────────────────────────────────────

  Widget _buildTopicCard() {
    return SectionCard(
      title: 'Topic',
      icon: Icons.sell_outlined,
      subtitle: 'What are you working on? Your analytics are split by topic.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _topics.length; i++)
              _TopicChip(
                topic: _topics[i],
                color: kTopicColors[i % kTopicColors.length],
                selected: _settings.currentTopicId == _topics[i].id,
                onTap: () => _update(
                    (s) => s.copyWith(currentTopicId: _topics[i].id)),
                onDelete: _topics[i].isBuiltIn
                    ? null
                    : () => _deleteTopic(_topics[i]),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTopicController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: kInk),
                cursorColor: kAccent,
                decoration: InputDecoration(
                  hintText: 'New topic, e.g. "Reading"',
                  hintStyle: const TextStyle(color: kInkFaint),
                  prefixIcon: const Icon(Icons.edit_outlined,
                      color: kInkFaint, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: kBackground.withValues(alpha: 0.6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kAccent, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _addTopic(),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: kAccent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _addTopic,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────

String _seasonLabel(Season s) => switch (s) {
      Season.spring => 'Spring',
      Season.summer => 'Summer',
      Season.autumn => 'Autumn',
      Season.winter => 'Winter',
    };

IconData _seasonIcon(Season s) => switch (s) {
      Season.spring => Icons.local_florist_rounded,
      Season.summer => Icons.wb_sunny_rounded,
      Season.autumn => Icons.park_rounded,
      Season.winter => Icons.ac_unit_rounded,
    };

Color _seasonColor(Season s) => switch (s) {
      Season.spring => const Color(0xFFE07FA6),
      Season.summer => const Color(0xFF6FA85B),
      Season.autumn => const Color(0xFFD46A2B),
      Season.winter => const Color(0xFF5FAEDB),
    };

String _timeOfDayHint(TimeOfDayMode m) => switch (m) {
      TimeOfDayMode.auto => 'Day while you focus, night while you rest.',
      TimeOfDayMode.day => 'Always daytime, even during breaks.',
      TimeOfDayMode.night => 'Always night, with stars, the moon, and '
          'fireflies.',
    };

class _Preset {
  final String name;
  final int focus;
  final int shortBreak;
  final int longBreak;
  final int sessions;

  const _Preset(
      this.name, this.focus, this.shortBreak, this.longBreak, this.sessions);

  static const all = [
    _Preset('Quick', 15, 3, 10, 4),
    _Preset('Classic', 25, 5, 15, 4),
    _Preset('Deep', 50, 10, 30, 3),
  ];

  bool matches(PomodoroSettings s) =>
      s.focusMinutes == focus &&
      s.breakMinutes == shortBreak &&
      s.longBreakMinutes == longBreak &&
      s.sessionsBeforeLongBreak == sessions;
}

class _PresetTile extends StatelessWidget {
  final _Preset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kAccent : kBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              preset.name,
              style: TextStyle(
                color: selected ? Colors.white : kInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${preset.focus} / ${preset.shortBreak}',
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : kInkFaint,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final String suffix;

  const _Stepper({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix = 'min',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: kInk, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          _RoundButton(
            icon: Icons.remove_rounded,
            onTap: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                      color: kInk, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text(suffix,
                    style: const TextStyle(color: kInkFaint, fontSize: 11)),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            onTap: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? kBackground : kBackground.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon,
              size: 20,
              color: enabled ? kAccent : kInkFaint.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

class _Option<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color color;

  const _Option(this.value, this.label, this.icon, this.color);
}

/// A row of big tappable tiles — an icon plus a label each — used in
/// place of SegmentedButton, which looked out of place next to the
/// rest of the warm, illustrated UI.
class _OptionGrid<T> extends StatelessWidget {
  final List<_Option<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _tile(options[i])),
        ],
      ],
    );
  }

  Widget _tile(_Option<T> option) {
    final isSelected = option.value == selected;

    return GestureDetector(
      onTap: () => onSelected(option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.16)
              : kBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? option.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: Icon(option.icon,
                  color: isSelected ? option.color : kInkFaint, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? kInk : kInkFaint,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final Topic topic;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TopicChip({
    required this.topic,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.fromLTRB(12, 8, onDelete == null ? 14 : 6, 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : kBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              topic.name,
              style: TextStyle(
                color: kInk,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: kInkFaint),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small live preview at the top of the screen — sky colors follow
/// the day/night choice and the badge follows the season — so the
/// person sees what their choices add up to without leaving settings.
class _ScenePreview extends StatelessWidget {
  final PomodoroSettings settings;

  const _ScenePreview({required this.settings});

  static const _day = [Color(0xFF8EC9E8), Color(0xFFF4D9A0)];
  static const _night = [Color(0xFF0B0E2A), Color(0xFF33234F)];

  @override
  Widget build(BuildContext context) {
    final mode = settings.timeOfDayMode;
    final colors = switch (mode) {
      TimeOfDayMode.day => _day,
      TimeOfDayMode.night => _night,
      TimeOfDayMode.auto => [_day[0], _night[1]],
    };
    final isDark = mode == TimeOfDayMode.night;
    final textColor = isDark ? Colors.white : kInk;
    final seasonColor = _seasonColor(settings.season);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Rolling hills along the bottom, tinted by season.
            Positioned(
              left: -40,
              right: -40,
              bottom: -70,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 120,
                decoration: BoxDecoration(
                  color: seasonColor.withValues(alpha: isDark ? 0.45 : 0.75),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(200)),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 20,
              child: Icon(
                switch (mode) {
                  TimeOfDayMode.day => Icons.wb_sunny_rounded,
                  TimeOfDayMode.night => Icons.nightlight_round,
                  TimeOfDayMode.auto => Icons.brightness_6_rounded,
                },
                size: 40,
                color: isDark
                    ? const Color(0xFFF5F0D0)
                    : const Color(0xFFFFD65C),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_seasonIcon(settings.season),
                            size: 14, color: seasonColor),
                        const SizedBox(width: 4),
                        Text(
                          _seasonLabel(settings.season),
                          style: const TextStyle(
                              color: kInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${settings.focusMinutes} min focus',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                  ),
                  Text(
                    '${settings.breakMinutes} min break · '
                    '${settings.longBreakMinutes} min long break',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A grid of live, animated previews of every clock style — each one
/// is the real clock face, just smaller, counting through a pretend
/// session so you can see how it moves before picking it.
class _ClockStylePicker extends StatefulWidget {
  final ClockStyle selected;
  final bool isDay;
  final ValueChanged<ClockStyle> onSelected;

  const _ClockStylePicker({
    required this.selected,
    required this.isDay,
    required this.onSelected,
  });

  @override
  State<_ClockStylePicker> createState() => _ClockStylePickerState();
}

class _ClockStylePickerState extends State<_ClockStylePicker>
    with SingleTickerProviderStateMixin {
  // One shared 12-second loop drives every preview.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileW = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final style in ClockStyle.values)
              SizedBox(width: tileW, child: _tile(style, tileW)),
          ],
        );
      },
    );
  }

  Widget _tile(ClockStyle style, double tileW) {
    final selected = style == widget.selected;

    return GestureDetector(
      onTap: () => widget.onSelected(style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDay
                ? const [Color(0xFF6FA9CC), Color(0xFFC79B63)]
                : const [Color(0xFF1B1E3D), Color(0xFF33234F)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? kAccent : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kAccent.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _loop,
              builder: (_, __) {
                final p = _loop.value;
                return ClockFace(
                  style: style,
                  progress: p,
                  seconds: (25 * 60 * (1 - p)).round(),
                  isDay: widget.isDay,
                  running: true,
                  time: _loop.lastElapsedDuration == null
                      ? 0
                      : _loop.lastElapsedDuration!.inMicroseconds / 1e6,
                  size: tileW - 24,
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    clockStyleLabel(style),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
