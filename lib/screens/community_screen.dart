// lib/screens/community_screen.dart — Leaderboard + Aktivitäts-Feed
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFF5E6D3);
  static const _dark = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'COMMUNITY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: _cream,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        // Pub-Namen für alte Reviews, die noch kein pubName-Feld haben
        future: _loadPubNames(),
        builder: (context, pubsSnap) {
          final pubNames = pubsSnap.data ?? {};

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '🏆 LEADERBOARD',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildLeaderboard(),
              const SizedBox(height: 32),
              const Text(
                'LATEST POURS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeed(pubNames),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, String>> _loadPubNames() async {
    final snap = await FirebaseFirestore.instance.collection('pubs').get();
    return {
      for (final doc in snap.docs)
        doc.id: (doc.data()['name'] as String? ?? ''),
    };
  }

  // ---------------- LEADERBOARD ----------------

  Widget _buildLeaderboard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: _gold),
            ),
          );
        }

        final users = (snapshot.data?.docs ?? [])
            .map((doc) => AppUser.fromFirestore(doc, null))
            .where((u) => u.totalReviews > 0)
            .toList();
        users.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
        final top = users.take(10).toList();

        if (top.isEmpty) {
          return const Text(
            'Noch keine Reviews — sei der Erste! 🍺',
            style: TextStyle(color: Colors.white38),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < top.length; i++) _leaderboardItem(i, top[i]),
          ],
        );
      },
    );
  }

  Widget _leaderboardItem(int index, AppUser user) {
    const medals = ['🥇', '🥈', '🥉'];
    final isPodium = index < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPodium ? _gold.withOpacity(0.5) : Colors.white10,
          width: isPodium ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              isPodium ? medals[index] : '${index + 1}.',
              style: TextStyle(
                fontSize: isPodium ? 22 : 16,
                fontWeight: FontWeight.w900,
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cream,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Ø ${user.averageRatingGiven.toStringAsFixed(1)}'
                  '${user.perfectPours > 0 ? '  ·  ${user.perfectPours}x Perfect Pour' : ''}'
                  '${user.currentStreak > 1 ? '  ·  ${user.currentStreak}🔥' : ''}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.totalReviews}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const Text(
                'PINTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- FEED ----------------

  Widget _buildFeed(Map<String, String> pubNames) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: _gold),
            ),
          );
        }

        final reviews = (snapshot.data?.docs ?? [])
            .map((doc) => Review.fromFirestore(doc, null))
            .toList();

        if (reviews.isEmpty) {
          return const Text(
            'Noch nichts los hier...',
            style: TextStyle(color: Colors.white38),
          );
        }

        return Column(
          children: reviews.map((r) => _feedItem(r, pubNames)).toList(),
        );
      },
    );
  }

  Widget _feedItem(Review review, Map<String, String> pubNames) {
    final pubName = review.pubName ?? pubNames[review.pubId] ?? 'Unknown Pub';
    final isHot = review.rating > 7.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review.primaryPhotoUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  review.primaryPhotoUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Feed-Foto konnte nicht geladen werden: $error');
                    return const SizedBox(width: 56, height: 56);
                  },
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    children: [
                      TextSpan(
                        text: review.userName ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _cream,
                        ),
                      ),
                      const TextSpan(text: ' hat im '),
                      TextSpan(
                        text: pubName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _cream,
                        ),
                      ),
                      const TextSpan(text: ' gezapft bekommen'),
                    ],
                  ),
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _timeAgo(review.createdAt),
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHot ? _gold.withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              review.rating.toStringAsFixed(1),
              style: TextStyle(
                color: isHot ? _gold : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    if (diff.inDays == 1) return 'gestern';
    return 'vor ${diff.inDays} Tagen';
  }
}
