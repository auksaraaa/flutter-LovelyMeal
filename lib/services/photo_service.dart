import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/photo_model.dart';

class PhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _photosCollection = 'user_photos';

  // Upload photo to Firebase Storage and save metadata to Firestore
  Future<PhotoModel> uploadPhoto({
    required String uid,
    required File photoFile,
    required String date, // Format: yyyy-MM-dd
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${photoFile.uri.pathSegments.last}';
      
      // Upload to Storage: users/{uid}/photos/{date}/{filename}
      final storageRef = _storage
          .ref()
          .child('users')
          .child(uid)
          .child(date)
          .child(fileName);

      await storageRef.putFile(photoFile);
      final storageUrl = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      final docRef = _firestore.collection(_photosCollection).doc();
      
      PhotoModel photoModel = PhotoModel(
        id: docRef.id,
        uid: uid,
        date: date,
        timestamp: timestamp,
        storageUrl: storageUrl,
        createdAt: DateTime.now(),
      );

      await docRef.set(photoModel.toMap());

      return photoModel;
    } catch (e) {
      throw 'ไม่สามารถอัปโหลดรูปภาพ: $e';
    }
  }

  // Get photos for a specific date
  Future<List<PhotoModel>> getPhotosByDate({
    required String uid,
    required String date,
  }) async {
    try {
      // Query by uid only, then filter by date in Dart to avoid composite index
      QuerySnapshot snapshot = await _firestore
          .collection(_photosCollection)
          .where('uid', isEqualTo: uid)
          .get();

      List<PhotoModel> photos = snapshot.docs
          .map((doc) =>
              PhotoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by date and sort by timestamp in app
      photos = photos
          .where((photo) => photo.date == date)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return photos;
    } catch (e) {
      throw 'ไม่สามารถดึงรูปภาพ: $e';
    }
  }

  // Get photos for a specific month
  Future<List<PhotoModel>> getPhotosByMonth({
    required String uid,
    required String yearMonth, // Format: yyyy-MM
  }) async {
    try {
      // Get all photos for the user first, then filter by month in Dart
      QuerySnapshot snapshot = await _firestore
          .collection(_photosCollection)
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<PhotoModel> photos = snapshot.docs
          .map((doc) =>
              PhotoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by month in Dart to avoid composite index issues
      List<PhotoModel> filteredPhotos = photos
          .where((photo) => photo.date.startsWith(yearMonth))
          .toList();

      return filteredPhotos;
    } catch (e) {
      throw 'ไม่สามารถดึงรูปภาพของเดือน: $e';
    }
  }

  // Get all photos for a user
  Future<List<PhotoModel>> getAllPhotos(String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_photosCollection)
          .where('uid', isEqualTo: uid)
          .orderBy('date', descending: true)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              PhotoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw 'ไม่สามารถดึงรูปภาพทั้งหมด: $e';
    }
  }



  // Stream photos for a specific date
  Stream<List<PhotoModel>> streamPhotosByDate({
    required String uid,
    required String date,
  }) {
    return _firestore
        .collection(_photosCollection)
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: date)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PhotoModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete photo from Firebase Storage and Firestore
  Future<void> deletePhoto(String photoId, String storageUrl) async {
    try {
      // Delete from Storage
      await FirebaseStorage.instance.refFromURL(storageUrl).delete();
      
      // Delete metadata from Firestore
      await _firestore.collection(_photosCollection).doc(photoId).delete();
    } catch (e) {
      throw 'ไม่สามารถลบรูปภาพ: $e';
    }
  }
}
