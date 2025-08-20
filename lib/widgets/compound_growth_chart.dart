import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CompoundGrowthChart extends StatefulWidget {
  const CompoundGrowthChart({super.key});

  @override
  State<CompoundGrowthChart> createState() => _CompoundGrowthChartState();
}

class _CompoundGrowthChartState extends State<CompoundGrowthChart> {
  static const double initialBalance = 100.0;
  static const double weeklyGrowthRate = 0.20; // 20%
  static const int totalWeeks = 51;

  List<FlSpot> expectedBalanceSpots = [];
  List<FlSpot> actualBalanceSpots = [];

  @override
  void initState() {
    super.initState();
    _generateExpectedBalanceData();
    _generateInitialActualData();
  }

  void _generateExpectedBalanceData() {
    expectedBalanceSpots.clear();
    double balance = initialBalance;

    expectedBalanceSpots.add(FlSpot(0, balance));

    for (int week = 1; week <= totalWeeks; week++) {
      balance *= (1 + weeklyGrowthRate);
      expectedBalanceSpots.add(FlSpot(week.toDouble(), balance));
    }
  }

  void _generateInitialActualData() {
    // Starting with just the initial balance
    actualBalanceSpots.clear();
    actualBalanceSpots.add(const FlSpot(0, initialBalance));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROAD TO \$1 MILLION',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(Colors.purple, 'Expected Profit', true),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.white, 'Actual Profit', false),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 100000,
                  verticalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        // Only show titles for multiples of 5
                        if (value % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            'Week ${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100000,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            _formatCurrency(value),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: totalWeeks.toDouble(),
                minY: 0,
                maxY: 1100000,
                lineBarsData: [
                  // Expected Balance Line (dotted)
                  LineChartBarData(
                    spots: expectedBalanceSpots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5], // Creates dotted line
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withOpacity(0.1),
                    ),
                  ),
                  // Actual Balance Line (solid)
                  LineChartBarData(
                    spots: actualBalanceSpots,
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.purple,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorder: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final isExpected = barSpot.barIndex == 0;
                        return LineTooltipItem(
                          '${isExpected ? 'Expected' : 'Actual'}\nWeek ${flSpot.x.toInt()}: ${_formatCurrency(flSpot.y)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCards(),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDotted) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDotted
              ? CustomPaint(
                  painter: DottedLinePainter(color),
                  size: const Size(20, 3),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final expectedFinalBalance = expectedBalanceSpots.last.y;
    final currentActualBalance = actualBalanceSpots.last.y;
    final currentWeek = actualBalanceSpots.length - 1;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Expected Balance (Week 51)',
            expectedFinalBalance,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Current Balance (Week $currentWeek)',
            currentActualBalance,
            Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Weekly Growth Target',
            20.0,
            Colors.green,
            isPercentage: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    Color color, {
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(0)}%'
                : _formatCurrency(value),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
