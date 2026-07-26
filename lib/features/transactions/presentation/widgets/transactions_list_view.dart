import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/rising_route.dart';
import '../../domain/transaction_notifier.dart';
import '../../domain/category_notifier.dart';
import '../manual_entry_screen.dart';

/// Renders the transaction ledger with swipe-to-delete and tap-to-edit.
///
/// Used two places:
/// - On the dashboard's compact "Recent transactions" card, with
///   [limit] set to a handful of rows and [dense] true.
/// - On [AllTransactionsScreen], full-size, unlimited, scrollable on its
///   own.
///
/// Keeping this as one widget means both places can never drift apart.
class TransactionsListView extends ConsumerWidget {
  final int? limit;
  final bool dense;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const TransactionsListView({
    super.key,
    this.limit,
    this.dense = false,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No transactions found for this period.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.offWhiteDim(0.5)),
              ),
            ),
          );
        }

        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error loading categories: $e')),
          data: (categories) {
            final categoryMap = {for (var c in categories) c.id: c.name};
            final items = (limit != null && transactions.length > limit!)
                ? transactions.sublist(0, limit!)
                : transactions;

            return ListView.builder(
              padding: EdgeInsets.only(bottom: dense ? 4 : 16),
              physics: physics,
              shrinkWrap: shrinkWrap,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final tx = items[index];
                final amountDisplay = (tx.amount / 100).toStringAsFixed(2);
                final dateDisplay = DateFormat('MMM dd, yyyy').format(tx.date);
                final categoryName = categoryMap[tx.categoryId] ??
                    (tx.isAutomated ? 'Bank Transfers' : 'Category #${tx.categoryId}');
                final titleText = (tx.note != null && tx.note!.isNotEmpty) ? tx.note! : categoryName;
                final isIncome = tx.categoryId == 2;

                final transactionCard = _TransactionTile(
                  title: titleText,
                  categoryName: categoryName,
                  dateDisplay: dateDisplay,
                  amountDisplay: amountDisplay,
                  isIncome: isIncome,
                  isAutomated: tx.isAutomated,
                  dense: dense,
                  onTap: tx.isAutomated
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            risingRoute(ManualEntryScreen(existingTransaction: tx)),
                          );
                        },
                );

                if (tx.isAutomated) {
                  return transactionCard;
                }

                return Dismissible(
                  key: ValueKey(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16.0, vertical: dense ? 5.0 : 7.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC97B86), Color(0xFF8E4A54)],
                      ),
                      borderRadius: BorderRadius.circular(dense ? 14 : 20),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22.0),
                    child: const Icon(Icons.delete_outline, color: AppColors.offWhite, size: 26),
                  ),
                  onDismissed: (direction) async {
                    if (tx.id != null) {
                      try {
                        await ref.read(transactionsProvider.notifier).deleteEntry(tx.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction deleted.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                          ref.invalidate(transactionsProvider);
                        }
                      }
                    }
                  },
                  child: transactionCard,
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading ledger: $e')),
    );
  }
}

/// A single transaction row. In [dense] mode (used inside the dashboard's
/// side-by-side card) it drops its own outer margin and shrinks paddings
/// and font sizes to fit a narrower column; otherwise it's the original
/// full-width row.
class _TransactionTile extends StatefulWidget {
  final String title;
  final String categoryName;
  final String dateDisplay;
  final String amountDisplay;
  final bool isIncome;
  final bool isAutomated;
  final bool dense;
  final VoidCallback? onTap;

  const _TransactionTile({
    required this.title,
    required this.categoryName,
    required this.dateDisplay,
    required this.amountDisplay,
    required this.isIncome,
    required this.isAutomated,
    required this.onTap,
    this.dense = false,
  });

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  double _scale = 1.0;

  void _setPressed(bool pressed) => setState(() => _scale = pressed ? 0.98 : 1.0);

  @override
  Widget build(BuildContext context) {
    final accent = widget.isIncome ? AppColors.sage : AppColors.mauve;
    final dense = widget.dense;

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16.0, vertical: dense ? 5.0 : 6.0),
          padding: EdgeInsets.all(dense ? 10 : 16),
          decoration: BoxDecoration(
            gradient: AppGradients.tile,
            borderRadius: BorderRadius.circular(dense ? 14 : 20),
            border: Border(left: BorderSide(color: accent, width: dense ? 2.5 : 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!dense)
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.plum, shape: BoxShape.circle),
                  child: Icon(
                    widget.isAutomated ? Icons.mark_email_read_outlined : Icons.receipt_long_outlined,
                    size: 19,
                    color: AppColors.offWhiteDim(0.85),
                  ),
                ),
              if (!dense) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: dense
                          ? TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.offWhite,
                            )
                          : Theme.of(context).textTheme.titleMedium,
                      maxLines: dense ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: dense ? 3 : 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.categoryName,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: dense ? 10.5 : 12,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!dense) ...[
                          Text('  •  ', style: TextStyle(color: AppColors.offWhiteDim(0.3))),
                          Text(widget.dateDisplay, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: dense ? 6 : 8),
              Text(
                '₺ ${widget.amountDisplay}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 12.5 : 16,
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
