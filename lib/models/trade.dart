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
  final double newBalance;

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
    required this.newBalance,
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
    return pnl >= 0 ? 'Win' : 'Loss';
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
    required double pnl,
    required double previousBalance,
  }) {
    final sizeUSDT = calculateSize(entryPrice, quantity, leverage);
    final outcome = determineOutcome(pnl);
    final newBalance = previousBalance + pnl;

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
      newBalance: newBalance,
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
      'newBalance': newBalance,
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
      newBalance: json['newBalance'],
    );
  }
}
