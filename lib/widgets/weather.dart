import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:weather/weather.dart';
import '../../controller/weather_controller.dart';

enum WeatherParticle { none, rain, lightning, fog, stars, clouds }

class WeatherTheme {
  final List<Color> gradient;
  final IconData icon;
  final WeatherParticle particles;

  WeatherTheme({
    required this.gradient,
    required this.icon,
    required this.particles,
  });

  static WeatherTheme defaultTheme() {
    return WeatherTheme(
      gradient: [Color(0xFF4299E1), Color(0xFF3182CE)],
      icon: Icons.wb_cloudy,
      particles: WeatherParticle.none,
    );
  }

  static WeatherTheme fromWeather(Weather weather) {
    final condition = weather.weatherConditionCode ?? 800;

    if (condition >= 200 && condition < 300) {
      return WeatherTheme(
        gradient: [Color(0xFF4A5568), Color(0xFF2D3748), Color(0xFF1A202C)],
        icon: Icons.thunderstorm,
        particles: WeatherParticle.lightning,
      );
    } else if (condition >= 300 && condition < 600) {
      return WeatherTheme(
        gradient: [Color(0xFF4299E1), Color(0xFF3182CE), Color(0xFF2C5282)],
        icon: Icons.water_drop,
        particles: WeatherParticle.rain,
      );
    } else if (condition >= 700 && condition < 800) {
      return WeatherTheme(
        gradient: [Color(0xFFB7C3D0), Color(0xFF90A4AE), Color(0xFF78909C)],
        icon: Icons.cloud,
        particles: WeatherParticle.fog,
      );
    } else if (condition == 800) {
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour < 18) {
        return WeatherTheme(
          gradient: [Color(0xFFFBD38D), Color(0xFFF6AD55), Color(0xFFED8936)],
          icon: Icons.wb_sunny,
          particles: WeatherParticle.none,
        );
      } else {
        return WeatherTheme(
          gradient: [Color(0xFF2C5282), Color(0xFF2A4365), Color(0xFF1A365D)],
          icon: Icons.nightlight_round,
          particles: WeatherParticle.stars,
        );
      }
    } else if (condition >= 801) {
      return WeatherTheme(
        gradient: [Color(0xFF90CDF4), Color(0xFF63B3ED), Color(0xFF4299E1)],
        icon: Icons.cloud_outlined,
        particles: WeatherParticle.clouds,
      );
    }

    return defaultTheme();
  }
}

class WeatherParticles extends StatelessWidget {
  final WeatherParticle particle;

  const WeatherParticles({super.key, required this.particle});

  @override
  Widget build(BuildContext context) {
    switch (particle) {
      case WeatherParticle.rain:
        return _RainAnimation();
      case WeatherParticle.stars:
        return _StarsAnimation();
      case WeatherParticle.clouds:
        return _CloudsAnimation();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _RainAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: List.generate(
          20,
          (i) => Positioned(
            left: (i * 20.0) + (i % 3) * 10,
            top: (i % 5) * 20.0,
            child: Container(
              width: 2,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(begin: 0, end: 8, duration: 1000.ms, curve: Curves.linear)
                .fadeIn(duration: 200.ms)
                .then()
                .fadeOut(duration: 200.ms),
          ),
        ),
      ),
    );
  }
}

class _StarsAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: List.generate(
          12,
          (i) => Positioned(
            left: (i * 30.0) + (i % 5) * 15,
            top: (i % 4) * 30.0,
            child: Icon(
              Icons.star,
              size: 8 + (i % 3) * 2,
              color: Colors.white.withOpacity(0.7),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeOut(duration: Duration(milliseconds: 1000 + (i % 4) * 500))
                .then()
                .fadeIn(duration: Duration(milliseconds: 1000 + (i % 4) * 500)),
          ),
        ),
      ),
    );
  }
}

class _CloudsAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 10,
            child: _CloudShape(size: 40)
                .animate(onPlay: (controller) => controller.repeat())
                .slideX(begin: 0, end: 2, duration: 4000.ms, curve: Curves.easeInOut)
                .then()
                .slideX(begin: 2, end: 0, duration: 4000.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            right: 20,
            top: 30,
            child: _CloudShape(size: 50)
                .animate(onPlay: (controller) => controller.repeat())
                .slideX(begin: 0, end: -2, duration: 5000.ms, curve: Curves.easeInOut)
                .then()
                .slideX(begin: -2, end: 0, duration: 5000.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _CloudShape extends StatelessWidget {
  final double size;

  const _CloudShape({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(size),
          ),
        ),
        Positioned(
          left: size * 0.3,
          top: -size * 0.15,
          child: Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class WeatherBox extends StatefulWidget {
  const WeatherBox({super.key});

  @override
  State<WeatherBox> createState() => _WeatherBoxState();
}

class _WeatherBoxState extends State<WeatherBox> {
  late final WeatherController _controller;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _controller = WeatherController();
    _listener = () {
      if (mounted) setState(() {});
    };
    _controller.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return _buildCard(
        child: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (_controller.error != null) {
      return _buildCard(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _controller.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.fetchWeather,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_controller.weather == null) return const SizedBox.shrink();

    final theme = WeatherTheme.fromWeather(_controller.weather!);

    
    return SizedBox(
      height: 150, 
      child: _buildCard(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Stack(
          children: [
            WeatherParticles(particle: theme.particles),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.weather!.areaName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_controller.weather!.temperature?.celsius?.toStringAsFixed(1) ?? '--'}°C',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _controller.weather!.weatherDescription ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(theme.icon, size: 48, color: Colors.white),
                      const SizedBox(height: 4),
                      _buildWeatherDetail(
                        Icons.water_drop,
                        '${_controller.weather!.humidity?.toStringAsFixed(0) ?? '--'}%',
                      ),
                      const SizedBox(height: 4),
                      _buildWeatherDetail(
                        Icons.air,
                        '${_controller.weather!.windSpeed != null ? (_controller.weather!.windSpeed! * 3.6).toStringAsFixed(1) : '--'} km/h',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

Widget _buildCard({required Widget child, LinearGradient? gradient}) {
  return Card(
    elevation: 4,
    margin: EdgeInsets.zero, 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    ),
  );
}


  Widget _buildWeatherDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}
