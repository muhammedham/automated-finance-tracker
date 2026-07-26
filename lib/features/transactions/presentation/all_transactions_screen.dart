import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../dashboard/domain/dashboard_providers.dart';
import 'widgets/transactions_list_view.dart';

/// Reached from the dashboard's "Recent transactions" card via its
/// "View all" link. Shows the full, unlimited, scrollable ledger with the
/// same date filter pills and the same swipe-to-delete / tap-to-edit
/// behavior as before — just on its own page instead of eating the whole
/// dashboard.
class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key});

  Future<void> _selectCustomDate(BuildContext context, WidgetRef ref) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedRange != null) {
      ref.read(dateFilterProvider.notifier).setFilter(
            DateFilter.custom,
            customStart: pickedRange.start,
            customEnd: pickedRange.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All transactions')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: DateFilter.values.map((filter) {
                final isSelected = dateRange.filterType == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterPill(
                    label: filter.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' '),
                    selected: isSelected,
                    onTap: () {
                      if (filter == DateFilter.custom) {
                        _selectCustomDate(context, ref);
                      } else {
                        ref.read(dateFilterProvider.notifier).setFilter(filter);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Expanded(child: TransactionsListView()),
        ],
      ),
    );
  }
}
