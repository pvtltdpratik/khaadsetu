import '../../domain/entities/weather_day.dart';
import '../../domain/entities/weather_forecast.dart';

/// Stands in for a remote weather API (e.g. IMD/OpenWeather). Returns a
/// fixed 5-day forecast after a short simulated delay.
class WeatherFakeDataSource {
  Future<WeatherForecast> fetchForecast() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final today = DateTime.now();
    const conditions = [
      WeatherCondition.partlyCloudy,
      WeatherCondition.sunny,
      WeatherCondition.rainy,
      WeatherCondition.rainy,
      WeatherCondition.cloudy,
    ];
    const highs = [31.0, 33.0, 27.0, 26.0, 29.0];
    const lows = [23.0, 24.0, 22.0, 21.0, 22.0];
    const rainChances = [20, 5, 70, 80, 40];

    return WeatherForecast(
      location: 'Shirur, Pune',
      days: List.generate(
        5,
        (i) => WeatherDay(
          date: today.add(Duration(days: i)),
          condition: conditions[i],
          tempHighC: highs[i],
          tempLowC: lows[i],
          rainChancePercent: rainChances[i],
        ),
      ),
    );
  }
}
