import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final Color baseColor;
  final Color surfaceColor; // New: For cards/surfaces
  final Color lightShadow;
  final Color darkShadow;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color secondaryAccentColor; // New
  final Color? glassBorderColor; // New: For glass
  final bool isDark;

  AppTheme({
    required this.name,
    required this.baseColor,
    required this.surfaceColor,
    required this.lightShadow,
    required this.darkShadow,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.secondaryAccentColor,
    this.glassBorderColor,
    this.isDark = false,
  });
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_selection';

  // 1. Glassmorphism Theme (Modern & Premium)
  static final AppTheme glassTheme = AppTheme(
    name: 'Glass',
    baseColor: const Color(0xFF0F172A), // Deep blue / slate
    surfaceColor: const Color(0x1FFFFFFF), // rgba(255, 255, 255, 0.12)
    lightShadow: Colors.transparent, // Not used in Glass usually
    darkShadow: Colors.transparent,
    textColor: const Color(0xFFFFFFFF),
    secondaryTextColor: const Color(0xFFCBD5E1),
    accentColor: const Color(0xFF38BDF8), // Sky Blue
    secondaryAccentColor: const Color(0xFFA5F3FC), // Light Cyan
    glassBorderColor: const Color(0x2EFFFFFF), // rgba(255,255,255,0.18)
    isDark: true,
  );

  // 2. Neumorphism Theme (Soft & Minimal)
  // Note: Neumorphism usually requires light/dark shadows on same base
  static final AppTheme lightTheme = AppTheme(
    // Renamed 'Soft Dark' to 'Neumorphism' effectively but keeping variable logic cleaner if we replace 'darkTheme' reference or create new ones
    name: 'Neumorphism',
    baseColor: const Color(0xFFE5E7EB), // Soft grey
    surfaceColor: const Color(
      0xFFE5E7EB,
    ), // Surface matches base for neumorphism
    lightShadow: const Color(0xFFFFFFFF),
    darkShadow: const Color(0xFF9CA3AF),
    textColor: const Color(0xFF111827),
    secondaryTextColor: const Color(0xFF4B5563),
    accentColor: const Color(0xFF6366F1), // Indigo
    secondaryAccentColor: const Color(
      0xFF818CF8,
    ), // Slightly lighter indigo for secondary
    isDark: false,
  );

  // 3. Cream Theme (Warm & Elegant)
  static final AppTheme creamTheme = AppTheme(
    name: 'Cream',
    baseColor: const Color(0xFFFFF7ED), // Cream
    surfaceColor: const Color(0xFFFFEDD5), // Surface cards
    lightShadow: const Color(0xFFFFFFFF),
    darkShadow: const Color(0xFFD7CCC8),
    textColor: const Color(0xFF3F2E1C),
    secondaryTextColor: const Color(0xFF6B4F2D),
    accentColor: const Color(0xFF9A3412), // Warm brown
    secondaryAccentColor: const Color(0xFFF59E0B), // Amber
    isDark: false,
  );

  // 4. Dark Theme (Professional & Safe)
  static final AppTheme darkTheme = AppTheme(
    name: 'Dark',
    baseColor: const Color(0xFF0B0F19),
    surfaceColor: const Color(0xFF111827),
    lightShadow: const Color(
      0xFF1F2937,
    ), // Lighter part of dark neumorph if needed
    darkShadow: const Color(0xFF000000),
    textColor: const Color(0xFFE5E7EB),
    secondaryTextColor: const Color(0xFF9CA3AF),
    accentColor: const Color(0xFF3B82F6), // Blue
    secondaryAccentColor: const Color(0xFF22C55E), // Green
    isDark: true,
  );

  // Current Theme State
  AppTheme _currentTheme = glassTheme;
  AppTheme get currentTheme => _currentTheme;

  ThemeService() {
    _loadTheme();
  }

  void setTheme(String themeName) {
    if (themeName == 'Neumorphism') {
      _currentTheme = lightTheme;
    } else if (themeName == 'Cream') {
      _currentTheme = creamTheme;
    } else if (themeName == 'Dark') {
      _currentTheme = darkTheme;
    } else {
      _currentTheme = glassTheme;
    }
    notifyListeners();
    _saveTheme(themeName);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_themeKey);
    setTheme(name ?? 'Glass');
  }

  Future<void> _saveTheme(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, name);
  }
}
