import 'package:compundx/constants/app_constants.dart';
import 'package:compundx/widgets/add_trade_form.dart';
import 'package:compundx/widgets/growth_chart.dart';
import 'package:compundx/widgets/trades_table.dart';
import 'package:compundx/services/trade_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CompundX());
}

class CompundX extends StatelessWidget {
  const CompundX({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompundX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TradeService _tradeService = TradeService();
  bool _sampleTradesLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load sample trades on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sampleTradesLoaded) {
        _tradeService.addSampleTrades();
        setState(() {
          _sampleTradesLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Growth Chart - reduced height for better layout
              SizedBox(height: 800, child: const GrowthChart()),
              Container(height: 20),

              // Add Trade Form - now optimized and compact
              AddTradeForm(),
              Container(height: 20),

              // Trades Table
              TradesTable(),
              Container(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
