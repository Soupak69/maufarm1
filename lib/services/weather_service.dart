import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  late final WeatherFactory _wf;

  WeatherService() {
    final apiKey = dotenv.env['WEATHER_API']!;
    if (apiKey.isEmpty) {
      throw Exception('Missing WEATHER_API in .env');
    }
    _wf = WeatherFactory(apiKey);
  }

  Future<Weather> fetchCurrentWeather() async {
   
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    
    return await _wf.currentWeatherByLocation(
      position.latitude,
      position.longitude,
    );
  }
}
