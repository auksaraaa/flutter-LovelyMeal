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
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      likes: List<String>.from(map['likes'] ?? []),
      dislikes: List<String>.from(map['dislikes'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
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
