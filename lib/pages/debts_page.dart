import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DebtsPage extends StatefulWidget {
  @override
  _DebtsPageState createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final TextEditingController _newPersonController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedPerson;
  bool _isPositiveAmount = true;

  @override
  void dispose() {
    _newPersonController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showAddPersonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Person'),
        content: TextField(
          controller: _newPersonController,
          decoration: InputDecoration(
            labelText: 'Person Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newPersonController.text.isNotEmpty) {
                final peopleBox = Hive.box('people');
                peopleBox.add(_newPersonController.text);
                setState(() {
                  _selectedPerson = _newPersonController.text;
                });
                _newPersonController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupExpensesByPerson(Box box) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (int i = 0; i < box.length; i++) {
      final expense = Map<String, dynamic>.from(box.getAt(i));
      final person = expense['person'] as String;
      
      if (!grouped.containsKey(person)) {
        grouped[person] = [];
      }
      grouped[person]!.add({...expense, 'index': i});
    }
    
    return grouped;
  }

  double _calculateTotal(List<Map<String, dynamic>> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + (expense['amount'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final debtsBox = Hive.box('debts');
    final peopleBox = Hive.box('people');

    return Scaffold(
      appBar: AppBar(title: Text('Manage Expenses')),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: debtsBox.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return Center(child: Text('No expenses recorded yet.'));
                }

                final groupedExpenses = _groupExpensesByPerson(box);
                
                return ListView.builder(
                  itemCount: groupedExpenses.length,
                  itemBuilder: (context, index) {
                    final person = groupedExpenses.keys.elementAt(index);
                    final expenses = groupedExpenses[person]!;
                    final total = _calculateTotal(expenses);
                    
                    return ExpansionTile(
                      title: Text(person),
                      subtitle: Text(
                        'Total: ${total >= 0 ? '₹$total' : '-₹${total.abs()}'}',
                        style: TextStyle(
                          color: total >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: expenses.map((expense) {
                        return Dismissible(
                          key: Key(expense['index'].toString()),
                          onDismissed: (direction) {
                            box.deleteAt(expense['index']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Record deleted')),
                            );
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            title: Text(
                              '${expense['amount'] >= 0 ? '₹${expense['amount']}' : '-₹${expense['amount'].abs()}'}',
                              style: TextStyle(
                                color: expense['amount'] >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            subtitle: Text('Reason: ${expense['reason']}'),
                            trailing: Text(DateTime.parse(expense['timestamp'])
                                .toLocal()
                                .toString()
                                .split('.')[0]),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: peopleBox.listenable(),
                        builder: (context, Box box, _) {
                          final people = List<String>.from(box.values);
                          return DropdownButtonFormField<String>(
                            value: _selectedPerson,
                            decoration: InputDecoration(
                              labelText: 'Select Person',
                              border: OutlineInputBorder(),
                            ),
                            items: people.map((person) {
                              return DropdownMenuItem(
                                value: person,
                                child: Text(person),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPerson = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _showAddPersonDialog(context),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(width: 8),
                    ToggleButtons(
                      isSelected: [_isPositiveAmount, !_isPositiveAmount],
                      onPressed: (index) {
                        setState(() {
                          _isPositiveAmount = index == 0;
                        });
                      },
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('+', style: TextStyle(color: Colors.green)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedPerson == null ||
                        _amountController.text.isEmpty ||
                        _reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    try {
                      double amount = double.parse(_amountController.text);
                      if (!_isPositiveAmount) {
                        amount = -amount;
                      }

                      final expense = {
                        'person': _selectedPerson,
                        'amount': amount,
                        'reason': _reasonController.text,
                        'timestamp': DateTime.now().toIso8601String(),
                      };

                      debtsBox.add(expense);

                      // Clear input fields
                      _amountController.clear();
                      _reasonController.clear();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Record added')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid amount entered')),
                      );
                    }
                  },
                  child: Text('Add Record'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}