import '../models/dining_table.dart';
import '../database.dart';

class TableDao {
  final DatabaseHelper _dbHelper;
  TableDao(this._dbHelper);

  Future<List<DiningTable>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('dining_table', orderBy: 'sort_order ASC');
    return rows.map(DiningTable.fromMap).toList();
  }

  Future<DiningTable?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('dining_table', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return DiningTable.fromMap(rows.first);
  }

  Future<List<DiningTable>> getByAreaId(int areaId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('dining_table', where: 'area_id = ?', whereArgs: [areaId], orderBy: 'sort_order ASC');
    return rows.map(DiningTable.fromMap).toList();
  }

  Future<int> create(DiningTable table) async {
    final db = await _dbHelper.database;
    return db.insert('dining_table', table.toMap());
  }

  Future<int> update(DiningTable table) async {
    final db = await _dbHelper.database;
    return db.update('dining_table', table.toMap(), where: 'id = ?', whereArgs: [table.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('dining_table', where: 'id = ?', whereArgs: [id]);
  }
}
