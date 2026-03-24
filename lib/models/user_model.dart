import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final List<String> likes;
  final List<String> dislikes;
  final List<String> allergies;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.likes = const [],
    this.dislikes = const [],
    this.allergies = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'likes': likes,
      'dislikes': dislikes,
      'allergies': allergies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final preferences = map['preferences'] is Map<String, dynamic>
        ? map['preferences'] as Map<String, dynamic>
        : <String, dynamic>{};

    final likesRaw =
        map['likes'] ??
        map['liked'] ??
        preferences['likes'] ??
        preferences['liked'];
    final dislikesRaw =
        map['dislikes'] ??
        map['disliked'] ??
        preferences['dislikes'] ??
        preferences['disliked'];
    final allergiesRaw = map['allergies'] ?? preferences['allergies'];

    return UserModel(
      uid: map['uid'] ?? map['userId'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? map['displayName'] ?? map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? map['photoURL'] ?? map['avatarUrl'],
      likes: _toStringList(likesRaw),
      dislikes: _toStringList(dislikesRaw),
      allergies: _toStringList(allergiesRaw),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // CopyWith method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    List<String>? likes,
    List<String>? dislikes,
    List<String>? allergies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
