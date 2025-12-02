class Weather {
  final String city;
  final String description;
  final double tempC;
  final String dateText;
  final int tzOffsetSec;

  const Weather({
    required this.city,
    required this.description,
    required this.tempC,
    required this.dateText,
    required this.tzOffsetSec,
  });
}

class ForecastEntry {
  final DateTime timeLocal;
  final double tempC;
  final String desc;
  final String icon;

  const ForecastEntry({
    required this.timeLocal,
    required this.tempC,
    required this.desc,
    required this.icon,
  });
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
