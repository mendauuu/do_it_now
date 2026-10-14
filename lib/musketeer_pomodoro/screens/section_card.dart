import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The rounded white card both the settings and analytics screens
/// use to group related content — one shared widget so a style
/// tweak only needs to happen in one place.
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: kAccent, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: kInk, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(color: kInkFaint, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
