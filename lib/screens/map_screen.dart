// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/pub_service.dart';
import '../models/models.dart';
import '../widgets/about_shamrock.dart';
import '../widgets/map_container.dart';
import '../widgets/brutal_pub_sheet.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _fabController;

  // Fallback: Dublin, bis echtes GPS da ist
  static final latlong.LatLng _dublinCenter = latlong.LatLng(53.3498, -6.2603);
  latlong.LatLng _userLocation = _dublinCenter;
  bool _hasRealLocation = false;

  final PubService _pubService = PubService();

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Fallback bleibt Dublin
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLocation = latlong.LatLng(pos.latitude, pos.longitude);
        _hasRealLocation = true;
      });
      try {
        _mapController.move(_userLocation, 14.0);
      } catch (_) {
        // Karte noch nicht gerendert — dann übernimmt initialCenter die Position
      }
    } catch (e) {
      print('GPS Fehler (Fallback Dublin): $e');
    }
  }

  void _showPubDetails(Pub pub) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Wichtig damit es hoch genug wird
      backgroundColor: Colors.transparent, // Wichtig für die runden Ecken
      builder: (context) =>
          BrutalPubSheet(pub: pub, onClose: () => Navigator.pop(context)),
    );
  }

  // ---------------- PUB HINZUFÜGEN (Long-Press) ----------------

  void _showAddPubDialog(latlong.LatLng point) {
    HapticFeedback.heavyImpact();
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        title: const Text(
          'NEW PUB',
          style: TextStyle(
            color: Color(0xFFF5E6D3),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(nameController, 'Pub name', autofocus: true),
            const SizedBox(height: 12),
            _buildDialogField(addressController, 'Address'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final address = addressController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await _pubService.addPub(
                  name: name,
                  address: address,
                  latitude: point.latitude,
                  longitude: point.longitude,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🍺 "$name" wurde hinzugefügt!'),
                      backgroundColor: const Color(0xFF1A1A1A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Speichern: $e')),
                  );
                }
              }
            },
            child: const Text(
              'ADD PUB',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String hint, {
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(color: Color(0xFFF5E6D3)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF0D0D0D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        // --- MITTE: TITEL ---
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFF5E6D3)],
          ).createShader(bounds),
          child: Text(
            'GUINNESS RATER',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),

        // --- RECHTS: PROFIL ---
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),

      // --- BODY (MAP) ---
      body: StreamBuilder<List<Pub>>(
        stream: _pubService.getPubsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Fehler: ${snapshot.error}",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          final pubs = snapshot.data ?? [];

          return Stack(
            children: [
              MapContainer(
                mapController: _mapController,
                pubs: pubs,
                center: _userLocation,
                zoom: 14.0,
                onMarkerTap: _showPubDetails,
                onMapTap: (latLng) {},
                onMapLongPress: _showAddPubDialog,
                userLocation: _userLocation,
                showUserLocation: true,
              ),
              // ☘️ INFO BUTTON UNTEN LINKS
              Positioned(
                left: 16,
                bottom: 30, // Tief genug für den Daumen
                child: GestureDetector(
                  onTap: () => showBrutalShamrockDialog(context),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8), // Eckig = Brutal
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFFD4AF37),
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Location Button
              Positioned(
                right: 16,
                bottom: 100,
                child: FloatingActionButton(
                  heroTag: 'locationFab',
                  mini: true,
                  onPressed: _centerOnUserLocation,
                  backgroundColor: Color(0xFF1a1a1a),
                  child: Icon(Icons.my_location, color: Color(0xFFD4AF37)),
                ),
              ),
            ],
          );
        },
      ),

      // --- FAB (RATE BUTTON) ---
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
        ),
        child: FloatingActionButton.extended(
          heroTag: 'mapReviewFab',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Tippe auf einen Pin zum Bewerten — oder halte die Karte gedrückt, um einen Pub anzulegen!",
                ),
              ),
            );
          },
          backgroundColor: Color(0xFFD4AF37),
          icon: Icon(Icons.add, color: Color(0xFF0D0D0D)),
          label: Text(
            'RATE',
            style: TextStyle(
              color: Color(0xFF0D0D0D),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnUserLocation() {
    _mapController.move(_userLocation, 15.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasRealLocation
              ? "Zurück zu deinem Standort 🍺"
              : "Sláinte! Willkommen in Dublin 🇮🇪 (GPS nicht verfügbar)",
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
