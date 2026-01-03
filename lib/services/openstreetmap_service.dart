// lib/services/openstreetmap_service.dart - NEON UPDATE
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../models/models.dart';
import 'map_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../widgets/mini_guinness_marker.dart'; // ✅ Importieren!

class OpenStreetMapService implements MapService {
  late MapController _mapController;

  @override
  Future<void> initialize() async {
    _mapController = MapController();
  }

  @override
  Widget buildMap({
    required List<Pub> pubs,
    required latlong.LatLng center,
    required double zoom,
    required void Function(Pub) onMarkerTap,
    required void Function(latlong.LatLng) onMapTap,
    latlong.LatLng? userLocation,
    bool showUserLocation = true,
  }) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: (tapPosition, point) => onMapTap(point),
        // Begrenzung, damit man nicht ins Unendliche zoomt
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        // Dunkle Karte
        TileLayer(
          urlTemplate:
              'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.guinness.rater',
        ),

        // Marker Layer mit den neuen Gläsern
        MarkerLayer(
          markers: pubs.map((pub) => _createMarker(pub, onMarkerTap)).toList(),
        ),

        // User Location (Goldener Punkt)
        if (showUserLocation && userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: userLocation,
                color: Color(0xFFD4AF37).withOpacity(0.2),
                borderColor: Color(0xFFD4AF37),
                borderStrokeWidth: 2,
                radius: 40, // Pulsierender Effekt-Radius
                useRadiusInMeter: true,
              ),
              CircleMarker(
                point: userLocation,
                color: Color(0xFFD4AF37),
                radius: 6, // Der eigentliche Punkt
              ),
            ],
          ),
      ],
    );
  }

  Marker _createMarker(Pub pub, void Function(Pub) onMarkerTap) {
    return Marker(
      width: 50.0,
      height: 65.0, // Etwas höher wegen der Spitze
      point: latlong.LatLng(pub.location.latitude, pub.location.longitude),

      // ✅ WICHTIG: Das hier sorgt dafür, dass die Spitze genau auf dem Punkt steht
      // (Alignment.topCenter richtet den "Ankerpunkt" so aus, dass der Marker nach oben wächst)
      alignment: Alignment.topCenter,

      child: GestureDetector(
        onTap: () => onMarkerTap(pub),
        child: MiniGuinnessMarker(rating: pub.averageRating, isHot: pub.isHot),
      ),
    );
  }

  @override
  latlong.LatLng convertGeoPoint(GeoPoint geoPoint) {
    return latlong.LatLng(geoPoint.latitude, geoPoint.longitude);
  }

  @override
  double calculateDistance(latlong.LatLng point1, latlong.LatLng point2) {
    final lat1 = point1.latitude * (pi / 180.0);
    final lon1 = point1.longitude * (pi / 180.0);
    final lat2 = point2.latitude * (pi / 180.0);
    final lon2 = point2.longitude * (pi / 180.0);
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return 6371.0 * c;
  }

  @override
  void dispose() {
    _mapController.dispose();
  }
}
