import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/email/imap_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/ziraat_parser.dart';
import '../../budget/domain/budget_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_notifier.dart';
import '../../transactions/domain/category_notifier.dart';

final emailSyncProvider = AsyncNotifierProvider<EmailSyncNotifier, void>(() {
  return EmailSyncNotifier();
});

class EmailSyncNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> syncBankEmails(String email, String appPassword) async {
    state = const AsyncValue.loading();
    int newlyAddedCount = 0;

    try {
      final imapService = ref.read(imapServiceProvider);
      final transactionRepo = await ref.read(transactionRepositoryProvider.future);

      // --- THE FINAL FIX: FIND OR CREATE 'Bank Transfers' ---
      var categories = await transactionRepo.getCategories();
      
      // 1. Setup Outgoing (Expense) - Look for 'Bank Transfers'
      var outgoingCat = categories.where((c) => c.name == 'Bank Transfers' && c.type == 'EXPENSE').firstOrNull;
      if (outgoingCat == null) {
        await transactionRepo.insertCategory('Bank Transfers', 'EXPENSE', '#607D8B');
        categories = await transactionRepo.getCategories(); // Refresh DB
        outgoingCat = categories.where((c) => c.name == 'Bank Transfers' && c.type == 'EXPENSE').firstOrNull;
      }
      int outgoingId = outgoingCat?.id ?? 1; 
      
      // 2. Setup Incoming (Income) - Look for 'Bank Transfers'
      var incomingCat = categories.where((c) => c.name == 'Bank Transfers' && c.type == 'INCOME').firstOrNull;
      if (incomingCat == null) {
        await transactionRepo.insertCategory('Bank Transfers', 'INCOME', '#4CAF50');
        categories = await transactionRepo.getCategories(); // Refresh DB
        incomingCat = categories.where((c) => c.name == 'Bank Transfers' && c.type == 'INCOME').firstOrNull;
      }
      int incomingId = incomingCat?.id ?? 2; 
      // --------------------------------------------------------

      final emailBodies = await imapService.fetchUnreadZiraatEmails(
        email: email,
        appPassword: appPassword,
        imapServer: 'imap.gmail.com', 
      );

      for (final body in emailBodies) {
        final transaction = ZiraatParser.parseDekont(body, 1, incomingId, outgoingId);
        
        if (transaction != null) {
          await transactionRepo.insertManualTransaction(transaction);
          newlyAddedCount++;
        }
      }

      if (newlyAddedCount > 0) {
        ref.invalidate(transactionsProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(categoriesProvider); // <-- Add this! (Or whatever your categories provider is named)

        final limitAsync = ref.read(dailyLimitProvider);
        final limit = limitAsync.value ?? 0.0;

        if (limit > 0) {
          final todayExpensesMinor = await transactionRepo.getTodayTotalExpenses();
          if ((todayExpensesMinor / 100) > limit) {
            await ref.read(notificationServiceProvider).showLimitAlert(limit);
          }
        }
      }

      state = const AsyncValue.data(null);
      return newlyAddedCount;
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}