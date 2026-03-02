import 'package:flutter/material.dart';

class ClockTheme {
  final String name;
  // Primary Colors
  final Color backgroundColor;
  final Color secondaryBackgroundColor;
  final Color textColor;
  final Color secondaryTextColor;

  // Clock Elements
  final Color borderColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color centerDotColor;

  // Accent & Highlights
  final Color accentColor;
  final Color highlightColor;
  final Color glowColor;

  // Status Colors
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color infoColor;

  // UI Elements
  final Color cardColor;
  final Color buttonColor;
  final Color buttonHoverColor;
  final Color inputFieldColor;

  // Effects
  final Color? shadowColor;
  final Color overlayColor;

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
    required this.centerDotColor,
    required this.accentColor,
    required this.highlightColor,
    required this.glowColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.infoColor,
    required this.cardColor,
    required this.buttonColor,
    required this.buttonHoverColor,
    required this.inputFieldColor,
    required this.overlayColor,
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
      minuteHandColor: Color(0xFFB8B8D6),
      secondHandColor: Color(0xFF7C83FD),
      centerDotColor: Color(0xFF7C83FD),
      accentColor: Color(0xFF7C83FD),
      highlightColor: Color(0xFFA8AFFF),
      glowColor: Color(0xFF5C63DD),
      successColor: Color(0xFF00D084),
      errorColor: Color(0xFFFF6B6B),
      warningColor: Color(0xFFFFD93D),
      infoColor: Color(0xFF6BCB77),
      cardColor: Color(0xFF1C1C2B),
      buttonColor: Color(0xFF7C83FD),
      buttonHoverColor: Color(0xFFA8AFFF),
      inputFieldColor: Color(0xFF242432),
      overlayColor: Color(0xFF000000),
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
      minuteHandColor: Color(0xFF81D4FA),
      secondHandColor: Color(0xFFFFCA28),
      centerDotColor: Color(0xFFFFCA28),
      accentColor: Color(0xFF1E88E5),
      highlightColor: Color(0xFF42A5F5),
      glowColor: Color(0xFF0097A7),
      successColor: Color(0xFF26A69A),
      errorColor: Color(0xFFEF5350),
      warningColor: Color(0xFFFFCA28),
      infoColor: Color(0xFF29B6F6),
      cardColor: Color(0xFF132F3D),
      buttonColor: Color(0xFF1E88E5),
      buttonHoverColor: Color(0xFF42A5F5),
      inputFieldColor: Color(0xFF1B3A47),
      overlayColor: Color(0xFF000000),
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
      minuteHandColor: Color(0xFFC8D5D0),
      secondHandColor: Color(0xFFFFB74D),
      centerDotColor: Color(0xFF4CAF50),
      accentColor: Color(0xFF4CAF50),
      highlightColor: Color(0xFF66BB6A),
      glowColor: Color(0xFF388E3C),
      successColor: Color(0xFF81C784),
      errorColor: Color(0xFFE57373),
      warningColor: Color(0xFFFFB74D),
      infoColor: Color(0xFF64B5F6),
      cardColor: Color(0xFF263C3F),
      buttonColor: Color(0xFF4CAF50),
      buttonHoverColor: Color(0xFF66BB6A),
      inputFieldColor: Color(0xFF2C3E42),
      overlayColor: Color(0xFF000000),
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
      minuteHandColor: Color(0xFF9FA8DA),
      secondHandColor: Color(0xFFFF8A65),
      centerDotColor: Color(0xFFFF8A65),
      accentColor: Color(0xFF5C6BC0),
      highlightColor: Color(0xFF7986CB),
      glowColor: Color(0xFF3F51B5),
      successColor: Color(0xFF81C784),
      errorColor: Color(0xFFEF5350),
      warningColor: Color(0xFFFFCA28),
      infoColor: Color(0xFF29B6F6),
      cardColor: Color(0xFF22234A),
      buttonColor: Color(0xFF5C6BC0),
      buttonHoverColor: Color(0xFF7986CB),
      inputFieldColor: Color(0xFF2A2B50),
      overlayColor: Color(0xFF000000),
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
      minuteHandColor: Color(0xFFBDBDBD),
      secondHandColor: Color(0xFF64B5F6),
      centerDotColor: Color(0xFF64B5F6),
      accentColor: Color(0xFF64B5F6),
      highlightColor: Color(0xFF90CAF9),
      glowColor: Color(0xFF2196F3),
      successColor: Color(0xFF4CAF50),
      errorColor: Color(0xFFE53935),
      warningColor: Color(0xFFFFA726),
      infoColor: Color(0xFF42A5F5),
      cardColor: Color(0xFF242424),
      buttonColor: Color(0xFF64B5F6),
      buttonHoverColor: Color(0xFF90CAF9),
      inputFieldColor: Color(0xFF2C2C2C),
      overlayColor: Color(0xFF000000),
      shadowColor: Colors.black54,
    ),

    // 🌅 Warm Dusk (Soft Warm Tone)
    const ClockTheme(
      name: "WarmDusk",
      backgroundColor: Color(0xFF2C1B1B),
      secondaryBackgroundColor: Color(0xFF3D2B2A),
      textColor: Color(0xFFFFD7B5),
      secondaryTextColor: Color(0xFFD4A574),
      borderColor: Color(0xFFC17A6B),
      hourHandColor: Color(0xFFFFD7B5),
      minuteHandColor: Color(0xFFE6C3A0),
      secondHandColor: Color(0xFFFFAB91),
      centerDotColor: Color(0xFFC17A6B),
      accentColor: Color(0xFFC17A6B),
      highlightColor: Color(0xFFD4956B),
      glowColor: Color(0xFFA1614F),
      successColor: Color(0xFF81C784),
      errorColor: Color(0xFFE74C3C),
      warningColor: Color(0xFFF39C12),
      infoColor: Color(0xFF3498DB),
      cardColor: Color(0xFF3D2B2A),
      buttonColor: Color(0xFFC17A6B),
      buttonHoverColor: Color(0xFFD4956B),
      inputFieldColor: Color(0xFF4A3534),
      overlayColor: Color(0xFF000000),
      shadowColor: Color(0xFF8B4513),
    ),
  ];

  // Convenience getter
  static ClockTheme get dark =>
      themes.firstWhere((t) => t.name == "QuietMidnight");

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockTheme &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
