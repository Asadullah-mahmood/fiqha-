import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranpak/models/WeatherDetailData.dart';
import 'package:quranpak/services/weatherServices.dart' show WeatherApiService;
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/widgets/AnimatedWeatherBackground.dart';

class WeatherDetailScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const WeatherDetailScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  WeatherDetailData? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await WeatherApiService().getDetailedWeather(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    if (!mounted) return;
    setState(() {
      _weather = data;
      _loading = false;
    });
  }

  bool get _isNight {
    if (_weather == null) return false;
    final now = DateTime.now();
    return now.isBefore(_weather!.sunrise) || now.isAfter(_weather!.sunset);
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code <= 48) return Icons.foggy;
    if (code <= 57) return Icons.grain;
    if (code <= 67) return Icons.water_drop;
    if (code <= 77) return Icons.ac_unit;
    if (code <= 82) return Icons.thunderstorm;
    return Icons.flash_on;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.gold),
              const SizedBox(height: 16),
              Text(
                'Loading weather...',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_weather == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'Could not load weather data',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadWeather();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppTheme.gold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final w = _weather!;

    return Scaffold(
      body: AnimatedWeatherBackground(
        weatherCode: w.weatherCode,
        isNight: _isNight,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.locationName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),

              // ── Hero Temperature ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        _getWeatherIcon(w.weatherCode),
                        size: 72,
                        color: Colors.white,
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 16),
                      Text(
                            '${w.currentTemp.round()}°',
                            style: GoogleFonts.inter(
                              fontSize: 96,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                              height: 1,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 800.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 8),
                      Text(
                        w.condition,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Feels like ${w.feelsLike.round()}°  ·  '
                        'H:${w.dailyForecasts[0].maxTemp.round()}°  '
                        'L:${w.dailyForecasts[0].minTemp.round()}°',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: _buildHourlyForecast(w)),
              SliverToBoxAdapter(child: _buildDailyForecast(w)),
              SliverToBoxAdapter(child: _buildDetailsGrid(w)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Glass card decoration
  // ═══════════════════════════════════════════════════════════════
  BoxDecoration get _glassCard => BoxDecoration(
    color: Colors.white.withOpacity(0.14),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.18)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  //  Hourly Forecast
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHourlyForecast(WeatherDetailData w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'HOURLY FORECAST',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
                textScaler: TextScaler.linear(1),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: w.hourlyForecasts.length,
            itemBuilder: (context, index) {
              final h = w.hourlyForecasts[index];
              final isNow = index == 0;
              return Container(
                    width: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isNow
                          ? AppTheme.gold.withOpacity(0.22)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNow
                            ? AppTheme.gold
                            : Colors.white.withOpacity(0.10),
                        width: isNow ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          isNow ? 'Now' : '${h.time.hour}:00',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isNow ? AppTheme.goldLight : Colors.white70,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                        Icon(
                          _getWeatherIcon(h.weatherCode),
                          size: 22,
                          color: Colors.white,
                        ),
                        Text(
                          '${h.temperature.round()}°',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                        if (h.precipitationProbability > 0)
                          Text(
                            '${h.precipitationProbability}%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.lightBlueAccent,
                            ),
                            textScaler: TextScaler.linear(1),
                          )
                        else
                          const SizedBox(height: 12),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (index * 50).ms)
                  .slideX(begin: 0.3, end: 0, duration: 400.ms);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  15-Day Forecast
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDailyForecast(WeatherDetailData w) {
    // Find global min/max for the range bars so they scale visually
    final globalMin = w.dailyForecasts
        .map((d) => d.minTemp)
        .reduce((a, b) => a < b ? a : b);
    final globalMax = w.dailyForecasts
        .map((d) => d.maxTemp)
        .reduce((a, b) => a > b ? a : b);
    final range = (globalMax - globalMin).clamp(1.0, double.infinity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: _glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                '15-DAY FORECAST',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
                textScaler: TextScaler.linear(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...w.dailyForecasts.asMap().entries.map((entry) {
            final index = entry.key;
            final d = entry.value;
            final dayName = _dayName(d.date);
            final isToday = index == 0;

            // Range bar positions (0..1 within global range)
            final leftFrac = (d.minTemp - globalMin) / range;
            final rightFrac = (d.maxTemp - globalMin) / range;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: index < w.dailyForecasts.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    child: Text(
                      dayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? AppTheme.goldLight : Colors.white,
                      ),
                      textScaler: TextScaler.linear(1),
                    ),
                  ),
                  Icon(
                    _getWeatherIcon(d.weatherCode),
                    size: 20,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${d.minTemp.round()}°',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Range bar with temperature-position gradient
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              // Track
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Fill between min & max
                              Positioned(
                                left: leftFrac * width,
                                width: (rightFrac - leftFrac) * width,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF64B5F6),
                                        Color(0xFFFFB74D),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${d.maxTemp.round()}°',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (d.precipitationSum > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${d.precipitationSum.toStringAsFixed(1)}mm',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: (index * 35).ms);
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Details Grid
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDetailsGrid(WeatherDetailData w) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
                textScaler: TextScaler.linear(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildDetailCard(
                'Wind',
                '${w.windSpeed.round()} km/h',
                _windDirection(w.windDirection),
                Icons.air,
                index: 0,
              ),
              _buildDetailCard(
                'Humidity',
                '${w.humidity}%',
                'Dew point '
                    '${(w.currentTemp - (100 - w.humidity) / 5).round()}°',
                Icons.water_drop_outlined,
                index: 1,
              ),
              _buildDetailCard(
                'UV Index',
                w.uvIndex.round().toString(),
                _uvLabel(w.uvIndex),
                Icons.wb_sunny_outlined,
                index: 2,
              ),
              _buildDetailCard(
                'Pressure',
                '${w.pressure.round()} hPa',
                'Sea level',
                Icons.speed,
                index: 3,
              ),
              _buildDetailCard(
                'Sunrise',
                '${w.sunrise.hour}:${w.sunrise.minute.toString().padLeft(2, '0')}',
                'AM',
                Icons.wb_twilight,
                index: 4,
              ),
              _buildDetailCard(
                'Sunset',
                '${w.sunset.hour}:${w.sunset.minute.toString().padLeft(2, '0')}',
                'PM',
                Icons.nights_stay_outlined,
                index: 5,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Weather data by Open-Meteo.com',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    String subtitle,
    IconData icon, {
    required int index,
  }) {
    return Container(
          padding: const EdgeInsets.all(14),
          decoration: _glassCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.goldLight),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                    textScaler: TextScaler.linear(1),
                  ),
                ],
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textScaler: TextScaler.linear(1),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                textScaler: TextScaler.linear(1),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 80).ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
        );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════════════
  String _dayName(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return 'Today';
    if (date.day == now.add(const Duration(days: 1)).day) return 'Tom';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _windDirection(int degrees) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((degrees + 22.5) / 45).floor() % 8];
  }

  String _uvLabel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }
}
