import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String kOwmKey = "30d2777cece5c31be24351fd3e7f6c0a";

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _index = 0;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  // Location state
  bool _loadingLocation = false;
  String _locationStatus = 'Getting your location…';
  Position? _position;

  // Current weather state
  bool _loadingWeather = false;
  String? _weatherError;
  String? _city;
  String? _description;
  double? _tempC;
  String? _dateText;

  // Forecast state
  bool _loadingForecast = false;
  String? _forecastError;
  int _tzOffsetSec = 0; // time zone offset from API (seconds)
  List<_ForecastItem> _forecast = [];

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear)
    );
    
    _refreshAll();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    // Reset animations
    _fadeController.reset();
    _rotationController.reset();
    
    await _getLocation();
    if (_position != null) {
      await _fetchCurrent(_position!.latitude, _position!.longitude);
      await _fetchForecast(_position!.latitude, _position!.longitude);
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationStatus = 'Requesting location…';
      _weatherError = null;
      _forecastError = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _locationStatus = 'Location services are OFF. Please enable GPS.';
          _position = null;
          _loadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = 'Permission denied. Please allow location.';
          _position = null;
          _loadingLocation = false;
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus =
              'Permission permanently denied. Enable it in app settings.';
          _position = null;
          _loadingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _position = pos;
        _locationStatus = 'Location OK';
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Location error: $e';
        _position = null;
        _loadingLocation = false;
      });
    }
  }

  Future<void> _fetchCurrent(double lat, double lon) async {
    if (kOwmKey.isEmpty) {
      setState(() {
        _weatherError = 'Missing API key in code.';
        _city = null;
        _description = null;
        _tempC = null;
        _dateText = null;
      });
      return;
    }

    setState(() {
      _loadingWeather = true;
      _weatherError = null;
    });

    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat': '$lat',
        'lon': '$lon',
        'appid': kOwmKey,
        'units': 'metric',
      });

      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) {
        setState(() {
          _weatherError = 'API error (${resp.statusCode}).';
          _loadingWeather = false;
        });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final city = (data['name'] ?? '') as String;
      final temp = (data['main']?['temp'] ?? 0).toDouble();
      final desc = (data['weather'] is List && data['weather'].isNotEmpty)
          ? (data['weather'][0]['description'] ?? '') as String
          : '';

      // Local date from dt + timezone
      final tzOffsetSec = (data['timezone'] as num?)?.toInt() ?? 0;
      final dtSec = (data['dt'] as num?)?.toInt();
      final baseUtc = dtSec != null
          ? DateTime.fromMillisecondsSinceEpoch(dtSec * 1000, isUtc: true)
          : DateTime.now().toUtc();
      final local = baseUtc.add(Duration(seconds: tzOffsetSec));
      final dateText = DateFormat('EEE, MMM d, yyyy').format(local);

      setState(() {
        _city = city.isEmpty ? 'Unknown location' : city;
        _tempC = temp;
        _description = desc.isEmpty ? '—' : desc;
        _dateText = dateText;
        _tzOffsetSec = tzOffsetSec;
        _loadingWeather = false;
      });
      
      // Trigger fade-in animation
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _weatherError = 'Network error: $e';
        _loadingWeather = false;
      });
    }
  }

  Future<void> _fetchForecast(double lat, double lon) async {
    if (kOwmKey.isEmpty) {
      setState(() {
        _forecastError = 'Missing API key in code.';
        _forecast = [];
      });
      return;
    }

    setState(() {
      _loadingForecast = true;
      _forecastError = null;
      _forecast = [];
    });

    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
        'lat': '$lat',
        'lon': '$lon',
        'appid': kOwmKey,
        'units': 'metric',
      });

      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) {
        setState(() {
          _forecastError = 'API error (${resp.statusCode}).';
          _loadingForecast = false;
        });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      // city.timezone gives offset for forecast
      final cityTz = (data['city']?['timezone'] as num?)?.toInt();
      if (cityTz != null) _tzOffsetSec = cityTz;

      final List list = (data['list'] as List? ?? []);
      final items = <_ForecastItem>[];

      for (final e in list) {
        final dtSec = (e['dt'] as num?)?.toInt();
        if (dtSec == null) continue;

        final utc = DateTime.fromMillisecondsSinceEpoch(dtSec * 1000, isUtc: true);
        final local = utc.add(Duration(seconds: _tzOffsetSec));

        final temp = (e['main']?['temp'] ?? 0).toDouble();
        final desc = (e['weather'] is List && e['weather'].isNotEmpty)
            ? (e['weather'][0]['description'] ?? '') as String
            : '';
        final icon = (e['weather'] is List && e['weather'].isNotEmpty)
            ? (e['weather'][0]['icon'] ?? '') as String
            : '';

        items.add(_ForecastItem(timeLocal: local, tempC: temp, desc: desc, icon: icon));
      }

      setState(() {
        _forecast = items; // OpenWeather returns ~40 entries (3h step, 5 days)
        _loadingForecast = false;
      });
    } catch (e) {
      setState(() {
        _forecastError = 'Network error: $e';
        _loadingForecast = false;
      });
    }
  }

  // Helper method to get gradient based on weather
  LinearGradient _getWeatherGradient() {
    if (_description == null) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
      );
    }

    final desc = _description!.toLowerCase();
    
    if (desc.contains('clear') || desc.contains('sunny')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFFFA726)], // Clear sky
      );
    } else if (desc.contains('cloud')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF78909C), Color(0xFFCFD8DC)], // Cloudy
      );
    } else if (desc.contains('rain') || desc.contains('drizzle')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF455A64), Color(0xFF90A4AE)], // Rainy
      );
    } else if (desc.contains('snow')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB0BEC5), Color(0xFFFFFFFF)], // Snowy
      );
    } else if (desc.contains('thunder') || desc.contains('storm')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF37474F), Color(0xFF78909C)], // Stormy
      );
    } else if (desc.contains('mist') || desc.contains('fog') || desc.contains('haze')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF90A4AE), Color(0xFFECEFF1)], // Misty
      );
    }
    
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)], // Default
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Current page
      Container(
        decoration: BoxDecoration(
          gradient: _getWeatherGradient(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Animated weather icon
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: const Icon(Icons.wb_sunny_outlined, size: 56),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                _locationStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              if (_loadingLocation || _loadingWeather) ...[
                const CircularProgressIndicator(),
                // Start rotation animation when loading
                Builder(builder: (context) {
                  if (_loadingWeather || _loadingLocation) {
                    _rotationController.repeat();
                  } else {
                    _rotationController.stop();
                  }
                  return const SizedBox.shrink();
                }),
              ],

              if (!_loadingLocation && !_loadingWeather && _weatherError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _weatherError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (!_loadingLocation &&
                  !_loadingWeather &&
                  _weatherError == null &&
                  _city != null &&
                  _tempC != null) ...[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        _city!,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      if (_dateText != null)
                        Text(
                          _dateText!,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _description!.isEmpty
                            ? '—'
                            : _description![0].toUpperCase() + _description!.substring(1),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_tempC!.toStringAsFixed(1)} °C',
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
              AnimatedScale(
                scale: (_loadingLocation || _loadingWeather || _loadingForecast) ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: FilledButton.icon(
                  onPressed:
                      _loadingLocation || _loadingWeather || _loadingForecast
                          ? null
                          : _refreshAll,
                  icon: AnimatedRotation(
                    turns: (_loadingLocation || _loadingWeather || _loadingForecast) ? 1.0 : 0.0,
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
      ),

      // Forecast page
      _buildForecastPage(),

      // About page
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getWeatherGradient().colors.first.withAlpha((0.3 * 255).round()),
              _getWeatherGradient().colors.last.withAlpha((0.1 * 255).round()),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Text(
                          'About', 
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: _getWeatherGradient().colors.first.withAlpha((0.8 * 255).round()),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Text(
                          'Weather App for Everyone.\nBy Rahmat Darwish.\nData: OpenWeatherMap.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getWeatherGradient().colors.first,
                _getWeatherGradient().colors.last.withAlpha((0.8 * 255).round()),
              ],
            ),
          ),
          child: AppBar(
            title: const Text(
              'Weather App',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: Container(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (states) => states.contains(WidgetState.selected)
                ? TextStyle(
                    color: _getWeatherGradient().colors.first, 
                    fontWeight: FontWeight.bold
                  )
                : const TextStyle(color: Colors.grey),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => states.contains(WidgetState.selected)
                ? IconThemeData(
                    color: _getWeatherGradient().colors.first, 
                    size: 26
                  )
                : const IconThemeData(color: Colors.grey, size: 22),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Current'),
            NavigationDestination(icon: Icon(Icons.view_day_outlined), label: 'Forecast'),
            NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
          ],
        ),
      ),
    );
  }

  // Forecast page widget
  Widget _buildForecastPage() {
    Widget content;
    
    if (_loadingLocation || _loadingForecast) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_forecastError != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_forecastError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    } else if (_forecast.isEmpty) {
      content = const Center(child: Text('No forecast data yet.'));
    } else {
      // Show all entries (3-hour steps, ~40 items = 5 days)
      content = AnimatedList(
        padding: const EdgeInsets.symmetric(vertical: 8),
        initialItemCount: _forecast.length,
        itemBuilder: (context, i, animation) {
          if (i >= _forecast.length) return const SizedBox.shrink();
          
          final f = _forecast[i];
          final timeStr = DateFormat('EEE, MMM d • HH:mm').format(f.timeLocal);
          final iconUrl = 'https://openweathermap.org/img/wn/${f.icon}@2x.png';
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: Image.network(
                    iconUrl, 
                    width: 40, 
                    height: 40, 
                    errorBuilder: (_, __, ___) => const Icon(Icons.cloud_outlined)
                  ),
                  title: Text(timeStr),
                  subtitle: Text(_capitalize(f.desc)),
                  trailing: Text(
                    '${f.tempC.toStringAsFixed(1)} °C',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // Wrap with gradient background
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

class _ForecastItem {
  final DateTime timeLocal;
  final double tempC;
  final String desc;
  final String icon;

  _ForecastItem({
    required this.timeLocal,
    required this.tempC,
    required this.desc,
    required this.icon,
  });
}
