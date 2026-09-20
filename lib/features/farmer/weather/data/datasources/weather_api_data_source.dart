import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../../core/network/api_client.dart';
import '../../domain/entities/weather_day.dart';
import '../../domain/entities/weather_forecast.dart';

/// The app still reads the device's GPS position; the forecast and the place
/// name come from the KHAAD Setu server (`GET /v1/weather`), which caches
/// them and hides the third-party weather providers from the client.
class WeatherApiDataSource {
  const WeatherApiDataSource(this._api);

  final ApiClient _api;

  Future<WeatherForecast> fetchForecast() async {
    final position = await _currentPosition();
    final json = await _api.get('/v1/weather', query: {
      'lat': '${position.latitude}',
      'lon': '${position.longitude}',
    }) as Map<String, dynamic>;

    return WeatherForecast(
      location: json['location'] as String,
      days: (json['days'] as List).map((e) => _parseDay(e as Map<String, dynamic>)).toList(),
    );
  }

  WeatherDay _parseDay(Map<String, dynamic> json) {
    return WeatherDay(
      date: DateTime.parse(json['date'] as String),
      condition: WeatherCondition.values.byName(json['condition'] as String),
      tempHighC: (json['tempHighC'] as num).toDouble(),
      tempLowC: (json['tempLowC'] as num).toDouble(),
      rainChancePercent: (json['rainChancePercent'] as num).round(),
    );
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiException(
        'Location services are turned off. Enable them in your device settings to see your local forecast.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw ApiException(
        "Location permission was denied, so the forecast can't be shown for where you are.",
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException("Couldn't get your location in time. Make sure location is enabled and try again.");
    }
  }
}
