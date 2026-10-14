import 'package:flutter/material.dart';

// Kept close to the scene's own palette (sun gold, castle stone,
// grass green, sunset orange) rather than default Material colors,
// so these screens don't feel like they belong to a different app
// from the animated one behind the clock.

const kInk = Color(0xFF4A3B2A);
const kInkFaint = Color(0xFF8A7860);
const kBackground = Color(0xFFF4E8D0);
const kBackgroundDeep = Color(0xFFE8D4AE);
const kCardColor = Colors.white;
const kAccent = Color(0xFFD46A2B);

// A small cycle of colors pulled straight from things already drawn
// in the scene (sun, grass, autumn foliage, mountains, river, flag),
// used for the topic-breakdown bars on the analytics screen.
const kTopicColors = [
  Color(0xFFFFD65C), // sun
  Color(0xFF6FA85B), // grass
  Color(0xFFD46A2B), // autumn foliage
  Color(0xFF8F7CB8), // mountains
  Color(0xFF5FAEDB), // river
  Color(0xFFC1443B), // castle flag
];
