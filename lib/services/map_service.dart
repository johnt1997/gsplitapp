// lib/services/map_service.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Für GeoPoint

abstract class MapService {
  // ✅ FIX: Nutze latlong2 LatLng statt eigene Klasse
  Widget buildMap({
    required List<Pub> pubs,
    required latlong.LatLng center,
    required double zoom,
    required void Function(Pub) onMarkerTap,
    required void Function(latlong.LatLng) onMapTap,
    latlong.LatLng? userLocation, // ✅ Getrennt von map center
    bool showUserLocation = true,
  });

  Future<void> initialize();
  void dispose();

  // ✅ FIX: Alle LatLng Referenzen sind jetzt latlong.LatLng
  latlong.LatLng convertGeoPoint(GeoPoint geoPoint);
  double calculateDistance(latlong.LatLng point1, latlong.LatLng point2);
}
