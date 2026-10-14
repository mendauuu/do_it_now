import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// One looping background sound the person can mix in.
class AmbientSound {
  final String id; // also the file name in assets/audio/
  final String label;
  final IconData icon;
  final Color color;

  const AmbientSound(this.id, this.label, this.icon, this.color);

  String get asset => 'audio/$id.mp3'; // AssetSource adds "assets/"
}

const ambientSounds = [
  AmbientSound('rain', 'Rain', Icons.umbrella_rounded, Color(0xFF5FAEDB)),
  AmbientSound(
      'thunder', 'Thunder', Icons.thunderstorm_rounded, Color(0xFF8F7CB8)),
  AmbientSound('wind', 'Wind', Icons.air_rounded, Color(0xFF8AA6B5)),
  AmbientSound('forest', 'Forest', Icons.forest_rounded, Color(0xFF6FA85B)),
  AmbientSound('birds', 'Birds', Icons.flutter_dash, Color(0xFFE8A92E)),
  AmbientSound('creek', 'Creek', Icons.water_drop_rounded, Color(0xFF4FB3A9)),
  AmbientSound('river', 'River', Icons.waves_rounded, Color(0xFF3F88C5)),
  AmbientSound('stream', 'Stream', Icons.water_rounded, Color(0xFF66B7D9)),
];

/// Ready-made mixes for one-tap relaxing.
class SoundMix {
  final String name;
  final IconData icon;
  final Map<String, double> volumes;

  const SoundMix(this.name, this.icon, this.volumes);
}

const soundMixes = [
  SoundMix('Rainy cabin', Icons.cabin_rounded,
      {'rain': 0.7, 'thunder': 0.35, 'wind': 0.25}),
  SoundMix('Forest walk', Icons.park_rounded,
      {'forest': 0.6, 'birds': 0.5, 'creek': 0.35}),
  SoundMix('Riverside', Icons.kayaking_rounded,
      {'river': 0.6, 'stream': 0.35, 'birds': 0.3}),
  SoundMix('Stormy night', Icons.nights_stay_rounded,
      {'rain': 0.6, 'thunder': 0.6, 'wind': 0.45}),
];

/// Plays the current mix: one looping player per active sound, each
/// faded smoothly to its target volume (and stopped once faded out),
/// so changing the mix or the timer phase never cuts sound abruptly.
///
/// A single shared instance, so the main screen and the settings
/// preview drive the same players instead of stacking up copies.
class AmbientPlayer {
  AmbientPlayer._() {
    // Let the sounds mix with each other (and with music from other
    // apps) instead of each new one stealing audio focus and pausing
    // the rest.
    AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
          .build(),
    );
  }

  static final instance = AmbientPlayer._();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, double> _volume = {}; // what's playing right now
  Map<String, double> _target = {};
  Timer? _fader;

  static const _fadeStep = 0.04; // per 50ms tick ≈ 1.2s full fade

  /// Fade toward [volumes] (sound id → 0..1); anything missing or 0
  /// fades out and stops.
  void apply(Map<String, double> volumes) {
    _target = {
      for (final e in volumes.entries)
        if (e.value > 0) e.key: e.value.clamp(0.0, 1.0),
    };

    for (final id in _target.keys) {
      if (_players.containsKey(id)) continue;
      final sound = ambientSounds.where((s) => s.id == id).firstOrNull;
      if (sound == null) continue;

      final player = AudioPlayer();
      _players[id] = player;
      _volume[id] = 0;
      player
        ..setReleaseMode(ReleaseMode.loop)
        ..setVolume(0)
        ..play(AssetSource(sound.asset), volume: 0).catchError((Object e) {
          debugPrint('Could not play ${sound.asset}: $e');
        });
    }

    _fader ??=
        Timer.periodic(const Duration(milliseconds: 50), (_) => _fadeTick());
  }

  void stopAll() => apply(const {});

  void _fadeTick() {
    var settled = true;

    for (final id in _players.keys.toList()) {
      final target = _target[id] ?? 0;
      final current = _volume[id] ?? 0;
      if (current == target) {
        if (target == 0) _release(id);
        continue;
      }

      settled = false;
      final next = current < target
          ? (current + _fadeStep).clamp(0.0, target)
          : (current - _fadeStep).clamp(target, 1.0);
      _volume[id] = next;
      _players[id]!.setVolume(next);
    }

    if (settled && _players.keys.every((id) => _target.containsKey(id))) {
      _fader?.cancel();
      _fader = null;
    }
  }

  void _release(String id) {
    final player = _players.remove(id);
    _volume.remove(id);
    player?.stop();
    player?.dispose();
  }
}
