import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Create user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw 'ไม่สามารถบันทึกข้อมูลผู้ใช้: $e';
    }
  }

  // Get user from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
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
      await _firestore
          .collection(_usersCollection)
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
      await _firestore.collection(_usersCollection).doc(uid).update(fields);
    } catch (e) {
      throw 'ไม่สามารถอัปเดตข้อมูลผู้ใช้: $e';
    }
  }

  // Delete user from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw 'ไม่สามารถลบข้อมูลผู้ใช้: $e';
    }
  }

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get all users (for admin purposes)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
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
      await _firestore.collection(_usersCollection).doc(uid).update({
        'likes': likes,
        'dislikes': dislikes,
        'allergies': allergies,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'ไม่สามารถอัปเดตข้อมูลอาหาร: $e';
    }
  }
}
