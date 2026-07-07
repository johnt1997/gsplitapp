import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../screens/review_screen.dart';
import '../providers/review_provider.dart';
import '../services/review_service.dart';
import 'package:provider/provider.dart';

class BrutalPubSheet extends StatelessWidget {
  final Pub pub;
  final VoidCallback onClose;

  const BrutalPubSheet({Key? key, required this.pub, required this.onClose})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔥 DER LIVE-STREAM: Wir hören direkt auf die 'reviews' Collection
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('pubId', isEqualTo: pub.id)
          // .orderBy('createdAt', descending: true) // Falls Index-Fehler kommt, erstmal weglassen
          .snapshots(),
      builder: (context, snapshot) {
        // 1. DATEN VERARBEITEN
        // fromFirestore versteht guinnessType als Int-Index und den
        // (direkt nach dem Posten noch null) serverTimestamp — fromJson nicht.
        List<Review> liveReviews = [];
        if (snapshot.hasData) {
          liveReviews = snapshot.data!.docs
              .map((doc) => Review.fromFirestore(doc, null))
              .toList();

          // Sortieren in Dart (verhindert Index-Fehler in Firebase)
          liveReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        // 2. STATISTIK LIVE BERECHNEN
        double avg = 0.0;
        if (liveReviews.isNotEmpty) {
          double sum = liveReviews.fold(0, (prev, r) => prev + r.rating);
          avg = sum / liveReviews.length;
        }

        bool isLegendary = avg >= 9.5;
        bool isHot = (avg > 7.5 || pub.isHot) && !isLegendary;
        Color statusColor = isLegendary
            ? const Color(0xFF50C878) // Grün
            : (isHot ? const Color(0xFFD4AF37) : Colors.white24); // Gold/Grau

        IconData statusIcon = isLegendary
            ? Icons.star
            : (isHot ? Icons.whatshot : Icons.store);

        String statusText = isLegendary
            ? "LEGENDARY"
            : (isHot ? "HOT SPOT" : "STANDARD");

        // 3. UI BAUEN
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // GRIFF
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // HEADER: NAME & CLOSE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pub.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF5E6D3),
                              letterSpacing: 1.5,
                              height: 1.1,
                              fontFamily: 'Oswald',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pub.address,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATS BOXEN (LIVE!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    // RATING BOX
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _showStatusDialog(
                          context,
                          statusText,
                          statusColor,
                          statusIcon,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // COUNT BOX
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${liveReviews.length}",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "REVIEWS",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // BESTES FOTO (höchstbewertetes Review mit Bild)
              _buildBestPhotoBanner(liveReviews),

              // RATE BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_a_photo, color: Colors.black),
                    label: const Text(
                      "RATE THIS PINT",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => ReviewProvider(),
                            child: ReviewScreen(
                              pubId: pub.id,
                              pubName: pub.name,
                              pubAddress: pub.address,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "LATEST POURS",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // LISTE (LIVE!)
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD4AF37),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: liveReviews.length,
                        itemBuilder: (context, index) {
                          final review = liveReviews[index];
                          return _buildReviewItem(context, review);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HILFSMETHODEN (Unverändert) ---

  void _showStatusDialog(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
  ) {
    String message = "";
    if (title == "LEGENDARY") {
      message = "This pub is serving perfection. A holy grail of Guinness.";
    } else if (title == "HOT SPOT") {
      message = "This place is on fire! Consistently great pints.";
    } else {
      message =
          "A standard pub. Good for a pint, but maybe not the best pour in town.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontFamily: 'Oswald'),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Ein Like pro User — Toggle über das likedBy-Array
  Widget _buildLikeButton(Review review) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final liked = uid != null && review.likedBy.contains(uid);

    return GestureDetector(
      onTap: uid == null ? null : () => _toggleLike(review, uid),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: liked ? const Color(0xFFD4AF37) : Colors.white38,
            ),
            const SizedBox(width: 4),
            Text(
              '${review.likedBy.length}',
              style: TextStyle(
                color: liked ? const Color(0xFFD4AF37) : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestPhotoBanner(List<Review> reviews) {
    final withPhoto = reviews.where((r) => r.primaryPhotoUrl != null).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    if (withPhoto.isEmpty) return const SizedBox.shrink();
    final best = withPhoto.first;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.network(
              best.primaryPhotoUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                  'Best-Pour-Foto konnte nicht geladen werden: $error',
                );
                return const SizedBox.shrink();
              },
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '📸 BEST POUR · ${best.rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bearbeiten/Löschen — nur für eigene Reviews sichtbar
  Widget _buildOwnerActions(BuildContext context, Review review) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || review.userId != uid) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showEditDialog(context, review),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Icon(Icons.edit_outlined, size: 16, color: Colors.white38),
          ),
        ),
        GestureDetector(
          onTap: () => _confirmDelete(context, review),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Icon(Icons.delete_outline, size: 16, color: Colors.white38),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        title: const Text(
          'REVIEW LÖSCHEN?',
          style: TextStyle(
            color: Color(0xFFF5E6D3),
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
              HapticFeedback.mediumImpact();
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

  void _showEditDialog(BuildContext context, Review review) {
    double rating = review.rating;
    final commentController = TextEditingController(text: review.comment);
    final priceController = TextEditingController(
      text: (review.price != null && review.price! > 0)
          ? review.price!.toStringAsFixed(2)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
          ),
          title: const Text(
            'EDIT REVIEW',
            style: TextStyle(
              color: Color(0xFFF5E6D3),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'RATING',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: rating,
                  min: 1.0,
                  max: 10.0,
                  divisions: 90,
                  activeColor: const Color(0xFFD4AF37),
                  inactiveColor: Colors.white10,
                  onChanged: (v) => setDialogState(() => rating = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFFF5E6D3)),
                  decoration: _editFieldDecoration('Kommentar'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Color(0xFFF5E6D3)),
                  decoration: _editFieldDecoration('Preis (€)'),
                ),
              ],
            ),
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
                HapticFeedback.mediumImpact();
                try {
                  await ReviewService().updateReview(
                    review,
                    rating: rating,
                    comment: commentController.text.trim(),
                    price: double.tryParse(
                      priceController.text.replaceAll(',', '.'),
                    ),
                  );
                } catch (e) {
                  debugPrint('Bearbeiten fehlgeschlagen: $e');
                }
              },
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _editFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF0D0D0D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white10),
      ),
    );
  }

  void _toggleLike(Review review, String uid) {
    HapticFeedback.lightImpact();
    final liked = review.likedBy.contains(uid);
    FirebaseFirestore.instance.collection('reviews').doc(review.id).update({
      'likedBy': liked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      'likes': FieldValue.increment(liked ? -1 : 1),
    });
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
  }

  void _showReviewDetails(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        title: Row(
          children: [
            Text(
              "RATING: ${review.rating}",
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontFamily: 'Oswald',
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (review.rating > 7.5)
              const Icon(Icons.whatshot, color: Color(0xFFD4AF37)),
          ],
        ),
        // Feste Breite: width:infinity im Bild bricht sonst die
        // Intrinsic-Width-Berechnung des AlertDialogs (isFinite-Assertion)
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review.primaryPhotoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.primaryPhotoUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Bild ausblenden, aber Fehler sichtbar loggen (z.B. CORS auf Web)
                      debugPrint(
                        'Review-Foto konnte nicht geladen werden: $error',
                      );
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                "${(review.userName ?? 'Anonymous')} — ${_formatDate(review.createdAt)}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                review.comment.isNotEmpty ? review.comment : "No comment.",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    bool isPerfect = review.rating >= 9.5;
    bool isHot = review.rating > 7.5 && !isPerfect;

    return GestureDetector(
      onTap: () => _showReviewDetails(context, review),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: isPerfect
              ? Border.all(color: Colors.green.withOpacity(0.3))
              : (isHot
                    ? Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      )
                    : null),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPerfect
                        ? Colors.green.withOpacity(0.2)
                        : (isHot
                              ? const Color(0xFFD4AF37).withOpacity(0.2)
                              : Colors.white10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: isPerfect
                              ? Colors.green
                              : (isHot
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (isHot || isPerfect) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isPerfect ? Icons.star : Icons.whatshot,
                          color: isPerfect
                              ? Colors.green
                              : const Color(0xFFD4AF37),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
                // WER & WANN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (review.userName ?? 'ANONYMOUS').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFF5E6D3),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(review.createdAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.primaryPhotoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  review.primaryPhotoUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Bild ausblenden, aber Fehler sichtbar loggen (z.B. CORS auf Web)
                    debugPrint(
                      'Review-Foto konnte nicht geladen werden: $error',
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (review.price != null && review.price! > 0) ...[
                  Icon(Icons.euro, size: 12, color: Colors.white38),
                  Text(
                    review.price!.toStringAsFixed(2),
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  SizedBox(width: 8),
                ],
                if (review.guinnessType != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      review.guinnessType.toString().split('.').last,
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                const Spacer(),
                _buildOwnerActions(context, review),
                _buildLikeButton(review),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFF5E6D3), height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
