// lib/widgets/map_container.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/map_service.dart';
import '../services/openstreetmap_service.dart';
import '../models/models.dart';

class MapContainer extends StatefulWidget {
  final List<Pub> pubs;
  final latlong.LatLng center;
  final double zoom;
  final void Function(Pub) onMarkerTap;
  final void Function(latlong.LatLng) onMapTap;
  final latlong.LatLng? userLocation;
  final bool showUserLocation;
  final Function(GoogleMapController)? onMapCreated;
  const MapContainer({
    Key? key,
    required this.pubs,
    required this.center,
    this.zoom = 14.0,
    required this.onMarkerTap,
    required this.onMapTap,
    this.userLocation,
    this.showUserLocation = true,
    this.onMapCreated, // 2. Im Konstruktor aufnehmen
  }) : super(key: key);

  @override
  _MapContainerState createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  late MapService _mapService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // ✅ FIX: OpenStreetMap für jetzt (kostenlos, sofort)
      _mapService = OpenStreetMapService();
      await _mapService.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Map initialization failed: $e');
      // Hier könntest du einen Fallback zeigen
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Nur dispose wenn initialisiert
    if (_isInitialized) {
      _mapService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return _mapService.buildMap(
      pubs: widget.pubs,
      center: widget.center,
      zoom: widget.zoom,
      onMarkerTap: widget.onMarkerTap,
      onMapTap: widget.onMapTap,
      userLocation: widget.userLocation,
      showUserLocation: widget.showUserLocation,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Color(0xFF0D0D0D),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Loading Guinness Map...',
              style: TextStyle(color: Color(0xFF746855), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
