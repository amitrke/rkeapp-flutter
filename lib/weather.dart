import 'package:rkeapp/models.dart';
import 'package:rkeapp/posts.dart';
import 'package:rkeapp/theme.dart';
import 'package:rkeapp/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherDetailsWidget extends StatelessWidget {
  const WeatherDetailsWidget({super.key});

  // OpenWeatherMap times are UTC seconds; shift by the city's offset.
  DateTime _local(int unixSeconds, int offsetSeconds) {
    return DateTime.fromMillisecondsSinceEpoch(
      (unixSeconds + offsetSeconds) * 1000,
      isUtc: true,
    );
  }

  String _dayLabel(int index, int unixSeconds, int offsetSeconds) {
    if (index == 0) return 'Today';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[_local(unixSeconds, offsetSeconds).weekday - 1];
  }

  static String _compass(int deg) {
    const points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return points[((deg % 360) / 45).round() % 8];
  }

  static String _uvLabel(double uvi) {
    if (uvi < 3) return 'Low';
    if (uvi < 6) return 'Moderate';
    if (uvi < 8) return 'High';
    if (uvi < 11) return 'Very high';
    return 'Extreme';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Consumer<AppData>(
      builder: (context, appData, _) {
        if (appData.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (appData.error) {
          return ErrorState(
            message: 'Couldn\'t load the weather. Check your connection.',
            onRetry: appDataService.reload,
          );
        }
        final details = appData.weatherDetails;
        if (details == null) {
          return ErrorState(
            message: 'Weather for Roorkee isn\'t available right now.',
            onRetry: appDataService.reload,
          );
        }

        final current = details.current;
        final offset = details.timezoneOffset;
        final today = details.daily.isNotEmpty ? details.daily.first : null;

        return RefreshIndicator(
          onRefresh: appDataService.reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.xl),
            children: [
              // Hero
              Container(
                padding: const EdgeInsets.all(Space.l),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.l),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${current.temp.round()}°',
                            style: text.displayLarge?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                        Icon(
                          weatherIcon(current.summary.icon),
                          size: 56,
                          color: scheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      capitalize(current.summary.description),
                      style: text.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        'Feels like ${current.feelsLike.round()}°',
                        if (today != null) 'High ${today.maxTemp.round()}°',
                        if (today != null) 'Low ${today.minTemp.round()}°',
                      ].join(' · '),
                      style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),

              // Metrics grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Space.s,
                crossAxisSpacing: Space.s,
                childAspectRatio: 2.4,
                children: [
                  _Metric(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '${current.humidity}%',
                  ),
                  _Metric(
                    icon: Icons.air,
                    label: 'Wind',
                    value: '${(current.windSpeed * 3.6).round()} km/h ${_compass(current.windDeg)}',
                  ),
                  _Metric(
                    icon: Icons.light_mode_outlined,
                    label: 'UV index',
                    value: '${current.uvi.round()} ${_uvLabel(current.uvi)}',
                  ),
                  _Metric(
                    icon: Icons.wb_twilight,
                    label: 'Sunset',
                    value: current.sunset > 0
                        ? clockLabel(_local(current.sunset, offset), minutes: true)
                        : '—',
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),

              // Hourly
              const SectionHeader('Next 12 hours'),
              const SizedBox(height: Space.s),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: details.hourly.length,
                  separatorBuilder: (_, __) => const SizedBox(width: Space.xs),
                  itemBuilder: (_, i) {
                    final h = details.hourly[i];
                    final isNow = i == 0;
                    return Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: Space.s),
                      decoration: BoxDecoration(
                        color: isNow ? scheme.surfaceContainerHigh : null,
                        borderRadius: BorderRadius.circular(Radii.m),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isNow ? 'Now' : clockLabel(_local(h.dt, offset)),
                            style: text.bodySmall?.copyWith(
                              color: isNow ? scheme.onSurface : scheme.onSurfaceVariant,
                              fontWeight: isNow ? FontWeight.w700 : null,
                            ),
                          ),
                          Icon(weatherIcon(h.summary.icon), size: 22),
                          Text(
                            '${h.temp.round()}°',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: Space.xl),

              // Daily
              const SectionHeader('7-day forecast'),
              const SizedBox(height: Space.xs),
              for (var i = 0; i < details.daily.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: Space.m),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          _dayLabel(i, details.daily[i].dt, offset),
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(weatherIcon(details.daily[i].summary.icon), size: 22),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Text(
                          details.daily[i].summary.main,
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        '${details.daily[i].maxTemp.round()}°',
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${details.daily[i].minTemp.round()}°',
                          textAlign: TextAlign.right,
                          style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: Space.xs),
              Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
