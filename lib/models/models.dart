import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:json_annotation/json_annotation.dart';
import 'dart:math';

part 'models.g.dart';

// ============= CUSTOM CONVERTERS =============
class GeoPointConverter
    implements JsonConverter<GeoPoint, Map<String, dynamic>> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(GeoPoint geoPoint) {
    return {'latitude': geoPoint.latitude, 'longitude': geoPoint.longitude};
  }
}

class DateTimeConverter implements JsonConverter<DateTime, int> {
  const DateTimeConverter();

  @override
  DateTime fromJson(int timestamp) =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  int toJson(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
}

class DateTimeNullableConverter implements JsonConverter<DateTime?, int?> {
  const DateTimeNullableConverter();

  @override
  DateTime? fromJson(int? timestamp) =>
      timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  @override
  int? toJson(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;
}

// ============= ENUMS =============
enum BadgeType { PASSPORT, VARIETY, QUALITY, LOCATION, TIMING, SPECIAL }

enum GuinnessType {
  DRAUGHT,
  EXTRA_STOUT,
  FOREIGN_EXTRA,
  NITRO,
  ORIGINAL,
  SPECIAL,
}

// ============= USER MODEL =============
@JsonSerializable(explicitToJson: true)
class AppUser {
  String id;
  String email;
  String displayName;
  String? photoUrl;

  @DateTimeConverter()
  DateTime createdAt;

  List<String> badgeIds;
  Map<String, dynamic> stats;

  int currentStreak;

  @DateTimeNullableConverter()
  DateTime? lastReviewDate;

  List<String> visitedPubIds;
  List<String> favoritePubIds;
  List<String> friends;

  // Getter
  int get totalReviews => (stats['totalReviews'] as int?) ?? 0;
  double get totalRatingSum =>
      (stats['totalRatingSum'] as num?)?.toDouble() ?? 0.0;
  int get perfectPours => (stats['perfectPours'] as int?) ?? 0;
  int get longestStreak => (stats['longestStreak'] as int?) ?? 0;

  double get averageRatingGiven {
    return totalReviews > 0 ? totalRatingSum / totalReviews : 0.0;
  }

  bool get isValid {
    return email.contains('@') &&
        displayName.isNotEmpty &&
        displayName.length >= 2;
  }

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.badgeIds = const [],
    this.stats = const {},
    this.currentStreak = 0,
    this.lastReviewDate,
    this.visitedPubIds = const [],
    this.favoritePubIds = const [],
    this.friends = const [],
  });

  void updateStatsAfterReview(double rating, bool isPerfectPour) {
    stats['totalReviews'] = totalReviews + 1;
    stats['totalRatingSum'] = totalRatingSum + rating;

    if (isPerfectPour) {
      stats['perfectPours'] = perfectPours + 1;
    }

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (lastReviewDate != null &&
        lastReviewDate!.year == yesterday.year &&
        lastReviewDate!.month == yesterday.month &&
        lastReviewDate!.day == yesterday.day) {
      currentStreak++;
    } else if (lastReviewDate == null || lastReviewDate!.isBefore(yesterday)) {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) {
      stats['longestStreak'] = currentStreak;
    }

    lastReviewDate = now;
  }

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return AppUser(
      id: snapshot.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Guinness Enthusiast',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      badgeIds: List<String>.from(data['badgeIds'] ?? []),
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      currentStreak: data['currentStreak'] ?? 0,
      lastReviewDate: data['lastReviewDate'] != null
          ? (data['lastReviewDate'] as Timestamp).toDate()
          : null,
      visitedPubIds: List<String>.from(data['visitedPubIds'] ?? []),
      favoritePubIds: List<String>.from(data['favoritePubIds'] ?? []),
      friends: List<String>.from(data['friends'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'badgeIds': badgeIds,
      'stats': stats,
      'currentStreak': currentStreak,
      'lastReviewDate': lastReviewDate != null
          ? Timestamp.fromDate(lastReviewDate!)
          : null,
      'visitedPubIds': visitedPubIds,
      'favoritePubIds': favoritePubIds,
      'friends': friends,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);
}

// ============= PUB MODEL =============
@JsonSerializable(explicitToJson: true)
class Pub {
  String id;
  String name;
  final List<Review> reviews;
  @GeoPointConverter()
  GeoPoint location;

  String address;
  String? googlePlaceId;
  double averageRating;
  int reviewCount;
  bool isVerified;

  @DateTimeNullableConverter()
  DateTime? lastReviewAt;

  bool isHot;
  List<String> photos;
  Map<String, dynamic>? openingHours;
  List<GuinnessType> availableTypes;
  String? description;
  String? phoneNumber;
  String? website;

  bool get isValid {
    return name.isNotEmpty &&
        address.isNotEmpty &&
        location.latitude.abs() <= 90 &&
        location.longitude.abs() <= 180;
  }

  Pub({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    this.googlePlaceId,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.lastReviewAt,
    this.isHot = false,
    this.photos = const [],
    this.reviews = const [],
    this.openingHours,
    this.availableTypes = const [GuinnessType.DRAUGHT],
    this.description,
    this.phoneNumber,
    this.website,
  });

  void markAsHot() {
    isHot = true;
    lastReviewAt = DateTime.now();
  }

  void updateRating(double newRating) {
    final totalRating = averageRating * reviewCount;
    reviewCount++;
    averageRating = (totalRating + newRating) / reviewCount;

    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    if (lastReviewAt == null || lastReviewAt!.isBefore(weekAgo)) {
      isHot = false;
    }
  }

  double distanceTo(GeoPoint userLocation) {
    const earthRadius = 6371.0;
    final lat1 = userLocation.latitude * (pi / 180.0);
    final lon1 = userLocation.longitude * (pi / 180.0);
    final lat2 = location.latitude * (pi / 180.0);
    final lon2 = location.longitude * (pi / 180.0);
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  String? get primaryPhoto => photos.isNotEmpty ? photos.first : null;
  latlong.LatLng get latLng =>
      latlong.LatLng(location.latitude, location.longitude);

  factory Pub.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Pub(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Pub',
      location: data['location'],
      address: data['address'] ?? '',
      googlePlaceId: data['googlePlaceId'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      lastReviewAt: data['lastReviewAt'] != null
          ? (data['lastReviewAt'] as Timestamp).toDate()
          : null,
      isHot: data['isHot'] ?? false,
      photos: List<String>.from(data['photos'] ?? []),
      openingHours: data['openingHours'],
      availableTypes:
          (data['availableTypes'] as List<dynamic>?)
              ?.map((type) => GuinnessType.values[type as int])
              .toList() ??
          [GuinnessType.DRAUGHT],
      description: data['description'],
      phoneNumber: data['phoneNumber'],
      website: data['website'],
      // Hinweis: Reviews sind in Firestore meist eine Subcollection
      // und werden separat geladen. Hier initialisieren wir leer.
      reviews: [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'address': address,
      'googlePlaceId': googlePlaceId,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'lastReviewAt': lastReviewAt != null
          ? Timestamp.fromDate(lastReviewAt!)
          : null,
      'isHot': isHot,
      'photos': photos,
      'openingHours': openingHours,
      'availableTypes': availableTypes.map((type) => type.index).toList(),
      'description': description,
      'phoneNumber': phoneNumber,
      'website': website,
    };
  }

  factory Pub.fromJson(Map<String, dynamic> json) => _$PubFromJson(json);
  Map<String, dynamic> toJson() => _$PubToJson(this);
}

// ============= REVIEW MODEL =============
@JsonSerializable(explicitToJson: true)
class Review {
  String id;
  String userId;
  String pubId;
  final double rating;
  final String comment;
  double shtickRating;
  double presentationRating;
  String? text;
  List<String> photoUrls;
  bool isPerfectPour;
  double? aiColorScore;

  @DateTimeConverter()
  DateTime createdAt;

  int likes;
  bool isPublic;
  GuinnessType? guinnessType;
  double? price;
  String? servingStyle;

  bool get isValid {
    return shtickRating >= 1 &&
        shtickRating <= 10 &&
        presentationRating >= 1 &&
        presentationRating <= 10 &&
        (text == null || text!.length <= 280) &&
        userId.isNotEmpty &&
        pubId.isNotEmpty;
  }

  double get overallRating => (shtickRating + presentationRating) / 2;

  Review({
    required this.id,
    required this.userId,
    required this.pubId,
    required this.rating,
    required this.comment,
    required this.shtickRating,
    required this.presentationRating,
    this.text,
    this.photoUrls = const [],
    this.isPerfectPour = false,
    this.aiColorScore,
    required this.createdAt,
    this.likes = 0,
    this.isPublic = true,
    this.guinnessType,
    this.price,
    this.servingStyle,
  });

  void setAIScore(double score) {
    aiColorScore = score;
    isPerfectPour = score >= 8.5;
  }

  String? get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  factory Review.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Review(
      id: snapshot.id,
      userId: data['userId'],
      pubId: data['pubId'],
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      shtickRating: (data['shtickRating'] as num? ?? 0.0).toDouble(),
      presentationRating: (data['presentationRating'] as num? ?? 0.0)
          .toDouble(),
      text: data['text'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      isPerfectPour: data['isPerfectPour'] ?? false,
      aiColorScore: (data['aiColorScore'] as num? ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: (data['likes'] as num? ?? 0).toInt(),
      isPublic: data['isPublic'] ?? true,
      guinnessType: data['guinnessType'] != null
          ? GuinnessType.values[data['guinnessType'] as int]
          : null,
      price: (data['price'] ?? 0.0).toDouble(),
      servingStyle: data['servingStyle'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pubId': pubId,
      'rating': rating,
      'comment': comment,
      'shtickRating': shtickRating,
      'presentationRating': presentationRating,
      'text': text,
      'photoUrls': photoUrls,
      'isPerfectPour': isPerfectPour,
      'aiColorScore': aiColorScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'isPublic': isPublic,
      'guinnessType': guinnessType?.index,
      'price': price,
      'servingStyle': servingStyle,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}

// ============= BADGE MODEL =============
@JsonSerializable(explicitToJson: true)
class Badge {
  String id;
  String name;
  String description;
  String iconPath;
  int colorArgb;
  int tier;
  BadgeType type;
  Map<String, dynamic> requirement;

  Color get color => Color(colorArgb);

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.colorArgb,
    required this.tier,
    required this.type,
    required this.requirement,
  });

  bool checkUnlock(Map<String, dynamic> userStats, AppUser user) {
    switch (type) {
      case BadgeType.PASSPORT:
        final requiredPubs = requirement['requiredPubs'] as int? ?? 0;
        return user.visitedPubIds.length >= requiredPubs;
      case BadgeType.VARIETY:
        final requiredTypes = requirement['requiredTypes'] as int? ?? 0;
        final userTypes = (user.stats['guinnessTypes'] as int?) ?? 0;
        return userTypes >= requiredTypes;
      case BadgeType.QUALITY:
        if (name.contains('Connoisseur')) {
          return user.averageRatingGiven >= 8.0;
        } else if (name.contains('Critic')) {
          return user.averageRatingGiven < 5.0;
        } else if (name.contains('Perfect Pour Master')) {
          final requiredCount = requirement['count'] as int? ?? 10;
          return user.perfectPours >= requiredCount;
        }
        return false;
      case BadgeType.LOCATION:
        final requiredLocation = requirement['location'] as String? ?? '';
        final requiredCount = requirement['count'] as int? ?? 0;
        final locationKey = 'location_${requiredLocation.toLowerCase()}';
        final userVisits = (user.stats[locationKey] as int?) ?? 0;
        return userVisits >= requiredCount;
      case BadgeType.TIMING:
        if (name.contains('Early Bird')) {
          final earlyReviews = (user.stats['earlyReviews'] as int?) ?? 0;
          return earlyReviews >= (requirement['count'] as int? ?? 5);
        } else if (name.contains('Night Owl')) {
          final nightReviews = (user.stats['nightReviews'] as int?) ?? 0;
          return nightReviews >= (requirement['count'] as int? ?? 5);
        } else if (name.contains('Streak Master')) {
          final requiredDays = requirement['days'] as int? ?? 7;
          return user.currentStreak >= requiredDays;
        }
        return false;
      case BadgeType.SPECIAL:
        return false;
      default:
        return false;
    }
  }

  factory Badge.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Badge(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Badge',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? 'assets/badges/default.png',
      colorArgb: data['color'] ?? 0xFFD4AF37,
      tier: data['tier'] ?? 1,
      type: BadgeType.values[data['type'] as int],
      requirement: Map<String, dynamic>.from(data['requirement'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'color': colorArgb,
      'tier': tier,
      'type': type.index,
      'requirement': requirement,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

// ============= CACHED REVIEW =============
@JsonSerializable()
class CachedReview {
  String id;
  String userId;
  String pubId;
  // --- HIER WURDEN DIE FELDER HINZUGEFÜGT ---
  double rating;
  String comment;
  // ----------------------------------------
  double shtickRating;
  double presentationRating;
  String? text;
  String? localImagePath;
  bool isPerfectPour;
  double? aiColorScore;

  @DateTimeConverter()
  DateTime createdAt;

  bool isSynced;
  int syncAttempts;

  @DateTimeNullableConverter()
  DateTime? lastSyncAttempt;

  String? syncError;

  bool get shouldRetry {
    if (isSynced) return false;
    if (syncAttempts >= 3) return false;
    if (lastSyncAttempt == null) return true;
    final backoffMinutes = pow(2, syncAttempts).toInt();
    final nextRetry = lastSyncAttempt!.add(Duration(minutes: backoffMinutes));
    return DateTime.now().isAfter(nextRetry);
  }

  void markSyncAttempt(String? error) {
    syncAttempts++;
    lastSyncAttempt = DateTime.now();
    syncError = error;
  }

  void markAsSynced() {
    isSynced = true;
    syncError = null;
  }

  CachedReview({
    required this.id,
    required this.userId,
    required this.pubId,
    required this.rating, // <-- Neu
    required this.comment, // <-- Neu
    required this.shtickRating,
    required this.presentationRating,
    this.text,
    this.localImagePath,
    this.isPerfectPour = false,
    this.aiColorScore,
    required this.createdAt,
    this.isSynced = false,
    this.syncAttempts = 0,
    this.lastSyncAttempt,
    this.syncError,
  });

  // Konvertiert Cache -> Echter Review (für Upload)
  Review toReview(List<String> photoUrls) {
    return Review(
      id: id,
      userId: userId,
      pubId: pubId,
      rating: rating, // <-- Neu
      comment: comment, // <-- Neu
      shtickRating: shtickRating,
      presentationRating: presentationRating,
      text: text,
      photoUrls: photoUrls,
      isPerfectPour: isPerfectPour,
      aiColorScore: aiColorScore,
      createdAt: createdAt,
      likes: 0,
      isPublic: true,
    );
  }

  // Erstellt Cache aus echtem Review (für Speicherung)
  static CachedReview fromReview(Review review, String localImagePath) {
    return CachedReview(
      id: review.id,
      userId: review.userId,
      pubId: review.pubId,
      rating: review.rating, // <-- Neu
      comment: review.comment, // <-- Neu
      shtickRating: review.shtickRating,
      presentationRating: review.presentationRating,
      text: review.text,
      localImagePath: localImagePath,
      isPerfectPour: review.isPerfectPour,
      aiColorScore: review.aiColorScore,
      createdAt: review.createdAt,
      isSynced: false,
      syncAttempts: 0,
      lastSyncAttempt: null,
      syncError: null,
    );
  }

  factory CachedReview.fromJson(Map<String, dynamic> json) =>
      _$CachedReviewFromJson(json);
  Map<String, dynamic> toJson() => _$CachedReviewToJson(this);
}
