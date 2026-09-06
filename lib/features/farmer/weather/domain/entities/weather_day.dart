import 'package:equatable/equatable.dart';

enum WeatherCondition { sunny, partlyCloudy, cloudy, rainy, stormy }

/// One day's forecast entry. Kept free of any Flutter/UI import — the
/// presentation layer maps [condition] to an icon and color.
class WeatherDay extends Equatable {
  const WeatherDay({
    required this.date,
    required this.condition,
    required this.tempHighC,
    required this.tempLowC,
    required this.rainChancePercent,
  });

  final DateTime date;
  final WeatherCondition condition;
  final double tempHighC;
  final double tempLowC;
  final int rainChancePercent;

  @override
  List<Object?> get props =>
      [date, condition, tempHighC, tempLowC, rainChancePercent];
}
