import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../domain/category_notifier.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategorySheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isExpense = cat.type == 'EXPENSE';
            final accent = isExpense ? AppColors.mauve : AppColors.sage;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.plumElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: accent, width: 3)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(cat.name, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(
                  cat.type.substring(0, 1) + cat.type.substring(1).toLowerCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.offWhiteDim(0.5)),
                  onPressed: () => ref.read(categoriesProvider.notifier).removeCategory(cat.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'EXPENSE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.offWhiteDim(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
            ),
            Text('New category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.offWhite),
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: selectedType,
              dropdownColor: AppColors.plumElevated,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                DropdownMenuItem(value: 'INCOME', child: Text('Income')),
              ],
              onChanged: (val) => selectedType = val as String,
            ),
            const SizedBox(height: 20),
            GradientButton(
              icon: Icons.add,
              label: 'Save Category',
              onPressed: () async {
                await ref.read(categoriesProvider.notifier).addCategory(nameController.text, selectedType, '#2196F3');
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
