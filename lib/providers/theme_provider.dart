// import 'package:flutter/material.dart';

// class ThemeProvider extends ChangeNotifier {
//   bool isdark = false;

//   void toggleThem() {
//     isdark = !isdark;
//     notifyListeners();
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool isdark = false;

  ThemeProvider() {
    loadTheme(); 
  }

  // Load saved theme
  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isdark = prefs.getBool('isDark') ?? false;
    notifyListeners();
  }

  // Toggle + save
  void toggleThem() async {
    isdark = !isdark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isdark);

    notifyListeners();
  }
}