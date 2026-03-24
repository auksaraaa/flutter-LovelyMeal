class UserPreferences {
  final List<String> allergies;
  final List<String> disliked;
  final List<String> liked;

  const UserPreferences({
    this.allergies = const [],
    this.disliked = const [],
    this.liked = const [],
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      allergies: List<String>.from(map['allergies'] ?? []),
      disliked: List<String>.from(map['dislikes'] ?? []),
      liked: List<String>.from(map['likes'] ?? []),
    );
  }
}
