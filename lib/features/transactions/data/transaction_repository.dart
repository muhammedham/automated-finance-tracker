import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import 'models/transaction_model.dart';
import 'models/category_model.dart';

// Provides the repository instance, waiting for the DB to initialize
final transactionRepositoryProvider = FutureProvider<TransactionRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TransactionRepository(db);
});

class TransactionRepository {
  final Database _db;

  TransactionRepository(this._db);

  Future<List<TransactionModel>> getTransactions({int limit = 50, int offset = 0}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<void> insertCategory(String name, String type, String color) async {
    await _db.insert('categories', {
      'name': name,
      'type': type,
      'color': color,
      'is_deleted': 0, // New categories are active by default
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    // Perform soft delete
    await _db.update(
      'categories', 
      {'is_deleted': 1}, 
      where: 'id = ?', 
      whereArgs: [categoryId]
    );
  }

  Future<void> insertManualTransaction(TransactionModel transaction) async {
    await _db.transaction((txn) async {
      // 1. Insert the transaction
      await txn.insert('transactions', transaction.toMap());

      // 2. Fetch the category type to determine math (+ or -)
      final categoryData = await txn.query(
        'categories',
        columns: ['type'],
        where: 'id = ?',
        whereArgs: [transaction.categoryId],
      );

      if (categoryData.isEmpty) throw Exception('Category not found');
      
      final isIncome = categoryData.first['type'] == 'INCOME';
      final balanceAdjustment = isIncome ? transaction.amount : -transaction.amount;

      // 3. Update the account balance securely
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [balanceAdjustment, transaction.accountId],
      );
    });
  }
  
  Future<void> deleteTransaction(int transactionId) async {
    await _db.transaction((txn) async {
      // 1. Fetch the transaction details before deleting it
      final txList = await txn.query(
        'transactions', 
        where: 'id = ?', 
        whereArgs: [transactionId],
      );
      
      if (txList.isEmpty) return; // Transaction doesn't exist
      
      final txData = txList.first;
      final amount = txData['amount'] as int;
      final accountId = txData['account_id'] as int;
      final categoryId = txData['category_id'] as int;

      // 2. Determine if we need to add or subtract from the balance
      final catList = await txn.query(
        'categories', 
        columns: ['type'], 
        where: 'id = ?', 
        whereArgs: [categoryId],
      );
      
      if (catList.isEmpty) throw Exception('Category not found');
      
      final isIncome = catList.first['type'] == 'INCOME';
      
      // 3. Reverse the logic: Submitting income added to balance, so deleting it subtracts.
      final balanceAdjustment = isIncome ? -amount : amount;

      // 4. Update the account balance
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [balanceAdjustment, accountId],
      );

      // 5. Finally, permanently delete the transaction
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<int> getTodayTotalExpenses() async {
    final now = DateTime.now();
    // Create strict boundary strings for today
    final startStr = DateTime(now.year, now.month, now.day).toIso8601String();
    final endStr = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    final result = await _db.rawQuery('''
      SELECT SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date <= ? AND c.type = 'EXPENSE'
    ''', [startStr, endStr]);

    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<CategoryModel>> getCategories() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'categories',
      where: 'is_deleted = 0',
    );
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<void> updateTransaction(TransactionModel newTx) async {
    await _db.transaction((txn) async {
      // 1. Fetch the old transaction to reverse its effect
      final oldTxList = await txn.query(
        'transactions', 
        where: 'id = ?', 
        whereArgs: [newTx.id],
      );
      if (oldTxList.isEmpty) throw Exception('Transaction not found');
      
      final oldTx = oldTxList.first;
      final oldAmount = oldTx['amount'] as int;
      final oldAccountId = oldTx['account_id'] as int;
      final oldCategoryId = oldTx['category_id'] as int;

      // 2. Fetch old category type to determine math (+ or -)
      final oldCatList = await txn.query(
        'categories', columns: ['type'], where: 'id = ?', whereArgs: [oldCategoryId]
      );
      final isOldIncome = oldCatList.first['type'] == 'INCOME';

      // 3. Reverse the old transaction's effect on the balance
      final revertAdjustment = isOldIncome ? -oldAmount : oldAmount;
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [revertAdjustment, oldAccountId],
      );

      // 4. Fetch new category type
      final newCatList = await txn.query(
        'categories', columns: ['type'], where: 'id = ?', whereArgs: [newTx.categoryId]
      );
      final isNewIncome = newCatList.first['type'] == 'INCOME';

      // 5. Apply the new transaction's effect on the balance
      final applyAdjustment = isNewIncome ? newTx.amount : -newTx.amount;
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [applyAdjustment, newTx.accountId],
      );

      // 6. Finally, update the transaction ledger
      await txn.update(
        'transactions',
        newTx.toMap(),
        where: 'id = ?',
        whereArgs: [newTx.id],
      );
    });
  }

  Future<Map<String, int>> getDashboardTotals(DateTime startDate, DateTime endDate) async {
    // SQLite can lexicographically compare ISO8601 strings perfectly
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final List<Map<String, dynamic>> result = await _db.rawQuery('''
      SELECT c.type, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date <= ?
      GROUP BY c.type
    ''', [startStr, endStr]);

    int totalIncome = 0;
    int totalExpense = 0;

    for (var row in result) {
      final type = row['type'] as String;
      
    
      final total = (row['total'] as num?)?.toInt() ?? 0; 
      
      if (type == 'INCOME') totalIncome = total;
      if (type == 'EXPENSE') totalExpense = total;
    }

    return {'income': totalIncome, 'expense': totalExpense};
  }
}