import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../domain/transaction_notifier.dart';
import '../domain/category_notifier.dart';
import '../data/models/transaction_model.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;

  const ManualEntryScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int _selectedAccountId = 1;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _amountController.text = (tx.amount / 100).toStringAsFixed(2);
      _selectedAccountId = tx.accountId;
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
      _noteController.text = tx.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.replaceAll(',', '.');
    final enteredAmount = double.tryParse(amountStr);

    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    try {
      if (widget.existingTransaction == null) {
        await ref.read(transactionsProvider.notifier).addManualEntry(
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId!,
          enteredAmount: enteredAmount,
          date: _selectedDate,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
      } else {
        await ref.read(transactionsProvider.notifier).editManualEntry(
          transactionId: widget.existingTransaction!.id!,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId!,
          enteredAmount: enteredAmount,
          date: _selectedDate,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingTransaction == null
              ? 'Transaction saved successfully!'
              : 'Transaction updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel('Amount'),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.offWhite,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  prefixText: '₺  ',
                  prefixStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mauve,
                  ),
                  hintText: '0.00',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _FieldLabel('Account'),
              DropdownButtonFormField<int>(
                initialValue: _selectedAccountId,
                dropdownColor: AppColors.plumElevated,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Cash Wallet')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              _FieldLabel('Category'),
              Consumer(
                builder: (context, ref, child) {
                  final categoriesAsync = ref.watch(categoriesProvider);

                  return categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) {
                        return Text(
                          'No categories found. Please add one first.',
                          style: TextStyle(color: AppColors.offWhiteDim(0.5)),
                        );
                      }

                      final validIds = categories.map((c) => c.id).toList();

                      if (_selectedCategoryId == null || !validIds.contains(_selectedCategoryId)) {
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (mounted) setState(() => _selectedCategoryId = validIds.first);
                         });
                      }

                      return DropdownButtonFormField<int>(
                        initialValue: validIds.contains(_selectedCategoryId) ? _selectedCategoryId : validIds.first,
                        dropdownColor: AppColors.plumElevated,
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => Text('Error loading categories: $e'),
                  );
                },
              ),
              const SizedBox(height: 20),

              _FieldLabel('Date'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(color: AppColors.offWhite, fontSize: 15),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.offWhiteDim(0.6)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _FieldLabel('Note (optional)'),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.offWhite),
                decoration: const InputDecoration(
                  hintText: 'Add a memo…',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              GradientButton(
                onPressed: _saveTransaction,
                icon: isEditing ? Icons.check : Icons.add,
                label: isEditing ? 'Update Transaction' : 'Save Transaction',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.offWhiteDim(0.5),
        ),
      ),
    );
  }
}
