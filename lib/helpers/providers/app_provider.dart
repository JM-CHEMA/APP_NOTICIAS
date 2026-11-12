import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _onboarded = false;
  ThemeMode get themeMode => _themeMode;
  bool get onboarded => _onboarded;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getBool('dark_mode') == true ? ThemeMode.dark : ThemeMode.light;
    _onboarded = prefs.getBool('onboarding_complete') == true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> finishOnboarding() async {
    _onboarded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}
