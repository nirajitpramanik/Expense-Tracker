import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models/expense_model.dart';
import 'pages/expense_list.dart';
import 'pages/debts_page.dart';
import 'pages/budget_page.dart';
import 'pages/expense_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseAdapter());

  await Hive.openBox<Expense>('expenses');
  await Hive.openBox('categories');
  await Hive.openBox('debts');
  await Hive.openBox('people');
  await Hive.openBox('budget');
  await Hive.openBox('income');

  // Add default categories if none exist
  var categoriesBox = Hive.box('categories');
  if (categoriesBox.isEmpty) {
    categoriesBox.addAll([
      'Food',
      'Transportation',
      'Shopping',
      'Bills',
      'Entertainment',
      'Health',
      'Education',
      'Other'
    ]);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.grey[900]!,
          background: Colors.black,
        ),
        cardTheme: CardTheme(
          color: Colors.grey[850],
          elevation: 4,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 2,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedCategory;
  bool _isExpense = true;

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Expense Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your finances',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Expenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpenseList()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet),
              title: Text('Budget'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BudgetPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.money),
              title: Text('Debts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DebtsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthlyOverviewCard(context),
              SizedBox(height: 24),
              _buildAddTransactionSection(context),
              SizedBox(height: 24),
              _buildRecentTransactionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyOverviewCard(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('budget').listenable(),
      builder: (context, Box budgetBox, _) {
        double monthlyBudget = budgetBox.get('monthlyBudget', defaultValue: 0.0);

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BudgetPage()),
                        );
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit Budget'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ValueListenableBuilder(
                  valueListenable: Hive.box<Expense>('expenses').listenable(),
                  builder: (context, Box<Expense> expensesBox, _) {
                    //double balance = _calculateMonthlyBalance(expensesBox);
                    double income = _calculateMonthlyIncome(expensesBox);
                    double expenses = _calculateMonthlyExpenses(expensesBox);
                    double remaining = monthlyBudget - expenses + income;

                    return Column(
                      children: [
                        _buildBudgetRow('Monthly Budget', monthlyBudget, textColor: Colors.blue),
                        SizedBox(height: 8),
                        _buildBudgetRow('Income', income, textColor: Colors.green),
                        SizedBox(height: 8),
                        _buildBudgetRow('Expenses', expenses, textColor: Colors.red),
                        Divider(),
                        _buildBudgetRow(
                          'Budget Remaining',
                          remaining,
                          textColor: remaining < 0 ? Colors.red : Colors.green,
                        ),
                        /*SizedBox(height: 8),
                        _buildBudgetRow(
                          'Account Balance',
                          balance,
                          textColor: balance < 0 ? Colors.red : Colors.green,
                        ),*/
                        SizedBox(height: 16),
                        if (monthlyBudget > 0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (expenses / monthlyBudget).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[700],
                              valueColor: AlwaysStoppedAnimation(
                                remaining < 0 ? Colors.red : Colors.green,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${(((monthlyBudget - remaining) / monthlyBudget) * 100).toStringAsFixed(1)}% of budget used',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTransactionSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text('Expense'),
                        icon: Icon(Icons.remove),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Income'),
                        icon: Icon(Icons.add),
                      ),
                    ],
                    selected: {_isExpense},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _isExpense = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: Hive.box('categories').listenable(),
              builder: (context, Box categoriesBox, _) {
                List<String> categories = List<String>.from(categoriesBox.values);

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        final newCategory = await _showAddCategoryDialog(context);
                        if (newCategory != null && newCategory.isNotEmpty) {
                          categoriesBox.add(newCategory);
                        }
                      },
                    ),
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addTransaction,
                icon: Icon(Icons.add),
                label: Text('Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExpenseList()),
                    );
                  },
                  icon: Icon(Icons.list),
                  label: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: Hive.box<Expense>('expenses').listenable(),
              builder: (context, Box<Expense> expensesBox, _) {
                final recentExpenses = expensesBox.values.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                final recent = recentExpenses.take(5).toList();

                return Column(
                  children: recent.map((expense) {
                    return ListTile(
                      leading: Icon(
                        expense.amount < 0 ? Icons.remove : Icons.add,
                        color: expense.amount < 0 ? Colors.red : Colors.green,
                      ),
                      title: Text(expense.category),
                      subtitle: Text(
                        expense.comment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${expense.amount.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: expense.amount < 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd').format(expense.date),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addTransaction() {
    if (_amountController.text.isEmpty ||
        _selectedCategory == null ||
        _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final expense = Expense(
      amount: _isExpense ? -amount : amount,
      category: _selectedCategory!,
      comment: _commentController.text,
      date: DateTime.now(),
    );

    final box = Hive.box<Expense>('expenses');
    box.add(expense);

    _amountController.clear();
    _commentController.clear();
    setState(() {
      _selectedCategory = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction added successfully')),
    );
  }

  Future<String?> _showAddCategoryDialog(BuildContext context) {
    final categoryController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Category'),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, categoryController.text.trim()),
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  double _calculateMonthlyExpenses(Box<Expense> expensesBox) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return expensesBox.values
        .where((expense) =>
            expense.amount < 0 && expense.date.isAfter(startOfMonth))
        .fold(0.0, (total, expense) => total + expense.amount.abs());
  }

  double _calculateMonthlyIncome(Box<Expense> expensesBox) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return expensesBox.values
        .where((expense) =>
            expense.amount > 0 && expense.date.isAfter(startOfMonth))
        .fold(0.0, (total, expense) => total + expense.amount.abs());
  }

  /*double _calculateMonthlyBalance(Box<Expense> expensesBox) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return expensesBox.values
        .where((expense) => expense.date.isAfter(startOfMonth))
        .fold(0.0, (total, expense) => total + expense.amount);
  }*/

  Widget _buildBudgetRow(String title, double value,
      {required Color textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
