import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController _newPersonController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final peopleBox = Hive.box('people');
    final categoriesBox = Hive.box('categories');

    void _addPerson(BuildContext context) {
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
                  peopleBox.add(_newPersonController.text);
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

    void _addCategory(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            controller: _newCategoryController,
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
            ElevatedButton(
              onPressed: () {
                if (_newCategoryController.text.isNotEmpty) {
                  categoriesBox.add(_newCategoryController.text);
                  _newCategoryController.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'People',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ValueListenableBuilder(
              valueListenable: peopleBox.listenable(),
              builder: (context, Box box, _) {
                final people = List<String>.from(box.values);
                return Column(
                  children: [
                    ...people.map((person) => ListTile(
                          title: Text(person),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              box.deleteAt(people.indexOf(person));
                            },
                          ),
                        )),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _addPerson(context),
                      child: Text('Add Person'),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ValueListenableBuilder(
              valueListenable: categoriesBox.listenable(),
              builder: (context, Box box, _) {
                final categories = List<String>.from(box.values);
                return Column(
                  children: [
                    ...categories.map((category) => ListTile(
                          title: Text(category),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              box.deleteAt(categories.indexOf(category));
                            },
                          ),
                        )),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _addCategory(context),
                      child: Text('Add Category'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
