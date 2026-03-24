class FoodModel {
  final String id;
  final String title;
  final List<String> category;
  final String image;
  final List<String> ingredients;
  final List<String> cooking;

  FoodModel({
    required this.id,
    required this.title,
    required this.category,
    required this.image,
    this.ingredients = const [],
    this.cooking = const [],
  });

  static String _toSafeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();

    if (value is List) {
      for (final item in value) {
        final text = _toSafeString(item);
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    if (value is Map) {
      const preferredKeys = ['url', 'image', 'src', 'name', 'title', 'value'];
      for (final key in preferredKeys) {
        if (value.containsKey(key)) {
          final text = _toSafeString(value[key]);
          if (text.isNotEmpty) return text;
        }
      }

      for (final entry in value.entries) {
        final text = _toSafeString(entry.value);
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return value.toString().trim();
  }

  static List<String> _toSafeStringList(dynamic value) {
    final result = <String>[];
    final seen = <String>{};

    void addText(String text) {
      final normalized = text.trim();
      if (normalized.isEmpty || seen.contains(normalized)) return;
      seen.add(normalized);
      result.add(normalized);
    }

    void collect(dynamic item) {
      if (item == null) return;

      if (item is String) {
        for (final part in item.split(',')) {
          addText(part);
        }
        return;
      }

      if (item is List) {
        for (final child in item) {
          collect(child);
        }
        return;
      }

      if (item is Map) {
        for (final child in item.values) {
          collect(child);
        }
        return;
      }

      addText(item.toString());
    }

    collect(value);
    return result;
  }

  factory FoodModel.fromFirestore(Map<String, dynamic> data, String id) {
    final titleFromName = _toSafeString(data['name']);
    final titleFromLegacy = _toSafeString(data['title']);
    final imageFromImage = _toSafeString(data['image']);
    final imageFromImages = _toSafeString(data['images']);

    final ingredientsList = _toSafeStringList(data['ingredients']);
    final categoryList = _toSafeStringList(data['category']);
    final cookingList = _toSafeStringList(data['cooking']);

    return FoodModel(
      id: id,
      title: titleFromName.isNotEmpty ? titleFromName : titleFromLegacy,
      category: categoryList,
      image: imageFromImage.isNotEmpty ? imageFromImage : imageFromImages,
      ingredients: ingredientsList,
      cooking: cookingList,
    );
  }

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    final ingredientsList = _toSafeStringList(json['ingredients']);
    final categoryList = _toSafeStringList(json['category']);
    final titleFromName = _toSafeString(json['name']);
    final titleFromLegacy = _toSafeString(json['title']);
    final image = _toSafeString(json['image']);
    final cookingList = _toSafeStringList(json['cooking']);

    return FoodModel(
      id: json['id']?.toString() ?? '',
      title: titleFromName.isNotEmpty ? titleFromName : titleFromLegacy,
      category: categoryList,
      image: image,
      ingredients: ingredientsList,
      cooking: cookingList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': title,
      'title': title,
      'category': category,
      'image': image,
      'ingredients': ingredients,
      'cooking': cooking,
    };
  }
}
