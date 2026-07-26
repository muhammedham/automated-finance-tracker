import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dailyLimitProvider = AsyncNotifierProvider<DailyLimitNotifier, double>(() {
  return DailyLimitNotifier();
});

class DailyLimitNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('daily_limit') ?? 0.0;
  }

  Future<void> setLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_limit', limit);
    state = AsyncValue.data(limit);
  }
}