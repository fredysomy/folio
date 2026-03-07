import 'dart:io';
import 'package:excel/excel.dart';
import '../models/holding.dart';

class ExcelService {
  Future<List<Holding>> parseMutualFundExcel(String filePath) async {
    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<Holding> holdings = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      int schemeNameIdx = -1;
      int unitsIdx = -1;
      int investedValueIdx = -1;
      int folioIdx = -1;

      int headerRowIdx = -1;

      // Find headers
      for (int i = 0; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        for (int j = 0; j < row.length; j++) {
          var val = row[j]?.value?.toString().toLowerCase() ?? "";
          if (val.contains("scheme name")) schemeNameIdx = j;
          if (val.contains("units")) unitsIdx = j;
          if (val.contains("invested value")) investedValueIdx = j;
          if (val.contains("folio no")) folioIdx = j;
        }
        if (schemeNameIdx != -1 && unitsIdx != -1) {
          headerRowIdx = i;
          break;
        }
      }

      if (headerRowIdx == -1) continue;

      // Parse data
      for (int i = headerRowIdx + 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.length <= schemeNameIdx || row[schemeNameIdx] == null) continue;

        String? name = row[schemeNameIdx]?.value?.toString();
        if (name == null ||
            name.isEmpty ||
            name.toLowerCase().contains("total"))
          continue;

        double units =
            double.tryParse(row[unitsIdx]?.value?.toString() ?? "0") ?? 0;
        double invested =
            double.tryParse(row[investedValueIdx]?.value?.toString() ?? "0") ??
            0;
        String? folio = folioIdx != -1
            ? row[folioIdx]?.value?.toString()
            : null;

        if (units > 0) {
          holdings.add(
            Holding(
              schemeName: name,
              units: units,
              investedValue: invested,
              folioNumber: folio,
            ),
          );
        }
      }
    }
    return holdings;
  }
}
