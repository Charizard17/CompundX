class Trade {
  final int id;
  final DateTime date;
  final String time;
  final String exchange;
  final String symbol;
  final String type;
  final int leverage;
  final double entryPrice;
  final double quantity;
  final double sizeUSDT;
  final String outcome;
  final double pnl;
  // New optional properties
  final String? beforeScreenshotUrl;
  final String? afterScreenshotUrl;
  final String? notes;

  Trade({
    required this.id,
    required this.date,
    required this.time,
    required this.exchange,
    required this.symbol,
    required this.type,
    required this.leverage,
    required this.entryPrice,
    required this.quantity,
    required this.sizeUSDT,
    required this.outcome,
    required this.pnl,
    this.beforeScreenshotUrl,
    this.afterScreenshotUrl,
    this.notes,
  });

  // Calculate size from entry price, quantity and leverage
  static double calculateSize(
    double entryPrice,
    double quantity,
    int leverage,
  ) {
    return (entryPrice * quantity) / leverage;
  }

  // Determine outcome based on PNL
  static String determineOutcome(double pnl) {
    if (pnl > 0) return 'Win';
    if (pnl < 0) return 'Loss';
    return '–'; // Dash for zero or unknown PNL
  }

  // Create a new trade with calculated fields
  factory Trade.create({
    required int id,
    required DateTime date,
    required String time,
    required String exchange,
    required String symbol,
    required String type,
    required int leverage,
    required double entryPrice,
    required double quantity,
    double pnl = 0.0, // Default to 0 for open trades
    String? beforeScreenshotUrl,
    String? afterScreenshotUrl,
    String? notes,
  }) {
    final sizeUSDT = calculateSize(entryPrice, quantity, leverage);
    final outcome = determineOutcome(pnl);

    return Trade(
      id: id,
      date: date,
      time: time,
      exchange: exchange,
      symbol: symbol,
      type: type,
      leverage: leverage,
      entryPrice: entryPrice,
      quantity: quantity,
      sizeUSDT: sizeUSDT,
      outcome: outcome,
      pnl: pnl,
      beforeScreenshotUrl: beforeScreenshotUrl,
      afterScreenshotUrl: afterScreenshotUrl,
      notes: notes,
    );
  }

  // Create a copy of this trade with updated fields
  Trade copyWith({
    int? id,
    DateTime? date,
    String? time,
    String? exchange,
    String? symbol,
    String? type,
    int? leverage,
    double? entryPrice,
    double? quantity,
    double? sizeUSDT,
    String? outcome,
    double? pnl,
    String? beforeScreenshotUrl,
    String? afterScreenshotUrl,
    String? notes,
  }) {
    final newPnl = pnl ?? this.pnl;
    final newOutcome = pnl != null
        ? determineOutcome(newPnl)
        : (outcome ?? this.outcome);

    return Trade(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      exchange: exchange ?? this.exchange,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      leverage: leverage ?? this.leverage,
      entryPrice: entryPrice ?? this.entryPrice,
      quantity: quantity ?? this.quantity,
      sizeUSDT: sizeUSDT ?? this.sizeUSDT,
      outcome: newOutcome,
      pnl: newPnl,
      beforeScreenshotUrl: beforeScreenshotUrl ?? this.beforeScreenshotUrl,
      afterScreenshotUrl: afterScreenshotUrl ?? this.afterScreenshotUrl,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'exchange': exchange,
      'symbol': symbol,
      'type': type,
      'leverage': leverage,
      'entryPrice': entryPrice,
      'quantity': quantity,
      'sizeUSDT': sizeUSDT,
      'outcome': outcome,
      'pnl': pnl,
      'beforeScreenshotUrl': beforeScreenshotUrl,
      'afterScreenshotUrl': afterScreenshotUrl,
      'notes': notes,
    };
  }

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      exchange: json['exchange'],
      symbol: json['symbol'],
      type: json['type'],
      leverage: json['leverage'],
      entryPrice: json['entryPrice'],
      quantity: json['quantity'],
      sizeUSDT: json['sizeUSDT'],
      outcome: json['outcome'],
      pnl: json['pnl'],
      beforeScreenshotUrl: json['beforeScreenshotUrl'],
      afterScreenshotUrl: json['afterScreenshotUrl'],
      notes: json['notes'],
    );
  }
}
