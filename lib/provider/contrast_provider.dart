import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContrastProvider extends ChangeNotifier {
  double _contrast = 1.0; 
  bool _initialized = false;

  double get contrast => _contrast;
  bool get isInitialized => _initialized;

  ContrastProvider() {
    _loadContrast();
  }

  Future<void> _loadContrast() async {
    final prefs = await SharedPreferences.getInstance();
    _contrast = prefs.getDouble('contrast') ?? 1.0;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setContrast(double value) async {
    _contrast = value.clamp(0.8, 1.5); 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('contrast', _contrast);
    notifyListeners();
  }

  Future<void> resetContrast() async {
    _contrast = 1.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('contrast');
    notifyListeners();
  }
}
