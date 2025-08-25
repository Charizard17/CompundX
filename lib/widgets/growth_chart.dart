import 'package:compundx/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/trade_service.dart';

class GrowthChart extends StatefulWidget {
  const GrowthChart({Key? key}) : super(key: key);

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart> {
  double _zoomLevel = 1.0;
  bool _isLogScale = false; // LINEAR/LOG toggle
  bool _showActualData = true; // NEW
  bool _showTargetCurve = true; // NEW
  List<FlSpot> _targetDataPoints = [];
  List<FlSpot> _actualDataPoints = [];
  List<FlSpot> _visibleTargetPoints = [];
  List<FlSpot> _visibleActualPoints = [];
  final TradeService _tradeService = TradeService();

  // Chart bounds based on zoom level
  double _minX = 0;
  double _maxX = 51;
  double _minY = 0;
  double _maxY = 1100000;

  @override
  void initState() {
    super.initState();
    _generateTargetDataPoints();
    _generateActualDataPoints();
    _updateChartBounds();

    // Listen to trade service changes
    _tradeService.addListener(_onTradesChanged);
  }

  @override
  void dispose() {
    _tradeService.removeListener(_onTradesChanged);
    super.dispose();
  }

  void _onTradesChanged() {
    setState(() {
      _generateActualDataPoints();
      _updateChartBounds();
    });
  }

  /// Convert value to logarithmic scale for display
  double _toLogScale(double value) {
    if (!_isLogScale) return value;
    return value <= 0 ? 0 : math.log(value) / math.ln10; // log base 10
  }

  /// Convert logarithmic scale back to actual value
  double _fromLogScale(double logValue) {
    if (!_isLogScale) return logValue;
    return math.pow(10, logValue).toDouble();
  }

  /// Convert data points to logarithmic scale if needed
  List<FlSpot> _convertToDisplayScale(List<FlSpot> points) {
    if (!_isLogScale) return points;

    return points.map((spot) {
      double logY = spot.y <= 0 ? 0 : math.log(spot.y) / math.ln10;
      return FlSpot(spot.x, logY);
    }).toList();
  }

  /// Formula: Value at week n = 100 × (1.2)^n
  void _generateTargetDataPoints() {
    _targetDataPoints.clear();
    for (int week = 0; week <= 51; week++) {
      double value = 100 * math.pow(1.2, week).toDouble();
      _targetDataPoints.add(FlSpot(week.toDouble(), value));
    }
  }

  /// Generate actual profit data points based on real trades
  void _generateActualDataPoints() {
    _actualDataPoints.clear();

    final weeklyProfits = _tradeService.getWeeklyProfits();
    final firstTradeWeek = _tradeService.getFirstTradeWeek();

    if (firstTradeWeek == null || weeklyProfits.isEmpty) {
      return; // No trades yet
    }

    // Starting balance
    double cumulativeBalance = 100.0;
    _actualDataPoints.add(FlSpot(0, cumulativeBalance));

    // Get all weeks that have trades, sorted
    List<int> weeksWithTrades = weeklyProfits.keys.toList()..sort();

    // Convert calendar weeks to chart weeks (first trade week becomes Week 1)
    for (int i = 0; i < weeksWithTrades.length; i++) {
      int calendarWeek = weeksWithTrades[i];
      int chartWeek =
          calendarWeek -
          firstTradeWeek +
          1; // Convert to chart week (1, 2, 3, etc.)

      // Add weekly profit to cumulative balance
      double weeklyProfit = weeklyProfits[calendarWeek]!;
      cumulativeBalance += weeklyProfit;

      _actualDataPoints.add(FlSpot(chartWeek.toDouble(), cumulativeBalance));

      // If there's a gap to the next week with trades, fill it
      if (i < weeksWithTrades.length - 1) {
        int nextCalendarWeek = weeksWithTrades[i + 1];
        int gapWeeks = nextCalendarWeek - calendarWeek;

        // Fill gap weeks with the same balance (flat line)
        for (int gapWeek = 1; gapWeek < gapWeeks; gapWeek++) {
          int gapChartWeek = chartWeek + gapWeek;
          _actualDataPoints.add(
            FlSpot(gapChartWeek.toDouble(), cumulativeBalance),
          );
        }
      }
    }

    // Sort by week to ensure proper line drawing
    _actualDataPoints.sort((a, b) => a.x.compareTo(b.x));
  }

  /// Update chart bounds based on zoom level and scale type
  void _updateChartBounds() {
    // Always start from origin
    _minX = 0;

    // Calculate visible X-axis range (zoom scales down from full 51 weeks)
    double fullWeeks = 51;
    _maxX = fullWeeks / _zoomLevel;

    // Ensure we don't exceed the actual data range
    if (_maxX > fullWeeks) {
      _maxX = fullWeeks;
    }

    // Include data points slightly beyond visible range for smooth curves
    double bufferRange = 2.0;
    double extendedMinX = math.max(0, _minX - bufferRange);
    double extendedMaxX = math.min(51, _maxX + bufferRange);

    // Filter visible points (in original scale)
    List<FlSpot> originalTargetPoints = _targetDataPoints
        .where((spot) => spot.x >= extendedMinX && spot.x <= extendedMaxX)
        .toList();

    List<FlSpot> originalActualPoints = _actualDataPoints
        .where((spot) => spot.x >= extendedMinX && spot.x <= extendedMaxX)
        .toList();

    // Convert to display scale (log or linear)
    _visibleTargetPoints = _convertToDisplayScale(originalTargetPoints);
    _visibleActualPoints = _convertToDisplayScale(originalActualPoints);

    // Calculate Y-axis bounds
    if (_isLogScale) {
      _updateLogYBounds(originalTargetPoints, originalActualPoints);
    } else {
      _updateLinearYBounds(originalTargetPoints, originalActualPoints);
    }
  }

  /// Update Y bounds for linear scale
  void _updateLinearYBounds(
    List<FlSpot> targetPoints,
    List<FlSpot> actualPoints,
  ) {
    _minY = 0;

    // Calculate Y-axis maximum based on the highest value in the VISIBLE range
    double maxVisibleValue = 0;

    // Check target points
    for (FlSpot spot in targetPoints) {
      if (spot.x >= _minX && spot.x <= _maxX) {
        maxVisibleValue = math.max(maxVisibleValue, spot.y);
      }
    }

    // Check actual points
    for (FlSpot spot in actualPoints) {
      if (spot.x >= _minX && spot.x <= _maxX) {
        maxVisibleValue = math.max(maxVisibleValue, spot.y);
      }
    }

    // Add small padding (10%) so curves don't touch the top
    _maxY = maxVisibleValue * 1.1;

    // Cap the Y-axis at 1.1M USD maximum
    if (_maxY > 1100000) {
      _maxY = 1100000;
    }

    // Ensure minimum Y range for very small values
    if (_maxY < 200) {
      _maxY = 200;
    }
  }

  /// Update Y bounds for logarithmic scale
  void _updateLogYBounds(List<FlSpot> targetPoints, List<FlSpot> actualPoints) {
    // Find min and max values in original scale
    double minOriginalValue = double.infinity;
    double maxOriginalValue = 0;

    // Check target points
    for (FlSpot spot in targetPoints) {
      if (spot.x >= _minX && spot.x <= _maxX && spot.y > 0) {
        minOriginalValue = math.min(minOriginalValue, spot.y);
        maxOriginalValue = math.max(maxOriginalValue, spot.y);
      }
    }

    // Check actual points
    for (FlSpot spot in actualPoints) {
      if (spot.x >= _minX && spot.x <= _maxX && spot.y > 0) {
        minOriginalValue = math.min(minOriginalValue, spot.y);
        maxOriginalValue = math.max(maxOriginalValue, spot.y);
      }
    }

    // Handle edge cases
    if (minOriginalValue == double.infinity) {
      minOriginalValue = 100; // Starting balance
      maxOriginalValue = 1000000; // 1M target
    }

    // Convert to log scale with some padding
    double logMin = math.log(minOriginalValue) / math.ln10;
    double logMax = math.log(maxOriginalValue) / math.ln10;

    // Expand the range slightly and round to nice values
    _minY = (logMin - 0.1).floorToDouble();
    _maxY = (logMax + 0.1).ceilToDouble();

    // Ensure reasonable bounds
    if (_minY < 0) _minY = 0; // Minimum 10^0 = $1
    if (_maxY > 6) _maxY = 6; // Maximum 10^6 = $1M
  }

  /// Format Y-axis labels as USD values - FIXED VERSION
  String _formatYAxisLabel(double value) {
    if (_isLogScale) {
      // Convert log value back to actual dollar amount
      double actualValue = _fromLogScale(value);
      return _formatCurrency(actualValue);
    } else {
      return _formatCurrency(value);
    }
  }

  /// Format currency with appropriate units (K, M)
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }

  /// Format tooltip values - FIXED VERSION
  String _formatTooltipValue(double value) {
    if (_isLogScale) {
      // Convert log value back to actual dollar amount
      double actualValue = _fromLogScale(value);
      return _formatCurrency(actualValue);
    } else {
      return _formatCurrency(value);
    }
  }

  /// Get appropriate Y-axis intervals based on scale type and current range
  double _getYAxisInterval() {
    if (_isLogScale) {
      // For log scale, use intervals of 1.0 (each represents a power of 10)
      double range = _maxY - _minY;

      if (range <= 2) {
        return 0.30103; // log10(2) ≈ 0.301, gives us nice intervals like 100, 200, 500, 1000
      } else if (range <= 4) {
        return 1.0; // Show every power of 10: 10, 100, 1000, 10000
      } else {
        return 1.0; // Always show major powers for large ranges
      }
    } else {
      // Linear scale intervals (existing logic)
      double range = _maxY - _minY;
      double targetInterval = range / 8; // Aim for ~8 intervals

      if (targetInterval >= 500000) {
        return 500000.0;
      } else if (targetInterval >= 200000) {
        return 200000.0;
      } else if (targetInterval >= 100000) {
        return 100000.0;
      } else if (targetInterval >= 50000) {
        return 50000.0;
      } else if (targetInterval >= 20000) {
        return 20000.0;
      } else if (targetInterval >= 10000) {
        return 10000.0;
      } else if (targetInterval >= 5000) {
        return 5000.0;
      } else if (targetInterval >= 2000) {
        return 2000.0;
      } else if (targetInterval >= 1000) {
        return 1000.0;
      } else if (targetInterval >= 500) {
        return 500.0;
      } else if (targetInterval >= 200) {
        return 200.0;
      } else if (targetInterval >= 100) {
        return 100.0;
      } else if (targetInterval >= 50) {
        return 50.0;
      } else if (targetInterval >= 20) {
        return 20.0;
      } else if (targetInterval >= 10) {
        return 10.0;
      } else {
        return math.max(1.0, targetInterval.ceil().toDouble());
      }
    }
  }

  /// Get appropriate X-axis intervals based on the current range and zoom level
  double _getXAxisInterval() {
    double range = _maxX - _minX;

    if (range <= 8) {
      return 1; // Show every week for very zoomed in views
    } else if (range <= 16) {
      return 2; // Show every 2 weeks
    } else if (range <= 30) {
      return 3; // Show every 3 weeks
    } else if (range <= 40) {
      return 5; // Show every 5 weeks
    } else {
      return 5; // Show every 5 weeks even for full view
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.cardColor),
          ),
          child: Row(
            children: [
              // LINEAR/LOG Scale Toggle Buttons
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogScale = false;
                          _updateChartBounds();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: !_isLogScale
                              ? AppConstants.primaryColor
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          'LINEAR',
                          style: TextStyle(
                            color: !_isLogScale
                                ? AppConstants.textPrimaryColor
                                : AppConstants.textSecondaryColor,
                            fontSize: AppConstants.mediumFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogScale = true;
                          _updateChartBounds();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isLogScale
                              ? AppConstants.primaryColor
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          'LOG',
                          style: TextStyle(
                            color: _isLogScale
                                ? AppConstants.textPrimaryColor
                                : AppConstants.textSecondaryColor,
                            fontSize: AppConstants.mediumFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 50),

              // Zoom Controls
              Expanded(
                child: Slider(
                  value: _zoomLevel,
                  min: 1.0,
                  max: 6.0,
                  divisions: 20,
                  activeColor: AppConstants.primaryColor,
                  inactiveColor: AppConstants.borderColor,
                  onChanged: (value) {
                    setState(() {
                      _zoomLevel = value;
                      _updateChartBounds();
                    });
                  },
                ),
              ),

              SizedBox(width: 50),

              // Line toggles (Actual and Target)
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showActualData = !_showActualData;
                        _updateChartBounds();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _showActualData
                            ? AppConstants.successColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _showActualData
                              ? AppConstants.successColor
                              : AppConstants.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppConstants.successColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Actual',
                            style: TextStyle(
                              color: _showActualData
                                  ? AppConstants.successColor
                                  : AppConstants.textPrimaryColor,
                              fontSize: AppConstants.mediumFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showTargetCurve = !_showTargetCurve;
                        _updateChartBounds();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _showTargetCurve
                            ? AppConstants.primaryColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _showTargetCurve
                              ? AppConstants.primaryColor
                              : AppConstants.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Target',
                            style: TextStyle(
                              color: _showTargetCurve
                                  ? AppConstants.primaryColor
                                  : AppConstants.textPrimaryColor,
                              fontSize: AppConstants.mediumFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Chart
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.cardColor),
            ),
            child: AnimatedBuilder(
              animation: _tradeService,
              builder: (context, child) {
                // Regenerate data when trades change
                _generateActualDataPoints();
                _updateChartBounds();

                return LineChart(
                  LineChartData(
                    minX: _minX,
                    maxX: _maxX,
                    minY: _minY,
                    maxY: _maxY,

                    // Clip data to prevent overflow
                    clipData: FlClipData.all(),

                    // Grid and borders
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: _getYAxisInterval(),
                      verticalInterval: _getXAxisInterval(),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppConstants.dividerColor.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: AppConstants.dividerColor.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),

                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: AppConstants.borderColor,
                        width: 1,
                      ),
                    ),

                    // Axes titles and labels
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _getXAxisInterval(),
                          getTitlesWidget: (value, meta) {
                            // Only show titles for values within our range
                            if (value < _minX || value > _maxX) {
                              return const SizedBox.shrink();
                            }
                            // Show label for exact interval values
                            double interval = _getXAxisInterval();
                            if (value % interval == 0) {
                              return Text(
                                'Week ${value.toInt()}',
                                style: const TextStyle(
                                  color: AppConstants.textSecondaryColor,
                                  fontSize: AppConstants.mediumFontSize,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: _getYAxisInterval(),
                          getTitlesWidget: (value, meta) {
                            // Only show titles for values within our range
                            if (value < _minY || value > _maxY) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              _formatYAxisLabel(value),
                              style: const TextStyle(
                                color: AppConstants.textSecondaryColor,
                                fontSize: AppConstants.mediumFontSize,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),

                    // Tooltip configuration
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            String lineType = touchedSpot.barIndex == 0
                                ? 'Target'
                                : 'Actual';
                            return LineTooltipItem(
                              '$lineType\nWeek ${touchedSpot.x.toInt()}\n${_formatTooltipValue(touchedSpot.y)}',
                              TextStyle(
                                color: touchedSpot.barIndex == 0
                                    ? AppConstants.primaryColor
                                    : AppConstants.successColor,
                                fontWeight: FontWeight.bold,
                                fontSize: AppConstants.mediumFontSize,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),

                    // Line data - both target and actual lines
                    lineBarsData: [
                      if (_showTargetCurve)
                        LineChartBarData(
                          spots: _visibleTargetPoints,
                          isCurved: true,
                          color: AppConstants.primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppConstants.primaryColor.withOpacity(0.1),
                          ),
                        ),
                      if (_showActualData && _visibleActualPoints.isNotEmpty)
                        LineChartBarData(
                          spots: _visibleActualPoints,
                          isCurved: false,
                          color: AppConstants.successColor,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: AppConstants.successColor,
                                strokeWidth: 1,
                                strokeColor: AppConstants.textPrimaryColor,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Statistics row
        if (_actualDataPoints.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.cardColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Current Balance',
                  _formatCurrency(_tradeService.currentBalance),
                  AppConstants.textPrimaryColor,
                ),
                _buildStatColumn(
                  'Total P&L',
                  _formatCurrency(_tradeService.totalPnL),
                  _tradeService.totalPnL >= 0
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                ),
                _buildStatColumn(
                  'Win Rate',
                  _tradeService.totalTrades > 0
                      ? '${((_tradeService.winningTrades / _tradeService.totalTrades) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  AppConstants.primaryColor,
                ),
                _buildStatColumn(
                  'Total Trades',
                  '${_tradeService.totalTrades}',
                  AppConstants.textSecondaryColor,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppConstants.textSecondaryColor,
            fontSize: AppConstants.mediumFontSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: AppConstants.largeFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
