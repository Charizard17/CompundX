import 'package:compundx/widgets/add_trade_form.dart';
import 'package:compundx/widgets/growth_chart.dart';
import 'package:compundx/widgets/trades_table.dart';
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
        scaffoldBackgroundColor: Colors.black,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 1000, child: const GrowthChart()),
              Container(height: 30),
              AddTradeForm(),
              Container(height: 30),
              TradesTable(),
              Container(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
