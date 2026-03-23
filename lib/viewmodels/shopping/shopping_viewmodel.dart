import 'package:flutter/foundation.dart';
import '../../domain/entities/shopping_item.dart';
import '../../data/implementations/repositories/shopping_repository.dart';

class ShoppingViewmodel extends ChangeNotifier {
  final ShoppingRepository repo;
  final int userId;
  ShoppingViewmodel(this.repo, {required this.userId});

  List<ShoppingItem> _items = [];
  bool loading = false;
  String? error;

  List<ShoppingItem> get needToBuy => _items.where((i) => !i.isPurchased).toList();
  List<ShoppingItem> get alreadyBought => _items.where((i) => i.isPurchased).toList();

  Future<void> loadItems() async {
    loading = true;
    notifyListeners();
    try {
      _items = await repo.getItems(userId);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(ShoppingItem item) async {
    try {
      final saved = await repo.addItem(item.copyWith(userId: userId));
      _items.add(saved);
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateItem(ShoppingItem item) async {
    try {
      await repo.updateItem(item);
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) _items[idx] = item;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await repo.deleteItem(id);
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAsPurchased(int id, double actualPrice) async {
    try {
      await repo.markAsPurchased(id, actualPrice);
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(isPurchased: true, actualPrice: actualPrice);
      }
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
