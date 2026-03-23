import '../../../domain/entities/shopping_item.dart';

class ShoppingItemDto {
  final int? id;
  final int userId;
  final String name;
  final int quantity;
  final String unit;
  final String category;
  final double estimatedPrice;
  final bool isPurchased;
  final double? actualPrice;

  const ShoppingItemDto({
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

  ShoppingItemDto copyWith({
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
    return ShoppingItemDto(
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

  factory ShoppingItemDto.fromMap(Map<String, dynamic> map) {
    return ShoppingItemDto(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      name: (map['name'] ?? '').toString(),
      quantity: (map['quantity'] as int?) ?? 1,
      unit: (map['unit'] ?? 'cái').toString(),
      category: (map['category'] ?? 'Khác').toString(),
      estimatedPrice: (map['estimated_price'] as num?)?.toDouble() ?? 0,
      isPurchased: (map['is_purchased'] as int?) == 1,
      actualPrice: (map['actual_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'estimated_price': estimatedPrice,
    'is_purchased': isPurchased ? 1 : 0,
    'actual_price': actualPrice,
  };

  ShoppingItem toEntity() => ShoppingItem(
    id: id,
    userId: userId,
    name: name,
    quantity: quantity,
    unit: unit,
    category: category,
    estimatedPrice: estimatedPrice,
    isPurchased: isPurchased,
    actualPrice: actualPrice,
  );

  static ShoppingItemDto fromEntity(ShoppingItem e) => ShoppingItemDto(
    id: e.id,
    userId: e.userId,
    name: e.name,
    quantity: e.quantity,
    unit: e.unit,
    category: e.category,
    estimatedPrice: e.estimatedPrice,
    isPurchased: e.isPurchased,
    actualPrice: e.actualPrice,
  );
}
