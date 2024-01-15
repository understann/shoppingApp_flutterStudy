import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widget/new_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroceyList extends StatefulWidget {
  const GroceyList({super.key});

  @override
  State<GroceyList> createState() => _GroceyListState();
}

class _GroceyListState extends State<GroceyList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url = Uri.https(
        dotenv.env['FIREBASEURL']!,
        'shopping-list.json');

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to Fetch Data. Pleas try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
              id: item.key,
              name: item.value['name'],
              quantity: item.value['quantity'],
              category: category),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
        dotenv.env['FIREBASEURL']!,
        'shopping-list/${item.id}.json');
    var response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Groceries'),
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
          ],
        ),
        body: Center(child: Text(_error!)),
      );
    } else {
      return _isLoading
          ? Scaffold(
              appBar: AppBar(
                title: const Text('My Groceries'),
                actions: [
                  IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
                ],
              ),
              body: const Center(child: CircularProgressIndicator()),
            )
          : Scaffold(
              appBar: AppBar(
                title: const Text('My Groceries'),
                actions: [
                  IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
                ],
              ),
              body: _groceryItems.isEmpty
                  ? const Center(child: Text('There are no groceries to buy'))
                  : ListView.builder(
                      itemCount: _groceryItems.length,
                      itemBuilder: (ctx, index) => Dismissible(
                        key: ValueKey(_groceryItems[index].id),
                        onDismissed: ((direction) =>
                            _removeItem(_groceryItems[index])),
                        child: ListTile(
                          title: Text(_groceryItems[index].name),
                          leading: Container(
                            width: 24,
                            height: 24,
                            color: _groceryItems[index].category.color,
                          ),
                          trailing:
                              Text(_groceryItems[index].quantity.toString()),
                        ),
                      ),
                    ),
            );
    }
  }
}
