// lib/screens/profile_screen.dart — Stats, Review-Historie, Badges, Logout
// Material's Badge-Widget ausblenden — wir nutzen unser eigenes Badge-Model
import 'package:flutter/material.dart' hide Badge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/badges_catalog.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFF5E6D3);
  static const _dark = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'Nicht eingeloggt',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MY PROFILE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: _cream,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                // Zurück zur Wurzel — AuthWrapper zeigt dann den Login
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(
              child: Text(
                'Profil nicht gefunden',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final user = AppUser.fromFirestore(userSnap.data!, null);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ---------- KOPF ----------
              Text(
                user.displayName.toUpperCase(),
                style: const TextStyle(
                  color: _cream,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),

              const SizedBox(height: 24),

              // ---------- STATS ----------
              Row(
                children: [
                  _statTile('${user.totalReviews}', 'REVIEWS'),
                  const SizedBox(width: 12),
                  _statTile(
                    user.averageRatingGiven.toStringAsFixed(1),
                    'Ø RATING',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statTile('${user.perfectPours}', 'PERFECT POURS'),
                  const SizedBox(width: 12),
                  _statTile('${user.currentStreak} 🔥', 'STREAK'),
                ],
              ),

              const SizedBox(height: 32),

              // ---------- BADGES ----------
              const Text(
                'BADGES',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: badgesCatalog
                    .map((b) => _badgeTile(b, user.badgeIds.contains(b.id)))
                    .toList(),
              ),

              const SizedBox(height: 32),

              // ---------- HISTORIE ----------
              const Text(
                'MY POURS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildHistory(uid),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _gold,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeTile(Badge badge, bool unlocked) {
    final color = unlocked ? badge.color : Colors.white24;
    return Tooltip(
      message: badge.description,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked ? color.withOpacity(0.1) : _dark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: unlocked ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(_badgeIcon(badge.type), color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              badge.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? _cream : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _badgeIcon(BadgeType type) {
    switch (type) {
      case BadgeType.PASSPORT:
        return Icons.explore;
      case BadgeType.VARIETY:
        return Icons.local_drink;
      case BadgeType.QUALITY:
        return Icons.star;
      case BadgeType.LOCATION:
        return Icons.location_on;
      case BadgeType.TIMING:
        return Icons.schedule;
      case BadgeType.SPECIAL:
        return Icons.auto_awesome;
    }
  }

  Widget _buildHistory(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: _gold)),
          );
        }

        final reviews = (snapshot.data?.docs ?? [])
            .map((doc) => Review.fromFirestore(doc, null))
            .toList();
        // Client-seitig sortieren (kein Firestore-Index nötig)
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Noch keine Reviews — Zeit für ein Pint! 🍺',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return Column(
          children: reviews.map((r) => _historyItem(context, r)).toList(),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        title: const Text(
          'REVIEW LÖSCHEN?',
          style: TextStyle(
            color: _cream,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Das Review und sein Foto werden dauerhaft gelöscht.',
          style: TextStyle(color: Colors.white70),
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
              Navigator.pop(ctx);
              try {
                await ReviewService().deleteReview(review);
              } catch (e) {
                debugPrint('Löschen fehlgeschlagen: $e');
              }
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(BuildContext context, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          if (review.primaryPhotoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                review.primaryPhotoUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Review-Foto konnte nicht geladen werden: $error');
                  return const SizedBox(width: 48, height: 48);
                },
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.sports_bar, color: Colors.white24),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: review.rating >= 7.5 ? _gold : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (review.comment.isNotEmpty)
                  Text(
                    review.comment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            "${review.createdAt.day.toString().padLeft(2, '0')}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}",
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _confirmDelete(context, review),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
