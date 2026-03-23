class ShoppingItem {
  final int? id;
  final int userId;
  final String name;
  final int quantity;
  final String unit;
  final String category;
  final double estimatedPrice;
  final bool isPurchased;
  final double? actualPrice;

  const ShoppingItem({
    this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.estimatedPrice,
    this.isPurchased = false,
    this.actualPrice,
  });

  double? get priceDifference =>
      actualPrice != null ? estimatedPrice - actualPrice! : null;

  ShoppingItem copyWith({
    int? id,
    int? userId,
    String? name,
    int? quantity,
    String? unit,
    String? category,
    double? estimatedPrice,
    bool? isPurchased,
    double? actualPrice,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isPurchased: isPurchased ?? this.isPurchased,
      actualPrice: actualPrice ?? this.actualPrice,
    );
  }
}
