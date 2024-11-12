import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

// Model class for item
class Item {
  int? indexNumber;
  int roomNumber;
  String clientName;
  int rentingDuration;

  Item({
    this.indexNumber,
    required this.roomNumber,
    required this.clientName,
    required this.rentingDuration,
  });

  // Convert Item to a map (for storing in DB)
  Map<String, dynamic> toMap() {
    return {
      'indexNumber': indexNumber,
      'roomNumber': roomNumber,
      'clientName': clientName,
      'rentingDuration': rentingDuration,
    };
  }

  // Convert map to Item
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      indexNumber: map['indexNumber'],
      roomNumber: map['roomNumber'],
      clientName: map['clientName'],
      rentingDuration: map['rentingDuration'],
    );
  }
}

// Database helper class
class DatabaseHelper {
  static Database? _database;

  // Get a reference to the database
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Open the database (no need for path_provider; it will use the default location)
    _database = await openDatabase(
      'renting_duration.db', // Database file name
      version: 1,
      onCreate: (db, version) async {
        // Create table if it doesn't exist
        await db.execute(
          '''CREATE TABLE Renting_duration_of_the_rooms(
            indexNumber INTEGER PRIMARY KEY AUTOINCREMENT, 
            roomNumber INTEGER, 
            clientName TEXT, 
            rentingDuration INTEGER)''',
        );
      },
    );

    return _database!;
  }

  // Insert an item into the database
  Future<void> insertItem(Item item) async {
    final db = await database;
    await db.insert(
      'Renting_duration_of_the_rooms',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve all items from the database
  Future<List<Item>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Renting_duration_of_the_rooms');

    return List.generate(maps.length, (i) {
      return Item.fromMap(maps[i]);
    });
  }

  // Update an existing item
  Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update(
      'Renting_duration_of_the_rooms',
      item.toMap(),
      where: 'indexNumber = ?',
      whereArgs: [item.indexNumber],
    );
  }

  // Delete an item
  Future<void> deleteItem(int indexNumber) async {
    final db = await database;
    await db.delete(
      'Renting_duration_of_the_rooms',
      where: 'indexNumber = ?',
      whereArgs: [indexNumber],
    );
  }
}

// Main app widget
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD with SQLite',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ItemListScreen(),
    );
  }
}

// Item list screen (CRUD operations UI)
class ItemListScreen extends StatefulWidget {
  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // Load items from the database
  _loadItems() async {
    final itemsFromDb = await _databaseHelper.getItems();
    setState(() {
      _items = itemsFromDb;
    });
  }

  // Add a new item
  _addItem(int roomNumber, String clientName, int rentingDuration) async {
    final newItem = Item(
      roomNumber: roomNumber,
      clientName: clientName,
      rentingDuration: rentingDuration,
    );
    await _databaseHelper.insertItem(newItem);
    _loadItems(); // Reload the list after adding
  }

  // Update an item
  _updateItem(Item item) async {
    TextEditingController roomNumberController = TextEditingController(text: item.roomNumber.toString());
    TextEditingController clientNameController = TextEditingController(text: item.clientName);
    TextEditingController rentingDurationController = TextEditingController(text: item.rentingDuration.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNumberController,
                decoration: InputDecoration(labelText: 'Room number'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: clientNameController,
                decoration: InputDecoration(labelText: 'Client name'),
              ),
              TextField(
                controller: rentingDurationController,
                decoration: InputDecoration(labelText: 'Renting duration'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final roomNumber = int.tryParse(roomNumberController.text) ?? 0;
                final clientName = clientNameController.text;
                final rentingDuration = int.tryParse(rentingDurationController.text) ?? 0;
                if (clientName.isNotEmpty && roomNumber > 0 && rentingDuration > 0) {
                  final updatedItem = Item(
                    indexNumber: item.indexNumber, // Keep the same indexNumber
                    roomNumber: roomNumber,
                    clientName: clientName,
                    rentingDuration: rentingDuration,
                  );
                  _databaseHelper.updateItem(updatedItem);
                  _loadItems(); // Reload the list after updating
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Delete an item
  _deleteItem(int indexNumber) async {
    await _databaseHelper.deleteItem(indexNumber);
    _loadItems(); // Reload the list after deleting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rented rooms')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.clientName),
            subtitle: Text('Room Number: ${item.roomNumber}, Renting Duration: ${item.rentingDuration} days'),
            onTap: () => _updateItem(item), // Show edit dialog on item tap
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteItem(item.indexNumber!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // Show dialog to add a new item
  _showAddItemDialog(BuildContext context) {
    TextEditingController roomNumberController = TextEditingController();
    TextEditingController clientNameController = TextEditingController();
    TextEditingController rentingDurationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rent a room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNumberController,
                decoration: InputDecoration(labelText: 'Room number'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: clientNameController,
                decoration: InputDecoration(labelText: 'Client name'),
              ),
              TextField(
                controller: rentingDurationController,
                decoration: InputDecoration(labelText: 'Renting duration'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final roomNumber = int.tryParse(roomNumberController.text) ?? 0;
                final clientName = clientNameController.text;
                final rentingDuration = int.tryParse(rentingDurationController.text) ?? 0;
                if (clientName.isNotEmpty && roomNumber > 0 && rentingDuration > 0) {
                  _addItem(roomNumber, clientName, rentingDuration);
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}