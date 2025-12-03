import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/constants/api_keys.dart';
import 'package:weather_app/features/weather/models/weather_models.dart';
import 'package:weather_app/features/weather/services/location_service.dart';
import 'package:weather_app/features/weather/services/weather_service.dart';
import 'about_screen.dart';
import 'current_screen.dart';
import 'forecast_screen.dart';

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
      CurrentScreen(
        weather: _weather,
        isLoading: _loadingLocation || _loadingWeather,
        locationStatus: _locationStatus,
        error: _weatherError,
        onRefresh: _refreshAll,
        fadeAnimation: _fadeAnimation,
        rotationAnimation: _rotationAnimation,
        weatherGradient: _getWeatherGradient(),
        isRefreshing: _loadingLocation || _loadingWeather || _loadingForecast,
      ),
      ForecastScreen(
        forecast: _forecast,
        isLoading: _loadingLocation || _loadingForecast,
        error: _forecastError,
      ),
      AboutScreen(
        weatherGradient: _getWeatherGradient(),
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

}