class Holding {
  final int? id;
  final String schemeName;
  final double units;
  final double investedValue;
  final String? folioNumber;
  final String? mfapiCode;
  final double? currentNav;
  final DateTime? lastUpdated;

  Holding({
    this.id,
    required this.schemeName,
    required this.units,
    required this.investedValue,
    this.folioNumber,
    this.mfapiCode,
    this.currentNav,
    this.lastUpdated,
  });

  double get currentValue => (currentNav ?? 0.0) * units;
  double get profitLoss => currentValue - investedValue;
  double get profitLossPercentage =>
      investedValue == 0 ? 0 : (profitLoss / investedValue) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schemeName': schemeName,
      'units': units,
      'investedValue': investedValue,
      'folioNumber': folioNumber,
      'mfapiCode': mfapiCode,
      'currentNav': currentNav,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory Holding.fromMap(Map<String, dynamic> map) {
    return Holding(
      id: map['id'],
      schemeName: map['schemeName'],
      units: (map['units'] as num).toDouble(),
      investedValue: (map['investedValue'] as num).toDouble(),
      folioNumber: map['folioNumber'],
      mfapiCode: map['mfapiCode'],
      currentNav: map['currentNav'] != null
          ? (map['currentNav'] as num).toDouble()
          : null,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null,
    );
  }

  Holding copyWith({
    int? id,
    String? schemeName,
    double? units,
    double? investedValue,
    String? folioNumber,
    String? mfapiCode,
    double? currentNav,
    DateTime? lastUpdated,
  }) {
    return Holding(
      id: id ?? this.id,
      schemeName: schemeName ?? this.schemeName,
      units: units ?? this.units,
      investedValue: investedValue ?? this.investedValue,
      folioNumber: folioNumber ?? this.folioNumber,
      mfapiCode: mfapiCode ?? this.mfapiCode,
      currentNav: currentNav ?? this.currentNav,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
