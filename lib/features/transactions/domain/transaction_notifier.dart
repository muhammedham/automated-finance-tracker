import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/transaction_repository.dart';
import '../../budget/domain/budget_provider.dart';
import '../../../core/notifications/notification_service.dart';

// The provider consumed by your UI
final transactionsProvider = AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
  return TransactionNotifier();
});



class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    return _fetchTransactions();
  }

  Future<List<TransactionModel>> _fetchTransactions() async {
    // Wait for the repository to be ready, then fetch data
    final repository = await ref.read(transactionRepositoryProvider.future);
    return repository.getTransactions();
  }

  Future<void> deleteEntry(int transactionId) async {
    try {
      final repository = await ref.read(transactionRepositoryProvider.future);
      await repository.deleteTransaction(transactionId);
      
      // Refresh the list, which seamlessly triggers a UI rebuild and dashboard update
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Future<void> addManualEntry({
    required int accountId,
    required int categoryId,
    required double enteredAmount, // E.g., 15.50 from UI input
    required DateTime date,
    String? note,
  }) async {
    // Convert UI decimal amount to minor units (integer) for the DB
    final int amountInMinorUnits = (enteredAmount * 100).round();

    final transaction = TransactionModel(
      accountId: accountId,
      categoryId: categoryId,
      amount: amountInMinorUnits,
      date: date,
      note: note,
      isAutomated: false, // Explicitly manual
    );
    
    
    try {
      final repository = await ref.read(transactionRepositoryProvider.future);
      await repository.insertManualTransaction(transaction);
      
      // Refresh the list to trigger a UI rebuild with the new data
      ref.invalidateSelf();

      await _checkBudgetLimit();
    } catch (e) {
      // In a production app, pass this to a logging service or UI snackbar
      throw Exception('Failed to add transaction: $e');
    } 
  }

  Future<void> editManualEntry({
    required int transactionId,
    required int accountId,
    required int categoryId,
    required double enteredAmount,
    required DateTime date,
    String? note,
  }) async {
    final int amountInMinorUnits = (enteredAmount * 100).round();

    final transaction = TransactionModel(
      id: transactionId,
      accountId: accountId,
      categoryId: categoryId,
      amount: amountInMinorUnits,
      date: date,
      note: note,
      isAutomated: false,
    );

    try {
      final repository = await ref.read(transactionRepositoryProvider.future);
      await repository.updateTransaction(transaction);
      // Refresh the list to trigger a UI rebuild and update the dashboard
      ref.invalidateSelf();

      await _checkBudgetLimit();
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> _checkBudgetLimit() async {
    final limitAsync = ref.read(dailyLimitProvider);
    final limit = limitAsync.value ?? 0.0;

    if (limit > 0) {
      final repository = await ref.read(transactionRepositoryProvider.future);
      final todayExpensesMinor = await repository.getTodayTotalExpenses();

      if ((todayExpensesMinor / 100) > limit) {
        await ref.read(notificationServiceProvider).showLimitAlert(limit);
      }
    }
  }
}

