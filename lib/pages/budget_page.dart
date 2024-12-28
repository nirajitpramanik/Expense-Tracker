import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class BudgetPage extends StatefulWidget {
  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _incomeSourceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final budgetBox = Hive.box('budget');
    _budgetController.text = (budgetBox.get('monthlyBudget', defaultValue: 0.0) as double).toString();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _incomeController.dispose();
    _incomeSourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Management'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Monthly Budget', Icons.account_balance_wallet),
              _buildBudgetCard(),
              SizedBox(height: 24),
              _buildSectionHeader('Income Sources', Icons.money),
              _buildIncomeCard(),
              SizedBox(height: 24),
              _buildSectionHeader('Monthly Summary', Icons.pie_chart),
              _buildSummaryCard(),
              SizedBox(height: 24),
              _buildSectionHeader('Recent Income', Icons.history),
              _buildRecentIncomeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: 'Set Monthly Budget',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
                helperText: 'Enter your total monthly budget',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveBudget,
                icon: Icon(Icons.save),
                label: Text('Save Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _incomeSourceController,
              decoration: InputDecoration(
                labelText: 'Income Source',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addIncome,
                icon: Icon(Icons.add),
                label: Text('Add Income'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('income').listenable(),
      builder: (context, Box incomeBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Expense>('expenses').listenable(),
          builder: (context, Box<Expense> expenseBox, _) {
            final totalIncome = _calculateTotalIncome(incomeBox);
            final totalExpenses = _calculateMonthlyExpenses(expenseBox);
            final balance = totalIncome - totalExpenses;
            
            return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Income', totalIncome, Colors.green),
                    SizedBox(height: 8),
                    _buildSummaryRow('Total Expenses', totalExpenses, Colors.red),
                    Divider(height: 24),
                    _buildSummaryRow(
                      'Balance',
                      balance,
                      balance >= 0 ? Colors.green : Colors.red,
                    ),
                    SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: totalIncome > 0 ? (totalExpenses / totalIncome).clamp(0.0, 1.0) : 1.0,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation(
                        totalExpenses <= totalIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentIncomeCard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('income').listenable(),
      builder: (context, Box box, _) {
        final incomes = box.values.toList().cast<Map<String, dynamic>>();
        incomes.sort((a, b) => DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp'])));
        
        return Card(
          elevation: 4,
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: incomes.take(5).length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final income = incomes[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.money),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                title: Text(income['source']),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(
                    DateTime.parse(income['timestamp']),
                  ),
                ),
                trailing: Text(
                  '₹${income['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _saveBudget() async {
    if (_budgetController.text.isNotEmpty) {
      final budget = double.parse(_budgetController.text);
      await Hive.box('budget').put('monthlyBudget', budget);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monthly budget updated')),
      );
    }
  }

  void _addIncome() async {
    if (_incomeController.text.isNotEmpty && _incomeSourceController.text.isNotEmpty) {
      final amount = double.parse(_incomeController.text);
      final source = _incomeSourceController.text;
      
      await Hive.box('income').add({
        'source': source,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _incomeController.clear();
      _incomeSourceController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income added successfully')),
      );
    }
  }

  double _calculateMonthlyExpenses(Box<Expense> box) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    return box.values
        .where((expense) => expense.date.isAfter(firstDayOfMonth))
        .fold(0.0, (total, expense) => total + expense.amount.abs());
  }

  double _calculateTotalIncome(Box box) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    return box.values
        .whereType<Map>()
        .where((income) => DateTime.parse(income['timestamp']).isAfter(firstDayOfMonth))
        .fold(0.0, (total, income) => total + (income['amount'] as double));
  }
}