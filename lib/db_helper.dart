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
    // ID အဟောင်းနဲ့ ပြန်ထည့်ရင် (Undo လုပ်ရင်) နေရာဟောင်းမှာပဲ အစားထိုးအောင် replace သုံးထားပါတယ်
    await db.insert('plants', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // OPTIMIZATION: Added limit and offset parameters for database-level pagination
  // This prevents loading hundreds of rows into memory all at once.
  static Future<List<Map<String, dynamic>>> getPlants({int limit = 10, int offset = 0}) async {
    final db = await getDB();
    return db.query(
      'plants', 
      orderBy: "id DESC",
      limit: limit,   // တစ်ခါခေါ်လျှင် ဘယ်နှစ်ခုခေါ်မည်နည်း
      offset: offset  // ဘယ်နေရာကနေ စခေါ်မည်နည်း
    ); 
  }
  

  // --- အသစ်ထည့်လိုက်သော မှတ်တမ်းဖျက်ရန် Function ---
  static Future<void> deletePlant(int id) async {
    final db = await getDB();
    await db.delete('plants', where: "id = ?", whereArgs: [id]);
  }
}
