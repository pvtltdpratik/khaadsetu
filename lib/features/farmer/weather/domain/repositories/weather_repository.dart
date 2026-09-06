import '../entities/weather_forecast.dart';

abstract class WeatherRepository {
  Future<WeatherForecast> getForecast();
}
