import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../models/expense_model.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? _lastExportedFilePath;

  @override
  void initState() {
    super.initState();
    _loadLastExportedFilePath();
  }

  Future<void> _loadLastExportedFilePath() async {
    // Load the last exported file path from Hive
    final box = await Hive.openBox('settings');
    final savedPath = box.get('lastExportedFilePath') as String?;
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        _lastExportedFilePath = savedPath;
      });
    }
  }

  Future<void> _saveLastExportedFilePath(String filePath) async {
    final box = await Hive.openBox('settings');
    await box.put('lastExportedFilePath', filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () => _exportToExcel(context),
          ),
          if (_lastExportedFilePath != null)
            IconButton(
              icon: Icon(Icons.folder_open),
              onPressed: () => _openLastExportedFile(context),
              tooltip: 'Open last exported file',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncomeSection(),
            SizedBox(height: 24),
            _buildExpensePieChart(),
            SizedBox(height: 24),
            _buildDebtsSummary(),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final excel = Excel.createExcel();

      final expenseSheet = excel['Expenses'];
      expenseSheet.appendRow(['Date', 'Category', 'Amount', 'Comment']);
      final expenses = Hive.box<Expense>('expenses').values.toList();
      for (var expense in expenses) {
        expenseSheet.appendRow([
          expense.date.toString(),
          expense.category,
          expense.amount.toString(),
          expense.comment,
        ]);
      }

      final incomeSheet = excel['Income'];
      incomeSheet.appendRow(['Date', 'Source', 'Amount']);
      final incomes = Hive.box('income').values.cast<Map>().toList();
      for (var income in incomes) {
        incomeSheet.appendRow([
          income['timestamp'],
          income['source'],
          income['amount'].toString(),
        ]);
      }

      final debtsSheet = excel['Debts'];
      debtsSheet.appendRow(['Date', 'Person', 'Amount', 'Reason']);
      final debts = Hive.box('debts').values.cast<Map>().toList();
      for (var debt in debts) {
        debtsSheet.appendRow([
          debt['timestamp'],
          debt['person'],
          debt['amount'].toString(),
          debt['reason'],
        ]);
      }

      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!await downloadsDirectory.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloads directory does not exist')),
        );
        return;
      }

      final fileName = 'expense_tracker_${DateTime.now().toIso8601String().replaceAll(":", "-")}.xlsx';
      final filePath = '${downloadsDirectory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      setState(() {
        _lastExportedFilePath = filePath;
      });

      // Save file path to persistent storage
      await _saveLastExportedFilePath(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report exported successfully'),
              Text(
                'Location: $fileName',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () => _openLastExportedFile(context),
          ),
        ),
      );
    } catch (e) {
      print('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _openLastExportedFile(BuildContext context) async {
    if (_lastExportedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No exported file available')),
      );
      return;
    }

    try {
      final result = await OpenFile.open(_lastExportedFilePath!);
      if (result.type != ResultType.done) {
        print('Open file error: ${result.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${result.message}')),
        );
      }
    } catch (e) {
      print('Open file error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: $e')),
      );
    }
  }

  Widget _buildIncomeSection() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('income').listenable(),
      builder: (context, Box box, _) {
        final incomes = box.values.cast<Map>().toList();
        final totalIncome = incomes.fold<double>(
          0,
          (sum, income) => sum + (income['amount'] as double),
        );

        final sourceMap = <String, double>{};
        for (var income in incomes) {
          final source = income['source'] as String;
          sourceMap[source] = (sourceMap[source] ?? 0) + (income['amount'] as double);
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                Text(
                  'Total Income: ₹${totalIncome.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 16),
                ...sourceMap.entries.map((entry) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensePieChart() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Expense>('expenses').listenable(),
      builder: (context, Box<Expense> box, _) {
        final expenses = box.values.where((e) => e.amount < 0).toList();
        final categoryMap = <String, double>{};
        
        for (var expense in expenses) {
          categoryMap[expense.category] = (categoryMap[expense.category] ?? 0) + expense.amount.abs();
        }

        final pieData = categoryMap.entries
            .map((entry) => PieChartSectionData(
                  value: entry.value,
                  title: '${entry.key}\n₹${entry.value.toStringAsFixed(0)}',
                  color: Colors.primaries[
                      categoryMap.keys.toList().indexOf(entry.key) %
                          Colors.primaries.length],
                  radius: 100,
                ))
            .toList();

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: pieData,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebtsSummary() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('debts').listenable(),
      builder: (context, Box box, _) {
        final debts = box.values.cast<Map>().toList();
        final personMap = <String, double>{};
        
        for (var debt in debts) {
          final person = debt['person'] as String;
          personMap[person] = (personMap[person] ?? 0) + (debt['amount'] as double);
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debt Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                ...personMap.entries.map((entry) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: entry.value >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}
