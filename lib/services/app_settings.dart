import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  bool incognitoMode = false;

  SharedPreferences? preferences;

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isCognitoMode => incognitoMode;

  AppSettings() {
    loadSettingsFromPrefs();
  }

  initPreferences() async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
  }

  loadSettingsFromPrefs() async {
    await initPreferences();
    bool darkTheme = preferences?.getBool('darkTheme') ?? false;
    themeMode = darkTheme ? ThemeMode.dark : ThemeMode.light;

    incognitoMode = preferences?.getBool('incognitoMode') ?? false;

    notifyListeners();
  }

  saveSettingstoPrefs() async {
    await initPreferences();
    bool value = isDarkMode;
    preferences?.setBool('darkTheme', value);
    notifyListeners();
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    saveSettingstoPrefs();
    notifyListeners();
  }

  saveIncognitotoPrefs() async {
    await initPreferences();
    preferences?.setBool('incognitoMode', incognitoMode);
  }

  void toggleIncognito() {
    incognitoMode = !incognitoMode;
    saveIncognitotoPrefs();
    notifyListeners();
  }
}

class AppTheme {
  static final darkTheme = ThemeData(
    // appBarTheme: const AppBarTheme(color: Colors.black),
    // bottomNavigationBarTheme:
    //     const BottomNavigationBarThemeData(selectedItemColor: Colors.white),
    scaffoldBackgroundColor: Colors.grey.shade900,
    colorScheme: const ColorScheme.dark(),
    iconTheme: const IconThemeData(color: Colors.white),
  );

  static final lightTheme = ThemeData(
    // appBarTheme: const AppBarTheme(color: Colors.purple),
    // bottomNavigationBarTheme:
    //     const BottomNavigationBarThemeData(selectedItemColor: Colors.black),
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(),
    iconTheme: const IconThemeData(color: Colors.black),
    primarySwatch: Colors.teal,
  );
}
