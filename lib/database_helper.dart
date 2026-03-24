import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('plants.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Database အသစ်ဖန်တီးခြင်း
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // အပင်မှတ်တမ်းများ သိမ်းဆည်းရန် ဇယား (Table) တည်ဆောက်ခြင်း
    await db.execute('''
CREATE TABLE plants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  imagePath TEXT NOT NULL,
  advice TEXT,
  saveDate TEXT NOT NULL
)
''');
  }

  // အပင်အသစ် သိမ်းဆည်းခြင်း
  Future<int> insertPlant(Map<String, dynamic> plant) async {
    final db = await instance.database;
    return await db.insert('plants', plant);
  }

  // သိမ်းထားသော အပင်များကို အမျိုးအစားအလိုက် ပြန်ခေါ်ခြင်း
  Future<List<Map<String, dynamic>>> getPlants() async {
    final db = await instance.database;
    return await db.query('plants', orderBy: 'saveDate DESC');
  }

  // အပင် မှတ်တမ်းဖျက်ခြင်း
  Future<int> deletePlant(int id) async {
    final db = await instance.database;
    return await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }
}
