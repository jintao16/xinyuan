import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// 数据库助手单例
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  static const int _dbVersion = 1;
  static const String _dbName = 'xinyuan_hotel.db';

  /// 获取数据库实例（懒加载）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// 建表 + 初始化预置数据
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 楼层
    batch.execute('''
      CREATE TABLE floor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_main INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 区域
    batch.execute('''
      CREATE TABLE area (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        floor_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (floor_id) REFERENCES floor(id) ON DELETE RESTRICT
      )
    ''');

    // 桌位
    batch.execute('''
      CREATE TABLE dining_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        area_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        seats INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (area_id) REFERENCES area(id) ON DELETE RESTRICT
      )
    ''');

    // 快捷时段
    batch.execute('''
      CREATE TABLE quick_time_slot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 预订
    batch.execute('''
      CREATE TABLE reservation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        table_id INTEGER,
        area_id INTEGER,
        customer_title TEXT NOT NULL DEFAULT '',
        customer_phone TEXT NOT NULL DEFAULT '',
        guest_count INTEGER,
        status TEXT NOT NULL DEFAULT 'booked',
        remark TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (table_id) REFERENCES dining_table(id) ON DELETE SET NULL,
        FOREIGN KEY (area_id) REFERENCES area(id) ON DELETE SET NULL
      )
    ''');

    // 索引
    batch.execute('CREATE INDEX idx_area_floor ON area(floor_id)');
    batch.execute('CREATE INDEX idx_table_area ON dining_table(area_id)');
    batch.execute('CREATE INDEX idx_reservation_date ON reservation(date)');
    batch.execute('CREATE INDEX idx_reservation_table ON reservation(table_id)');
    batch.execute('CREATE INDEX idx_reservation_area ON reservation(area_id)');
    batch.execute('CREATE INDEX idx_reservation_status ON reservation(status)');

    await batch.commit(noResult: true);

    // 预置数据
    await _seedInitialData(db);
  }

  /// 预置初始数据（按 design.md 第 8 章）
  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();

    // 楼层
    batch.insert('floor', {'name': '一楼', 'sort_order': 1, 'is_main': 0});
    batch.insert('floor', {'name': '二楼', 'sort_order': 2, 'is_main': 1});

    // 一楼大厅
    batch.insert('area', {'floor_id': 1, 'name': '一楼大厅', 'type': 'hall', 'sort_order': 1});

    // 二楼大厅 + 包厢
    batch.insert('area', {'floor_id': 2, 'name': '二楼大厅', 'type': 'hall', 'sort_order': 1});
    batch.insert('area', {'floor_id': 2, 'name': 'VIP1号包厢', 'type': 'private_room', 'sort_order': 2});
    batch.insert('area', {'floor_id': 2, 'name': 'VIP2号包厢', 'type': 'private_room', 'sort_order': 3});
    batch.insert('area', {'floor_id': 2, 'name': '牡丹厅包厢', 'type': 'private_room', 'sort_order': 4});

    // 一楼大厅活动桌
    batch.insert('dining_table', {'area_id': 1, 'name': 'A1', 'seats': 8, 'sort_order': 1});
    batch.insert('dining_table', {'area_id': 1, 'name': 'A2', 'seats': 8, 'sort_order': 2});

    // 二楼大厅小桌 + 大桌
    batch.insert('dining_table', {'area_id': 2, 'name': 'B1', 'seats': 4, 'sort_order': 1});
    batch.insert('dining_table', {'area_id': 2, 'name': 'B2', 'seats': 4, 'sort_order': 2});
    batch.insert('dining_table', {'area_id': 2, 'name': 'B3', 'seats': 4, 'sort_order': 3});
    batch.insert('dining_table', {'area_id': 2, 'name': 'B4', 'seats': 4, 'sort_order': 4});
    batch.insert('dining_table', {'area_id': 2, 'name': 'C1', 'seats': 12, 'sort_order': 5});
    batch.insert('dining_table', {'area_id': 2, 'name': 'C2', 'seats': 14, 'sort_order': 6});

    // VIP1号包厢
    batch.insert('dining_table', {'area_id': 3, 'name': '大圆桌', 'seats': 16, 'sort_order': 1});

    // VIP2号包厢（大小桌组合）
    batch.insert('dining_table', {'area_id': 4, 'name': '大圆桌', 'seats': 20, 'sort_order': 1});
    batch.insert('dining_table', {'area_id': 4, 'name': '小方桌', 'seats': 4, 'sort_order': 2});

    // 牡丹厅包厢
    batch.insert('dining_table', {'area_id': 5, 'name': '大圆桌', 'seats': 18, 'sort_order': 1});

    // 快捷时段
    batch.insert('quick_time_slot', {'name': '午餐', 'start_time': '11:00', 'end_time': '13:00', 'sort_order': 1});
    batch.insert('quick_time_slot', {'name': '晚餐', 'start_time': '17:00', 'end_time': '19:00', 'sort_order': 2});

    await batch.commit(noResult: true);
  }

  /// 关闭数据库（测试用）
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 删除数据库（测试/重置用）
  Future<void> deleteDb() async {
    await close();
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);
    await databaseFactory.deleteDatabase(dbPath);
  }

  /// 重置到初始预置数据状态（测试用）
  /// 清空所有表后重新执行 _seedInitialData
  Future<void> resetToSeed() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('reservation');
      await txn.delete('dining_table');
      await txn.delete('quick_time_slot');
      await txn.delete('area');
      await txn.delete('floor');
    });
    await _seedInitialData(db);
  }
}
