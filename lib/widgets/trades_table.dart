import 'package:compundx/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../models/trade.dart';
import '../services/trade_service.dart';
import 'edit_trade_dialog.dart';

class TradesTable extends StatelessWidget {
  const TradesTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.cardColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trades',
                style: TextStyle(
                  color: AppConstants.textPrimaryColor,
                  fontSize: AppConstants.largeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Balance display
              AnimatedBuilder(
                animation: TradeService(),
                builder: (context, child) {
                  final balance = TradeService().currentBalance;
                  final totalPnL = TradeService().totalPnL;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: totalPnL >= 0
                          ? AppConstants.successColor.withOpacity(0.2)
                          : AppConstants.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: totalPnL >= 0
                            ? AppConstants.successColor
                            : AppConstants.errorColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: AppConstants.textPrimaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Balance: \$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppConstants.textPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: AppConstants.mediumFontSize,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 1177,
            decoration: BoxDecoration(
              border: Border.all(color: AppConstants.borderColor),
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
                        return _buildTableRow(
                          context,
                          entry.value,
                          entry.key + 1,
                        );
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
        color: AppConstants.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('#', 40),
          _buildHeaderCell('Date', 75),
          _buildHeaderCell('Time', 50),
          _buildHeaderCell('Exchange', 80),
          _buildHeaderCell('Symbol', 90),
          _buildHeaderCell('Type', 50),
          _buildHeaderCell('Leverage', 70),
          _buildHeaderCell('Entry Price', 90),
          _buildHeaderCell('Quantity', 90),
          _buildHeaderCell('Size (\$)', 90),
          _buildHeaderCell('Result', 55),
          _buildHeaderCell('PNL', 90),
          _buildHeaderCell('Balance', 90),
          _buildHeaderCell('Before', 55),
          _buildHeaderCell('After', 55),
          _buildHeaderCell('Notes', 55),
          _buildHeaderCell('Edit', 50),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppConstants.borderColor, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: AppConstants.mediumFontSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Trade trade, int index) {
    final tradeService = TradeService();
    final currentBalance = tradeService.getBalanceAtIndex(index - 1);

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppConstants.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildDataCell(index.toString(), 40),
          _buildDataCell(
            '${trade.date.day.toString().padLeft(2, '0')}/${trade.date.month.toString().padLeft(2, '0')}/${trade.date.year.toString().substring(2)}',
            75,
          ),
          _buildDataCell(trade.time, 50),
          _buildDataCell(trade.exchange, 80),
          _buildDataCell(trade.symbol, 90),
          _buildDataCell(
            trade.type,
            50,
            color: trade.type == 'Long'
                ? AppConstants.successColor
                : AppConstants.errorColor,
          ),
          _buildDataCell(trade.leverage.toString(), 70),
          _buildDataCell(trade.entryPrice.toStringAsFixed(0), 90),
          _buildDataCell(trade.quantity.toStringAsFixed(2), 90),
          _buildDataCell(trade.sizeUSD.toStringAsFixed(0), 90),
          _buildDataCell(
            trade.result,
            55,
            color: trade.result == 'Win'
                ? AppConstants.successColor
                : trade.result == 'Loss'
                ? AppConstants.errorColor
                : AppConstants.textHintColor,
          ),
          _buildDataCell(
            trade.pnl == 0
                ? '–'
                : trade.pnl > 0
                ? '+${trade.pnl.toStringAsFixed(0)}'
                : trade.pnl.toStringAsFixed(0),
            90,
            color: trade.pnl > 0
                ? AppConstants.successColor
                : trade.pnl < 0
                ? AppConstants.errorColor
                : AppConstants.textHintColor,
          ),
          _buildDataCell(
            currentBalance.toStringAsFixed(0),
            90,
            color: AppConstants.primaryColor,
          ),
          _buildIconCell(
            trade.beforeScreenshotUrl != null
                ? Icons.image
                : Icons.image_not_supported,
            55,
            color: trade.beforeScreenshotUrl != null
                ? AppConstants.infoColor
                : AppConstants.borderColor,
            onTap: trade.beforeScreenshotUrl != null
                ? () => _showImageDialog(
                    context,
                    trade.beforeScreenshotUrl!,
                    'Before Screenshot',
                  )
                : null,
          ),
          _buildIconCell(
            trade.afterScreenshotUrl != null
                ? Icons.image
                : Icons.image_not_supported,
            55,
            color: trade.afterScreenshotUrl != null
                ? AppConstants.infoColor
                : AppConstants.borderColor,
            onTap: trade.afterScreenshotUrl != null
                ? () => _showImageDialog(
                    context,
                    trade.afterScreenshotUrl!,
                    'After Screenshot',
                  )
                : null,
          ),
          _buildIconCell(
            trade.notes != null && trade.notes!.isNotEmpty
                ? Icons.note
                : Icons.note,
            55,
            color: trade.notes != null && trade.notes!.isNotEmpty
                ? AppConstants.infoColor
                : AppConstants.borderColor,
            onTap: trade.notes != null && trade.notes!.isNotEmpty
                ? () => _showNotesDialog(context, trade.notes!)
                : null,
          ),
          _buildIconCell(
            Icons.edit,
            50,
            color: AppConstants.warningColor,
            onTap: () => _showEditDialog(context, trade),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {Color? color}) {
    return Container(
      width: width,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppConstants.borderColor, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? AppConstants.textSecondaryColor,
          fontSize: AppConstants.smallFontSize,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildIconCell(
    IconData icon,
    double width, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      width: width,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppConstants.borderColor, width: 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Icon(
          icon,
          size: 14,
          color: color ?? AppConstants.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppConstants.disabledColor,
            ),
            SizedBox(height: 12),
            Text(
              'No trades yet',
              style: TextStyle(
                color: AppConstants.disabledColor,
                fontSize: AppConstants.largeFontSize,
              ),
            ),
            Text(
              'Add your first trade above',
              style: TextStyle(
                color: AppConstants.disabledColor,
                fontSize: AppConstants.mediumFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Trade trade) {
    showDialog(
      context: context,
      builder: (context) => EditTradeDialog(trade: trade),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppConstants.surfaceColor,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppConstants.textPrimaryColor,
                  fontSize: AppConstants.largeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: AppConstants.cardColor,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              color: AppConstants.errorColor,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotesDialog(BuildContext context, String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text(
          'Trade Notes',
          style: TextStyle(color: AppConstants.textPrimaryColor),
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            notes,
            style: const TextStyle(color: AppConstants.textSecondaryColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
