import 'dart:convert';
import 'package:http/http.dart' as http;

class MFAPIService {
  static const String baseUrl = 'https://api.mfapi.in/mf';

  Future<List<Map<String, dynamic>>> searchScheme(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search?q=$query'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getLatestNav(String code) async {
    final response = await http.get(Uri.parse('$baseUrl/$code/latest'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  // Attempt to auto-match a scheme name to a code
  Future<String?> autoMatchScheme(String name) async {
    // Clean name for better matching (remove folio, direct growth etc)
    String cleanName = name.split('Direct')[0].trim();
    List<Map<String, dynamic>> results = await searchScheme(cleanName);

    if (results.isEmpty) return null;

    // Filter for Direct Growth if possible
    var directGrowth = results
        .where(
          (r) =>
              r['schemeName'].toString().toLowerCase().contains('direct') &&
              r['schemeName'].toString().toLowerCase().contains('growth'),
        )
        .toList();

    if (directGrowth.isNotEmpty) {
      // Sort by similarity to the original name — best match first
      directGrowth.sort((a, b) {
        double scoreA = _schemeSimilarity(name, a['schemeName'].toString());
        double scoreB = _schemeSimilarity(name, b['schemeName'].toString());
        return scoreB.compareTo(scoreA);
      });
      return directGrowth.first['schemeCode'].toString();
    }

    return results.first['schemeCode'].toString();
  }

  /// Jaccard similarity between the meaningful words of two scheme names.
  double _schemeSimilarity(String original, String candidate) {
    const ignore = {'direct', 'plan', 'growth', 'option'};

    Set<String> _words(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !ignore.contains(w))
        .toSet();

    final origWords = _words(original);
    final candWords = _words(candidate);
    if (origWords.isEmpty || candWords.isEmpty) return 0;

    final intersection = origWords.intersection(candWords).length;
    final union = origWords.union(candWords).length;
    return intersection / union;
  }
}
