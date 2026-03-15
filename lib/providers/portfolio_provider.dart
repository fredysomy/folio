import 'package:flutter/material.dart';
import '../models/holding.dart';
import '../models/stock_holding.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';
import '../services/mf_api_service.dart';
import '../services/stock_api_service.dart';
import '../services/stock_excel_service.dart';

class PortfolioProvider with ChangeNotifier {
  List<Holding> _holdings = [];
  List<StockHolding> _stockHoldings = [];
  Map<String, dynamic>? _lastNetWorthRecord;
  bool _isLoading = false;

  final DatabaseService _dbService = DatabaseService();
  final ExcelService _excelService = ExcelService();
  final MFAPIService _apiService = MFAPIService();
  final StockApiService _stockApiService = StockApiService();
  final StockExcelService _stockExcelService = StockExcelService();

  List<Holding> get holdings => _holdings;
  List<StockHolding> get stockHoldings => _stockHoldings;
  Map<String, dynamic>? get lastNetWorthRecord => _lastNetWorthRecord;
  bool get isLoading => _isLoading;

  double get mfInvested => _holdings.fold(0, (s, h) => s + h.investedValue);
  double get mfCurrentValue => _holdings.fold(0, (s, h) => s + h.currentValue);
  double get stockInvested =>
      _stockHoldings.fold(0, (s, h) => s + h.investedValue);
  double get stockCurrentValue =>
      _stockHoldings.fold(0, (s, h) => s + h.currentValue);

  double get totalInvested => mfInvested + stockInvested;
  double get currentNetWorth => mfCurrentValue + stockCurrentValue;
  double get totalProfitLoss => currentNetWorth - totalInvested;
  double get totalProfitLossPercentage =>
      totalInvested == 0 ? 0 : (totalProfitLoss / totalInvested) * 100;

  double get dayChange => _lastNetWorthRecord?['dayChange'] ?? 0.0;
  double get dayChangePercentage {
    if (_lastNetWorthRecord == null) return 0.0;
    double prev = _lastNetWorthRecord!['totalValue'] - _lastNetWorthRecord!['dayChange'];
    return prev == 0 ? 0.0 : (dayChange / prev) * 100;
  }

  PortfolioProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _holdings = await _dbService.getHoldings();
    _stockHoldings = await _dbService.getStockHoldings();
    _lastNetWorthRecord = await _dbService.getLastNetWorthRecord();
    _isLoading = false;
    notifyListeners();
  }

  // Alias kept for RefreshIndicator callbacks
  Future<void> loadHoldings() => loadAll();

  // ── Mutual Funds ────────────────────────────────────────────────────────────

  Future<void> importExcel(String filePath) async {
    _isLoading = true;
    notifyListeners();

    final newHoldings = await _excelService.parseMutualFundExcel(filePath);
    await _dbService.clearHoldings();

    for (var holding in newHoldings) {
      String? code = await _apiService.autoMatchScheme(holding.schemeName);
      Holding updated = holding.copyWith(mfapiCode: code);

      if (code != null) {
        final navData = await _apiService.getLatestNav(code);
        if (navData != null) {
          updated = updated.copyWith(
            currentNav: double.tryParse(navData['data'][0]['nav']),
            lastUpdated: DateTime.now(),
          );
        }
      }
      await _dbService.insertHolding(updated);
    }

    await loadAll();
  }

  Future<void> syncNavs({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    final today = DateTime.now();
    for (int i = 0; i < _holdings.length; i++) {
      final h = _holdings[i];

      // Skip if NAV already fetched today and not forced
      if (!forceRefresh && h.lastUpdated != null) {
        final lu = h.lastUpdated!;
        if (lu.year == today.year &&
            lu.month == today.month &&
            lu.day == today.day) {
          continue;
        }
      }

      final code = h.mfapiCode;
      if (code != null) {
        final navData = await _apiService.getLatestNav(code);
        if (navData != null) {
          _holdings[i] = h.copyWith(
            currentNav: double.tryParse(navData['data'][0]['nav']),
            lastUpdated: today,
          );
          await _dbService.updateHolding(_holdings[i]);
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMapping(int id, String code) async {
    int idx = _holdings.indexWhere((h) => h.id == id);
    if (idx != -1) {
      final navData = await _apiService.getLatestNav(code);
      _holdings[idx] = _holdings[idx].copyWith(
        mfapiCode: code,
        currentNav:
            navData != null ? double.tryParse(navData['data'][0]['nav']) : null,
        lastUpdated: DateTime.now(),
      );
      await _dbService.updateHolding(_holdings[idx]);
      notifyListeners();
    }
  }

  // ── Stocks ──────────────────────────────────────────────────────────────────

  Future<void> importStockExcel(String filePath) async {
    _isLoading = true;
    notifyListeners();

    final parsed = await _stockExcelService.parseStockExcel(filePath);
    await _dbService.clearStockHoldings();

    for (var s in parsed) {
      // If Excel already has a closing price, use it directly.
      // Still try the API to get a live price + percent change.
      final result =
          await _stockApiService.getStockPrice(s.apiName ?? s.companyName);
      final updated = result != null
          ? s.copyWith(
              currentPrice: result['currentPrice'],
              percentChange: result['percentChange'],
              apiName: result['resolvedName'],
              lastUpdated: DateTime.now(),
            )
          : s; // falls back to Excel closing price if API fails
      await _dbService.insertStockHolding(updated);
    }

    await loadAll();
  }

  /// Update the API lookup name for a stock and immediately re-fetch its price.
  Future<bool> updateStockApiName(int id, String newApiName) async {
    final idx = _stockHoldings.indexWhere((h) => h.id == id);
    if (idx == -1) return false;

    final result = await _stockApiService.getStockPrice(newApiName);
    _stockHoldings[idx] = _stockHoldings[idx].copyWith(
      apiName: newApiName,
      currentPrice: result?['currentPrice'],
      percentChange: result?['percentChange'],
      lastUpdated: result != null ? DateTime.now() : _stockHoldings[idx].lastUpdated,
    );
    await _dbService.updateStockHolding(_stockHoldings[idx]);
    notifyListeners();
    return result != null;
  }

  Future<void> syncStockPrices({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    final today = DateTime.now();
    for (int i = 0; i < _stockHoldings.length; i++) {
      final h = _stockHoldings[i];

      // Skip if fetched today and not forced — conserve API quota
      if (!forceRefresh && h.lastUpdated != null) {
        final lu = h.lastUpdated!;
        if (lu.year == today.year &&
            lu.month == today.month &&
            lu.day == today.day) {
          continue;
        }
      }

      final result = await _stockApiService
          .getStockPrice(h.apiName ?? h.companyName);
      if (result != null) {
        _stockHoldings[i] = h.copyWith(
          currentPrice: result['currentPrice'],
          percentChange: result['percentChange'],
          lastUpdated: today,
        );
        await _dbService.updateStockHolding(_stockHoldings[i]);
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
