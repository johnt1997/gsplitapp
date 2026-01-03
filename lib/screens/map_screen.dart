// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/pub_service.dart';
import '../models/models.dart';
import '../widgets/about_shamrock.dart';
import '../widgets/map_container.dart';
import '../widgets/brutal_pub_sheet.dart';
import '../services/auth_service.dart'; // Damit wir abmelden können

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  static const LatLng _dublinCenter = LatLng(53.3444, -6.2631);
  // --------------------------------

  //late GoogleMapController mapController;
  late AnimationController _fabController;
  latlong.LatLng _userLocation = latlong.LatLng(53.3498, -6.2603);
  // Der Service
  final PubService _pubService = PubService();
  // Standardmäßig Deutsch
  String _currentLanguageCode = 'de';

  // Helper Map für die Flaggen
  final Map<String, String> _flags = {
    'de': '🇩🇪',
    'en': '🇬🇧', // oder 🇮🇪 für den Guinness Vibe ;)
    'fr': '🇫🇷',
  };

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    //_createMarkers();
  }

  void _showPubDetails(Pub pub) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Wichtig damit es hoch genug wird
      backgroundColor: Colors.transparent, // Wichtig für die runden Ecken
      builder: (context) => BrutalPubSheet(
        pub: pub,
        // ✅ Das ist NEU: Wir müssen dem Sheet sagen, wie es zugeht
        onClose: () => Navigator.pop(context),
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

        // --- LINKS: SPRACHE (EDEL & BRUTAL) ---
        leadingWidth: 70,
        leading: Center(
          child: Theme(
            data: Theme.of(context).copyWith(
              // Das Menü Design: Dunkel mit Goldrand
              popupMenuTheme: PopupMenuThemeData(
                color: const Color(0xFF1A1A1A),
                textStyle: const TextStyle(color: Color(0xFFF5E6D3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Change Language',
              offset: const Offset(0, 50),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _flags[_currentLanguageCode]!,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              onSelected: (String code) {
                setState(() {
                  _currentLanguageCode = code;
                  // TODO: Später echte Übersetzung hier triggern
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildFlagItem('de', 'GERMAN'),
                const PopupMenuDivider(height: 1),
                _buildFlagItem('en', 'ENGLISH'),
                const PopupMenuDivider(height: 1),
                _buildFlagItem('fr', 'FRENCH'),
              ],
            ),
          ),
        ),

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

        // --- RECHTS: ACTIONS ---
        actions: [
          // 3. LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
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
                pubs: pubs,
                center: _userLocation,
                zoom: 14.0,
                onMarkerTap: _showPubDetails,
                onMapTap: (latLng) => print('Map tapped at: $latLng'),
                userLocation: _userLocation,
                showUserLocation: true,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),
              // ☘️ NEU: INFO BUTTON UNTEN LINKS
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
                content: Text("Klick bitte auf einen Pin, um zu bewerten!"),
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

  void _centerOnUserLocation() async {
    // Wenn wir echte GPS-Daten hätten, würden wir _userLocation nehmen.
    // Für den Start fliegen wir nach Dublin!

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: _dublinCenter, // Ab nach Irland!
            zoom: 15.0, // Schön nah ran an die Pubs
            tilt: 45.0, // Ein bisschen 3D-Look für den Vibe
          ),
        ),
      );

      // Kleines Feedback für den User
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sláinte! Willkommen in Dublin 🇮🇪"),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  PopupMenuItem<String> _buildFlagItem(String code, String label) {
    return PopupMenuItem<String>(
      value: code,
      height: 40,
      child: Row(
        children: [
          Text(_flags[code]!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: _currentLanguageCode == code
                  ? const Color(0xFFD4AF37)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
