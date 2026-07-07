import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/badges_catalog.dart';
import '../models/models.dart';

/// Pflegt die User-Stats (users-Collection) nach jedem Review und
/// schaltet Badges frei. Nutzt die fertige Logik aus models.dart:
/// AppUser.updateStatsAfterReview() und Badge.checkUnlock().
class UserStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gibt die NEU freigeschalteten Badges zurück (für "BADGE UNLOCKED!").
  Future<List<Badge>> recordReview({
    required String pubId,
    required double rating,
    required bool isPerfectPour,
    GuinnessType? guinnessType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final docRef = _db.collection('users').doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) return [];

    final user = AppUser.fromFirestore(snap, null);

    // 1. Basis-Stats + Streak (fertige Logik im Model)
    user.updateStatsAfterReview(rating, isPerfectPour);

    // 2. Besuchte Pubs
    if (!user.visitedPubIds.contains(pubId)) {
      user.visitedPubIds = [...user.visitedPubIds, pubId];
    }

    // 3. Probierte Guinness-Typen (distinct)
    if (guinnessType != null) {
      final seen = List<int>.from(user.stats['guinnessTypesSeen'] ?? []);
      if (!seen.contains(guinnessType.index)) {
        seen.add(guinnessType.index);
        user.stats['guinnessTypesSeen'] = seen;
      }
      user.stats['guinnessTypes'] = seen.length;
    }

    // 4. Tageszeit-Stats für Early Bird / Night Owl
    final hour = DateTime.now().hour;
    if (hour < 12) {
      user.stats['earlyReviews'] =
          ((user.stats['earlyReviews'] as int?) ?? 0) + 1;
    }
    if (hour >= 22 || hour < 4) {
      user.stats['nightReviews'] =
          ((user.stats['nightReviews'] as int?) ?? 0) + 1;
    }

    // 5. Badges prüfen
    final newBadges = badgesCatalog
        .where(
          (b) =>
              !user.badgeIds.contains(b.id) && b.checkUnlock(user.stats, user),
        )
        .toList();
    if (newBadges.isNotEmpty) {
      user.badgeIds = [...user.badgeIds, ...newBadges.map((b) => b.id)];
    }

    // 6. Zurückschreiben
    await docRef.set(user.toFirestore(), SetOptions(merge: true));

    return newBadges;
  }
}
