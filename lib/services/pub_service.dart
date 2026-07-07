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

  // 2. Neuen Pub anlegen (Long-Press auf die Karte)
  Future<void> addPub({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final pub = Pub(
      id: '', // Firestore vergibt die ID
      name: name,
      address: address,
      location: GeoPoint(latitude, longitude),
    );
    await _db.collection('pubs').add(pub.toFirestore());
  }
}
