class StockHolding {
  final int? id;
  final String companyName;
  final double quantity;
  final double avgBuyPrice;
  final String? isin;
  final String? apiName; // name used to query indianapi.in
  final double? currentPrice;
  final double? percentChange;
  final DateTime? lastUpdated;

  StockHolding({
    this.id,
    required this.companyName,
    required this.quantity,
    required this.avgBuyPrice,
    this.isin,
    this.apiName,
    this.currentPrice,
    this.percentChange,
    this.lastUpdated,
  });

  double get investedValue => quantity * avgBuyPrice;
  double get currentValue => (currentPrice ?? 0.0) * quantity;
  double get profitLoss => currentValue - investedValue;
  double get profitLossPercentage =>
      investedValue == 0 ? 0 : (profitLoss / investedValue) * 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'companyName': companyName,
        'quantity': quantity,
        'avgBuyPrice': avgBuyPrice,
        'isin': isin,
        'apiName': apiName,
        'currentPrice': currentPrice,
        'percentChange': percentChange,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory StockHolding.fromMap(Map<String, dynamic> m) => StockHolding(
        id: m['id'],
        companyName: m['companyName'],
        quantity: (m['quantity'] as num).toDouble(),
        avgBuyPrice: (m['avgBuyPrice'] as num).toDouble(),
        isin: m['isin'],
        apiName: m['apiName'],
        currentPrice:
            m['currentPrice'] != null ? (m['currentPrice'] as num).toDouble() : null,
        percentChange:
            m['percentChange'] != null ? (m['percentChange'] as num).toDouble() : null,
        lastUpdated:
            m['lastUpdated'] != null ? DateTime.parse(m['lastUpdated']) : null,
      );

  StockHolding copyWith({
    int? id,
    String? companyName,
    double? quantity,
    double? avgBuyPrice,
    String? isin,
    String? apiName,
    double? currentPrice,
    double? percentChange,
    DateTime? lastUpdated,
  }) =>
      StockHolding(
        id: id ?? this.id,
        companyName: companyName ?? this.companyName,
        quantity: quantity ?? this.quantity,
        avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
        isin: isin ?? this.isin,
        apiName: apiName ?? this.apiName,
        currentPrice: currentPrice ?? this.currentPrice,
        percentChange: percentChange ?? this.percentChange,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}
