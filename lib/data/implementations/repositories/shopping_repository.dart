import '../../../domain/entities/shopping_item.dart';
import '../../../data/interfaces/repositories/ishopping_repository.dart';
import '../../dtos/shopping/shopping_item_dto.dart';
import '../api/shopping/shopping_api.dart';

class ShoppingRepository implements IShoppingRepository {
  final ShoppingApi _api;
  ShoppingRepository(this._api);

  @override
  Future<List<ShoppingItem>> getItems(int userId) async {
    final dtos = await _api.getAll(userId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<ShoppingItem> addItem(ShoppingItem item) async {
    final dto = await _api.insert(ShoppingItemDto.fromEntity(item));
    return dto.toEntity();
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    await _api.update(ShoppingItemDto.fromEntity(item));
  }

  @override
  Future<void> deleteItem(int id) async {
    await _api.delete(id);
  }

  @override
  Future<void> markAsPurchased(int id, double actualPrice) async {
    await _api.markAsPurchased(id, actualPrice);
  }
}
