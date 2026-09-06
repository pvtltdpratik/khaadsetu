import 'package:flutter/material.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/weather_day.dart';
import '../../domain/entities/weather_forecast.dart';

/// Horizontally scrolling row of day cards. A "strip" reads the same way at
/// every breakpoint — cards just get a little roomier on larger screens —
/// since forecasts are naturally a scannable horizontal sequence.
class WeatherStrip extends StatelessWidget {
  const WeatherStrip({super.key, required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardWidth = context.responsive(mobile: 92.0, tablet: 104.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: colors.textMuted),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    forecast.location,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colors.textMuted),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.days.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, i) {
                  final day = forecast.days[i];
                  return SizedBox(
                    width: cardWidth,
                    child: _DayTile(day: day, isToday: i == 0),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.isToday});

  final WeatherDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isToday ? 'Today' : _weekdayLabel(day.date),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Icon(_iconFor(day.condition), color: _colorFor(day.condition, colors), size: 26),
          Text(
            '${day.tempHighC.round()}° / ${day.tempLowC.round()}°',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_outlined, size: 12, color: colors.info),
              const SizedBox(width: 2),
              Text(
                '${day.rainChancePercent}%',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String _weekdayLabel(DateTime date) => _weekdays[date.weekday - 1];

  IconData _iconFor(WeatherCondition c) => switch (c) {
        WeatherCondition.sunny => Icons.wb_sunny_rounded,
        WeatherCondition.partlyCloudy => Icons.wb_cloudy_outlined,
        WeatherCondition.cloudy => Icons.cloud_rounded,
        WeatherCondition.rainy => Icons.water_drop_rounded,
        WeatherCondition.stormy => Icons.thunderstorm_rounded,
      };

  Color _colorFor(WeatherCondition c, AppColorTokens colors) => switch (c) {
        WeatherCondition.sunny => colors.warning,
        WeatherCondition.partlyCloudy || WeatherCondition.cloudy => colors.textMuted,
        WeatherCondition.rainy || WeatherCondition.stormy => colors.info,
      };
}
