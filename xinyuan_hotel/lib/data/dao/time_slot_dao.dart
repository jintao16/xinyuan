import '../models/quick_time_slot.dart';
import '../database.dart';

class TimeSlotDao {
  final DatabaseHelper _dbHelper;
  TimeSlotDao(this._dbHelper);

  Future<List<QuickTimeSlot>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('quick_time_slot', orderBy: 'sort_order ASC');
    return rows.map(QuickTimeSlot.fromMap).toList();
  }

  Future<QuickTimeSlot?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('quick_time_slot', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return QuickTimeSlot.fromMap(rows.first);
  }

  Future<int> create(QuickTimeSlot slot) async {
    final db = await _dbHelper.database;
    return db.insert('quick_time_slot', slot.toMap());
  }

  Future<int> update(QuickTimeSlot slot) async {
    final db = await _dbHelper.database;
    return db.update('quick_time_slot', slot.toMap(), where: 'id = ?', whereArgs: [slot.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('quick_time_slot', where: 'id = ?', whereArgs: [id]);
  }
}
