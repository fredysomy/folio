import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'database_service.dart';
import 'mf_api_service.dart';
import 'stock_api_service.dart';

const _kTaskName = 'daily_portfolio_summary';
const _kTaskUniqueName = 'daily_portfolio_summary_unique';
const _prefsHourKey = 'daily_summary_hour';
const _prefsMinuteKey = 'daily_summary_minute';
const _defaultHour = 21;
const _defaultMinute = 0;

/// Top-level callback for WorkManager — runs in a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _kTaskName) {
      await _showSummaryAndReschedule();
    }
    return true;
  });
}

Future<void> _showSummaryAndReschedule() async {
  // Build the notification content from live API data.
  final result = await _PortfolioSummaryJob().run();

  // Re-initialise the plugin inside this isolate and show the notification.
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(settings: const InitializationSettings(android: android));

  await plugin.show(
    id: 1,
    title: result.title,
    body: result.body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'portfolio_updates',
        'Portfolio Updates',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(result.body),
      ),
    ),
  );

  // Reschedule for the same time tomorrow.
  final prefs = await SharedPreferences.getInstance();
  final hour = prefs.getInt(_prefsHourKey) ?? _defaultHour;
  final minute = prefs.getInt(_prefsMinuteKey) ?? _defaultMinute;
  await _scheduleNext(hour, minute);
}

Future<void> _scheduleNext(int hour, int minute) async {
  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

  await Workmanager().registerOneOffTask(
    _kTaskUniqueName,
    _kTaskName,
    initialDelay: next.difference(now),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> ensureScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsHourKey)) {
      await prefs.setInt(_prefsHourKey, _defaultHour);
    }
    if (!prefs.containsKey(_prefsMinuteKey)) {
      await prefs.setInt(_prefsMinuteKey, _defaultMinute);
    }
    final hour = prefs.getInt(_prefsHourKey)!;
    final minute = prefs.getInt(_prefsMinuteKey)!;
    await _scheduleNext(hour, minute);
  }

  Future<TimeOfDay> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_prefsHourKey) ?? _defaultHour,
      minute: prefs.getInt(_prefsMinuteKey) ?? _defaultMinute,
    );
  }

  Future<void> updateSchedule(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsHourKey, time.hour);
    await prefs.setInt(_prefsMinuteKey, time.minute);
    await Workmanager().cancelByUniqueName(_kTaskUniqueName);
    await _scheduleNext(time.hour, time.minute);
  }

  /// Immediately fetches live data and shows the notification (for testing).
  Future<void> runSummaryNow() async {
    await _showSummaryAndReschedule();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SummaryResult {
  final String title;
  final String body;
  const _SummaryResult({required this.title, required this.body});
}

class _PortfolioSummaryJob {
  final _db = DatabaseService();
  final _mfApi = MFAPIService();
  final _stockApi = StockApiService();

  Future<_SummaryResult> run() async {
    final holdings = await _db.getHoldings();
    final stockHoldings = await _db.getStockHoldings();

    double mfValue = 0, stockValue = 0, mfInvested = 0, stockInvested = 0;
    final now = DateTime.now();

    for (var h in holdings) {
      double nav = h.currentNav ?? 0;
      mfInvested += h.investedValue;
      if (h.mfapiCode != null) {
        final latest = await _mfApi.getLatestNav(h.mfapiCode!);
        final parsed = _parseNav(latest);
        if (parsed != null) {
          nav = parsed;
          await _db.updateHolding(h.copyWith(currentNav: nav, lastUpdated: now));
        }
      }
      mfValue += nav * h.units;
    }

    for (var s in stockHoldings) {
      double price = s.currentPrice ?? 0;
      stockInvested += s.investedValue;
      final latest = await _stockApi.getStockPrice(s.apiName ?? s.companyName);
      if (latest != null) {
        price = latest['currentPrice'];
        await _db.updateStockHolding(
          s.copyWith(
            currentPrice: price,
            percentChange: latest['percentChange'],
            apiName: latest['resolvedName'],
            lastUpdated: now,
          ),
        );
      }
      stockValue += price * s.quantity;
    }

    final last = await _db.getLastNetWorthRecord();
    final prevTotal = _toDouble(last?['totalValue']);
    final prevMf = _toDouble(last?['mfValue']);
    final prevStock = _toDouble(last?['stockValue']);

    final total = mfValue + stockValue;
    final totalChange = total - prevTotal;
    final mfChange = mfValue - prevMf;
    final stockChange = stockValue - prevStock;
    final pct = prevTotal > 0 ? (totalChange / prevTotal) * 100 : 0.0;
    final invested = mfInvested + stockInvested;
    final pnl = total - invested;
    final pnlPct = invested > 0 ? (pnl / invested) * 100 : 0.0;

    await _db.insertNetWorthRecord({
      'date': now.toIso8601String(),
      'totalValue': total,
      'dayChange': totalChange,
      'type': 'daily_summary',
      'mfValue': mfValue,
      'stockValue': stockValue,
    });

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dir = totalChange >= 0 ? 'up' : 'down';
    final overallDir = pnl >= 0 ? 'Up' : 'Down';

    final body = [
      'Mutual Funds: ${_move(mfChange, fmt)} today',
      'Stocks: ${_move(stockChange, fmt)} today',
      'Total: ${_move(totalChange, fmt)} (${pct.abs().toStringAsFixed(2)}%) today',
      'Overall: $overallDir ${fmt.format(pnl.abs())} (${pnlPct.abs().toStringAsFixed(2)}%)',
    ].join('\n');

    return _SummaryResult(
      title: 'Your portfolio is $dir ${_move(totalChange, fmt)} today',
      body: body,
    );
  }

  double? _parseNav(Map<String, dynamic>? r) {
    if (r == null) return null;
    final data = r['data'];
    if (data is List && data.isNotEmpty) {
      return double.tryParse(data.first['nav'].toString());
    }
    return null;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _move(double amount, NumberFormat fmt) {
    final prefix = amount > 0 ? '+' : amount < 0 ? '-' : '';
    return '$prefix${fmt.format(amount.abs())}';
  }
}
