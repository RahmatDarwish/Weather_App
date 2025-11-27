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
    * Open `lib/main.dart`.
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
he project currently resides primarily in `main.dart` for simplicity, structured as follows:

* **WeatherApp:** The root widget setting up the Material App theme.
* **HomeScreen:** Handles the `BottomNavigationBar` navigation logic.
* **_fetchCurrent:** Async function to call the Current Weather API endpoint.
* **_fetchForecast:** Async function to call the 5-day Forecast API endpoint.
* **_getWeatherGradient:** Logic to determine UI colors based on API description strings.

## Permissions

**Android:**
Ensure your `android/app/src/main/AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
