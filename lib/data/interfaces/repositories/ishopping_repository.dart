import '../../../domain/entities/shopping_item.dart';

abstract class IShoppingRepository {
  Future<List<ShoppingItem>> getItems(int userId);
  Future<ShoppingItem> addItem(ShoppingItem item);
  Future<void> updateItem(ShoppingItem item);
  Future<void> deleteItem(int id);
  Future<void> markAsPurchased(int id, double actualPrice);
}
