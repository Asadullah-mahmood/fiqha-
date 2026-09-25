class WeatherData {
  final double temperature;
  final String condition;
  final String icon; // Optional: for an icon name or code

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}
