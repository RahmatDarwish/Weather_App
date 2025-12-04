# Weather App

A dynamic Flutter application that provides real-time weather updates and forecasts based on the user's current location.

The app features a polished Material 3 UI, smooth animations, and dynamic background themes that change according to current weather conditions.

##  Features

* **Geolocation Integration:** Automatically detects the user's GPS position to fetch relevant local weather data.
* **Real-time Weather:** Displays current temperature, city name, date, and detailed weather descriptions.
* **Detailed Forecast:** Provides a 5-day / 3-hour interval forecast list with specific time slots, temperatures, and icons.
* **Dynamic UI:**
    * **Adaptive Gradients:** Background colors shift based on the weather (Sunny, Rainy, Cloudy, Snowy, Stormy, etc.).
    * **Animations:** Smooth fade-ins, sliding page transitions, and rotating elements for a modern user experience.
* **Robust Error Handling:** Manages location permission denials, network timeouts, and API errors gracefully.
* **Material 3 Design:** Utilizes the latest Flutter theming standards.

## Screenshots

| Current Weather | Forecast View | About Page | Current Weather (sunny) |
|:---:|:---:|:---:|:---:|
| <img src="img/cloudy-current-page.png" width="200"> | <img src="img/cloudy-forecast.png" width="200"> | <img src="img/about.png" width="200"> | <img src="img/sunny-current-page.png" width="200"> |

* **Vidoe Demonstration** [Video.webm](https://github.com/user-attachments/assets/90fbe5dd-acb3-4e29-8ec3-aecc455b644f)


## Tech Stack & Dependencies
* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **API:** [OpenWeatherMap](https://openweathermap.org/)
* **Packages used:**
    * [`http`](https://pub.dev/packages/http) - For handling API requests.
    * [`geolocator`](https://pub.dev/packages/geolocator) - For accessing device GPS location.
    * [`intl`](https://pub.dev/packages/intl) - For date and time formatting.

## Getting Started
Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
* An Android Emulator or physical device.
* An API Key from OpenWeatherMap.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [git@github.com:RahmatDarwish/Weather_App.git]
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure the API Key:**
    * Sign up at [OpenWeatherMap](https://openweathermap.org/api) to get a free API key.
    * Open `lib/features/weather/models/weather_models.dart`.
    * Locate the constant at the top of the file:
        ```dart
        const String kOwmKey = "YOUR_OPENWEATHERMAP_API_KEY_HERE";
        ```
    * Replace the placeholder text with your actual API key.

4.  **Run the App:**
    ```bash
    flutter run
    ```

## Project Structure
The project follows a feature-based architecture for scalability and maintainability:

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Root app widget configuration
├── constants/
│   └── api_keys.dart         # API configuration and keys
└── features/
    └── weather/
        ├── models/
        │   └── weather_models.dart     # Data models for weather data
        ├── services/
        │   ├── weather_service.dart    # OpenWeatherMap API integration
        │   └── location_service.dart   # Geolocation service
        └── presentation/
            └── screens/
                ├── home_screen.dart       # Navigation and BottomNavigationBar
                ├── current_screen.dart    # Current weather display
                ├── forecast_screen.dart   # 5-day forecast view
                └── about_screen.dart      # About page
```

**Key Components:**
* **WeatherApp (app.dart):** The root widget setting up the Material 3 theme and app configuration.
* **HomeScreen:** Manages `BottomNavigationBar` navigation between screens.
* **CurrentScreen:** Displays current weather with adaptive gradients and animations.
* **ForecastScreen:** Shows 5-day/3-hour interval forecast data.
* **AboutScreen:** Application information page.
* **WeatherService:** Handles OpenWeatherMap API calls and data parsing.
* **LocationService:** Manages device geolocation and permission handling.
* **WeatherModels:** Data models for API responses and local state management.

## Permissions

**Android:**
Ensure your `android/app/src/main/AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
