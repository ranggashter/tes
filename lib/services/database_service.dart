import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/sensor_log.dart';

class DatabaseService {
  static Database? _database;

  // Singleton
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fallsafe.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sensor_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        print('✅ Tabel sensor_logs dibuat');
      },
    );
  }

  // Simpan log baru
  static Future<int> insertLog(SensorLog log) async {
    final db = await database;
    return await db.insert('sensor_logs', log.toMap());
  }

  // Ambil semua log (terbaru di atas)
  static Future<List<SensorLog>> getAllLogs() async {
    final db = await database;
    final maps = await db.query(
      'sensor_logs',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SensorLog.fromMap(map)).toList();
  }

  // Ambil log terakhir
  static Future<SensorLog?> getLatestLog() async {
    final db = await database;
    final maps = await db.query(
      'sensor_logs',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SensorLog.fromMap(maps.first);
  }

  // Hitung total log
  static Future<int> countLogs() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM sensor_logs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Hapus semua log (untuk testing)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('sensor_logs');
  }
}