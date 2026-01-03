import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../screens/review_screen.dart';
import '../providers/review_provider.dart';
import 'package:provider/provider.dart';

class BrutalPubSheet extends StatelessWidget {
  final Pub pub;
  final VoidCallback onClose;

  const BrutalPubSheet({Key? key, required this.pub, required this.onClose})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔥 DER LIVE-STREAM: Wir hören direkt auf die 'reviews' Collection
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('pubId', isEqualTo: pub.id)
          // .orderBy('createdAt', descending: true) // Falls Index-Fehler kommt, erstmal weglassen
          .snapshots(),
      builder: (context, snapshot) {
        // 1. DATEN VERARBEITEN
        List<Review> liveReviews = [];
        if (snapshot.hasData) {
          liveReviews = snapshot.data!.docs.map((doc) {
            // Wir nutzen fromFirestore, müssen aber Data+ID übergeben
            // Da fromFirestore im Model etwas anders aufgebaut ist, nutzen wir hier einen schnellen Fix:
            final data = doc.data() as Map<String, dynamic>;
            // Wir nutzen fromJson, weil das einfacher ist für QuerySnapshot maps
            return Review.fromJson({
              ...data,
              'id': doc.id,
              // Timestamp Fix für JSON
              'createdAt':
                  (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
              'lastReviewDate': null, // Ignorieren wir hier
            });
          }).toList();

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
                              userId: "test_user",
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
        content: Text(
          review.comment.isNotEmpty ? review.comment : "No comment.",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
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
              ],
            ),
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
