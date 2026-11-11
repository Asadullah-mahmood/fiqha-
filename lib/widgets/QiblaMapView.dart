import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:qibla/qibla.dart';

import 'package:quranpak/widgets/customIcons.dart';

class QiblaMapView extends StatelessWidget {
  final double userLat;
  final double userLng;
  final bool noCompassSensor;

  const QiblaMapView({
    super.key,
    required this.userLat,
    required this.userLng,
    this.noCompassSensor = false,
  });

  @override
  Widget build(BuildContext context) {
    final userPoint = LatLng(userLat, userLng);
    final kaabaPoint = LatLng(kaabaLat, kaabaLng);

    // Great-circle path from user to Ka'bah.
    // qiblaGreatCircle returns List<List<double>>; each inner list is [lat, lng].
    final List<LatLng> pathPoints = qiblaGreatCircle(userLat, userLng, 50)
        .map((p) => LatLng(p[0], p[1]))
        .toList();

    // Fit the map to contain both markers.
    final bounds = LatLngBounds.fromPoints([userPoint, kaabaPoint]);

    return Stack(
      children: [
        // ---- Full-screen map ----
        FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
            minZoom: 2,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.yourpackage.quranpak',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: pathPoints,
                  color: Colors.red,
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: userPoint,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 26,
                    ),
                  ),
                ),
                Marker(
                  point: kaabaPoint,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      customIcons.kaaba,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ---- Instruction banner overlaid at the top ----
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: _InstructionBanner(noCompassSensor: noCompassSensor),
        ),

        // ---- OSM attribution (required by tile policy) ----
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '© OpenStreetMap contributors',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  final bool noCompassSensor;

  const _InstructionBanner({required this.noCompassSensor});

  @override
  Widget build(BuildContext context) {
    final message = noCompassSensor
        ? 'No compass sensor found. The red line shows the direction to the Ka\'bah from your location. Face along this line to pray.'
        : 'The red line shows the direction to the Ka\'bah from your location. Face along this line to pray.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2B76C).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF6D4C41), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF4E342E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}