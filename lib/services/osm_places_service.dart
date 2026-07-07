import 'dart:convert';
import 'package:http/http.dart' as http;

/// Ein Pub/Bar-Vorschlag aus OpenStreetMap (Overpass API).
class OsmPlace {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  OsmPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// Findet echte Pubs/Bars in der Nähe über die kostenlose Overpass API,
/// damit man beim Anlegen nicht alles von Hand tippen muss.
class OsmPlacesService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<OsmPlace>> findNearbyPubs(
    double latitude,
    double longitude, {
    int radiusMeters = 400,
  }) async {
    final query =
        '[out:json][timeout:10];'
        '(node["amenity"~"pub|bar|biergarten"]["name"](around:$radiusMeters,$latitude,$longitude);'
        'way["amenity"~"pub|bar|biergarten"]["name"](around:$radiusMeters,$latitude,$longitude););'
        'out center 15;';

    final response = await http
        .post(Uri.parse(_endpoint), body: {'data': query})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Overpass HTTP ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final elements = (data['elements'] as List<dynamic>? ?? []);

    final places = <OsmPlace>[];
    for (final el in elements) {
      final tags = (el['tags'] as Map<String, dynamic>? ?? {});
      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) continue;

      // Bei "way"-Elementen liegen die Koordinaten unter "center"
      final lat = (el['lat'] ?? el['center']?['lat']) as num?;
      final lon = (el['lon'] ?? el['center']?['lon']) as num?;
      if (lat == null || lon == null) continue;

      final addressParts = [
        [
          tags['addr:street'],
          tags['addr:housenumber'],
        ].whereType<String>().join(' '),
        tags['addr:city'],
      ].whereType<String>().where((s) => s.isNotEmpty).toList();

      places.add(
        OsmPlace(
          name: name,
          address: addressParts.join(', '),
          latitude: lat.toDouble(),
          longitude: lon.toDouble(),
        ),
      );
    }
    return places;
  }
}
