class FoodItem {
  final String name;
  final String category; // ประเภทอาหาร
  final List<String> ingredients; // วัตถุดิบทั้งหมด (แยกจาก string)
  final List<String> matchedIngredients; // วัตถุดิบที่ match กับที่ค้น
  final List<String> instructions; // วิธีทำอาหาร
  final int matchCount;

  FoodItem({
    required this.name,
    required this.category,
    required this.ingredients,
    this.matchedIngredients = const [],
    this.instructions = const [],
    this.matchCount = 0,
  });

  static List<String> _toStringList(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return rawValue
          .split(RegExp(r'\r?\n|\.|;|[,、]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  /// FastAPI คืน ingredients เป็น String ("ไข่, แป้ง, น้ำมัน")
  /// และ matched_ingredients เป็น List[str]
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // ingredients อาจเป็น String หรือ List ก็ได้
    final rawIng = json['ingredients'];
    final List<String> ingList = rawIng is List
        ? List<String>.from(rawIng)
        : (rawIng as String? ?? '')
              .split(RegExp(r'[,、 ]+'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

    final categoryText = (json['category'] ?? '').toString().trim();
    final categoryLooksLikeInstruction =
        categoryText.startsWith('วิธีทำ') || categoryText.contains('วิธีทำ:');

    final rawInstructions =
        json['instructions'] ??
        json['method'] ??
        json['steps'] ??
        json['recipe'] ??
        json['cooking_steps'] ??
        json['how_to_cook'] ??
        json['วิธีทำ'] ??
        (categoryLooksLikeInstruction ? categoryText : null);

    return FoodItem(
      name: json['name'] ?? '',
      category: categoryLooksLikeInstruction ? '' : categoryText,
      ingredients: ingList,
      matchedIngredients: List<String>.from(json['matched_ingredients'] ?? []),
      instructions: _toStringList(rawInstructions),
      matchCount: (json['match_count'] as int?) ?? 0,
    );
  }
}
