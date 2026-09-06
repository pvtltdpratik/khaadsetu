import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/weather_day.dart';
import '../../domain/entities/weather_forecast.dart';

/// Real weather for the device's current location — Open-Meteo
/// (open-meteo.com) for the forecast and BigDataCloud's reverse-geocode
/// endpoint for a human-readable place name. Both are free and need no API
/// key, which is the right tradeoff for this app's scale.
class WeatherApiDataSource {
  WeatherApiDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherForecast> fetchForecast() async {
    final position = await _currentPosition();
    final location = await _placeNameFor(position);
    final days = await _forecastFor(position);
    return WeatherForecast(location: location, days: days);
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw WeatherApiException(
        'Location services are turned off. Enable them in your device settings to see your local forecast.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw WeatherApiException(
        "Location permission was denied, so the forecast can't be shown for where you are.",
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw WeatherApiException(
        "Couldn't get your location in time. Make sure location is enabled and try again.",
      );
    }
  }

  Future<String> _placeNameFor(Position position) async {
    try {
      final uri = Uri.https('api.bigdatacloud.net', '/data/reverse-geocode-client', {
        'latitude': '${position.latitude}',
        'longitude': '${position.longitude}',
        'localityLanguage': 'en',
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _coordinatesLabel(position);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final city = (json['city'] as String?)?.trim();
      final region = (json['principalSubdivision'] as String?)?.trim();
      if (city == null || city.isEmpty) return _coordinatesLabel(position);
      return (region == null || region.isEmpty) ? city : '$city, $region';
    } catch (_) {
      // A missing place name shouldn't sink the whole forecast — fall back
      // to coordinates and keep going.
      return _coordinatesLabel(position);
    }
  }

  String _coordinatesLabel(Position position) =>
      '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';

  Future<List<WeatherDay>> _forecastFor(Position position) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${position.latitude}',
      'longitude': '${position.longitude}',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '5',
    });
    final response = await _guardConnection(() => _client.get(uri).timeout(const Duration(seconds: 15)));
    if (response.statusCode != 200) {
      throw WeatherApiException('The weather service returned an error (${response.statusCode}).');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final codes = (daily['weather_code'] as List).cast<num>();
    final highs = (daily['temperature_2m_max'] as List).cast<num>();
    final lows = (daily['temperature_2m_min'] as List).cast<num>();
    final rainChances = (daily['precipitation_probability_max'] as List).cast<num>();

    return List.generate(
      dates.length,
      (i) => WeatherDay(
        date: DateTime.parse(dates[i]),
        condition: _conditionFor(codes[i].toInt()),
        tempHighC: highs[i].toDouble(),
        tempLowC: lows[i].toDouble(),
        rainChancePercent: rainChances[i].toInt(),
      ),
    );
  }

  /// Wraps low-level network failures into a message worth showing a
  /// non-technical user, matching the pattern already used for the soil-scan
  /// backend calls.
  Future<http.Response> _guardConnection(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw WeatherApiException("Couldn't reach the weather service. Check your internet connection and try again.");
    } on TimeoutException {
      throw WeatherApiException('The weather service took too long to respond. Please try again.');
    }
  }

  /// Maps Open-Meteo's WMO weather codes down to this app's condition set.
  /// https://open-meteo.com/en/docs#weathervariables
  WeatherCondition _conditionFor(int code) {
    if (code == 0 || code == 1) return WeatherCondition.sunny;
    if (code == 2) return WeatherCondition.partlyCloudy;
    if (code == 3 || code == 45 || code == 48) return WeatherCondition.cloudy;
    if (code >= 95) return WeatherCondition.stormy;
    return WeatherCondition.rainy;
  }
}

/// Thrown for any location or network failure so the presentation layer can
/// show a real, specific message instead of a generic error.
class WeatherApiException implements Exception {
  WeatherApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
