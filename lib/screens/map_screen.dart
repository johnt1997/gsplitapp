// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/pub_service.dart';
import '../services/osm_places_service.dart';
import '../models/models.dart';
import '../widgets/about_shamrock.dart';
import '../widgets/map_container.dart';
import '../widgets/brutal_pub_sheet.dart';
import 'community_screen.dart';
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

    showDialog(
      context: context,
      builder: (ctx) => _AddPubDialog(
        point: point,
        onSubmit: (name, address, latitude, longitude) async {
          try {
            await _pubService.addPub(
              name: name,
              address: address,
              latitude: latitude,
              longitude: longitude,
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

        // --- RECHTS: COMMUNITY & PROFIL ---
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFFD4AF37)),
            tooltip: 'Leaderboard & Feed',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            },
          ),
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

/// Dialog zum Anlegen eines Pubs. Sucht beim Öffnen automatisch echte
/// Pubs/Bars in der Nähe des Long-Press-Punkts (OpenStreetMap/Overpass),
/// damit man Name & Adresse nicht tippen muss.
class _AddPubDialog extends StatefulWidget {
  final latlong.LatLng point;
  final Future<void> Function(
    String name,
    String address,
    double latitude,
    double longitude,
  )
  onSubmit;

  const _AddPubDialog({required this.point, required this.onSubmit});

  @override
  State<_AddPubDialog> createState() => _AddPubDialogState();
}

class _AddPubDialogState extends State<_AddPubDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  late double _latitude = widget.point.latitude;
  late double _longitude = widget.point.longitude;

  List<OsmPlace> _suggestions = [];
  bool _loading = true;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    OsmPlacesService()
        .findNearbyPubs(widget.point.latitude, widget.point.longitude)
        .then((places) {
          if (mounted) {
            setState(() {
              _suggestions = places;
              _loading = false;
            });
          }
        })
        .catchError((e) {
          print('Overpass-Suche fehlgeschlagen: $e');
          if (mounted) setState(() => _loading = false);
        });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _pickSuggestion(int index) {
    HapticFeedback.selectionClick();
    final place = _suggestions[index];
    setState(() {
      _selectedIndex = index;
      _nameController.text = place.name;
      _addressController.text = place.address;
      // Echte OSM-Koordinaten sind genauer als der Long-Press-Punkt
      _latitude = place.latitude;
      _longitude = place.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Suche Pubs in der Nähe...',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (_suggestions.isNotEmpty) ...[
              const Text(
                'IN DER NÄHE GEFUNDEN (OSM):',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => _pickSuggestion(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFD4AF37).withOpacity(0.15)
                              : const Color(0xFF0D0D0D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFD4AF37)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sports_bar,
                              size: 16,
                              color: Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFF5E6D3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (place.address.isNotEmpty)
                                    Text(
                                      place.address,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildField(_nameController, 'Pub name'),
            const SizedBox(height: 12),
            _buildField(_addressController, 'Address'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final address = _addressController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context);
            widget.onSubmit(name, address, _latitude, _longitude);
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
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
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
}
