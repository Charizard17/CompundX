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

  // Add sample trades for testing
  void addSampleTrades() {
    // Sample trade 1 - Win
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
    );

    // Sample trade 2 - Loss
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
    );
  }
}
