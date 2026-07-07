// lib/widgets/map_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/openstreetmap_service.dart';
import '../models/models.dart';

class MapContainer extends StatelessWidget {
  final MapController mapController;
  final List<Pub> pubs;
  final latlong.LatLng center;
  final double zoom;
  final void Function(Pub) onMarkerTap;
  final void Function(latlong.LatLng) onMapTap;
  final void Function(latlong.LatLng)? onMapLongPress;
  final latlong.LatLng? userLocation;
  final bool showUserLocation;

  const MapContainer({
    Key? key,
    required this.mapController,
    required this.pubs,
    required this.center,
    this.zoom = 14.0,
    required this.onMarkerTap,
    required this.onMapTap,
    this.onMapLongPress,
    this.userLocation,
    this.showUserLocation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OpenStreetMapService().buildMap(
      mapController: mapController,
      pubs: pubs,
      center: center,
      zoom: zoom,
      onMarkerTap: onMarkerTap,
      onMapTap: onMapTap,
      onMapLongPress: onMapLongPress,
      userLocation: userLocation,
      showUserLocation: showUserLocation,
    );
  }
}
