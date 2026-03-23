import 'package:sqflite/sqflite.dart';
import '../../../dtos/shopping/shopping_item_dto.dart';
import '../../local/app_database.dart';

class ShoppingApi {
  final AppDatabase database;
  ShoppingApi(this.database);

  Future<List<ShoppingItemDto>> getAll(int userId) async {
    final db = await database.db;
    final rows = await db.query(
      'shopping_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'category, id',
    );
    return rows.map(ShoppingItemDto.fromMap).toList();
  }

  Future<ShoppingItemDto> insert(ShoppingItemDto dto) async {
    final db = await database.db;
    final id = await db.insert('shopping_items', dto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return dto.copyWith(id: id);
  }

  Future<void> update(ShoppingItemDto dto) async {
    final db = await database.db;
    await db.update('shopping_items', dto.toMap(),
        where: 'id = ?', whereArgs: [dto.id]);
  }

  Future<void> delete(int id) async {
    final db = await database.db;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsPurchased(int id, double actualPrice) async {
    final db = await database.db;
    await db.update(
      'shopping_items',
      {'is_purchased': 1, 'actual_price': actualPrice},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
