import 'package:flutter/material.dart';
import 'package:do_it_now/ui/ui_screens/analysis/analysis_screen.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'theme_selection_page.dart';

class SettingsPage extends StatefulWidget {
  final int currentThemeIndex;
  final Function(int) onThemeChanged;
  final ClockTheme theme;

  const SettingsPage({
    super.key,
    required this.currentThemeIndex,
    required this.onThemeChanged,
    required this.theme,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = 'English';
  }

  void _openThemes() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ThemeSelectionPage(
            currentThemeIndex: widget.currentThemeIndex,
            onThemeChanged: widget.onThemeChanged,
            theme: widget.theme,
          ),
        ),
      );

  void _openAnalytics() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(theme: widget.theme),
        ),
      );

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.secondaryBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: widget.theme.borderColor),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: widget.theme.highlightColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Language',
                style: TextStyle(
                    color: widget.theme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _langTile('English', true),
            _langTile('Español', false),
            _langTile('Français', false),
            _langTile('O\'zbek', false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _langTile(String lang, bool enabled) {
    final selected = _language == lang;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? widget.theme.buttonColor : widget.theme.borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        enabled: enabled,
        title: Text(lang,
            style: TextStyle(
                color: enabled
                    ? widget.theme.textColor
                    : widget.theme.secondaryTextColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        subtitle: enabled
            ? null
            : Text('Coming soon',
                style: TextStyle(
                    color: widget.theme.secondaryTextColor, fontSize: 12)),
        trailing: selected
            ? Icon(Icons.check_circle, color: widget.theme.successColor)
            : null,
        onTap: enabled
            ? () {
                setState(() => _language = lang);
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Settings',
            style: TextStyle(
                color: widget.theme.textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _sectionLabel('Appearance'),
          _tile(
            icon: Icons.palette,
            title: 'Theme',
            subtitle: ClockTheme.themes[widget.currentThemeIndex].name,
            onTap: _openThemes,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Preferences'),
          _tile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _language,
            onTap: _showLanguageSheet,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Insights'),
          _tile(
            icon: Icons.bar_chart_rounded,
            title: 'Productivity analytics',
            subtitle: 'View your task stats',
            onTap: _openAnalytics,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10, left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: widget.theme.secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: widget.theme.secondaryBackgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: widget.theme.borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.theme.hourHandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: widget.theme.hourHandColor, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                color: widget.theme.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: widget.theme.secondaryTextColor, fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios,
            color: widget.theme.secondaryTextColor, size: 15),
        onTap: onTap,
      ),
    );
  }
}
