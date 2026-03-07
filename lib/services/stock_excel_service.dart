import 'dart:io';
import 'package:excel/excel.dart';
import '../models/stock_holding.dart';

class StockExcelService {
  Future<List<StockHolding>> parseStockExcel(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<StockHolding> holdings = [];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      int nameIdx = -1;
      int qtyIdx = -1;
      int avgPriceIdx = -1;
      int isinIdx = -1;
      int closingPriceIdx = -1;
      int headerRowIdx = -1;

      for (int i = 0; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        for (int j = 0; j < row.length; j++) {
          final val = row[j]?.value?.toString().toLowerCase().trim() ?? '';
          if (_matchesName(val)) nameIdx = j;
          if (_matchesQty(val)) qtyIdx = j;
          if (_matchesAvgPrice(val)) avgPriceIdx = j;
          if (val.contains('isin')) isinIdx = j;
          if (_matchesClosingPrice(val)) closingPriceIdx = j;
        }
        if (nameIdx != -1 && qtyIdx != -1 && avgPriceIdx != -1) {
          headerRowIdx = i;
          break;
        }
      }

      if (headerRowIdx == -1) continue;

      for (int i = headerRowIdx + 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length <= nameIdx || row[nameIdx] == null) continue;

        final name = row[nameIdx]?.value?.toString().trim();
        if (name == null ||
            name.isEmpty ||
            name.toLowerCase().contains('total')) continue;

        final qty =
            double.tryParse(row[qtyIdx]?.value?.toString() ?? '');
        final avgPrice =
            double.tryParse(row[avgPriceIdx]?.value?.toString() ?? '');
        if (qty == null || qty <= 0 || avgPrice == null) continue;

        final isin = isinIdx != -1
            ? row[isinIdx]?.value?.toString().trim()
            : null;

        // Read closing price from Excel if available
        double? closingPrice;
        if (closingPriceIdx != -1 && row.length > closingPriceIdx) {
          closingPrice =
              double.tryParse(row[closingPriceIdx]?.value?.toString() ?? '');
        }

        holdings.add(StockHolding(
          companyName: name,
          quantity: qty,
          avgBuyPrice: avgPrice,
          isin: isin,
          apiName: _buildApiName(name),
          currentPrice: closingPrice,
          lastUpdated: closingPrice != null ? DateTime.now() : null,
        ));
      }
    }
    return holdings;
  }

  // Known fund house / AMC prefixes to split concatenated names like HDFCSILVER → HDFC SILVER
  static const _knownPrefixes = [
    'MIRAE', 'MOTILAL', 'FRANKLIN', 'INVESCO', 'CANARA', 'BANDHAN',
    'EDELWEISS', 'NIPPON', 'KOTAK', 'HDFC', 'ICICI', 'AXIS', 'TATA',
    'UTI', 'SBI', 'DSP',
  ];

  /// Cleans the raw name for API lookup.
  /// "RAIL VIKAS NIGAM LIMITED" → "Rail Vikas Nigam"
  /// "HDFCAMC - HDFCSILVER"    → "Hdfc Silver"
  String _buildApiName(String raw) {
    // If name has " - ", the part after it is the actual fund/ETF name
    String name = raw.contains(' - ') ? raw.split(' - ').last.trim() : raw;

    // Strip known AMC suffixes (AMC, MUTUAL, FUND, MF) from the token
    name = name.replaceAll(RegExp(r'\b(AMC|MUTUAL|FUND|MF)\b'), '').trim();

    // Insert space between a known prefix and the rest
    // e.g. HDFCSILVER → HDFC SILVER
    for (final prefix in _knownPrefixes) {
      if (name.toUpperCase().startsWith(prefix) &&
          name.length > prefix.length) {
        name = '${name.substring(0, prefix.length)} ${name.substring(prefix.length)}';
        break;
      }
    }

    // Strip company suffixes from regular stock names
    name = name
        .replaceAll(RegExp(r'\bLIMITED\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bLTD\.?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Title-case
    return name
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  bool _matchesName(String v) =>
      v == 'instrument' ||
      v == 'stock' ||
      v == 'scrip' ||
      v.contains('stock name') ||
      v.contains('company name') ||
      v.contains('instrument name');

  bool _matchesQty(String v) =>
      v == 'qty' ||
      v == 'quantity' ||
      v == 'shares' ||
      v.contains('qty') ||
      v.contains('quantity');

  bool _matchesAvgPrice(String v) =>
      v.contains('avg') ||
      v.contains('average') ||
      v.contains('buy price') ||
      v.contains('purchase price') ||
      v.contains('cost price');

  bool _matchesClosingPrice(String v) =>
      v == 'closing price' ||
      v == 'close price' ||
      v == 'ltp' ||
      v == 'last price' ||
      v.contains('closing price') ||
      v.contains('close price') ||
      v.contains('current price');
}
