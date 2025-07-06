import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _emailScannerEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get emailScannerEnabled => _emailScannerEnabled;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleEmailScanner() {
    _emailScannerEnabled = !_emailScannerEnabled;
    notifyListeners();
  }
} 