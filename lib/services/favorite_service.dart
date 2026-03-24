import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/food_model.dart';
import 'database_service.dart';

class FavoriteService {
  static final DatabaseService _databaseService = DatabaseService();

  static String _resolveUserId(String userId) {
    final inputUserId = userId.trim();
    final authUserId = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

    if (authUserId.isNotEmpty &&
        inputUserId.isNotEmpty &&
        inputUserId != authUserId) {
      debugPrint(
        '⚠️ FavoriteService userId mismatch input=$inputUserId auth=$authUserId, using auth uid',
      );
    }

    if (authUserId.isNotEmpty) return authUserId;
    return inputUserId;
  }

  static Set<String> _extractIdsFromList(dynamic raw) {
    final ids = <String>{};
    if (raw is! List) return ids;

    for (final item in raw) {
      if (item is String || item is num) {
        final id = item.toString().trim();
        if (id.isNotEmpty) ids.add(id);
        continue;
      }

      if (item is Map) {
        final rawId = item['id'] ?? item['foodId'] ?? item['food_id'];
        final id = rawId?.toString().trim() ?? '';
        if (id.isNotEmpty) ids.add(id);

        final rawName = item['name'] ?? item['title'];
        final name = rawName?.toString().trim() ?? '';
        if (name.isNotEmpty) ids.add(name);
      }
    }

    return ids;
  }

  static List<Map<String, dynamic>> _extractItemsFromData(
    Map<String, dynamic>? data,
  ) {
    final rawItems = data?['items'];
    if (rawItems is! List) return <Map<String, dynamic>>[];

    final items = <Map<String, dynamic>>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(Map<String, dynamic>.from(item));
      } else if (item is Map) {
        items.add(Map<String, dynamic>.from(item));
      }
    }
    return items;
  }

  static Set<String> _extractIdsFromData(Map<String, dynamic>? data) {
    final ids = <String>{};
    if (data == null) return ids;

    ids.addAll(_extractIdsFromList(data['items']));
    ids.addAll(_extractIdsFromList(data['foodIds']));
    ids.addAll(_extractIdsFromList(data['favorites']));

    final singleId = data['id'] ?? data['foodId'] ?? data['food_id'];
    final singleIdText = singleId?.toString().trim() ?? '';
    if (singleIdText.isNotEmpty) {
      ids.add(singleIdText);
    }

    return ids;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Future<Set<String>> getFavoriteIds(String userId) async {
    final normalizedUserId = _resolveUserId(userId);
    if (normalizedUserId.isEmpty) return <String>{};

    final ids = <String>{};

    try {
      final favoritesDoc = await _databaseService.favoritesCollection
          .doc(normalizedUserId)
          .get();
      ids.addAll(_extractIdsFromData(_asMap(favoritesDoc.data())));
    } catch (_) {
      // Ignore read failures from favorites document and continue.
    }

    // Optional compatibility with old schemas where doc id is not user uid.
    // These queries may be denied by strict rules, so failures are ignored.
    try {
      final byUserId = await _databaseService.favoritesCollection
          .where('userId', isEqualTo: normalizedUserId)
          .get();
      for (final doc in byUserId.docs) {
        ids.addAll(_extractIdsFromData(_asMap(doc.data())));
      }
    } catch (_) {
      // Ignore query failure under strict rules.
    }

    try {
      final byUid = await _databaseService.favoritesCollection
          .where('uid', isEqualTo: normalizedUserId)
          .get();
      for (final doc in byUid.docs) {
        ids.addAll(_extractIdsFromData(_asMap(doc.data())));
      }
    } catch (_) {
      // Ignore query failure under strict rules.
    }

    debugPrint('❤️ getFavoriteIds user=$normalizedUserId count=${ids.length}');

    return ids;
  }

  static Future<bool> isFavorite(String userId, String foodId) async {
    if (userId.trim().isEmpty || foodId.trim().isEmpty) return false;
    final ids = await getFavoriteIds(userId);
    return ids.contains(foodId);
  }

  static Future<void> addFavorite(String userId, FoodModel food) async {
    final normalizedUserId = _resolveUserId(userId);
    if (normalizedUserId.isEmpty || food.id.trim().isEmpty) return;

    debugPrint(
      '❤️ addFavorite user=$normalizedUserId foodId=${food.id} title=${food.title}',
    );

    final ids = await getFavoriteIds(normalizedUserId);
    ids.add(food.id);

    final favRef = _databaseService.favoritesCollection.doc(normalizedUserId);
    final currentItems = <Map<String, dynamic>>[];

    try {
      final favDoc = await favRef.get();
      currentItems.addAll(_extractItemsFromData(_asMap(favDoc.data())));
    } catch (_) {
      // Ignore read failure and continue with write attempt.
    }

    currentItems.removeWhere(
      (item) =>
          (item['id']?.toString().trim() ??
              item['foodId']?.toString().trim()) ==
          food.id,
    );
    currentItems.add(food.toFirestore());

    await favRef.set({
      'userId': normalizedUserId,
      'uid': normalizedUserId,
      'foodIds': ids.toList(growable: false),
      'items': currentItems,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint(
      '❤️ updated favorites/$normalizedUserId items=${currentItems.length}',
    );
  }

  static Future<void> removeFavorite(String userId, String foodId) async {
    final normalizedUserId = _resolveUserId(userId);
    if (normalizedUserId.isEmpty || foodId.trim().isEmpty) return;

    debugPrint('💔 removeFavorite user=$normalizedUserId foodId=$foodId');

    final ids = await getFavoriteIds(normalizedUserId);

    // ลบทั้ง ID และชื่อเมนอืออก
    final foodTitle = await _getFoodTitle(foodId);
    ids.remove(foodId);
    if (foodTitle.isNotEmpty) {
      ids.remove(foodTitle);
    }

    final favRef = _databaseService.favoritesCollection.doc(normalizedUserId);
    final currentItems = <Map<String, dynamic>>[];

    try {
      final favDoc = await favRef.get();
      currentItems.addAll(_extractItemsFromData(_asMap(favDoc.data())));
    } catch (_) {
      // Ignore read failure and continue with write attempt.
    }

    currentItems.removeWhere(
      (item) =>
          (item['id']?.toString().trim() ??
              item['foodId']?.toString().trim()) ==
          foodId,
    );

    await favRef.set({
      'userId': normalizedUserId,
      'uid': normalizedUserId,
      'foodIds': ids.toList(growable: false),
      'items': currentItems,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint(
      '💔 updated favorites/$normalizedUserId items=${currentItems.length}',
    );
  }

  static Future<String> _getFoodTitle(String foodId) async {
    try {
      final doc = await _databaseService.foodCollection.doc(foodId).get();
      if (doc.exists) {
        final data = _asMap(doc.data());
        return (data?['name'] ?? data?['title'] ?? '').toString().trim();
      }
    } catch (_) {
      // Ignore error
    }
    return '';
  }

  static Future<List<FoodModel>> getFavoriteFoods(String userId) async {
    final normalizedUserId = _resolveUserId(userId);
    final ids = await getFavoriteIds(normalizedUserId);
    debugPrint(
      '📋 getFavoriteFoods user=$normalizedUserId foodIds=${ids.length} items=$ids',
    );
    if (ids.isEmpty) return <FoodModel>[];

    final normalizedKeys = ids
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    final allFoodSnapshot = await _databaseService.foodCollection.get();
    final foods = <FoodModel>[];

    for (final doc in allFoodSnapshot.docs) {
      try {
        final food = FoodModel.fromFirestore(
          _asMap(doc.data()) ?? const <String, dynamic>{},
          doc.id,
        );

        final matches =
            normalizedKeys.contains(doc.id.trim().toLowerCase()) ||
            normalizedKeys.contains(food.title.trim().toLowerCase());
        if (!matches) continue;

        if (food.title.isNotEmpty) {
          foods.add(food);
          debugPrint(
            '  ✓ Found from food collection: ${food.id} - ${food.title}',
          );
        }
      } catch (_) {
        // Skip invalid docs and continue reading others.
      }
    }

    if (foods.isNotEmpty) {
      debugPrint(
        '✅ getFavoriteFoods: returned ${foods.length} from food collection',
      );
      return foods;
    }

    // Fallback: ใช้ items แต่ filter เฉพาะที่อยู่ใน foodIds
    debugPrint('⚠️ getFavoriteFoods: falling back to items in favorites doc');
    final favoritesDoc = await _databaseService.favoritesCollection
        .doc(normalizedUserId)
        .get();
    final fallbackItems = _extractItemsFromData(_asMap(favoritesDoc.data()));
    final result = fallbackItems
        .where((item) {
          final itemId = (item['id'] ?? item['foodId'])
              .toString()
              .trim()
              .toLowerCase();
          final isIncluded = normalizedKeys.contains(itemId);
          if (isIncluded) {
            debugPrint('  ✓ Fallback item: $itemId matches foodIds');
          }
          return isIncluded;
        })
        .map(
          (item) => FoodModel.fromFirestore(item, item['id']?.toString() ?? ''),
        )
        .where((food) => food.title.isNotEmpty)
        .toList();
    debugPrint(
      '✅ getFavoriteFoods: returned ${result.length} from fallback items',
    );
    return result;
  }
}
