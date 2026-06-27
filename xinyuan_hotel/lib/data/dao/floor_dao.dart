import '../models/floor.dart';
import '../database.dart';

class FloorDao {
  final DatabaseHelper _dbHelper;
  FloorDao(this._dbHelper);

  Future<List<Floor>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('floor', orderBy: 'sort_order ASC');
    return rows.map(Floor.fromMap).toList();
  }

  Future<Floor?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('floor', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Floor.fromMap(rows.first);
  }

  Future<int> create(Floor floor) async {
    final db = await _dbHelper.database;
    return db.insert('floor', floor.toMap());
  }

  Future<int> update(Floor floor) async {
    final db = await _dbHelper.database;
    return db.update('floor', floor.toMap(), where: 'id = ?', whereArgs: [floor.id]);
  }

  /// 检查是否可删除（无关联区域）
  Future<bool> canDelete(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('area', where: 'floor_id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty;
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('floor', where: 'id = ?', whereArgs: [id]);
  }
}
