import 'package:flutter/foundation.dart';
import '../models/trade.dart';

class TradeService extends ChangeNotifier {
  static final TradeService _instance = TradeService._internal();
  factory TradeService() => _instance;
  TradeService._internal();

  final List<Trade> _trades = [];
  double _currentBalance = 100.0; // Starting balance of $100 USD
  int _nextTradeId = 1;

  // Getters
  List<Trade> get trades => List.unmodifiable(_trades);
  double get currentBalance => _currentBalance;
  int get totalTrades => _trades.length;
  int get winningTrades => _trades.where((t) => t.outcome == 'Win').length;
  int get losingTrades => _trades.where((t) => t.outcome == 'Loss').length;
  double get totalPnL => _trades.fold(0.0, (sum, trade) => sum + trade.pnl);

  // Get weekly profit data for chart (grouped by calendar week)
  Map<int, double> getWeeklyProfits() {
    Map<int, double> weeklyProfits = {};

    for (Trade trade in _trades) {
      // Calculate calendar week number
      int weekOfYear = _getWeekOfYear(trade.date);

      // Add PnL to the week total
      weeklyProfits[weekOfYear] = (weeklyProfits[weekOfYear] ?? 0) + trade.pnl;
    }

    return weeklyProfits;
  }

  // Get the first week that has trades (this becomes "Week 1" on chart)
  int? getFirstTradeWeek() {
    if (_trades.isEmpty) return null;

    int firstWeek = _trades
        .map((t) => _getWeekOfYear(t.date))
        .reduce((a, b) => a < b ? a : b);
    return firstWeek;
  }

  // Calculate week number of year (Monday = start of week)
  int _getWeekOfYear(DateTime date) {
    // Get the first day of the year
    DateTime firstDayOfYear = DateTime(date.year, 1, 1);

    // Calculate the first Monday of the year
    int firstMondayOffset = (8 - firstDayOfYear.weekday) % 7;
    DateTime firstMonday = firstDayOfYear.add(
      Duration(days: firstMondayOffset),
    );

    // If the date is before the first Monday, it belongs to the previous year's last week
    if (date.isBefore(firstMonday)) {
      return _getWeekOfYear(DateTime(date.year - 1, 12, 31));
    }

    // Calculate week number
    int daysSinceFirstMonday = date.difference(firstMonday).inDays;
    return (daysSinceFirstMonday ~/ 7) + 1;
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
    required double pnl,
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
      pnl: pnl,
      previousBalance: _currentBalance,
    );

    _trades.add(trade);
    _currentBalance = trade.newBalance;
    _nextTradeId++;

    // Sort trades by date to maintain chronological order
    _trades.sort((a, b) => a.date.compareTo(b.date));

    notifyListeners();
  }

  // Remove a trade (optional feature)
  void removeTrade(int tradeId) {
    final tradeIndex = _trades.indexWhere((trade) => trade.id == tradeId);
    if (tradeIndex != -1) {
      _trades.removeAt(tradeIndex);
      _recalculateBalances();
      notifyListeners();
    }
  }

  // Clear all trades
  void clearAllTrades() {
    _trades.clear();
    _currentBalance = 100.0;
    _nextTradeId = 1;
    notifyListeners();
  }

  // Recalculate all balances after a trade removal
  void _recalculateBalances() {
    _currentBalance = 100.0; // Reset to starting balance

    // Sort trades by date first
    _trades.sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < _trades.length; i++) {
      final trade = _trades[i];
      final newBalance = _currentBalance + trade.pnl;

      // Create new trade with updated balance
      _trades[i] = Trade(
        id: trade.id,
        date: trade.date,
        time: trade.time,
        exchange: trade.exchange,
        symbol: trade.symbol,
        type: trade.type,
        leverage: trade.leverage,
        entryPrice: trade.entryPrice,
        quantity: trade.quantity,
        sizeUSDT: trade.sizeUSDT,
        outcome: trade.outcome,
        pnl: trade.pnl,
        newBalance: newBalance,
      );

      _currentBalance = newBalance;
    }
  }

  // Add comprehensive sample trades for weeks 32, 33, and 34 (2025)
  void addSampleTrades() {
    // Clear existing trades first
    clearAllTrades();

    // Week 32 Trades (August 4-10, 2025) - 5 trades

    // Trade 1 - Monday, Week 32
    addTrade(
      date: DateTime(2025, 8, 4),
      time: '09:15',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 65000.0,
      quantity: 0.08,
      pnl: 25.0,
    );

    // Trade 2 - Tuesday, Week 32
    addTrade(
      date: DateTime(2025, 8, 5),
      time: '14:30',
      exchange: 'Bybit',
      symbol: 'ETHUSDT',
      type: 'Short',
      leverage: 15,
      entryPrice: 3200.0,
      quantity: 0.25,
      pnl: -15.0,
    );

    // Trade 3 - Thursday, Week 32
    addTrade(
      date: DateTime(2025, 8, 7),
      time: '11:45',
      exchange: 'Bybit',
      symbol: 'SOLUSDT',
      type: 'Long',
      leverage: 20,
      entryPrice: 180.0,
      quantity: 2.5,
      pnl: 40.0,
    );

    // Trade 4 - Friday, Week 32
    addTrade(
      date: DateTime(2025, 8, 8),
      time: '16:20',
      exchange: 'Bybit',
      symbol: 'ADAUSDT',
      type: 'Short',
      leverage: 12,
      entryPrice: 0.45,
      quantity: 800.0,
      pnl: 18.0,
    );

    // Trade 5 - Saturday, Week 32
    addTrade(
      date: DateTime(2025, 8, 9),
      time: '10:10',
      exchange: 'Bybit',
      symbol: 'DOTUSDT',
      type: 'Long',
      leverage: 8,
      entryPrice: 7.2,
      quantity: 30.0,
      pnl: -12.0,
    );

    // Week 33 Trades (August 11-17, 2025) - 4 trades

    // Trade 6 - Monday, Week 33
    addTrade(
      date: DateTime(2025, 8, 11),
      time: '08:30',
      exchange: 'Bybit',
      symbol: 'BTCUSDT',
      type: 'Short',
      leverage: 12,
      entryPrice: 66500.0,
      quantity: 0.06,
      pnl: 35.0,
    );

    // Trade 7 - Wednesday, Week 33
    addTrade(
      date: DateTime(2025, 8, 13),
      time: '13:15',
      exchange: 'Bybit',
      symbol: 'MATICUSDT',
      type: 'Long',
      leverage: 18,
      entryPrice: 0.85,
      quantity: 500.0,
      pnl: -20.0,
    );

    // Trade 8 - Friday, Week 33
    addTrade(
      date: DateTime(2025, 8, 15),
      time: '15:45',
      exchange: 'Bybit',
      symbol: 'LINKUSDT',
      type: 'Long',
      leverage: 10,
      entryPrice: 14.5,
      quantity: 15.0,
      pnl: 28.0,
    );

    // Trade 9 - Sunday, Week 33
    addTrade(
      date: DateTime(2025, 8, 17),
      time: '19:00',
      exchange: 'Bybit',
      symbol: 'AVAXUSDT',
      type: 'Short',
      leverage: 15,
      entryPrice: 32.0,
      quantity: 8.0,
      pnl: 22.0,
    );

    // Week 34 Trades (August 18-24, 2025) - 5 trades

    // Trade 10 - Tuesday, Week 34
    addTrade(
      date: DateTime(2025, 8, 19),
      time: '10:20',
      exchange: 'Bybit',
      symbol: 'ETHUSDT',
      type: 'Long',
      leverage: 14,
      entryPrice: 3350.0,
      quantity: 0.18,
      pnl: 45.0,
    );

    // Trade 11 - Wednesday, Week 34
    addTrade(
      date: DateTime(2025, 8, 20),
      time: '12:50',
      exchange: 'Bybit',
      symbol: 'BNBUSDT',
      type: 'Short',
      leverage: 8,
      entryPrice: 520.0,
      quantity: 1.2,
      pnl: -18.0,
    );

    // Trade 12 - Thursday, Week 34
    addTrade(
      date: DateTime(2025, 8, 21),
      time: '14:35',
      exchange: 'Bybit',
      symbol: 'XRPUSDT',
      type: 'Long',
      leverage: 25,
      entryPrice: 0.62,
      quantity: 400.0,
      pnl: 30.0,
    );

    // Trade 13 - Friday, Week 34
    addTrade(
      date: DateTime(2025, 8, 22),
      time: '16:10',
      exchange: 'Bybit',
      symbol: 'ATOMUSDT',
      type: 'Short',
      leverage: 12,
      entryPrice: 9.8,
      quantity: 25.0,
      pnl: 15.0,
    );

    // Trade 14 - Saturday, Week 34
    addTrade(
      date: DateTime(2025, 8, 23),
      time: '11:25',
      exchange: 'Bybit',
      symbol: 'UNIUSDT',
      type: 'Long',
      leverage: 16,
      entryPrice: 8.4,
      quantity: 20.0,
      pnl: -8.0,
    );

    // Week 35 (August 25-31, 2025) – no trades

    // Week 36 Trades (September 1-7, 2025) - 5 trades

    // Trade 15 - Monday, Week 36
    addTrade(
      date: DateTime(2025, 9, 2),
      time: '11:45',
      exchange: 'Bybit',
      symbol: 'SOLUSDT',
      type: 'Long',
      leverage: 20,
      entryPrice: 180.0,
      quantity: 2.5,
      pnl: 40.0,
    );

    // Trade 16 - Tuesday, Week 36
    addTrade(
      date: DateTime(2025, 9, 3),
      time: '19:00',
      exchange: 'Bybit',
      symbol: 'AVAXUSDT',
      type: 'Short',
      leverage: 15,
      entryPrice: 32.0,
      quantity: 8.0,
      pnl: 22.0,
    );

    // Trade 17 - Wednesday, Week 36
    addTrade(
      date: DateTime(2025, 9, 2),
      time: '11:25',
      exchange: 'Bybit',
      symbol: 'UNIUSDT',
      type: 'Long',
      leverage: 16,
      entryPrice: 8.4,
      quantity: 20.0,
      pnl: -8.0,
    );

    // Trade 18 - Wednesday, Week 36
    addTrade(
      date: DateTime(2025, 9, 5),
      time: '14:30',
      exchange: 'Bybit',
      symbol: 'ETHUSDT',
      type: 'Short',
      leverage: 15,
      entryPrice: 3200.0,
      quantity: 0.25,
      pnl: -15.0,
    );

    // Trade 19 - Friday, Week 36
    addTrade(
      date: DateTime(2025, 9, 3),
      time: '10:10',
      exchange: 'Bybit',
      symbol: 'DOTUSDT',
      type: 'Long',
      leverage: 8,
      entryPrice: 7.2,
      quantity: 30.0,
      pnl: -12.0,
    );
  }
}
