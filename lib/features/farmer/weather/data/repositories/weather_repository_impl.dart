import '../../domain/entities/weather_forecast.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_api_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  const WeatherRepositoryImpl(this._dataSource);

  final WeatherApiDataSource _dataSource;

  @override
  Future<WeatherForecast> getForecast() {
    return _dataSource.fetchForecast();
  }
}
