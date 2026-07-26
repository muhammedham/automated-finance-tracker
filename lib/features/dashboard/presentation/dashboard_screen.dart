import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/rising_route.dart';
import '../../../core/widgets/filter_pill.dart';
import '../domain/dashboard_providers.dart';
import '../../budget/domain/budget_provider.dart';
import '../../automation/domain/email_sync_notifier.dart';
import '../../transactions/presentation/manual_entry_screen.dart';
import '../../transactions/presentation/expense_pie_chart.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../../transactions/presentation/widgets/transactions_list_view.dart';
import '../../transactions/presentation/category_management_screen.dart';
import 'widgets/app_drawer.dart';

/// Height of the side-by-side "Expenses by category" / "Recent
/// transactions" row. Bump this if you add more categories/rows and want
/// more breathing room — both cards scroll internally if their content
/// doesn't fit.
const double _overviewRowHeight = 300;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Drives the menu <-> close morph on the AppBar icon. It's kept in sync
  // with the drawer's actual open/closed state via onDrawerChanged below,
  // so it animates correctly whether the drawer was opened by tapping the
  // icon *or* by swiping in from the left edge.
  late final AnimationController _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (isOpen) {
      _scaffoldKey.currentState?.closeDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _onDrawerChanged(bool isOpened) {
    if (isOpened) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  Future<void> _syncEmails(BuildContext context) async {
    try {
      final count = await ref.read(emailSyncProvider.notifier).syncBankEmails(
        'YOUR_EMAIL_HERE',
        'YOUR_APP_PASSWORD_HERE',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully parsed $count new transactions!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  Future<void> _selectCustomDate(BuildContext context) async {
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

  void _showLimitDialog(BuildContext context) {
    final limitController = TextEditingController();
    final currentLimit = ref.read(dailyLimitProvider).value ?? 0.0;
    if (currentLimit > 0) {
      limitController.text = currentLimit.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Daily Limit'),
          content: TextField(
            controller: limitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Limit (₺)',
              hintText: 'Enter 0 to remove limit',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newLimit = double.tryParse(limitController.text) ?? 0.0;
                ref.read(dailyLimitProvider.notifier).setLimit(newLimit);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newLimit > 0
                        ? 'Daily limit set to ₺$newLimit'
                        : 'Daily limit removed'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(dateFilterProvider);
    final totalsAsync = ref.watch(dashboardTotalsProvider);

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: _onDrawerChanged,
      drawer: AppDrawer(
        onAdd: () => Navigator.push(context, risingRoute(const ManualEntryScreen())),
        onCategories: () => Navigator.push(context, risingRoute(const CategoryManagementScreen())),
        onSync: () => _syncEmails(context),
        onLimit: () => _showLimitDialog(context),
      ),
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkResponse(
            onTap: _toggleDrawer,
            radius: 24,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.chipSelected,
                shape: BoxShape.circle,
              ),
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _menuController,
                color: AppColors.black,
                size: 20,
              ),
            ),
          ),
        ),
        title: const Text('MyWallet'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, risingRoute(const ManualEntryScreen())),
        backgroundColor: AppColors.mauve,
        foregroundColor: AppColors.black,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: _FadeInOnLoad(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FILTERS
              const SizedBox(height: 14),
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
                            _selectCustomDate(context);
                          } else {
                            ref.read(dateFilterProvider.notifier).setFilter(filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // ANALYTICS CARDS
              totalsAsync.when(
                data: (totals) {
                  final income = (totals['income'] ?? 0) / 100;
                  final expense = (totals['expense'] ?? 0) / 100;
                  final balance = income - expense;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _BalanceHeroCard(balance: balance),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                title: 'Income',
                                amount: income,
                                accent: AppColors.sage,
                                gradient: AppGradients.incomeCard,
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                title: 'Expense',
                                amount: expense,
                                accent: AppColors.mauve,
                                gradient: AppGradients.expenseCard,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error loading analytics: $e')),
                ),
              ),

              const _SectionHeader(label: 'Overview'),

              // EXPENSES BY CATEGORY + RECENT TRANSACTIONS, SIDE BY SIDE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: _overviewRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _OverviewPanel(
                          title: 'Expenses',
                          child: const ExpensePieChart(compact: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: _OverviewPanel(
                          title: 'Recent',
                          trailing: GestureDetector(
                            onTap: () => Navigator.push(context, risingRoute(const AllTransactionsScreen())),
                            child: Text(
                              'View all',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mauve,
                              ),
                            ),
                          ),
                          child: const TransactionsListView(limit: 4, dense: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared card chrome for the two side-by-side "Overview" panels, so the
/// expense chart and the recent-transactions list sit inside visually
/// identical cards.
class _OverviewPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _OverviewPanel({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.tile,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.offWhiteDim(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Simple fade + rise entrance for the dashboard body on first build.
class _FadeInOnLoad extends StatefulWidget {
  final Widget child;
  const _FadeInOnLoad({required this.child});

  @override
  State<_FadeInOnLoad> createState() => _FadeInOnLoadState();
}

class _FadeInOnLoadState extends State<_FadeInOnLoad> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - _fade.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// The hero balance card: a real gradient surface with an animated,
/// counting-up figure whenever the balance changes, and a soft mauve
/// glow in the corner as the one signature flourish.
class _BalanceHeroCard extends StatelessWidget {
  final double balance;

  const _BalanceHeroCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.offWhiteDim(0.07)),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.mauveDim(0.4), AppColors.mauveDim(0.0)],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NET BALANCE', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '₺ ${value.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displaySmall,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color accent;
  final Gradient gradient;
  final IconData icon;

  const _MiniStatCard({
    required this.title,
    required this.amount,
    required this.accent,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.offWhiteDim(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: AppColors.black),
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.offWhiteDim(0.55),
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Text(
              '₺ ${value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.offWhite,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 26.0, 16.0, 8.0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(gradient: AppGradients.chipSelected, borderRadius: BorderRadius.circular(2)),
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
