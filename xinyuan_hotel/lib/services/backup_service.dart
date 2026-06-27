import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/dao/area_dao.dart';
import '../data/dao/floor_dao.dart';
import '../data/dao/reservation_dao.dart';
import '../data/dao/table_dao.dart';
import '../data/dao/time_slot_dao.dart';
import '../data/database.dart';
import '../data/models/area.dart';
import '../data/models/dining_table.dart';
import '../data/models/floor.dart';
import '../data/models/quick_time_slot.dart';
import '../data/models/reservation.dart';

/// 导入结果摘要
class ImportResult {
  final int floors;
  final int areas;
  final int tables;
  final int timeSlots;
  final int reservations;

  const ImportResult({
    required this.floors,
    required this.areas,
    required this.tables,
    required this.timeSlots,
    required this.reservations,
  });

  @override
  String toString() => 'ImportResult(floors: $floors, areas: $areas, tables: $tables, timeSlots: $timeSlots, reservations: $reservations)';
}

/// 备份服务（导入/导出）
class BackupService {
  final DatabaseHelper _dbHelper;
  final FloorDao _floorDao;
  final AreaDao _areaDao;
  final TableDao _tableDao;
  final TimeSlotDao _timeSlotDao;
  final ReservationDao _reservationDao;

  BackupService(
    this._dbHelper,
    this._floorDao,
    this._areaDao,
    this._tableDao,
    this._timeSlotDao,
    this._reservationDao,
  );

  /// 导出全库为 JSON 字符串
  Future<String> exportToJson() async {
    final List<Floor> floors = await _floorDao.getAll();
    final List<Area> areas = await _areaDao.getAll();
    final List<DiningTable> tables = await _tableDao.getAll();
    final List<QuickTimeSlot> timeSlots = await _timeSlotDao.getAll();
    final List<Reservation> reservations = await _reservationDao.getAll();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'floors': floors.map((f) => f.toMap()).toList(),
      'areas': areas.map((a) => a.toMap()).toList(),
      'tables': tables.map((t) => t.toMap()).toList(),
      'timeSlots': timeSlots.map((s) => s.toMap()).toList(),
      'reservations': reservations.map((r) => r.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 导出并保存到文件，返回文件路径
  /// 文件名格式：xinyuan_backup_YYYYMMDD_HHmmss.json
  Future<String> exportToFile() async {
    final json = await exportToJson();
    final now = DateTime.now();
    final timestamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final fileName = 'xinyuan_backup_$timestamp.json';

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, fileName);
    final file = File(filePath);
    await file.writeAsString(json);
    return filePath;
  }

  /// 覆盖式导入：清空所有表，用导入数据替换
  /// 在事务内执行，失败回滚
  Future<ImportResult> importFromJson(String jsonStr) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw const FormatException('JSON 格式错误');
    }

    // 结构校验
    final requiredKeys = ['floors', 'areas', 'tables', 'reservations'];
    for (final key in requiredKeys) {
      if (!data.containsKey(key)) {
        throw FormatException('数据缺少必需字段: $key');
      }
    }

    final db = await _dbHelper.database;

    return db.transaction((txn) async {
      // 清空（按外键依赖反序）
      await txn.delete('reservation');
      await txn.delete('dining_table');
      await txn.delete('quick_time_slot');
      await txn.delete('area');
      await txn.delete('floor');

      // 插入楼层
      int floorsCount = 0;
      for (final item in data['floors'] as List) {
        await txn.insert('floor', Map<String, dynamic>.from(item));
        floorsCount++;
      }

      // 插入区域
      int areasCount = 0;
      for (final item in data['areas'] as List) {
        await txn.insert('area', Map<String, dynamic>.from(item));
        areasCount++;
      }

      // 插入桌位
      int tablesCount = 0;
      for (final item in data['tables'] as List) {
        await txn.insert('dining_table', Map<String, dynamic>.from(item));
        tablesCount++;
      }

      // 插入快捷时段
      int timeSlotsCount = 0;
      if (data['timeSlots'] != null) {
        for (final item in data['timeSlots'] as List) {
          await txn.insert('quick_time_slot', Map<String, dynamic>.from(item));
          timeSlotsCount++;
        }
      }

      // 插入预订
      int reservationsCount = 0;
      for (final item in data['reservations'] as List) {
        await txn.insert('reservation', Map<String, dynamic>.from(item));
        reservationsCount++;
      }

      return ImportResult(
        floors: floorsCount,
        areas: areasCount,
        tables: tablesCount,
        timeSlots: timeSlotsCount,
        reservations: reservationsCount,
      );
    });
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
