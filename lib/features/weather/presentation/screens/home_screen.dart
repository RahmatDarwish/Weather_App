import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/constants/api_keys.dart';
import 'package:weather_app/features/weather/models/weather_models.dart';
import 'package:weather_app/features/weather/services/location_service.dart';
import 'package:weather_app/features/weather/services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _weatherService = WeatherService();
  final _locationService = LocationService();

  int _index = 0;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  bool _loadingLocation = false;
  bool _loadingWeather = false;
  bool _loadingForecast = false;

  String _locationStatus = 'Getting your location…';
  String? _weatherError;
  String? _forecastError;

  Position? _position;
  Weather? _weather;
  List<ForecastEntry> _forecast = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
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
    _fadeController.reset();
    _rotationController.reset();

    setState(() {
      _weatherError = null;
      _forecastError = null;
    });

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
      final pos = await _locationService.getCurrentPosition();
      setState(() {
        _position = pos;
        _locationStatus = 'Location OK';
        _loadingLocation = false;
      });
    } on LocationException catch (e) {
      setState(() {
        _locationStatus = e.message;
        _position = null;
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
        _weather = null;
      });
      return;
    }

    setState(() {
      _loadingWeather = true;
      _weatherError = null;
    });

    try {
      final weather = await _weatherService.fetchCurrent(lat, lon);
      setState(() {
        _weather = weather;
        _loadingWeather = false;
      });
      _fadeController.forward();
    } on WeatherException catch (e) {
      setState(() {
        _weatherError = e.message;
        _weather = null;
        _loadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = 'Network error: $e';
        _weather = null;
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
      final items = await _weatherService.fetchForecast(lat, lon);
      setState(() {
        _forecast = items;
        _loadingForecast = false;
      });
    } on WeatherException catch (e) {
      setState(() {
        _forecastError = e.message;
        _loadingForecast = false;
      });
    } catch (e) {
      setState(() {
        _forecastError = 'Network error: $e';
        _loadingForecast = false;
      });
    }
  }

  LinearGradient _getWeatherGradient() {
    final desc = _weather?.description.toLowerCase();
    if (desc == null) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
      );
    }
    if (desc.contains('clear') || desc.contains('sunny')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFFFA726)],
      );
    } else if (desc.contains('cloud')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF78909C), Color(0xFFCFD8DC)],
      );
    } else if (desc.contains('rain') || desc.contains('drizzle')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
      );
    } else if (desc.contains('snow')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB0BEC5), Color(0xFFFFFFFF)],
      );
    } else if (desc.contains('thunder') || desc.contains('storm')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF37474F), Color(0xFF78909C)],
      );
    } else if (desc.contains('mist') ||
        desc.contains('fog') ||
        desc.contains('haze')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF90A4AE), Color(0xFFECEFF1)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildCurrentPage(),
      _buildForecastPage(),
      _buildAboutPage(),
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
        transitionBuilder: (child, animation) {
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
                    fontWeight: FontWeight.bold,
                  )
                : const TextStyle(color: Colors.grey),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => states.contains(WidgetState.selected)
                ? IconThemeData(
                    color: _getWeatherGradient().colors.first,
                    size: 26,
                  )
                : const IconThemeData(color: Colors.grey, size: 22),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              label: 'Current',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_day_outlined),
              label: 'Forecast',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: _getWeatherGradient(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingLocation || _loadingWeather) ...[
                const CircularProgressIndicator(),
                Builder(builder: (context) {
                  if (_loadingWeather || _loadingLocation) {
                    _rotationController.repeat();
                  } else {
                    _rotationController.stop();
                  }
                  return const SizedBox.shrink();
                }),
              ],
              if (!_loadingLocation &&
                  !_loadingWeather &&
                  _weatherError != null)
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
                  _weather != null) ...[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        _weather!.city,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weather!.dateText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _capitalize(_weather!.description),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_weather!.tempC.toStringAsFixed(1)} °C',
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
                scale: (_loadingLocation || _loadingWeather || _loadingForecast)
                    ? 0.95
                    : 1.0,
                duration: const Duration(milliseconds: 150),
                child: FilledButton.icon(
                  onPressed: _loadingLocation ||
                          _loadingWeather ||
                          _loadingForecast
                      ? null
                      : _refreshAll,
                  icon: AnimatedRotation(
                    turns: (_loadingLocation ||
                            _loadingWeather ||
                            _loadingForecast)
                        ? 1.0
                        : 0.0,
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

  Widget _buildForecastPage() {
    Widget content;

    if (_loadingLocation || _loadingForecast) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_forecastError != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _forecastError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (_forecast.isEmpty) {
      content = const Center(child: Text('No forecast data yet.'));
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _forecast.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final f = _forecast[i];
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

  Widget _buildAboutPage() {
    return Container(
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
                          color: _getWeatherGradient()
                              .colors
                              .first
                              .withAlpha((0.8 * 255).round()),
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
                          'Weather App.\nBy Rahmat Darwish.\nData: OpenWeatherMap.',
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
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
