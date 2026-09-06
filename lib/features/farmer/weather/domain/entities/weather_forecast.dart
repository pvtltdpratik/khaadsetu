import 'package:equatable/equatable.dart';

import 'weather_day.dart';

class WeatherForecast extends Equatable {
  const WeatherForecast({required this.location, required this.days});

  final String location;

  /// Today first, followed by the upcoming days.
  final List<WeatherDay> days;

  WeatherDay get today => days.first;

  @override
  List<Object?> get props => [location, days];
}
