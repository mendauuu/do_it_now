import 'package:flutter/material.dart';
import 'package:do_it_now/ui/theme/app_colors.dart';

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
    // 🌙 Quiet Midnight (Ultra Clean Dark)
    const ClockTheme(
      name: "QuietMidnight",
      backgroundColor: Color(0xFF14141F),
      secondaryBackgroundColor: Color(0xFF1C1C2B),
      textColor: Color(0xFFE6E6FA),
      secondaryTextColor: Color(0xFF8A8AA3),
      borderColor: Color(0xFF2A2A3D),
      hourHandColor: Color(0xFFE6E6FA),
      minuteHandColor: Color(0xFFE6E6FA),
      secondHandColor: Color(0xFF7C83FD),
      shadowColor: Colors.black54,
    ),

    // 🌊 Deep Ocean (Calm Blue)
    const ClockTheme(
      name: "DeepOcean",
      backgroundColor: Color(0xFF0F2027),
      secondaryBackgroundColor: Color(0xFF132F3D),
      textColor: Color(0xFFB3E5FC),
      secondaryTextColor: Color(0xFF4FC3F7),
      borderColor: Color(0xFF1E88E5),
      hourHandColor: Color(0xFFB3E5FC),
      minuteHandColor: Color(0xFFB3E5FC),
      secondHandColor: Color(0xFFFFCA28),
      shadowColor: Colors.black45,
    ),

    // 🌿 Sage Calm (Very Relaxing)
    const ClockTheme(
      name: "SageCalm",
      backgroundColor: Color(0xFF1E2D2F),
      secondaryBackgroundColor: Color(0xFF263C3F),
      textColor: Color(0xFFDDE5E2),
      secondaryTextColor: Color(0xFF9DB8A0),
      borderColor: Color(0xFF4CAF50),
      hourHandColor: Color(0xFFDDE5E2),
      minuteHandColor: Color(0xFFDDE5E2),
      secondHandColor: Color(0xFFFFB74D),
      shadowColor: Colors.greenAccent,
    ),

    // 🌌 Soft Indigo (Modern Tech Look)
    const ClockTheme(
      name: "SoftIndigo",
      backgroundColor: Color(0xFF1A1B2F),
      secondaryBackgroundColor: Color(0xFF22234A),
      textColor: Color(0xFFC5CAE9),
      secondaryTextColor: Color(0xFF7986CB),
      borderColor: Color(0xFF5C6BC0),
      hourHandColor: Color(0xFFC5CAE9),
      minuteHandColor: Color(0xFFC5CAE9),
      secondHandColor: Color(0xFFFF8A65),
      shadowColor: Colors.indigoAccent,
    ),

    // 🪨 Graphite Minimal (Very Premium)
    const ClockTheme(
      name: "Graphite",
      backgroundColor: Color(0xFF181818),
      secondaryBackgroundColor: Color(0xFF242424),
      textColor: Color(0xFFE0E0E0),
      secondaryTextColor: Color(0xFF9E9E9E),
      borderColor: Color(0xFF424242),
      hourHandColor: Color(0xFFE0E0E0),
      minuteHandColor: Color(0xFFE0E0E0),
      secondHandColor: Color(0xFF64B5F6),
      shadowColor: Colors.black54,
    ),

    // 🌅 Warm Dusk (Soft Warm Tone)
    const ClockTheme(
      name: "WarmDusk",
      backgroundColor: Color(0xFF2B1D1D),
      secondaryBackgroundColor: Color(0xFF3A2626),
      textColor: Color(0xFFFFE0B2),
      secondaryTextColor: Color(0xFFFFAB91),
      borderColor: Color(0xFF8D6E63),
      hourHandColor: Color(0xFFFFE0B2),
      minuteHandColor: Color(0xFFFFE0B2),
      secondHandColor: Color(0xFFEF5350),
      shadowColor: Colors.deepOrangeAccent,
    ),
    // 🔹 Classic Light
    const ClockTheme(
      name: "Light",
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.background,
      secondaryBackgroundColor: AppColors.surface,
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
