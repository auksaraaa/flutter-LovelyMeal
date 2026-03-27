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

  static dynamic _pickFirst(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

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
    // รองรับ backend เดิม (ingredients) และรูปแบบใหม่จาก parse_metadata (subingredients)
    final rawIng = _pickFirst(json, [
      'ingredients',
      'subingredients',
      'ingredient',
    ]);
    final List<String> ingList = _toStringList(rawIng);

    final categoryText = (json['category'] ?? '').toString().trim();
    final categoryLooksLikeInstruction =
        categoryText.startsWith('วิธีทำ') || categoryText.contains('วิธีทำ:');

    final rawInstructions =
        json['instructions'] ??
        json['cooking'] ??
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
      matchedIngredients: _toStringList(
        _pickFirst(json, ['matched_ingredients', 'matchedIngredients']),
      ),
      instructions: _toStringList(rawInstructions),
      matchCount: (json['match_count'] as int?) ?? 0,
    );
  }
}
