import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../constants/api_keys.dart';
import '../models/weather_models.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Weather> fetchCurrent(double lat, double lon) async {
    if (kOwmKey.isEmpty) {
      throw WeatherException('Missing API key in code.');
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': '$lat',
      'lon': '$lon',
      'appid': kOwmKey,
      'units': 'metric',
    });

    final resp = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw WeatherException('API error (${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final city = (data['name'] ?? '') as String;
    final temp = (data['main']?['temp'] ?? 0).toDouble();
    final desc = (data['weather'] is List && data['weather'].isNotEmpty)
        ? (data['weather'][0]['description'] ?? '') as String
        : '';

    final tzOffsetSec = (data['timezone'] as num?)?.toInt() ?? 0;
    final dtSec = (data['dt'] as num?)?.toInt();
    final baseUtc = dtSec != null
        ? DateTime.fromMillisecondsSinceEpoch(dtSec * 1000, isUtc: true)
        : DateTime.now().toUtc();
    final local = baseUtc.add(Duration(seconds: tzOffsetSec));
    final dateText = DateFormat('EEE, MMM d, yyyy').format(local);

    return Weather(
      city: city.isEmpty ? 'Unknown location' : city,
      description: desc.isEmpty ? '—' : desc,
      tempC: temp,
      dateText: dateText,
      tzOffsetSec: tzOffsetSec,
    );
  }

  Future<List<ForecastEntry>> fetchForecast(double lat, double lon) async {
    if (kOwmKey.isEmpty) {
      throw WeatherException('Missing API key in code.');
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
      'lat': '$lat',
      'lon': '$lon',
      'appid': kOwmKey,
      'units': 'metric',
    });

    final resp = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw WeatherException('API error (${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final tzOffsetSec = (data['city']?['timezone'] as num?)?.toInt() ?? 0;

    final List list = (data['list'] as List? ?? []);
    final items = <ForecastEntry>[];

    for (final e in list) {
      final dtSec = (e['dt'] as num?)?.toInt();
      if (dtSec == null) continue;

      final utc =
          DateTime.fromMillisecondsSinceEpoch(dtSec * 1000, isUtc: true);
      final local = utc.add(Duration(seconds: tzOffsetSec));

      final temp = (e['main']?['temp'] ?? 0).toDouble();
      final desc = (e['weather'] is List && e['weather'].isNotEmpty)
          ? (e['weather'][0]['description'] ?? '') as String
          : '';
      final icon = (e['weather'] is List && e['weather'].isNotEmpty)
          ? (e['weather'][0]['icon'] ?? '') as String
          : '';

      items.add(
        ForecastEntry(
          timeLocal: local,
          tempC: temp,
          desc: desc,
          icon: icon,
        ),
      );
    }

    return items;
  }
}
