import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  String get usersCollectionName => 'users';
  String get foodCollectionName => 'food';
  String get favoritesCollectionName => 'favorites';

  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection(usersCollectionName);

  CollectionReference<Map<String, dynamic>> get foodCollection =>
      firestore.collection(foodCollectionName);

  CollectionReference<Map<String, dynamic>> get favoritesCollection =>
      firestore.collection(favoritesCollectionName);

  // Create user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await firestore
          .collection(usersCollectionName)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw 'ไม่สามารถบันทึกข้อมูลผู้ใช้: $e';
    }
  }

  // Get user from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await firestore
          .collection(usersCollectionName)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'ไม่สามารถดึงข้อมูลผู้ใช้: $e';
    }
  }

  // Update user in Firestore
  Future<void> updateUser(UserModel user) async {
    try {
      await firestore
          .collection(usersCollectionName)
          .doc(user.uid)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw 'ไม่สามารถอัปเดตข้อมูลผู้ใช้: $e';
    }
  }

  // Update specific user fields - เพิ่ม method นี้
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = DateTime.now().toIso8601String();
      await usersCollection.doc(uid).update(fields);
    } catch (e) {
      throw 'ไม่สามารถอัปเดตข้อมูลผู้ใช้: $e';
    }
  }

  // Delete user from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
    } catch (e) {
      throw 'ไม่สามารถลบข้อมูลผู้ใช้: $e';
    }
  }

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    return usersCollection.doc(uid).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      final fallback = await usersCollection
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (fallback.docs.isNotEmpty) {
        return UserModel.fromMap(fallback.docs.first.data());
      }

      return null;
    });
  }

  // Stream user data with flexible matching for legacy schemas.
  Stream<UserModel?> streamUserFlexible({required String uid, String? email}) {
    return usersCollection.doc(uid).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      if (email != null && email.isNotEmpty) {
        try {
          final emailDoc = await firestore
              .collection(usersCollectionName)
              .doc(email)
              .get();
          if (emailDoc.exists) {
            return UserModel.fromMap(emailDoc.data() as Map<String, dynamic>);
          }
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
        }
      }

      try {
        final fallback = await firestore
            .collection(usersCollectionName)
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (fallback.docs.isNotEmpty) {
          return UserModel.fromMap(fallback.docs.first.data());
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }

      return null;
    });
  }

  // Get all users (for admin purposes)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await firestore
          .collection(usersCollectionName)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'ไม่สามารถดึงข้อมูลผู้ใช้ทั้งหมด: $e';
    }
  }

  // Update user food preferences
  Future<void> updateFoodPreferences({
    required String uid,
    required List<String> likes,
    required List<String> dislikes,
    required List<String> allergies,
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final userRef = usersCollection.doc(uid);
      final historyRef = userRef.collection('food_preferences_history').doc();

      final batch = firestore.batch();
      batch.update(userRef, {
        'likes': likes,
        'dislikes': dislikes,
        'allergies': allergies,
        'updatedAt': nowIso,
      });
      batch.set(historyRef, {
        'likes': likes,
        'dislikes': dislikes,
        'allergies': allergies,
        'createdAt': nowIso,
      });

      await batch.commit();
    } catch (e) {
      throw 'ไม่สามารถอัปเดตข้อมูลอาหาร: $e';
    }
  }

  // Read ingredient options from Firestore collection `food` using only `ingredients` field.
  Future<List<String>> getIngredients() async {
    try {
      final snapshot = await foodCollection.get();
      final ingredients = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final rawIngredients = data['ingredients'];
        if (rawIngredients is Iterable) {
          for (final item in rawIngredients) {
            if (item is String && item.trim().isNotEmpty) {
              ingredients.add(item.trim());
            }
          }
        } else if (rawIngredients is String &&
            rawIngredients.trim().isNotEmpty) {
          final splitItems = rawIngredients
              .split(RegExp(r'[,\n]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty);
          ingredients.addAll(splitItems);
        }
      }

      final result = ingredients.toList()..sort();
      if (result.isEmpty) {
        throw 'ไม่พบข้อมูล ingredients ในคอลเลกชัน food';
      }
      return result;
    } catch (e) {
      throw 'ไม่สามารถโหลด ingredients จากคอลเลกชัน food: $e';
    }
  }
}
