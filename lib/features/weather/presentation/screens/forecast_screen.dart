import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/features/weather/models/weather_models.dart';

class ForecastScreen extends StatelessWidget {
  final List<ForecastEntry> forecast;
  final bool isLoading;
  final String? error;

  const ForecastScreen({
    super.key,
    required this.forecast,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (forecast.isEmpty) {
      content = const Center(child: Text('No forecast data yet.'));
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: forecast.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final f = forecast[i];
          final timeStr = DateFormat('EEE, MMM d • HH:mm').format(f.timeLocal);
          final iconUrl = 'https://openweathermap.org/img/wn/${f.icon}@2x.png';
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Image.network(
                iconUrl,
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => const Icon(Icons.cloud_outlined),
              ),
              title: Text(timeStr),
              subtitle: Text(_capitalize(f.desc)),
              trailing: Text(
                '${f.tempC.toStringAsFixed(1)} °C',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade100,
            Colors.white,
          ],
        ),
      ),
      child: content,
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
