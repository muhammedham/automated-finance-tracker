import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/transaction_notifier.dart';
import '../domain/category_notifier.dart';

// A palette-derived cycle of colors so the chart reads as part of the same
// system instead of dropping in default Material hues.
const List<Color> _chartColors = [
  AppColors.mauve,
  Color(0xFF6E5A6C), // deeper mauve/plum blend
  AppColors.sage,
  Color(0xFF5A6156), // deeper sage
  Color(0xFFC9B8C6), // light mauve tint
  AppColors.charcoal,
  Color(0xFF8A7488), // muted mauve-grey
  Color(0xFFA9AFA5), // light sage tint
];

/// The expenses-by-category donut chart.
///
/// - `compact: false` (default): the original full-width layout — a
///   150x150 donut side-by-side with its legend, wrapped in its own card.
///   Kept for anywhere this widget might be reused full-width.
/// - `compact: true`: a vertical layout with a smaller donut on top and
///   a scrollable legend beneath it, and no outer card chrome of its own
///   (the caller supplies the card) — sized to sit in the dashboard's
///   side-by-side "Overview" row next to Recent Transactions.
class ExpensePieChart extends ConsumerWidget {
  final bool compact;

  const ExpensePieChart({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Error loading chart: $e')),
      ),
      data: (transactions) {
        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text('Error loading categories: $e')),
          ),
          data: (categories) {
            final categoryMap = {for (var c in categories) c.id: c};
            final Map<int, int> totalsByCategory = {};

            for (final tx in transactions) {
              final category = categoryMap[tx.categoryId];
              if (category != null && category.type == 'EXPENSE') {
                totalsByCategory.update(
                  tx.categoryId,
                  (value) => value + tx.amount,
                  ifAbsent: () => tx.amount,
                );
              }
            }

            if (totalsByCategory.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No expenses to show for this period.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.offWhiteDim(0.5)),
                  ),
                ),
              );
            }

            final grandTotal = totalsByCategory.values.fold<int>(0, (a, b) => a + b);
            final sortedEntries = totalsByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final sections = <PieChartSectionData>[];
            final legendItems = <Widget>[];

            for (var i = 0; i < sortedEntries.length; i++) {
              final entry = sortedEntries[i];
              final category = categoryMap[entry.key];
              final categoryName = category?.name ?? 'Category #${entry.key}';
              final color = _chartColors[i % _chartColors.length];
              final percentage = (entry.value / grandTotal) * 100;

              sections.add(
                PieChartSectionData(
                  value: entry.value.toDouble(),
                  color: color,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: compact ? 34 : 58,
                  titleStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              );

              legendItems.add(
                Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 3.0 : 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 8 : 10,
                        height: compact ? 8 : 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: compact ? 11 : 13,
                            color: AppColors.offWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₺ ${(entry.value / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.offWhiteDim(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (compact) {
              return Column(
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: legendItems),
                    ),
                  ),
                ],
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: AppGradients.tile,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.offWhiteDim(0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: legendItems,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
