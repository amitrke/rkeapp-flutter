import 'package:rkeapp/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherDetailsWidget extends StatelessWidget {
  const WeatherDetailsWidget({super.key});

  DateTime _withOffset(int unixSeconds, int offsetSeconds) {
    return DateTime.fromMillisecondsSinceEpoch(
      (unixSeconds + offsetSeconds) * 1000,
      isUtc: true,
    );
  }

  String _hourLabel(int unixSeconds, int offsetSeconds) {
    final dt = _withOffset(unixSeconds, offsetSeconds);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dayLabel(int unixSeconds, int offsetSeconds) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dt = _withOffset(unixSeconds, offsetSeconds);
    return names[dt.weekday - 1];
  }

  Widget _icon(String icon, {double size = 56}) {
    if (icon.isEmpty) {
      return Icon(Icons.wb_sunny, size: size, color: Colors.orange);
    }
    return Image.network(
      'https://openweathermap.org/img/wn/$icon@2x.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.wb_sunny, size: size, color: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, appData, _) {
        if (appData.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final details = appData.weatherDetails;
        if (details == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Weather details are not available right now.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final current = details.current;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Roorkee Weather',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.timezone,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${current.temp.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                current.summary.description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _icon(current.summary.icon, size: 72),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text('Humidity ${current.humidity}% ',
                            style: const TextStyle(color: Colors.white70)),
                        Text('Wind ${current.windSpeed.toStringAsFixed(1)} m/s',
                            style: const TextStyle(color: Colors.white70)),
                        Text('Pressure ${current.pressure} hPa',
                            style: const TextStyle(color: Colors.white70)),
                        Text('UV ${current.uvi.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hourly Forecast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: details.hourly.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final h = details.hourly[i];
                    return Container(
                      width: 94,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _hourLabel(h.dt, details.timezoneOffset),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _icon(h.summary.icon, size: 40),
                          const SizedBox(height: 4),
                          Text(
                            '${h.temp.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '7-Day Forecast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...details.daily.map((d) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            _dayLabel(d.dt, details.timezoneOffset),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _icon(d.summary.icon, size: 38),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            d.summary.main,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        Text(
                          '${d.minTemp.toStringAsFixed(0)}° / ${d.maxTemp.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
