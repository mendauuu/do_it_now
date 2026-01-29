import 'package:flutter/material.dart';

class ClockTheme {
  final String name;
  final Color backgroundColor;
  final Color secondaryBackgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color? shadowColor;

  const ClockTheme({
    required this.name,
    required this.backgroundColor,
    required this.secondaryBackgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
    this.shadowColor,
  });

  static final List<ClockTheme> themes = [
    // 🔹 Classic Light
    const ClockTheme(
      name: "Light",
      backgroundColor: Color(0xFFF0F4F8),
      secondaryBackgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF2C3E50),
      secondaryTextColor: Color(0xFFE0E6ED),
      borderColor: Color(0xFFBDC3C7),
      hourHandColor: Color(0xFF2C3E50),
      minuteHandColor: Color(0xFF2C3E50),
      secondHandColor: Color(0xFFE74C3C),
      shadowColor: Colors.black26,
    ),

    // 🔹 Classic Dark
    const ClockTheme(
      name: "Dark",
      backgroundColor: Color(0xFF121212),
      secondaryBackgroundColor: Color(0xFF1E1E1E),
      textColor: Colors.white,
      secondaryTextColor: Color(0xFF424242),
      borderColor: Color(0xFF424242),
      hourHandColor: Colors.white,
      minuteHandColor: Colors.white,
      secondHandColor: Color(0xFFFF5252),
      shadowColor: Colors.black45,
    ),

    // 🔹 Neon Glow
    const ClockTheme(
      name: "Neon",
      backgroundColor: Color(0xFF0D0D0D),
      secondaryBackgroundColor: Color(0xFF1B1B1B),
      textColor: Color(0xFF00FFDD), // cyan
      secondaryTextColor: Color(0xFF0F7B7B),
      borderColor: Color(0xFF00FFC6),
      hourHandColor: Color(0xFF00FFDD),
      minuteHandColor: Color(0xFF00FFDD),
      secondHandColor: Color(0xFFFF00FF), // magenta
      shadowColor: Colors.cyanAccent,
    ),

    // 🔹 Soft Pastel
    const ClockTheme(
      name: "Pastel",
      backgroundColor: Color(0xFFFFF8F0),
      secondaryBackgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF6C5B7B),
      secondaryTextColor: Color(0xFFDCD6F7),
      borderColor: Color(0xFFB8B8B8),
      hourHandColor: Color(0xFF6C5B7B),
      minuteHandColor: Color(0xFF6C5B7B),
      secondHandColor: Color(0xFFE56B6F),
      shadowColor: Colors.grey,
    ),

    // 🔹 Elegant Blue
    const ClockTheme(
      name: "ElegantBlue",
      backgroundColor: Color(0xFF0A1F44),
      secondaryBackgroundColor: Color(0xFF142850),
      textColor: Color(0xFFB8D8F8),
      secondaryTextColor: Color(0xFF7EA7D8),
      borderColor: Color(0xFF3E6FB0),
      hourHandColor: Color(0xFFB8D8F8),
      minuteHandColor: Color(0xFFB8D8F8),
      secondHandColor: Color(0xFFFFC947),
      shadowColor: Colors.black45,
    ),

    // 🔹 Midnight Purple
    const ClockTheme(
      name: "MidnightPurple",
      backgroundColor: Color(0xFF1A0F2B),
      secondaryBackgroundColor: Color(0xFF2B1B3D),
      textColor: Color(0xFFE0C3FC),
      secondaryTextColor: Color(0xFFBFA2FF),
      borderColor: Color(0xFF7D5FFF),
      hourHandColor: Color(0xFFE0C3FC),
      minuteHandColor: Color(0xFFE0C3FC),
      secondHandColor: Color(0xFFFF6B6B),
      shadowColor: Colors.purpleAccent,
    ),

    // 🔹 Forest Green
    const ClockTheme(
      name: "ForestGreen",
      backgroundColor: Color(0xFF0B2D0B),
      secondaryBackgroundColor: Color(0xFF133913),
      textColor: Color(0xFFA8E6A3),
      secondaryTextColor: Color(0xFF7ACF7A),
      borderColor: Color(0xFF4CAF50),
      hourHandColor: Color(0xFFA8E6A3),
      minuteHandColor: Color(0xFFA8E6A3),
      secondHandColor: Color(0xFFFFC107),
      shadowColor: Colors.greenAccent,
    ),
  ];

  // Convenience getter
  static ClockTheme get dark => themes.firstWhere((t) => t.name == "Dark");

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockTheme &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
