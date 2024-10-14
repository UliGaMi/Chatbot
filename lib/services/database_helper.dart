import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chatbot.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE chat_history(id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT, is_user INTEGER)',
        );
      },
    );
  }

  Future<void> insertMessage(String message, bool isUser) async {
    final db = await database;
    await db.insert(
      'chat_history',
      {'message': message, 'is_user': isUser ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final db = await database;
    return await db.query('chat_history');
  }

  Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete('chat_history');
  }
}


