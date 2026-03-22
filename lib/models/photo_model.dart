import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoModel {
  final String id;
  final String uid;
  final String date; // Format: yyyy-MM-dd
  final int timestamp;
  final String storageUrl;
  final DateTime createdAt;
  final bool? isFood; // null = not checked, true = food, false = not food
  final double? foodConfidence; // Confidence score (0.0-1.0)

  PhotoModel({
    required this.id,
    required this.uid,
    required this.date,
    required this.timestamp,
    required this.storageUrl,
    required this.createdAt,
    this.isFood,
    this.foodConfidence,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'date': date,
      'timestamp': timestamp,
      'storageUrl': storageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFood': isFood,
      'foodConfidence': foodConfidence,
    };
  }

  // Create PhotoModel from Firestore document
  factory PhotoModel.fromMap(Map<String, dynamic> map, String docId) {
    return PhotoModel(
      id: docId,
      uid: map['uid'] ?? '',
      date: map['date'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      storageUrl: map['storageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFood: map['isFood'] as bool?,
      foodConfidence: map['foodConfidence'] as double?,
    );
  }

  // Copy with method
  PhotoModel copyWith({
    String? id,
    String? uid,
    String? date,
    int? timestamp,
    String? storageUrl,
    DateTime? createdAt,
    bool? isFood,
    double? foodConfidence,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      storageUrl: storageUrl ?? this.storageUrl,
      createdAt: createdAt ?? this.createdAt,
      isFood: isFood ?? this.isFood,
      foodConfidence: foodConfidence ?? this.foodConfidence,
    );
  }
}
