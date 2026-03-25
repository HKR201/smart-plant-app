import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> getDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'plants_care.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE plants(id INTEGER PRIMARY KEY AUTOINCREMENT, plant_name TEXT, category TEXT, message TEXT, image_path TEXT, date TEXT)",
        );
      },
      version: 1,
    );
  }

  static Future<void> savePlant(Map<String, dynamic> data) async {
    final db = await getDB();
    await db.insert('plants', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPlants() async {
    final db = await getDB();
    return db.query('plants', orderBy: "id DESC"); // အသစ်ဆုံးကို အပေါ်ဆုံးက ပြမည်
  }
}
