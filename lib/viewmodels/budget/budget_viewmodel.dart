import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/implementations/local/app_database.dart';

class BudgetViewmodel extends ChangeNotifier {
  final int userId;
  BudgetViewmodel({required this.userId});

  double _budgetLimit = 0;
  bool loading = false;

  double get budgetLimit => _budgetLimit;

  Future<void> loadBudget() async {
    loading = true;
    notifyListeners();
    try {
      final db = await AppDatabase.instance.db;
      final rows = await db.query('budget', where: 'user_id = ?', whereArgs: [userId]);
      if (rows.isNotEmpty) {
        _budgetLimit = (rows.first['amount'] as num?)?.toDouble() ?? 0;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget(double amount) async {
    _budgetLimit = amount;
    notifyListeners();
    final db = await AppDatabase.instance.db;
    await db.insert(
      'budget',
      {'user_id': userId, 'amount': amount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
