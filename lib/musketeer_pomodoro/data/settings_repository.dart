import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Loads and saves [PomodoroSettings] with shared_preferences — a
/// safe, universal choice regardless of what Do It Now uses for its
/// own data (unlike session history, settings don't need to live in
/// the same SQLite database as anything else).
class SettingsRepository {
  static const _kFocusMinutes = 'musketeer_focus_minutes';
  static const _kBreakMinutes = 'musketeer_break_minutes';
  static const _kLongBreakMinutes = 'musketeer_long_break_minutes';
  static const _kSessionsBeforeLongBreak =
      'musketeer_sessions_before_long_break';
  static const _kSceneMode = 'musketeer_scene_mode';
  static const _kSeason = 'musketeer_season';
  static const _kTimeOfDayMode = 'musketeer_time_of_day_mode';
  static const _kCurrentTopicId = 'musketeer_current_topic_id';
  static const _kDailyGoalMinutes = 'musketeer_daily_goal_minutes';
  static const _kClockStyle = 'musketeer_clock_style';
  static const _kSoundsOn = 'musketeer_sounds_on';
  static const _kSoundMode = 'musketeer_sound_mode';
  static const _kSoundVolumes = 'musketeer_sound_volumes';

  Future<PomodoroSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = PomodoroSettings();

    return PomodoroSettings(
      focusMinutes: prefs.getInt(_kFocusMinutes) ?? defaults.focusMinutes,
      breakMinutes: prefs.getInt(_kBreakMinutes) ?? defaults.breakMinutes,
      longBreakMinutes:
          prefs.getInt(_kLongBreakMinutes) ?? defaults.longBreakMinutes,
      sessionsBeforeLongBreak: prefs.getInt(_kSessionsBeforeLongBreak) ??
          defaults.sessionsBeforeLongBreak,
      sceneMode: SceneMode
          .values[prefs.getInt(_kSceneMode) ?? defaults.sceneMode.index],
      season: Season.values[prefs.getInt(_kSeason) ?? defaults.season.index],
      timeOfDayMode: TimeOfDayMode.values[
          prefs.getInt(_kTimeOfDayMode) ?? defaults.timeOfDayMode.index],
      currentTopicId:
          prefs.getString(_kCurrentTopicId) ?? defaults.currentTopicId,
      dailyGoalMinutes:
          prefs.getInt(_kDailyGoalMinutes) ?? defaults.dailyGoalMinutes,
      clockStyle: _clockStyleFrom(prefs.getString(_kClockStyle)),
      soundsOn: prefs.getBool(_kSoundsOn) ?? defaults.soundsOn,
      soundMode: SoundMode.values.firstWhere(
        (m) => m.name == prefs.getString(_kSoundMode),
        orElse: () => defaults.soundMode,
      ),
      soundVolumes: _volumesFrom(prefs.getString(_kSoundVolumes)),
    );
  }

  Future<void> save(PomodoroSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFocusMinutes, settings.focusMinutes);
    await prefs.setInt(_kBreakMinutes, settings.breakMinutes);
    await prefs.setInt(_kLongBreakMinutes, settings.longBreakMinutes);
    await prefs.setInt(
        _kSessionsBeforeLongBreak, settings.sessionsBeforeLongBreak);
    await prefs.setInt(_kSceneMode, settings.sceneMode.index);
    await prefs.setInt(_kSeason, settings.season.index);
    await prefs.setInt(_kTimeOfDayMode, settings.timeOfDayMode.index);
    await prefs.setString(_kCurrentTopicId, settings.currentTopicId);
    await prefs.setInt(_kDailyGoalMinutes, settings.dailyGoalMinutes);
    await prefs.setString(_kClockStyle, settings.clockStyle.name);
    await prefs.setBool(_kSoundsOn, settings.soundsOn);
    await prefs.setString(_kSoundMode, settings.soundMode.name);
    await prefs.setString(_kSoundVolumes, jsonEncode(settings.soundVolumes));
  }

  static Map<String, double> _volumesFrom(String? json) {
    if (json == null) return const {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries) e.key: (e.value as num).toDouble(),
      };
    } catch (_) {
      return const {};
    }
  }

  // Stored by name rather than index so adding or reordering styles
  // later can't silently switch someone to a different one.
  static ClockStyle _clockStyleFrom(String? name) {
    for (final style in ClockStyle.values) {
      if (style.name == name) return style;
    }
    return const PomodoroSettings().clockStyle;
  }
}
