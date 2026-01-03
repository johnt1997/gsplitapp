// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map json) => AppUser(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  photoUrl: json['photoUrl'] as String?,
  createdAt: const DateTimeConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  badgeIds:
      (json['badgeIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  stats:
      (json['stats'] as Map?)?.map((k, e) => MapEntry(k as String, e)) ??
      const {},
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  lastReviewDate: const DateTimeNullableConverter().fromJson(
    (json['lastReviewDate'] as num?)?.toInt(),
  ),
  visitedPubIds:
      (json['visitedPubIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  favoritePubIds:
      (json['favoritePubIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  friends:
      (json['friends'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'badgeIds': instance.badgeIds,
  'stats': instance.stats,
  'currentStreak': instance.currentStreak,
  'lastReviewDate': const DateTimeNullableConverter().toJson(
    instance.lastReviewDate,
  ),
  'visitedPubIds': instance.visitedPubIds,
  'favoritePubIds': instance.favoritePubIds,
  'friends': instance.friends,
};

Pub _$PubFromJson(Map json) => Pub(
  id: json['id'] as String,
  name: json['name'] as String,
  location: const GeoPointConverter().fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  address: json['address'] as String,
  googlePlaceId: json['googlePlaceId'] as String?,
  averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
  reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  isVerified: json['isVerified'] as bool? ?? false,
  lastReviewAt: const DateTimeNullableConverter().fromJson(
    (json['lastReviewAt'] as num?)?.toInt(),
  ),
  isHot: json['isHot'] as bool? ?? false,
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  reviews:
      (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ??
      const [],
  openingHours: (json['openingHours'] as Map?)?.map(
    (k, e) => MapEntry(k as String, e),
  ),
  availableTypes:
      (json['availableTypes'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$GuinnessTypeEnumMap, e))
          .toList() ??
      const [GuinnessType.DRAUGHT],
  description: json['description'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  website: json['website'] as String?,
);

Map<String, dynamic> _$PubToJson(Pub instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'reviews': instance.reviews.map((e) => e.toJson()).toList(),
  'location': const GeoPointConverter().toJson(instance.location),
  'address': instance.address,
  'googlePlaceId': instance.googlePlaceId,
  'averageRating': instance.averageRating,
  'reviewCount': instance.reviewCount,
  'isVerified': instance.isVerified,
  'lastReviewAt': const DateTimeNullableConverter().toJson(
    instance.lastReviewAt,
  ),
  'isHot': instance.isHot,
  'photos': instance.photos,
  'openingHours': instance.openingHours,
  'availableTypes': instance.availableTypes
      .map((e) => _$GuinnessTypeEnumMap[e]!)
      .toList(),
  'description': instance.description,
  'phoneNumber': instance.phoneNumber,
  'website': instance.website,
};

const _$GuinnessTypeEnumMap = {
  GuinnessType.DRAUGHT: 'DRAUGHT',
  GuinnessType.EXTRA_STOUT: 'EXTRA_STOUT',
  GuinnessType.FOREIGN_EXTRA: 'FOREIGN_EXTRA',
  GuinnessType.NITRO: 'NITRO',
  GuinnessType.ORIGINAL: 'ORIGINAL',
  GuinnessType.SPECIAL: 'SPECIAL',
};

Review _$ReviewFromJson(Map json) => Review(
  id: json['id'] as String,
  userId: json['userId'] as String,
  pubId: json['pubId'] as String,
  rating: (json['rating'] as num).toDouble(),
  comment: json['comment'] as String,
  shtickRating: (json['shtickRating'] as num).toDouble(),
  presentationRating: (json['presentationRating'] as num).toDouble(),
  text: json['text'] as String?,
  photoUrls:
      (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isPerfectPour: json['isPerfectPour'] as bool? ?? false,
  aiColorScore: (json['aiColorScore'] as num?)?.toDouble(),
  createdAt: const DateTimeConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  isPublic: json['isPublic'] as bool? ?? true,
  guinnessType: $enumDecodeNullable(
    _$GuinnessTypeEnumMap,
    json['guinnessType'],
  ),
  price: (json['price'] as num?)?.toDouble(),
  servingStyle: json['servingStyle'] as String?,
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'pubId': instance.pubId,
  'rating': instance.rating,
  'comment': instance.comment,
  'shtickRating': instance.shtickRating,
  'presentationRating': instance.presentationRating,
  'text': instance.text,
  'photoUrls': instance.photoUrls,
  'isPerfectPour': instance.isPerfectPour,
  'aiColorScore': instance.aiColorScore,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'likes': instance.likes,
  'isPublic': instance.isPublic,
  'guinnessType': _$GuinnessTypeEnumMap[instance.guinnessType],
  'price': instance.price,
  'servingStyle': instance.servingStyle,
};

Badge _$BadgeFromJson(Map json) => Badge(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  iconPath: json['iconPath'] as String,
  colorArgb: (json['colorArgb'] as num).toInt(),
  tier: (json['tier'] as num).toInt(),
  type: $enumDecode(_$BadgeTypeEnumMap, json['type']),
  requirement: Map<String, dynamic>.from(json['requirement'] as Map),
);

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'iconPath': instance.iconPath,
  'colorArgb': instance.colorArgb,
  'tier': instance.tier,
  'type': _$BadgeTypeEnumMap[instance.type]!,
  'requirement': instance.requirement,
};

const _$BadgeTypeEnumMap = {
  BadgeType.PASSPORT: 'PASSPORT',
  BadgeType.VARIETY: 'VARIETY',
  BadgeType.QUALITY: 'QUALITY',
  BadgeType.LOCATION: 'LOCATION',
  BadgeType.TIMING: 'TIMING',
  BadgeType.SPECIAL: 'SPECIAL',
};

CachedReview _$CachedReviewFromJson(Map json) => CachedReview(
  id: json['id'] as String,
  userId: json['userId'] as String,
  pubId: json['pubId'] as String,
  rating: (json['rating'] as num).toDouble(),
  comment: json['comment'] as String,
  shtickRating: (json['shtickRating'] as num).toDouble(),
  presentationRating: (json['presentationRating'] as num).toDouble(),
  text: json['text'] as String?,
  localImagePath: json['localImagePath'] as String?,
  isPerfectPour: json['isPerfectPour'] as bool? ?? false,
  aiColorScore: (json['aiColorScore'] as num?)?.toDouble(),
  createdAt: const DateTimeConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  isSynced: json['isSynced'] as bool? ?? false,
  syncAttempts: (json['syncAttempts'] as num?)?.toInt() ?? 0,
  lastSyncAttempt: const DateTimeNullableConverter().fromJson(
    (json['lastSyncAttempt'] as num?)?.toInt(),
  ),
  syncError: json['syncError'] as String?,
);

Map<String, dynamic> _$CachedReviewToJson(CachedReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'pubId': instance.pubId,
      'rating': instance.rating,
      'comment': instance.comment,
      'shtickRating': instance.shtickRating,
      'presentationRating': instance.presentationRating,
      'text': instance.text,
      'localImagePath': instance.localImagePath,
      'isPerfectPour': instance.isPerfectPour,
      'aiColorScore': instance.aiColorScore,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'isSynced': instance.isSynced,
      'syncAttempts': instance.syncAttempts,
      'lastSyncAttempt': const DateTimeNullableConverter().toJson(
        instance.lastSyncAttempt,
      ),
      'syncError': instance.syncError,
    };
