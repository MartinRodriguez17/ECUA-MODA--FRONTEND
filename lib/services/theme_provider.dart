import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _cargarTema();
  }

  Future<void> _cargarTema() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('tema_oscuro') ?? false;
    notifyListeners();
  }

  Future<void> toggleTema() async {
    _isDark = !_isDark;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', _isDark);
    notifyListeners();
  }
}