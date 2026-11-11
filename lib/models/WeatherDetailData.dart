class WeatherDetailData {
  final double currentTemp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final double uvIndex;
  final double precipitation;
  final String condition;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;
  final List<DailyForecast> dailyForecasts;
  final List<HourlyForecast> hourlyForecasts;

  WeatherDetailData({
    required this.currentTemp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.uvIndex,
    required this.precipitation,
    required this.condition,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
    required this.dailyForecasts,
    required this.hourlyForecasts,
  });

  // ── Safe parsers (handle null + missing fields) ──
  static double _d(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return fallback;
  }

  static int _i(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return fallback;
  }

  static double? _dAt(List? list, int index, [double fallback = 0]) {
    if (list == null || index >= list.length) return fallback;
    return _d(list[index], fallback);
  }

  static int? _iAt(List? list, int index, [int fallback = 0]) {
    if (list == null || index >= list.length) return fallback;
    return _i(list[index], fallback);
  }

  factory WeatherDetailData.fromJson(Map<String, dynamic> json) {
    final current = (json['current'] ?? {}) as Map<String, dynamic>;
    final daily = (json['daily'] ?? {}) as Map<String, dynamic>;
    final hourly = (json['hourly'] ?? {}) as Map<String, dynamic>;

    // ── Daily forecasts ──
    final dailyList = <DailyForecast>[];
    final dailyTimes = (daily['time'] as List?) ?? const [];
    final maxTemps = daily['temperature_2m_max'] as List?;
    final minTemps = daily['temperature_2m_min'] as List?;
    final precipSums = daily['precipitation_sum'] as List?;
    final weatherCodes = daily['weather_code'] as List?;
    final windMax = daily['wind_speed_10m_max'] as List?;
    final uvMax = daily['uv_index_max'] as List?;

    for (int i = 0; i < dailyTimes.length; i++) {
      dailyList.add(
        DailyForecast(
          date: DateTime.parse(dailyTimes[i] as String),
          maxTemp: _d(maxTemps?[i] ?? 0),
          minTemp: _d(minTemps?[i] ?? 0),
          precipitationSum: _d(precipSums?[i] ?? 0),
          weatherCode: _i(weatherCodes?[i] ?? 0),
          windSpeedMax: _d(windMax?[i] ?? 0),
          uvIndexMax: _d(uvMax?[i] ?? 0),
        ),
      );
    }

    // ── Hourly forecasts (next 24 hours) ──
    final hourlyList = <HourlyForecast>[];
    final hourlyTimes = (hourly['time'] as List?) ?? const [];
    final hourlyTemps = hourly['temperature_2m'] as List?;
    final hourlyPrecip = hourly['precipitation_probability'] as List?;
    final hourlyCodes = hourly['weather_code'] as List?;

    final now = DateTime.now();
    for (int i = 0; i < hourlyTimes.length; i++) {
      final time = DateTime.parse(hourlyTimes[i] as String);
      if (time.isAfter(now) && hourlyList.length < 24) {
        hourlyList.add(
          HourlyForecast(
            time: time,
            temperature: _d(hourlyTemps?[i] ?? 0),
            precipitationProbability: _i(hourlyPrecip?[i] ?? 0),
            weatherCode: _i(hourlyCodes?[i] ?? 0),
          ),
        );
      }
    }

    // ── Sunrise / Sunset (may be null on some days) ──
    final sunriseList = daily['sunrise'] as List?;
    final sunsetList = daily['sunset'] as List?;
    final sunrise = (sunriseList != null && sunriseList.isNotEmpty)
        ? DateTime.parse(sunriseList[0] as String)
        : DateTime.now();
    final sunset = (sunsetList != null && sunsetList.isNotEmpty)
        ? DateTime.parse(sunsetList[0] as String)
        : DateTime.now();

    return WeatherDetailData(
      currentTemp: _d(current['temperature_2m']),
      feelsLike: _d(current['apparent_temperature']),
      humidity: _i(current['relative_humidity_2m']),
      windSpeed: _d(current['wind_speed_10m']),
      windDirection: _i(current['wind_direction_10m']),
      pressure: _d(current['pressure_msl'], 1013),
      uvIndex: _d(current['uv_index']), // ← often null at night
      precipitation: _d(current['precipitation']), // ← often null
      condition: _conditionFromCode(_i(current['weather_code'])),
      weatherCode: _i(current['weather_code']),
      sunrise: sunrise,
      sunset: sunset,
      dailyForecasts: dailyList,
      hourlyForecasts: hourlyList,
    );
  }

  static String _conditionFromCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain Showers';
    if (code <= 86) return 'Snow Showers';
    return 'Thunderstorm';
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double precipitationSum;
  final int weatherCode;
  final double windSpeedMax;
  final double uvIndexMax;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationSum,
    required this.weatherCode,
    required this.windSpeedMax,
    required this.uvIndexMax,
  });
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });
}
