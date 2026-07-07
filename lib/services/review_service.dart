import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';

/// Gemeinsame Review-Operationen: Pub-Schnitt neu berechnen,
/// eigene Reviews bearbeiten und löschen.
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Berechnet averageRating/reviewCount/isHot eines Pubs aus allen Reviews neu.
  Future<void> recalcPubStats(String pubId) async {
    final all = await _db
        .collection('reviews')
        .where('pubId', isEqualTo: pubId)
        .get();

    if (all.docs.isEmpty) {
      await _db.collection('pubs').doc(pubId).update({
        'averageRating': 0.0,
        'reviewCount': 0,
        'isHot': false,
      });
      return;
    }

    double total = 0;
    for (var doc in all.docs) {
      total += (doc.data()['rating'] as num? ?? 0).toDouble();
    }
    final avg = total / all.docs.length;

    await _db.collection('pubs').doc(pubId).update({
      'averageRating': avg,
      'reviewCount': all.docs.length,
      'isHot': avg >= 7.5,
    });
  }

  Future<void> updateReview(
    Review review, {
    required double rating,
    required String comment,
    double? price,
  }) async {
    await _db.collection('reviews').doc(review.id).update({
      'rating': rating,
      // Alt-Felder konsistent mitpflegen (siehe submitReview)
      'shtickRating': rating,
      'presentationRating': rating,
      'comment': comment,
      'text': comment,
      'price': price,
    });
    await recalcPubStats(review.pubId);
  }

  Future<void> deleteReview(Review review) async {
    await _db.collection('reviews').doc(review.id).delete();

    // Foto(s) im Storage mitlöschen — Fehler hier sind nicht kritisch
    for (final url in review.photoUrls) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (_) {}
    }

    await recalcPubStats(review.pubId);
  }
}
