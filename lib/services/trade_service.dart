import 'package:flutter/foundation.dart';
import '../models/trade.dart';

class TradeService extends ChangeNotifier {
  static final TradeService _instance = TradeService._internal();
  factory TradeService() => _instance;
  TradeService._internal();

  final List<Trade> _trades = [];
  double _initialBalance = 100.0; // Starting balance of $100 USD
  int _nextTradeId = 1;

  // Getters
  List<Trade> get trades => List.unmodifiable(_trades);
  double get initialBalance => _initialBalance;
  int get totalTrades => _trades.length;
  int get winningTrades => _trades.where((t) => t.outcome == 'Win').length;
  int get losingTrades => _trades.where((t) => t.outcome == 'Loss').length;
  double get totalPnL => _trades.fold(0.0, (sum, trade) => sum + trade.pnl);

  // Calculate current balance based on initial balance + all PnL
  double get currentBalance => _initialBalance + totalPnL;

  // Calculate balance at a specific point in the trade history
  double getBalanceAtIndex(int index) {
    if (index < 0 || index >= _trades.length) return currentBalance;

    double balance = _initialBalance;
    for (int i = 0; i <= index; i++) {
      balance += _trades[i].pnl;
    }
    return balance;
  }

  // Set initial balance
  void setInitialBalance(double balance) {
    _initialBalance = balance;
    notifyListeners();
  }

  // Add a new trade
  void addTrade({
    required DateTime date,
    required String time,
    required String exchange,
    required String symbol,
    required String type,
    required int leverage,
    required double entryPrice,
    required double quantity,
    double? pnl, // Optional - defaults to 0 for open trades
    String? beforeScreenshotUrl,
    String? afterScreenshotUrl,
    String? notes,
  }) {
    final trade = Trade.create(
      id: _nextTradeId,
      date: date,
      time: time,
      exchange: exchange,
      symbol: symbol,
      type: type,
      leverage: leverage,
      entryPrice: entryPrice,
      quantity: quantity,
      pnl: pnl ?? 0.0, // Default to 0 for open trades
      beforeScreenshotUrl: beforeScreenshotUrl,
      afterScreenshotUrl: afterScreenshotUrl,
      notes: notes,
    );

    _trades.add(trade);
    _nextTradeId++;
    notifyListeners();
  }

  // Update/Edit an existing trade
  void updateTrade(
    int tradeId, {
    DateTime? date,
    String? time,
    String? exchange,
    String? symbol,
    String? type,
    int? leverage,
    double? entryPrice,
    double? quantity,
    double? pnl,
    String? beforeScreenshotUrl,
    String? afterScreenshotUrl,
    String? notes,
  }) {
    final tradeIndex = _trades.indexWhere((trade) => trade.id == tradeId);
    if (tradeIndex != -1) {
      final originalTrade = _trades[tradeIndex];

      // Recalculate sizeUSDT if relevant fields are updated
      final newEntryPrice = entryPrice ?? originalTrade.entryPrice;
      final newQuantity = quantity ?? originalTrade.quantity;
      final newLeverage = leverage ?? originalTrade.leverage;
      final newSizeUSDT = Trade.calculateSize(
        newEntryPrice,
        newQuantity,
        newLeverage,
      );

      _trades[tradeIndex] = originalTrade.copyWith(
        date: date,
        time: time,
        exchange: exchange,
        symbol: symbol,
        type: type,
        leverage: leverage,
        entryPrice: entryPrice,
        quantity: quantity,
        sizeUSDT: newSizeUSDT,
        pnl: pnl,
        beforeScreenshotUrl: beforeScreenshotUrl,
        afterScreenshotUrl: afterScreenshotUrl,
        notes: notes,
      );

      notifyListeners();
    }
  }

  // Remove a trade
  void removeTrade(int tradeId) {
    final tradeIndex = _trades.indexWhere((trade) => trade.id == tradeId);
    if (tradeIndex != -1) {
      _trades.removeAt(tradeIndex);
      notifyListeners();
    }
  }

  // Clear all trades
  void clearAllTrades() {
    _trades.clear();
    _initialBalance = 100.0;
    _nextTradeId = 1;
    notifyListeners();
  }

  // Get a specific trade by ID
  Trade? getTradeById(int tradeId) {
    try {
      return _trades.firstWhere((trade) => trade.id == tradeId);
    } catch (e) {
      return null;
    }
  }

  // Get weekly profits for growth chart
  Map<int, double> getWeeklyProfits() {
    if (_trades.isEmpty) return {};

    Map<int, double> weeklyProfits = {};

    // Get the first trade week as reference
    final firstTradeWeek = getFirstTradeWeek();
    if (firstTradeWeek == null) return {};

    // Initialize all weeks with 0
    final latestWeek = _getWeekNumber(_trades.last.date);
    for (int week = firstTradeWeek; week <= latestWeek; week++) {
      weeklyProfits[week] = 0.0;
    }

    // Sum up profits by week
    for (Trade trade in _trades) {
      int weekNumber = _getWeekNumber(trade.date);
      weeklyProfits[weekNumber] =
          (weeklyProfits[weekNumber] ?? 0.0) + trade.pnl;
    }

    return weeklyProfits;
  }

  // Get the first trade week number
  int? getFirstTradeWeek() {
    if (_trades.isEmpty) return null;
    return _getWeekNumber(_trades.first.date);
  }

  // Helper method to get week number from date
  int _getWeekNumber(DateTime date) {
    // Get the start of the year
    DateTime startOfYear = DateTime(date.year, 1, 1);

    // Find the first Monday of the year
    int daysToFirstMonday = (DateTime.monday - startOfYear.weekday + 7) % 7;
    DateTime firstMonday = startOfYear.add(Duration(days: daysToFirstMonday));

    // Calculate week number
    if (date.isBefore(firstMonday)) {
      // If date is before first Monday, it belongs to week 0 or previous year's last week
      return 0;
    }

    int daysDifference = date.difference(firstMonday).inDays;
    return (daysDifference / 7).floor() + 1;
  }

  // Get cumulative balance data for growth chart
  List<double> getCumulativeBalanceData() {
    List<double> balanceData = [_initialBalance];
    double runningBalance = _initialBalance;

    for (Trade trade in _trades) {
      runningBalance += trade.pnl;
      balanceData.add(runningBalance);
    }

    return balanceData;
  }

  // Get data points for growth chart
  List<Map<String, dynamic>> getGrowthChartData() {
    List<Map<String, dynamic>> dataPoints = [];

    // Add initial point
    dataPoints.add({
      'week': 0,
      'balance': _initialBalance,
      'date': _trades.isNotEmpty ? _trades.first.date : DateTime.now(),
    });

    if (_trades.isEmpty) return dataPoints;

    double runningBalance = _initialBalance;
    Map<int, double> weeklyProfits = getWeeklyProfits();
    int? firstWeek = getFirstTradeWeek();

    if (firstWeek != null) {
      weeklyProfits.keys.toList()..sort();

      for (int week in weeklyProfits.keys) {
        runningBalance += weeklyProfits[week]!;
        dataPoints.add({
          'week': week - firstWeek + 1, // Normalize to start from week 1
          'balance': runningBalance,
          'profit': weeklyProfits[week],
        });
      }
    }

    return dataPoints;
  }

  // Add sample trades for testing
  void addSampleTrades() {
    // Sample trade 1 - Win (closed trade)
    addTrade(
      date: DateTime(2025, 8, 22),
      time: '11:56',
      exchange: 'Bybit',
      symbol: 'ETHUSDT',
      type: 'Short',
      leverage: 15,
      entryPrice: 4356.0,
      quantity: 0.21,
      pnl: 30.0,
      notes: 'Good short entry at resistance level',
    );

    // Sample trade 2 - Loss (closed trade)
    addTrade(
      date: DateTime(2025, 8, 22),
      time: '14:39',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 117000.0,
      quantity: 0.04,
      pnl: -50.0,
      notes: 'Stopped out, wrong market direction',
    );

    // Sample trade 3 - Open trade (no PNL yet)
    addTrade(
      date: DateTime(2025, 8, 24),
      time: '09:15',
      exchange: 'Bybit',
      symbol: 'SOLUSDT',
      type: 'Long',
      leverage: 20,
      entryPrice: 180.0,
      quantity: 2.5,
      // No PNL - this is an open trade
      notes: 'Waiting for breakout confirmation',
    );

    // Sample trade 4 - Loss (closed trade)
    addTrade(
      date: DateTime(2025, 9, 2),
      time: '14:39',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 117000.0,
      quantity: 0.04,
      pnl: -50.0,
      notes: 'Stopped out, wrong market direction',
    );

    // Sample trade 5 - Loss (closed trade)
    addTrade(
      date: DateTime(2025, 9, 5),
      time: '14:39',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 117000.0,
      quantity: 0.04,
      pnl: 170.0,
    );

    // Sample trade 6 - Loss (closed trade)
    addTrade(
      date: DateTime(2025, 9, 22),
      time: '14:39',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 117000.0,
      quantity: 0.04,
      pnl: 150.0,
    );

    // Sample trade 7 - Loss (closed trade)
    addTrade(
      date: DateTime(2025, 9, 30),
      time: '14:39',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 117000.0,
      quantity: 0.04,
      pnl: 110.0,
    );

    // Sample trade 6 - Loss (closed trade)
    addTrade(
      date: DateTime(2025, 9, 30),
      time: '14:39',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 117000.0,
      quantity: 0.04,
      pnl: 190.0,
    );
  }
}
