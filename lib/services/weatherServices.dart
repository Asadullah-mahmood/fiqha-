import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quranpak/models/WeatherDetailData.dart';
import 'package:quranpak/models/weatherData.dart';

class WeatherService {
  // A map to convert WMO codes to descriptions
  static const Map<int, String> _wmoDescriptions = {
    0: "Clear Sky",
    1: "Mainly Clear",
    2: "Partly Cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing Rime Fog",
    51: "Light Drizzle",
    53: "Moderate Drizzle",
    55: "Dense Drizzle",
    61: "Slight Rain",
    63: "Moderate Rain",
    65: "Heavy Rain",
    71: "Slight Snow",
    73: "Moderate Snow",
    75: "Heavy Snow",
    80: "Slight Rain Showers",
    81: "Moderate Rain Showers",
    82: "Violent Rain Showers",
    95: "Thunderstorm",
    96: "Thunderstorm with Slight Hail",
    99: "Thunderstorm with Heavy Hail",
  };

  Future<WeatherData?> getCurrentWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        final double temp = current['temperature_2m'].toDouble();
        final int code = current['weather_code'].toInt();

        // Get description from the map, or fallback to "Unknown"
        final String condition = _wmoDescriptions[code] ?? "Unknown";

        return WeatherData(
          temperature: temp,
          condition: condition,
          icon: _getIconName(code), // Helper to get an icon name
        );
      } else {
        debugPrint(
          "Weather API returned ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      print("Failed to fetch weather: $e");
    }
    return null;
  }

  // Helper to map codes to icon names (you can use this with weather_icons_animated or similar)
  String _getIconName(int code) {
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


class WeatherApiService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherDetailData?> getDetailedWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'current=temperature_2m,relative_humidity_2m,apparent_temperature,'
        'precipitation,weather_code,wind_speed_10m,wind_direction_10m,'
        'pressure_msl,uv_index&'
        'daily=temperature_2m_max,temperature_2m_min,precipitation_sum,'
        'weather_code,wind_speed_10m_max,uv_index_max,sunrise,sunset&'
        'hourly=temperature_2m,precipitation_probability,weather_code&'
        'forecast_days=16&'
        'timezone=auto&'
        'wind_speed_unit=kmh',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check for API error
        if (data['error'] == true) {
          print('Open-Meteo error: ${data['reason']}');
          return null;
        }
        return WeatherDetailData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Weather API error: $e');
      return null;
    }
  }
}
