import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_notifier.dart';
import '../../transactions/domain/category_notifier.dart';

enum DateFilter { thisWeek, lastWeek, thisMonth, lastMonth, custom }

class DateRange {
  final DateTime start;
  final DateTime end;
  final DateFilter filterType;

  DateRange(this.start, this.end, this.filterType);
}

// 1. Manages the currently selected date filter
final dateFilterProvider = NotifierProvider<DateFilterNotifier, DateRange>(() {
  return DateFilterNotifier();
});

class DateFilterNotifier extends Notifier<DateRange> {
  @override
  DateRange build() {
    return _calculateRange(DateFilter.thisMonth); // Default view
  }

  void setFilter(DateFilter filter, {DateTime? customStart, DateTime? customEnd}) {
    if (filter == DateFilter.custom && customStart != null && customEnd != null) {
      state = DateRange(customStart, customEnd, filter);
    } else {
      state = _calculateRange(filter);
    }
  }

  DateRange _calculateRange(DateFilter filter) {
    final now = DateTime.now();
    DateTime start, end;

    switch (filter) {
      case DateFilter.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
        break;
      case DateFilter.lastWeek:
        start = now.subtract(Duration(days: now.weekday + 6));
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
        break;
      case DateFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateFilter.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case DateFilter.custom:
        start = now; end = now; // Handled dynamically above
        break;
    }
    return DateRange(start, end, filter);
  }
}

// 2. Fetches the totals from SQLite whenever the date filter OR the transactions change
final dashboardTotalsProvider = FutureProvider<Map<String, int>>((ref) async {
  final dateRange = ref.watch(dateFilterProvider);
  
  // By watching the transactionsProvider, this recalculates automatically 
  // whenever a new transaction is added via the Manual Entry Screen!
  ref.watch(transactionsProvider); 

  final repository = await ref.read(transactionRepositoryProvider.future);
  return repository.getDashboardTotals(dateRange.start, dateRange.end);
});

// Provider that aggregates expenses by category
final expensesByCategoryProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final transactionsState = ref.watch(transactionsProvider);
  final categoriesState = ref.watch(categoriesProvider);

  // 1. Handle Loading States
  if (transactionsState.isLoading || categoriesState.isLoading) {
    return const AsyncValue.loading();
  }

  // 2. Handle Error States
  if (transactionsState.hasError) {
    return AsyncValue.error(transactionsState.error!, transactionsState.stackTrace!);
  }
  if (categoriesState.hasError) {
    return AsyncValue.error(categoriesState.error!, categoriesState.stackTrace!);
  }

  // 3. Process Data
  final transactions = transactionsState.value!;
  final categories = categoriesState.value!;

  // Create an O(1) lookup map for categories
  final categoryMap = {for (var c in categories) c.id: c};
  final Map<String, double> expenseTotals = {};

  for (final tx in transactions) {
    final category = categoryMap[tx.categoryId];
    // Filter strictly for EXPENSE types
    if (category != null && category.type == 'EXPENSE') {
      final amountInStandard = tx.amount / 100; // Convert kuruş to standard
      expenseTotals[category.name] = (expenseTotals[category.name] ?? 0) + amountInStandard;
    }
  }

  return AsyncValue.data(expenseTotals);
});