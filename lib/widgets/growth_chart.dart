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

  /// Generate exponential growth target data points
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

  /// Update chart bounds based on zoom level
  void _updateChartBounds() {
    // Always start from origin
    _minX = 0;
    _minY = 0;

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

    // Filter visible points
    _visibleTargetPoints = _targetDataPoints
        .where((spot) => spot.x >= extendedMinX && spot.x <= extendedMaxX)
        .toList();

    _visibleActualPoints = _actualDataPoints
        .where((spot) => spot.x >= extendedMinX && spot.x <= extendedMaxX)
        .toList();

    // Calculate Y-axis maximum based on the highest value in the VISIBLE range
    double maxVisibleValue = 0;

    // Check target points
    for (FlSpot spot in _targetDataPoints) {
      if (spot.x >= _minX && spot.x <= _maxX) {
        maxVisibleValue = math.max(maxVisibleValue, spot.y);
      }
    }

    // Check actual points
    for (FlSpot spot in _actualDataPoints) {
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

  /// Format Y-axis labels as USD values
  String _formatYAxisLabel(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  /// Format tooltip values
  String _formatTooltipValue(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  /// Get appropriate Y-axis intervals based on the current range
  double _getYAxisInterval() {
    double range = _maxY - _minY;
    double targetInterval = range / 8; // Aim for ~8 intervals

    // Round to nice round numbers
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
        // Title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Text(
            'ROAD TO \$1 MILLION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Zoom Controls
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: _zoomLevel,
                  min: 1.0,
                  max: 6.0,
                  divisions: 20,
                  activeColor: Colors.purpleAccent,
                  inactiveColor: Colors.grey.shade600,
                  onChanged: (value) {
                    setState(() {
                      _zoomLevel = value;
                      _updateChartBounds();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        // Chart
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: LineChart(
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
                      color: Colors.grey.shade700.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade700.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),

                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade600, width: 1),
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
                              color: Colors.white70,
                              fontSize: 10,
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
                            color: Colors.white70,
                            fontSize: 10,
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
                                ? Colors.purpleAccent
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),

                // Line data - both target and actual lines
                lineBarsData: [
                  // Target line (purple)
                  LineChartBarData(
                    spots: _visibleTargetPoints,
                    isCurved: true,
                    color: Colors.purpleAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purpleAccent.withOpacity(0.1),
                    ),
                  ),
                  // Actual profit line (green/lime)
                  if (_visibleActualPoints.isNotEmpty)
                    LineChartBarData(
                      spots: _visibleActualPoints,
                      isCurved:
                          false, // Keep actual line more angular to show real data points
                      color: Colors.green,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.green,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
