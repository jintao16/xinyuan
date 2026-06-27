import '../models/reservation.dart';
import '../database.dart';

class ReservationDao {
  final DatabaseHelper _dbHelper;
  ReservationDao(this._dbHelper);

  Future<List<Reservation>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('reservation', orderBy: 'date ASC, start_time ASC');
    return rows.map(Reservation.fromMap).toList();
  }

  Future<Reservation?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('reservation', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Reservation.fromMap(rows.first);
  }

  Future<List<Reservation>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query('reservation', where: 'date = ?', whereArgs: [date], orderBy: 'start_time ASC');
    return rows.map(Reservation.fromMap).toList();
  }

  Future<List<Reservation>> getByDateRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'reservation',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, start_time ASC',
    );
    return rows.map(Reservation.fromMap).toList();
  }

  Future<List<Reservation>> getByStatus(ReservationStatus status, {String? date}) async {
    final db = await _dbHelper.database;
    if (date != null) {
      final rows = await db.query(
        'reservation',
        where: 'status = ? AND date = ?',
        whereArgs: [status.dbValue, date],
        orderBy: 'start_time ASC',
      );
      return rows.map(Reservation.fromMap).toList();
    }
    final rows = await db.query('reservation', where: 'status = ?', whereArgs: [status.dbValue]);
    return rows.map(Reservation.fromMap).toList();
  }

  /// 查询指定桌位在某日期、某时段有冲突的预订
  Future<List<Reservation>> getConflictsForTable({
    required int tableId,
    required String date,
    required String startTime,
    required String endTime,
    int? excludeId,
  }) async {
    final db = await _dbHelper.database;
    final where = StringBuffer(
      'table_id = ? AND date = ? AND status = ? AND start_time < ? AND end_time > ?',
    );
    final args = <dynamic>[tableId, date, ReservationStatus.booked.dbValue, endTime, startTime];
    if (excludeId != null) {
      where.write(' AND id != ?');
      args.add(excludeId);
    }
    final rows = await db.query('reservation', where: where.toString(), whereArgs: args);
    return rows.map(Reservation.fromMap).toList();
  }

  /// 查询指定包厢在某日期、某时段有冲突的预订
  Future<List<Reservation>> getConflictsForArea({
    required int areaId,
    required String date,
    required String startTime,
    required String endTime,
    int? excludeId,
  }) async {
    final db = await _dbHelper.database;
    final where = StringBuffer(
      'area_id = ? AND date = ? AND status = ? AND start_time < ? AND end_time > ?',
    );
    final args = <dynamic>[areaId, date, ReservationStatus.booked.dbValue, endTime, startTime];
    if (excludeId != null) {
      where.write(' AND id != ?');
      args.add(excludeId);
    }
    final rows = await db.query('reservation', where: where.toString(), whereArgs: args);
    return rows.map(Reservation.fromMap).toList();
  }

  Future<int> create(Reservation reservation) async {
    final db = await _dbHelper.database;
    return db.insert('reservation', reservation.toMap());
  }

  Future<int> update(Reservation reservation) async {
    final db = await _dbHelper.database;
    return db.update('reservation', reservation.toMap(), where: 'id = ?', whereArgs: [reservation.id]);
  }

  Future<int> changeStatus(int id, ReservationStatus status, String updatedAt) async {
    final db = await _dbHelper.database;
    return db.update('reservation', {'status': status.dbValue, 'updated_at': updatedAt}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('reservation', where: 'id = ?', whereArgs: [id]);
  }
}
