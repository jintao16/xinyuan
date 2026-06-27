import '../models/area.dart';
import '../database.dart';

class AreaDao {
  final DatabaseHelper _dbHelper;
  AreaDao(this._dbHelper);

  Future<List<Area>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('area', orderBy: 'sort_order ASC');
    return rows.map(Area.fromMap).toList();
  }

  Future<Area?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('area', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Area.fromMap(rows.first);
  }

  Future<List<Area>> getByFloorId(int floorId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('area', where: 'floor_id = ?', whereArgs: [floorId], orderBy: 'sort_order ASC');
    return rows.map(Area.fromMap).toList();
  }

  Future<List<Area>> getByType(AreaType type) async {
    final db = await _dbHelper.database;
    final rows = await db.query('area', where: 'type = ?', whereArgs: [type.dbValue], orderBy: 'sort_order ASC');
    return rows.map(Area.fromMap).toList();
  }

  Future<int> create(Area area) async {
    final db = await _dbHelper.database;
    return db.insert('area', area.toMap());
  }

  Future<int> update(Area area) async {
    final db = await _dbHelper.database;
    return db.update('area', area.toMap(), where: 'id = ?', whereArgs: [area.id]);
  }

  /// 检查是否可删除（无关联桌位）
  Future<bool> canDelete(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('dining_table', where: 'area_id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty;
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('area', where: 'id = ?', whereArgs: [id]);
  }
}
