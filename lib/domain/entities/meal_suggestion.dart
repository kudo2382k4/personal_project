class MealIngredient {
  final String item;
  final String quantity;
  final String unit;

  const MealIngredient({
    required this.item,
    required this.quantity,
    required this.unit,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      item: json['item'] as String? ?? '',
      quantity: json['quantity']?.toString() ?? '',
      unit: json['unit'] as String? ?? '',
    );
  }
}

class MealSuggestion {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<MealIngredient> mainIngredients;

  const MealSuggestion({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.mainIngredients,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['main_ingredients'] as List<dynamic>? ?? [];
    return MealSuggestion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      mainIngredients: rawIngredients
          .map((e) => MealIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Danh sách tên nguyên liệu (để so sánh với shopping list)
  List<String> get ingredientNames =>
      mainIngredients.map((e) => e.item).toList();
}
