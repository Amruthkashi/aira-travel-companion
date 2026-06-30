import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final String fromCity;
  final String destinationCity;
  final List<String>? layovers;

  const MapScreen({
    super.key,
    required this.fromCity,
    required this.destinationCity,
    this.layovers,
  });

  // Coordinates lookup map for Indian and International cities
  static final Map<String, LatLng> _cityCoordinates = {
    'mumbai': const LatLng(19.0760, 72.8777),
    'delhi': const LatLng(28.7041, 77.1025),
    'bengaluru': const LatLng(12.9716, 77.5946),
    'bangalore': const LatLng(12.9716, 77.5946),
    'hyderabad': const LatLng(17.3850, 78.4867),
    'chennai': const LatLng(13.0827, 80.2707),
    'kolkata': const LatLng(22.5726, 88.3639),
    'calcutta': const LatLng(22.5726, 88.3639),
    'pune': const LatLng(18.5204, 73.8567),
    'ahmedabad': const LatLng(23.0225, 72.5714),
    'jaipur': const LatLng(26.9124, 75.7873),
    'goa': const LatLng(15.2993, 74.1240),
    'kochi': const LatLng(9.9312, 76.2673),
    'cochin': const LatLng(9.9312, 76.2673),
    'lucknow': const LatLng(26.8467, 80.9462),
    'dubai': const LatLng(25.2048, 55.2708),
    'london': const LatLng(51.5074, -0.1278),
    'singapore': const LatLng(1.3521, 103.8198),
    'frankfurt': const LatLng(50.1109, 8.6821),
    'doha': const LatLng(25.2854, 51.5310),
    'new york': const LatLng(40.7128, -74.0060),
    'nyc': const LatLng(40.7128, -74.0060),
    'bangkok': const LatLng(13.7563, 100.5018),
    'kuala lumpur': const LatLng(3.1390, 101.6869),
    'kl': const LatLng(3.1390, 101.6869),
  };

  LatLng _getCoordinates(String city) {
    final normalized = city.toLowerCase().trim();
    if (_cityCoordinates.containsKey(normalized)) {
      return _cityCoordinates[normalized]!;
    }
    // Fallback: substring match
    for (final entry in _cityCoordinates.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    // Absolute fallback: Delhi
    return const LatLng(28.7041, 77.1025);
  }

  @override
  Widget build(BuildContext context) {
    final startLatLng = _getCoordinates(fromCity);
    final endLatLng = _getCoordinates(destinationCity);

    final cleanLayovers = layovers?.where((c) => c.trim().isNotEmpty).toList() ?? [];
    final List<LatLng> layoverLatLngs = cleanLayovers.map((c) => _getCoordinates(c)).toList();

    // Centering calculations (average of all path coordinates)
    double sumLat = startLatLng.latitude + endLatLng.latitude;
    double sumLng = startLatLng.longitude + endLatLng.longitude;
    for (final pt in layoverLatLngs) {
      sumLat += pt.latitude;
      sumLng += pt.longitude;
    }
    final int totalPoints = 2 + layoverLatLngs.length;
    final centerLatLng = LatLng(sumLat / totalPoints, sumLng / totalPoints);

    // Zoom level calculation based on max coordinate difference
    double zoom = 4.0;
    double maxLatDiff = (startLatLng.latitude - endLatLng.latitude).abs();
    double maxLngDiff = (startLatLng.longitude - endLatLng.longitude).abs();
    
    // Scan layover coordinates to find actual bounds difference
    for (final pt in layoverLatLngs) {
      final diffLatStart = (startLatLng.latitude - pt.latitude).abs();
      final diffLngStart = (startLatLng.longitude - pt.longitude).abs();
      final diffLatEnd = (endLatLng.latitude - pt.latitude).abs();
      final diffLngEnd = (endLatLng.longitude - pt.longitude).abs();
      if (diffLatStart > maxLatDiff) maxLatDiff = diffLatStart;
      if (diffLngStart > maxLngDiff) maxLngDiff = diffLngStart;
      if (diffLatEnd > maxLatDiff) maxLatDiff = diffLatEnd;
      if (diffLngEnd > maxLngDiff) maxLngDiff = diffLngEnd;
    }

    final double maxDiff = maxLatDiff > maxLngDiff ? maxLatDiff : maxLngDiff;
    if (maxDiff > 80.0) {
      zoom = 1.5;
    } else if (maxDiff > 40.0) {
      zoom = 2.5;
    } else if (maxDiff > 20.0) {
      zoom = 3.5;
    } else if (maxDiff > 10.0) {
      zoom = 4.5;
    } else if (maxDiff > 5.0) {
      zoom = 5.5;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'FLIGHT PATH VISUALIZER',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: zoom,
              minZoom: 1.0,
              maxZoom: 18.0,
            ),
            children: [
              // OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'aira_mobile',
              ),
              // Polylines mapping flight segments
              PolylineLayer(
                polylines: [
                  if (layoverLatLngs.isEmpty)
                    Polyline(
                      points: [startLatLng, endLatLng],
                      color: const Color(0xFF2563EB), // Primary Blue
                      strokeWidth: 4.5,
                    )
                  else ...[
                    // Leg 1: Origin to first layover
                    Polyline(
                      points: [startLatLng, layoverLatLngs.first],
                      color: const Color(0xFF2563EB),
                      strokeWidth: 4.5,
                    ),
                    // Layovers sequence
                    for (int i = 0; i < layoverLatLngs.length - 1; i++)
                      Polyline(
                        points: [layoverLatLngs[i], layoverLatLngs[i + 1]],
                        color: const Color(0xFFF59E0B), // Orange-Amber
                        strokeWidth: 4.0,
                      ),
                    // Final Leg: Last layover to destination
                    Polyline(
                      points: [layoverLatLngs.last, endLatLng],
                      color: const Color(0xFF10B981), // Emerald Green
                      strokeWidth: 4.5,
                    ),
                  ],
                ],
              ),
              // Markers Layer
              MarkerLayer(
                markers: [
                  // Origin Marker
                  Marker(
                    point: startLatLng,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flight_takeoff,
                        color: Colors.greenAccent,
                        size: 26,
                      ),
                    ),
                  ),
                  // Destination Marker
                  Marker(
                    point: endLatLng,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flight_land,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                    ),
                  ),
                  // Layover Markers
                  for (int i = 0; i < layoverLatLngs.length; i++)
                    Marker(
                      point: layoverLatLngs[i],
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.orangeAccent,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Float info overlay card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FLIGHT ROUTE DETAILS',
                    style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fromCity,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.swap_horiz, color: Color(0xFF60A5FA)),
                      Expanded(
                        child: Text(
                          destinationCity,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  if (cleanLayovers.isNotEmpty) ...[
                    const Divider(height: 16, color: Color(0xFF334155)),
                    Row(
                      children: [
                        const Icon(Icons.airline_stops, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Layovers: ${cleanLayovers.join(' ➔ ')}',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
