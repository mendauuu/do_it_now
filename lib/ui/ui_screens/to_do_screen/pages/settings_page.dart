import 'package:do_it_now/ui/ui_screens/analysis/analysis_screen.dart';
import 'package:flutter/material.dart';
import '../../../theme/clock_theme.dart';
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
  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = 'English'; // Default language
  }

  void _openThemeSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThemeSelectionPage(
          currentThemeIndex: widget.currentThemeIndex,
          onThemeChanged: widget.onThemeChanged,
          theme: widget.theme,
        ),
      ),
    );
  }

  void _showLanguageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.secondaryBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: widget.theme.borderColor),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: widget.theme.highlightColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Language',
              style: TextStyle(
                color: widget.theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'English',
              'español',
              'français',
              'Deutsch',
            ].map((language) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedLanguage == language
                        ? widget.theme.buttonColor
                        : widget.theme.borderColor,
                    width: selectedLanguage == language ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    language,
                    style: TextStyle(
                      color: widget.theme.textColor,
                      fontWeight: selectedLanguage == language
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: selectedLanguage == language
                      ? Icon(Icons.check_circle,
                          color: widget.theme.successColor)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedLanguage = language;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: widget.theme.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: widget.theme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Appearance Section
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    color: widget.theme.hourHandColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Theme Settings Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  color: widget.theme.secondaryBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: widget.theme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.theme.hourHandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: widget.theme.hourHandColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'Theme',
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      ClockTheme.themes[widget.currentThemeIndex].name,
                      style: TextStyle(
                        color: widget.theme.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: widget.theme.secondaryTextColor,
                      size: 16,
                    ),
                    onTap: _openThemeSelection,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Section
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                child: Text(
                  'Preferences',
                  style: TextStyle(
                    color: widget.theme.hourHandColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Language Settings Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  color: widget.theme.secondaryBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: widget.theme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.theme.hourHandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.language,
                        color: widget.theme.hourHandColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'Language',
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      selectedLanguage,
                      style: TextStyle(
                        color: widget.theme.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: widget.theme.secondaryTextColor,
                      size: 16,
                    ),
                    onTap: _showLanguageOptions,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Analytics Section
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                child: Text(
                  'Analytics',
                  style: TextStyle(
                    color: widget.theme.hourHandColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Analysis Screen
              AnalysisScreen(theme: widget.theme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
