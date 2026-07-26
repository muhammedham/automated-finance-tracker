import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/transaction_repository.dart';

// New AsyncNotifierProvider replacing the old FutureProvider
final categoriesProvider = AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final repository = await ref.read(transactionRepositoryProvider.future);
    return repository.getCategories();
  }

  Future<void> addCategory(String name, String type, String color) async {
    final repository = await ref.read(transactionRepositoryProvider.future);
    await repository.insertCategory(name, type, color);
    ref.invalidateSelf(); // Triggers rebuild
  }

  Future<void> removeCategory(int id) async {
    final repository = await ref.read(transactionRepositoryProvider.future);
    await repository.deleteCategory(id);
    ref.invalidateSelf(); // Triggers rebuild
  }
}