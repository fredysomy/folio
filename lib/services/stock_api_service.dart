import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StockApiService {
  static const _baseUrl = 'https://stock.indianapi.in';
  static const _keysPrefsKey = 'stock_api_keys';
  static const _keyIndexPrefsKey = 'stock_api_key_index';

  // ── Key Management ──────────────────────────────────────────────────────────

  Future<List<String>> getApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keysPrefsKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  Future<void> saveApiKeys(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keysPrefsKey, jsonEncode(keys));
  }

  Future<void> addApiKey(String key) async {
    final keys = await getApiKeys();
    if (!keys.contains(key)) {
      keys.add(key);
      await saveApiKeys(keys);
    }
  }

  Future<void> removeApiKey(String key) async {
    final keys = await getApiKeys();
    keys.remove(key);
    await saveApiKeys(keys);
    // Reset index if out of range
    final prefs = await SharedPreferences.getInstance();
    int idx = prefs.getInt(_keyIndexPrefsKey) ?? 0;
    if (keys.isNotEmpty && idx >= keys.length) {
      await prefs.setInt(_keyIndexPrefsKey, 0);
    }
  }

  /// Returns the next key in round-robin order.
  Future<String?> _nextKey() async {
    final keys = await getApiKeys();
    if (keys.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    int idx = prefs.getInt(_keyIndexPrefsKey) ?? 0;
    if (idx >= keys.length) idx = 0;
    final key = keys[idx];
    await prefs.setInt(_keyIndexPrefsKey, (idx + 1) % keys.length);
    return key;
  }

  // ── Price Fetch ─────────────────────────────────────────────────────────────

  /// Returns {currentPrice, percentChange, resolvedName} or null.
  /// Uses round-robin across saved API keys.
  Future<Map<String, dynamic>?> getStockPrice(String companyName) async {
    final apiKey = await _nextKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse(
          '$_baseUrl/stock?name=${Uri.encodeQueryComponent(companyName)}');
      final response = await http.get(
        uri,
        headers: {'X-Api-Key': apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final priceMap = data['currentPrice'] as Map<String, dynamic>?;
      if (priceMap == null) return null;

      final priceStr = (priceMap['NSE'] ?? priceMap['BSE'])?.toString();
      final price = double.tryParse(priceStr ?? '');
      if (price == null) return null;

      return {
        'currentPrice': price,
        'percentChange': data['percentChange'] != null
            ? double.tryParse(data['percentChange'].toString())
            : null,
        'resolvedName': data['companyName']?.toString() ?? companyName,
      };
    } catch (_) {
      return null;
    }
  }
}
