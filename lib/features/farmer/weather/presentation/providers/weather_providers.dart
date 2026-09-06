import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/weather_fake_data_source.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_forecast.dart';
import '../../domain/repositories/weather_repository.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(WeatherFakeDataSource());
});

final weatherForecastProvider =
    FutureProvider.autoDispose<WeatherForecast>((ref) {
  return ref.watch(weatherRepositoryProvider).getForecast();
});
