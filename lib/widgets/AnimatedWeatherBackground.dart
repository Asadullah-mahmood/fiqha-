import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quranpak/utils/AppTheme.dart';

/// A weather-aware animated background.
/// Pass a WMO weather code (Open-Meteo) and it will render the
/// appropriate gradient + animated particles (rain, snow, clouds, etc.)
class AnimatedWeatherBackground extends StatefulWidget {
  final int weatherCode;
  final bool isNight;
  final Widget child;

  const AnimatedWeatherBackground({
    super.key,
    required this.weatherCode,
    required this.child,
    this.isNight = false,
  });

  @override
  State<AnimatedWeatherBackground> createState() =>
      _AnimatedWeatherBackgroundState();
}

class _AnimatedWeatherBackgroundState extends State<AnimatedWeatherBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  // ── Weather category from WMO code ──
  _WeatherKind get _kind {
    final c = widget.weatherCode;
    if (c == 0) return _WeatherKind.clear;
    if (c <= 3) return _WeatherKind.cloudy;
    if (c == 45 || c == 48) return _WeatherKind.fog;
    if (c <= 57) return _WeatherKind.drizzle;
    if (c <= 67) return _WeatherKind.rain;
    if (c <= 77) return _WeatherKind.snow;
    if (c <= 82) return _WeatherKind.showers;
    if (c <= 86) return _WeatherKind.snowShowers;
    if (c <= 99) return _WeatherKind.thunderstorm;
    return _WeatherKind.cloudy;
  }

  LinearGradient get _gradient {
    if (widget.isNight) {
      return const LinearGradient(
        colors: [Color(0xFF0B1929), Color(0xFF1B2A41)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    switch (_kind) {
      case _WeatherKind.clear:
        return const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case _WeatherKind.cloudy:
        return const LinearGradient(
          colors: [Color(0xFF546E7A), Color(0xFF90A4AE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case _WeatherKind.fog:
        return const LinearGradient(
          colors: [Color(0xFF6D7B86), Color(0xFFB0BEC5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case _WeatherKind.drizzle:
      case _WeatherKind.rain:
      case _WeatherKind.showers:
        return const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF455A64)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case _WeatherKind.snow:
      case _WeatherKind.snowShowers:
        // Snow: soft icy blue → white
        return const LinearGradient(
          colors: [Color(0xFF5B7C99), Color(0xFFB3D0E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case _WeatherKind.thunderstorm:
        return const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF3A3A5C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      decoration: BoxDecoration(gradient: _gradient),
      child: Stack(
        children: [
          // ── Animated particles per weather kind ──
          Positioned.fill(
            child: _buildParticles(_kind),
          ),
          // ── Sun glow for clear sky ──
          if (_kind == _WeatherKind.clear && !widget.isNight)
            Positioned(
              top: -60,
              right: -60,
              child: _SunGlow(),
            ),
          // ── Moon for night ──
          if (widget.isNight && _kind == _WeatherKind.clear)
            Positioned(
              top: 40,
              right: 40,
              child: _Moon(),
            ),
          // ── Content ──
          widget.child,
        ],
      ),
    );
  }

  Widget _buildParticles(_WeatherKind kind) {
    switch (kind) {
      case _WeatherKind.rain:
      case _WeatherKind.showers:
        return _RainLayer(controller: _particleController, count: 80);
      case _WeatherKind.drizzle:
        return _RainLayer(controller: _particleController, count: 40, thin: true);
      case _WeatherKind.snow:
      case _WeatherKind.snowShowers:
        return _SnowLayer(controller: _particleController, count: 60);
      case _WeatherKind.cloudy:
      case _WeatherKind.fog:
        return _CloudLayer(controller: _particleController);
      case _WeatherKind.thunderstorm:
        return Stack(
          children: [
            _RainLayer(controller: _particleController, count: 100),
            _LightningFlash(controller: _particleController),
          ],
        );
      case _WeatherKind.clear:
        return const SizedBox.shrink();
    }
  }
}

enum _WeatherKind {
  clear,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  showers,
  snowShowers,
  thunderstorm,
}

// ═══════════════════════════════════════════════════════════════
//  RAIN
// ═══════════════════════════════════════════════════════════════
class _RainLayer extends StatelessWidget {
  final AnimationController controller;
  final int count;
  final bool thin;

  const _RainLayer({
    required this.controller,
    this.count = 60,
    this.thin = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RainPainter(
            progress: controller.value,
            count: count,
            thin: thin,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  final int count;
  final bool thin;

  _RainPainter({required this.progress, required this.count, required this.thin});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(thin ? 0.25 : 0.40)
      ..strokeWidth = thin ? 0.8 : 1.4
      ..strokeCap = StrokeCap.round;

    final rand = math.Random(42);
    for (int i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final speed = 0.6 + rand.nextDouble() * 0.6;
      final y = ((progress * speed + rand.nextDouble()) % 1.0) * size.height;
      final len = (thin ? 8.0 : 14.0) + rand.nextDouble() * (thin ? 6 : 10);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1.5, y + len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
//  SNOW  ❄
// ═══════════════════════════════════════════════════════════════
class _SnowLayer extends StatelessWidget {
  final AnimationController controller;
  final int count;

  const _SnowLayer({required this.controller, this.count = 50});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SnowPainter(progress: controller.value, count: count),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SnowPainter extends CustomPainter {
  final double progress;
  final int count;

  _SnowPainter({required this.progress, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(7);
    for (int i = 0; i < count; i++) {
      final baseX = rand.nextDouble() * size.width;
      final speed = 0.3 + rand.nextDouble() * 0.4;
      final drift = math.sin((progress * 6.28 * 2) + i) * 20;
      final y = ((progress * speed + rand.nextDouble()) % 1.0) * size.height;
      final r = 1.2 + rand.nextDouble() * 2.2;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.65 + rand.nextDouble() * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(baseX + drift, y), r, paint);

      // Draw a small 6-point star on the larger flakes
      if (r > 2.4) {
        final starPaint = Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round;
        final c = Offset(baseX + drift, y);
        for (int k = 0; k < 6; k++) {
          final angle = k * math.pi / 3;
          canvas.drawLine(
            c,
            c + Offset(math.cos(angle) * r * 1.6, math.sin(angle) * r * 1.6),
            starPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
//  CLOUDS / FOG
// ═══════════════════════════════════════════════════════════════
class _CloudLayer extends StatelessWidget {
  final AnimationController controller;

  const _CloudLayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            _CloudBlob(
              top: 80,
              size: 180,
              opacity: 0.18,
              offsetX: -1 + (controller.value * 2),
            ),
            _CloudBlob(
              top: 200,
              size: 260,
              opacity: 0.12,
              offsetX: 1 - (controller.value * 2),
            ),
            _CloudBlob(
              top: 380,
              size: 220,
              opacity: 0.10,
              offsetX: -1 + (controller.value * 2),
            ),
          ],
        );
      },
    );
  }
}

class _CloudBlob extends StatelessWidget {
  final double top;
  final double size;
  final double opacity;
  final double offsetX;

  const _CloudBlob({
    required this.top,
    required this.size,
    required this.opacity,
    required this.offsetX,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: offsetX * 60,
      child: Container(
        width: size,
        height: size * 0.55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(size),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(opacity * 0.8),
              blurRadius: 40,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUN GLOW (clear sky)
// ═══════════════════════════════════════════════════════════════
class _SunGlow extends StatefulWidget {
  @override
  State<_SunGlow> createState() => _SunGlowState();
}

class _SunGlowState extends State<_SunGlow> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scale = 0.9 + _c.value * 0.15;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFF59D).withOpacity(0.55),
                  const Color(0xFFFFF59D).withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MOON
// ═══════════════════════════════════════════════════════════════
class _Moon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF8E1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFF8E1).withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LIGHTNING FLASH (thunderstorm)
// ═══════════════════════════════════════════════════════════════
class _LightningFlash extends StatelessWidget {
  final AnimationController controller;

  const _LightningFlash({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Flash briefly every ~1.5s
        final t = controller.value;
        final flash = (math.sin(t * math.pi * 8) > 0.95) ? 0.5 : 0.0;
        if (flash == 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: Container(color: Colors.white.withOpacity(flash)),
        );
      },
    );
  }
}