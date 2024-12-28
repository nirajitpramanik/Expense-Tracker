import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense_model.dart';  // Add this import

class SettingsPage extends StatelessWidget {
  final TextEditingController _newPersonController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  Future<void> _requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      _showSnackBar(context, 'Storage permission already granted.');
      return;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        _showSnackBar(context, 'Storage permission granted.');
      } else {
        _showSnackBar(context, 'Storage permission denied.');
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      _showSnackBar(context, 'Permission permanently denied. Opening settings...');
      await openAppSettings();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Expenses'),
        content: Text(
          'This will permanently delete all expense records. This action cannot be undone. Categories, budgets, and debts will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                // Get the expenses box as Box<Expense>
                final expensesBox = Hive.box<Expense>('expenses');
                await expensesBox.clear();
                Navigator.pop(context);
                _showSnackBar(context, 'All expenses have been reset');
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar(context, 'Error resetting expenses: $e');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required Function(String) onAdd,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                controller.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    String title,
    Box box,
    VoidCallback onAdd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box box, _) {
            final items = List<String>.from(box.values);
            return Column(
              children: [
                ...items.map((item) => ListTile(
                      title: Text(item),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => box.deleteAt(items.indexOf(item)),
                      ),
                    )),
                ElevatedButton(
                  onPressed: onAdd,
                  child: Text('Add ${title.toLowerCase()}'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final peopleBox = Hive.box('people');
    final categoriesBox = Hive.box('categories');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  title: const Text('Storage Permission'),
                  subtitle: const Text('Required for saving reports'),
                  trailing: ElevatedButton(
                    onPressed: () => _requestStoragePermission(context),
                    child: const Text('Request'),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Management',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showResetConfirmationDialog(context),
                        icon: Icon(Icons.refresh),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        label: Text('Reset Expenses'),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This will delete all expense records while preserving categories, budgets, and debts.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildListSection(
                    'People',
                    peopleBox,
                    () => _showAddDialog(
                      context,
                      title: 'Add New Person',
                      controller: _newPersonController,
                      onAdd: (value) => peopleBox.add(value),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildListSection(
                    'Categories',
                    categoriesBox,
                    () => _showAddDialog(
                      context,
                      title: 'Add New Category',
                      controller: _newCategoryController,
                      onAdd: (value) => categoriesBox.add(value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}