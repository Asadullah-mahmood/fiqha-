import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:precise_compass/precise_compass.dart';
import 'package:qibla/qibla.dart';
import 'package:quranpak/services/locationService.dart';
import 'package:quranpak/widgets/QiblaMapView.dart';
import 'package:quranpak/widgets/customIcons.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<CompassReading>? _compassSub;
  late final AnimationController _pulseController;

  double? _qiblaBearing;
  double? _distanceKm;
  double? _accuracy;
  double _confidence = 0;
  bool _shouldCalibrate = false;
  bool _isLoading = true;
  bool _isAligned = false;
  double? _userLat;
  double? _userLng;
  bool _showMapView = false;

  /// True once we know the device has no usable magnetometer/compass
  /// sensor. When true we fall back to a manual ("virtual") Qibla mode
  /// instead of blocking the user with a plain error.
  bool _noCompassSensor = false;

  String? _error;

  // Continuous (unwrapped) heading used to drive the rotating dial so it
  // never "spins the long way round" when the raw heading wraps past
  // 0°/360° - this is what was causing the weird jump/animation before.
  double? _lastHeadingDeg;
  double? _unwrappedHeadingDeg;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Get location
      final loc = await LocationService.getCurrentLocation();

      // 2. Calculate Qibla bearing + distance to the Ka'bah from the
      // user's position. This never needs the compass sensor, so it
      // works whether or not step 3 below finds a magnetometer.
      _userLat = loc.latitude;
      _userLng = loc.longitude;


      final bearing = qiblaAngle(loc.latitude, loc.longitude);
      final km = distanceKm(loc.latitude, loc.longitude, kaabaLat, kaabaLng);



      if (!mounted) return;
      setState(() {
        _qiblaBearing = bearing;
        _distanceKm = km;
      });

      // 3. Start compass stream to check for + read the sensor.
      // precise_compass never throws for a missing sensor: instead a
      // reading arrives with hasHeading = false (source: unavailable),
      // which is how we detect "no sensor in this phone".
      _compassSub = PreciseCompass.heading.listen((reading) {
        if (!mounted) return;

        if (!reading.hasHeading) {
          setState(() {
            _noCompassSensor = true;
            _isLoading = false;
          });
          return;
        }

        _updateDialRotation(reading.heading);

        final aligned = _qiblaBearing == null
            ? false
            : _computeAligned(reading.heading, _qiblaBearing!);

        if (aligned && !_isAligned) {
          HapticFeedback.mediumImpact();
          _pulseController.repeat(reverse: true);
        } else if (!aligned && _isAligned) {
          _pulseController.stop();
          _pulseController.value = 0;
        }

        setState(() {
          _noCompassSensor = false;
          _accuracy = reading.accuracyDegrees;
          _confidence = reading.confidence;
          _shouldCalibrate = reading.shouldCalibrate;
          _isAligned = aligned;
          _isLoading = false;
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Accumulates the raw heading into a continuous angle so the dial can
  /// be driven with AnimatedRotation without ever whipping around a full
  /// circle when the sensor value wraps past 0°/360°.
  void _updateDialRotation(double headingDeg) {
    if (_lastHeadingDeg == null) {
      _unwrappedHeadingDeg = headingDeg;
    } else {
      double delta = headingDeg - _lastHeadingDeg!;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      _unwrappedHeadingDeg = (_unwrappedHeadingDeg ?? headingDeg) + delta;
    }
    _lastHeadingDeg = headingDeg;
  }

  /// Whether the device is within 5° of the Qibla bearing.
  bool _computeAligned(double heading, double bearing) {
    final diff = (bearing - heading).abs() % 360;
    final shortest = diff > 180 ? 360 - diff : diff;
    return shortest <= 5;
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFBF8F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to find the Qibla',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F3D26),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'قبلہ کیسے معلوم کریں',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F3D26),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _instructionBlock(
                  english: 'Without a compass sensor',
                  urdu: 'کمپاس سینسر کے بغیر',
                  points: const [
                    'Open the map view (map icon in the top bar).',
                    'The red line runs from your location to the Ka\'bah.',
                    'Turn your phone so the arrow/line points away from you.',
                    'Use the sun, a street, or another landmark to keep your bearing.',
                  ],
                  urduPoints: const [
                    'اوپر والے نقشے کے آئیکن سے میپ کھولیں۔',
                    'سرخ لکیر آپ کی لوکیشن سے کعبہ تک جاتی ہے۔',
                    'فون کو اس طرح گھمائیں کہ تیر/لکیر آپ سے دور ہو۔',
                    'سمت برقرار رکھنے کے لیے سورج یا کسی اور نشان کا استعمال کریں۔',
                  ],
                ),
                const Divider(height: 28),
                _instructionBlock(
                  english: 'Offline use',
                  urdu: 'انٹرنیٹ کے بغیر استعمال',
                  points: const [
                    'The Qibla bearing and distance are calculated on-device — they work with no internet.',
                    'The map view needs internet the first time to load map tiles.',
                    'Once tiles are cached, the map shows your area and the Ka\'bah line offline.',
                    'If the map is blank offline, use the compass dial or the manual bearing card.',
                  ],
                  urduPoints: const [
                    'قبلہ کی سمت اور فاصلہ فون پر ہی حساب ہوتا ہے — انٹرنیٹ کی ضرورت نہیں۔',
                    'میپ کو پہلی بار کھلنے کے لیے انٹرنیٹ چاہیے۔',
                    'ایک بار لوڈ ہونے کے بعد میپ آف لائن بھی دکھائی دیتا ہے۔',
                    'آف لائن میپ خالی ہو تو کمپاس ڈائل یا بیئرنگ کارڈ استعمال کریں۔',
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ///Instruction how to check qibla without sensor
  Widget _instructionBlock({
    required String english,
    required String urdu,
    required List<String> points,
    required List<String> urduPoints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          english,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        Text(
          urdu,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.notoNastaliqUrdu(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        ...points.map(
              (p) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    p,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...urduPoints.map(
              (p) => Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    p,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The dial rotates opposite to the device heading so N always points
  /// to true north, however the device is held.
  double get _dialTurns => -(_unwrappedHeadingDeg ?? 0) / 360;

  /// Applied to the Ka'bah marker so its glyph stays upright while its
  /// position still moves around the rotating rim.
  double get _kaabaCounterTurns => (_unwrappedHeadingDeg ?? 0) / 360;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Qibla Finder',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (!_noCompassSensor)
            IconButton(
              icon: Icon(_showMapView ? Icons.explore_outlined : Icons.map_outlined),
              tooltip: _showMapView ? 'Show compass' : 'Show on map',
              onPressed: () {
                setState(() => _showMapView = !_showMapView);
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'How to find Qibla',
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      )
          : _error != null
          ? _buildError()
          : (_noCompassSensor || _showMapView)
          ? _buildManualQibla()
          : SafeArea(child: _buildCompass()),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared info card: bearing (from true north), 8-point direction label,
  /// and distance to the Ka'bah. Used by both live and manual modes.
  Widget _buildBearingCard(double screenWidth) {
    final dirLabel = _qiblaBearing == null ? '' : compassDir(_qiblaBearing!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'QIBLA DIRECTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _qiblaBearing == null
                ? '--'
                : '${_qiblaBearing!.toStringAsFixed(1)}° $dirLabel',
            style: GoogleFonts.inter(
              fontSize: (screenWidth * 0.09).clamp(28.0, 40.0),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE2B76C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'from True North',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
          ),
          if (_distanceKm != null) ...[
            const SizedBox(height: 12),
            Text(
              '${_distanceKm!.toStringAsFixed(0)} km to the Ka\'bah',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  /// AnimatedContainer-style status pill under the dial.
  Widget _buildAlignmentStatus({required bool aligned, required bool manual}) {
    final label = manual
        ? 'Turn to face the marked direction'
        : (aligned ? 'You are facing the Qibla' : 'Rotate to align with the Qibla');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: aligned ? const Color(0xFF1B5E20).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: aligned ? const Color(0xFF1B5E20) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aligned ? Icons.check_circle : Icons.explore_outlined,
            size: 20,
            color: aligned ? const Color(0xFF1B5E20) : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: aligned ? const Color(0xFF1B5E20) : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A small stylised Ka'bah glyph: black cube, gold border, gold band.
/// The Ka'bah glyph pulled from the custom "fiqha_icons" font.
/// Keeps the pulse / glow / highlight behavior so alignment feedback
/// still works exactly like before.
Widget _kaabaIcon({required double size, bool highlighted = false}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: highlighted
          ? [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.55),
                blurRadius: size * 0.7,
                spreadRadius: size * 0.12,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: size * 0.2,
              ),
            ],
    ),
    child: Center(
      child: Icon(
        customIcons.kaaba,
        size: size * 0.85,
        color: highlighted
            ? const Color(0xFF1B5E20)
            : const Color(0xFF161616),
      ),
    ),
  );
}


  /// Positions the Ka'bah glyph on the rim of the dial at the Qibla
  /// bearing, and counter-rotates it so it stays upright as the dial
  /// spins with the device heading.
  Widget _kaabaMarker(
      double compassSize,
      double bearingDeg,
      double counterTurns,
      bool aligned,
      ) {
    final markerSize = compassSize * 0.17;
    final radius = compassSize / 2 - markerSize * 0.85;
    final paintAngleRad = (bearingDeg - 90) * math.pi / 180;
    final dx = compassSize / 2 + radius * math.cos(paintAngleRad);
    final dy = compassSize / 2 + radius * math.sin(paintAngleRad);

    return Positioned(
      left: dx - markerSize / 2 + 20,
      top: dy - markerSize / 2 + 8,
      child: AnimatedRotation(
        turns: counterTurns,
        duration: const Duration(milliseconds: 180),
        curve: Curves.linear,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = aligned ? 1.0 + (_pulseController.value * 0.18) : 1.0;
            return Transform.scale(scale: pulse, child: child);
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _kaabaIcon(size: markerSize, highlighted: aligned),
              if (aligned)
                Positioned(
                  top: -markerSize * 0.35,
                  right: -markerSize * 0.35,
                  child: Container(
                    width: markerSize * 0.5,
                    height: markerSize * 0.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: markerSize * 0.34,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared compass dial used by both live and manual mode. In live mode
  /// [dialTurns]/[counterTurns] track the device heading; in manual mode
  /// they stay at 0 and the dial itself is static.
  Widget _buildDial({
    required double compassSize,
    required double dialTurns,
    required double counterTurns,
    required bool aligned,
    required double bearingDeg,
  }) {
    final pointerAreaHeight = compassSize * 0.16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: pointerAreaHeight,
          child: Center(
            child: AnimatedScale(
              scale: aligned ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_drop_down,
                size: pointerAreaHeight * 1.4,
                color: aligned ? const Color(0xFF1B5E20) : const Color(0xFF0F3D26),
              ),
            ),
          ),
        ),
        SizedBox(
          width: compassSize,
          height: compassSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedRotation(
                turns: dialTurns,
                duration: const Duration(milliseconds: 180),
                curve: Curves.linear,
                child: SizedBox(
                  width: compassSize,
                  height: compassSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: compassSize,
                        height: compassSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF1B5E20),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _CompassFacePainter(compassSize: compassSize),
                        ),
                      ),
                      _kaabaMarker(compassSize, bearingDeg, counterTurns, aligned),
                    ],
                  ),
                ),
              ),

              // Fixed center dot - represents the device's position and
              // never rotates with the dial.
              Container(
                width: compassSize * 0.05,
                height: compassSize * 0.05,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3D26),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Manual / "virtual" Qibla mode, shown when no compass sensor was
  /// found. The dial is static (nothing rotates with the phone) and
  /// marks the Qibla bearing; the user aligns it themselves using a
  /// separate compass, a map app, or the sun.
  /// Manual / "virtual" Qibla mode, shown when no compass sensor was
  /// found (or when the user manually switches to map view). Shows an
  /// OpenStreetMap with the user's position, the Ka'bah, and a red
  /// great-circle line connecting them.
  Widget _buildManualQibla() {
    if (_userLat == null || _userLng == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      );
    }

    return QiblaMapView(
      userLat: _userLat!,
      userLng: _userLng!,
      noCompassSensor: _noCompassSensor,
    );
  }

  Widget _buildCompass() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final compassSize = (screenWidth * 0.7).clamp(200.0, 320.0);
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Calibration hint
              if (_shouldCalibrate)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2B76C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2B76C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.screen_rotation,
                          color: Color(0xFF8D6E63), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Move your phone in a figure-8 motion to calibrate',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8D6E63),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildBearingCard(screenWidth),
              const SizedBox(height: 28),

              _buildDial(
                compassSize: compassSize,
                dialTurns: _dialTurns,
                counterTurns: _kaabaCounterTurns,
                aligned: _isAligned,
                bearingDeg: _qiblaBearing ?? 0,
              ),
              const SizedBox(height: 24),

              _buildAlignmentStatus(aligned: _isAligned, manual: false),
              const SizedBox(height: 24),

              if (_accuracy != null)
                Text(
                  'Compass accuracy: ±${_accuracy!.toStringAsFixed(0)}° '
                      '(${(_confidence * 100).toStringAsFixed(0)}% confident)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              SizedBox(height: 40 + bottomInset),
            ],
          ),
        );
      },
    );
  }
}

/// Paints the compass face: cardinal + intercardinal labels and tick
/// marks, with dynamic sizing based on the dial's diameter.
class _CompassFacePainter extends CustomPainter {
  final double compassSize;

  _CompassFacePainter({required this.compassSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final majorTickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.6;

    // Tick marks every 5°, longer at every 15°, longest at the cardinals.
    for (int deg = 0; deg < 360; deg += 5) {
      final angle = (deg - 90) * math.pi / 180;
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 15 == 0;
      final tickLen = isCardinal
          ? compassSize * 0.07
          : isMajor
          ? compassSize * 0.045
          : compassSize * 0.02;
      final startOffset = radius - compassSize * 0.02;
      final endOffset = startOffset - tickLen;
      final start = Offset(
        center.dx + startOffset * math.cos(angle),
        center.dy + startOffset * math.sin(angle),
      );
      final end = Offset(
        center.dx + endOffset * math.cos(angle),
        center.dy + endOffset * math.sin(angle),
      );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }

    final cardinalFontSize = (compassSize * 0.055).clamp(13.0, 17.0);
    final interFontSize = (compassSize * 0.035).clamp(9.0, 12.0);

    final labels = <Map<String, Object>>[
      {'text': 'N', 'deg': 0.0, 'color': const Color(0xFF1B5E20), 'size': cardinalFontSize, 'bold': true},
      {'text': 'NE', 'deg': 45.0, 'color': Colors.grey.shade500, 'size': interFontSize, 'bold': false},
      {'text': 'E', 'deg': 90.0, 'color': Colors.grey.shade600, 'size': cardinalFontSize, 'bold': true},
      {'text': 'SE', 'deg': 135.0, 'color': Colors.grey.shade500, 'size': interFontSize, 'bold': false},
      {'text': 'S', 'deg': 180.0, 'color': Colors.grey.shade600, 'size': cardinalFontSize, 'bold': true},
      {'text': 'SW', 'deg': 225.0, 'color': Colors.grey.shade500, 'size': interFontSize, 'bold': false},
      {'text': 'W', 'deg': 270.0, 'color': Colors.grey.shade600, 'size': cardinalFontSize, 'bold': true},
      {'text': 'NW', 'deg': 315.0, 'color': Colors.grey.shade500, 'size': interFontSize, 'bold': false},
    ];

    for (final label in labels) {
      final deg = label['deg'] as double;
      final angle = (deg - 90) * math.pi / 180;
      final labelRadius = radius - compassSize * 0.14;
      final dx = center.dx + labelRadius * math.cos(angle);
      final dy = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label['text'] as String,
          style: TextStyle(
            fontSize: label['size'] as double,
            fontWeight:
            (label['bold'] as bool) ? FontWeight.bold : FontWeight.w500,
            color: label['color'] as Color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(dx - textPainter.width / 2, dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassFacePainter oldDelegate) => false;
}