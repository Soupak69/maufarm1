import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleProvider extends ChangeNotifier {
  static const String _key = 'font_scale';
  double _scale = 1.0;

  double get scale => _scale;

  FontScaleProvider() {
    _loadScale();
  }

  Future<void> _loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_key) ?? 1.0;
    notifyListeners();
  }

  Future<void> _saveScale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, _scale);
  }

  void increase() {
    if (_scale < 1.5) {
      _scale += 0.1;
      _saveScale();
      notifyListeners();
    }
  }

  void decrease() {
    if (_scale > 0.8) {
      _scale -= 0.1;
      _saveScale();
      notifyListeners();
    }
  }

  void reset() {
    _scale = 1.0;
    _saveScale();
    notifyListeners();
  }
}

