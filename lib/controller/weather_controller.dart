import 'dart:async';
import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import '../services/weather_service.dart';

class WeatherController extends ChangeNotifier {
  static final WeatherController _instance = WeatherController._internal();
  factory WeatherController() => _instance;

  WeatherController._internal() {
    fetchWeather();
    _startAutoRefresh();
  }

  final WeatherService _weatherService = WeatherService();

  Weather? _weather;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeather() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final weather = await _weatherService.fetchCurrentWeather();

      _weather = weather;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      fetchWeather();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
