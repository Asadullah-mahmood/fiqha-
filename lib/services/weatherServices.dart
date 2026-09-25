import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    if (code == 0) return "sunny";
    if (code <= 3) return "partly_cloudy";
    if (code >= 51 && code <= 67) return "rainy";
    if (code >= 71 && code <= 77) return "snowy";
    if (code >= 95) return "thunderstorm";
    return "cloudy";
  }
}
