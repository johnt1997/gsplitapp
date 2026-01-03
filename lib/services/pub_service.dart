import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class PubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Live-Stream aller Pubs
  Stream<List<Pub>> getPubsStream() {
    return _db.collection('pubs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Wir wandeln das Firestore-Dokument in dein Pub-Objekt um
        return Pub.fromFirestore(
          doc,
          null,
        ); // null, da wir keine SnapshotOptions nutzen
      }).toList();
    });
  }

  // 2. Einmaliges Hochladen der Fake-Daten (Seeding)
  Future<void> seedFakePubs() async {
    // Deine Fake-Liste (Hardcoded für den Start)
    final List<Map<String, dynamic>> fakePubsData = [
      {
        'name': 'The Temple Bar',
        'location': const GeoPoint(53.3456, -6.2672),
        'address': '47-48 Temple Bar, Dublin',
        'averageRating': 8.5,
        'reviewCount': 142,
        'isHot': true,
      },
      {
        'name': 'The Brazen Head',
        'location': const GeoPoint(53.3433, -6.2755),
        'address': '20 Lower Bridge St, Dublin',
        'averageRating': 9.2,
        'reviewCount': 89,
        'isHot': false,
      },
      {
        'name': 'Mulligan\'s',
        'location': const GeoPoint(53.3444, -6.2550),
        'address': '8 Poolbeg St, Dublin',
        'averageRating': 7.8,
        'reviewCount': 203,
        'isHot': true,
      },
    ];

    for (var data in fakePubsData) {
      await _db.collection('pubs').add(data);
    }
    print("✅ FAKE PUBS IN DATENBANK GELADEN!");
  }
}
