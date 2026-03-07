import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_tracker/services/excel_service.dart';
import 'package:networth_tracker/services/mf_api_service.dart';
import 'package:networth_tracker/models/holding.dart';

void main() {
  // Use a simple test to verify the services work with actual data
  test('Verify Excel Parsing and MFAPI Mapping', () async {
    final excelService = ExcelService();
    final apiService = MFAPIService();

    final filePath =
        '/Users/fredysomy/Desktop/personal/Portfolio/Mutual_Funds_7649736484_06-02-2026_06-02-2026 (1).xlsx';

    print('Testing file: $filePath');

    final holdings = await excelService.parseMutualFundExcel(filePath);

    expect(holdings, isNotEmpty);
    print('Found ${holdings.length} holdings in Excel:');

    for (var h in holdings) {
      print(
        ' - ${h.schemeName}: ${h.units} units (Invested: ${h.investedValue})',
      );

      // Test auto-match for the first fund
      if (holdings.indexOf(h) == 0) {
        print('Attempting to auto-match: ${h.schemeName}...');
        String? code = await apiService.autoMatchScheme(h.schemeName);
        print('Matched Code: $code');

        if (code != null) {
          final navData = await apiService.getLatestNav(code);
          print('Latest NAV for $code: ${navData?['data'][0]['nav']}');
          expect(navData, isNotNull);
        }
      }
    }
  });
}
