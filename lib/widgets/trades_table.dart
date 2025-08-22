import 'package:flutter/material.dart';
import '../models/trade.dart';
import '../services/trade_service.dart';

class TradesTable extends StatelessWidget {
  const TradesTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trades',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                AnimatedBuilder(
                  animation: TradeService(),
                  builder: (context, child) {
                    final trades = TradeService().trades;
                    if (trades.isEmpty) {
                      return _buildEmptyState();
                    }
                    return Column(
                      children: trades.asMap().entries.map((entry) {
                        return _buildTableRow(entry.value, entry.key + 1);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('#', 40),
          _buildHeaderCell('Date', 80),
          _buildHeaderCell('Time', 60),
          _buildHeaderCell('Exchange', 80),
          _buildHeaderCell('Symbol', 80),
          _buildHeaderCell('Type', 60),
          _buildHeaderCell('Leverage', 80),
          _buildHeaderCell('Entry Price', 90),
          _buildHeaderCell('Quantity', 80),
          _buildHeaderCell('Size(USDT)', 90),
          _buildHeaderCell('Outcome', 80),
          _buildHeaderCell('PNL', 60),
          _buildHeaderCell('New Balance', 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade600, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Trade trade, int index) {
    final isEven = index % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade800 : Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade700, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildDataCell(index.toString(), 40),
          _buildDataCell(
            '${trade.date.day.toString().padLeft(2, '0')}/${trade.date.month.toString().padLeft(2, '0')}/${trade.date.year.toString().substring(2)}',
            80,
          ),
          _buildDataCell(trade.time, 60),
          _buildDataCell(trade.exchange, 80),
          _buildDataCell(trade.symbol, 80),
          _buildDataCell(
            trade.type,
            60,
            color: trade.type == 'Long' ? Colors.green : Colors.red,
          ),
          _buildDataCell(trade.leverage.toString(), 80),
          _buildDataCell(trade.entryPrice.toStringAsFixed(0), 90),
          _buildDataCell(trade.quantity.toStringAsFixed(2), 80),
          _buildDataCell(trade.sizeUSDT.toStringAsFixed(0), 90),
          _buildDataCell(
            trade.outcome,
            80,
            color: trade.outcome == 'Win' ? Colors.green : Colors.red,
          ),
          _buildDataCell(
            trade.pnl >= 0
                ? '+${trade.pnl.toStringAsFixed(0)}'
                : trade.pnl.toStringAsFixed(0),
            60,
            color: trade.pnl >= 0 ? Colors.green : Colors.red,
          ),
          _buildDataCell(
            trade.newBalance.toStringAsFixed(0),
            100,
            color: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {Color? color}) {
    return Container(
      width: width,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade600, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontSize: 10,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No trades yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Add your first trade above',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
