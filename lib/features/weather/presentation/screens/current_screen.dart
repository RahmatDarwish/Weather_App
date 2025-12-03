import 'package:flutter/material.dart';
import 'package:weather_app/features/weather/models/weather_models.dart';

class CurrentScreen extends StatelessWidget {
  final Weather? weather;
  final bool isLoading;
  final String locationStatus;
  final String? error;
  final VoidCallback onRefresh;
  final Animation<double> fadeAnimation;
  final Animation<double> rotationAnimation;
  final LinearGradient weatherGradient;
  final bool isRefreshing;

  const CurrentScreen({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.locationStatus,
    this.error,
    required this.onRefresh,
    required this.fadeAnimation,
    required this.rotationAnimation,
    required this.weatherGradient,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: weatherGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: rotationAnimation.value * 2 * 3.14159,
                    child: const Icon(Icons.wb_sunny_outlined, size: 56),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                locationStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading) ...[
                const CircularProgressIndicator(),
              ],
              if (!isLoading && error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (!isLoading && error == null && weather != null) ...[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        weather!.city,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weather!.dateText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _capitalize(weather!.description),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${weather!.tempC.toStringAsFixed(1)} °C',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AnimatedScale(
                scale: isRefreshing ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: FilledButton.icon(
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: AnimatedRotation(
                    turns: isRefreshing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(Icons.refresh),
                  ),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
