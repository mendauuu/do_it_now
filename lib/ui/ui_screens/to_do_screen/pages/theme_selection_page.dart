import 'package:flutter/material.dart';
import '../../../theme/clock_theme.dart';

class ThemeSelectionPage extends StatefulWidget {
  final int currentThemeIndex;
  final Function(int) onThemeChanged;
  final ClockTheme theme;

  const ThemeSelectionPage({
    super.key,
    required this.currentThemeIndex,
    required this.onThemeChanged,
    required this.theme,
  });

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  late int selectedThemeIndex;

  @override
  void initState() {
    super.initState();
    selectedThemeIndex = widget.currentThemeIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
        elevation: 0,
        title: Text(
          'Select Theme',
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: ClockTheme.themes.length,
          itemBuilder: (context, index) {
            final theme = ClockTheme.themes[index];
            final isSelected = selectedThemeIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedThemeIndex = index;
                });
                widget.onThemeChanged(index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.theme.buttonColor.withOpacity(0.1)
                      : widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? widget.theme.buttonColor
                        : widget.theme.borderColor,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: widget.theme.glowColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Theme color preview
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.borderColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Hour hand
                          Positioned(
                            top: 10,
                            child: Container(
                              width: 3,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.hourHandColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Center dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.centerDotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Theme info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              color: widget.theme.textColor,
                              fontSize: 17,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Theme ${index + 1}',
                            style: TextStyle(
                              color: widget.theme.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Checkmark
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.theme.buttonColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check,
                          color: widget.theme.buttonColor,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
