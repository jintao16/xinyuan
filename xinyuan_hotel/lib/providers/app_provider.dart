import 'package:flutter/foundation.dart';

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
import '../services/availability_service.dart';
import '../services/backup_service.dart';
import '../services/conflict_service.dart';
import '../services/stats_service.dart';
import '../utils/time_util.dart';

/// 全局应用 Provider
/// 持有所有 DAO/Service 实例，缓存常用数据，统一通知 UI 刷新
class AppProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final FloorDao _floorDao;
  final AreaDao _areaDao;
  final TableDao _tableDao;
  final TimeSlotDao _timeSlotDao;
  final ReservationDao _reservationDao;

  late final ConflictService _conflictService;
  late final AvailabilityService _availabilityService;
  late final StatsService _statsService;
  late final BackupService _backupService;

  // 缓存
  List<Floor> _floors = [];
  List<Area> _areas = [];
  List<DiningTable> _tables = [];
  List<QuickTimeSlot> _timeSlots = [];
  List<Reservation> _todayReservations = [];

  AppProvider()
      : _dbHelper = DatabaseHelper(),
        _floorDao = FloorDao(DatabaseHelper()),
        _areaDao = AreaDao(DatabaseHelper()),
        _tableDao = TableDao(DatabaseHelper()),
        _timeSlotDao = TimeSlotDao(DatabaseHelper()),
        _reservationDao = ReservationDao(DatabaseHelper()) {
    _conflictService = ConflictService(_reservationDao);
    _availabilityService = AvailabilityService(_floorDao, _areaDao, _tableDao, _reservationDao);
    _statsService = StatsService(_reservationDao, _tableDao, _areaDao);
    _backupService = BackupService(_dbHelper, _floorDao, _areaDao, _tableDao, _timeSlotDao, _reservationDao);
  }

  // ===== 访问器 =====
  List<Floor> get floors => _floors;
  List<Area> get areas => _areas;
  List<DiningTable> get tables => _tables;
  List<QuickTimeSlot> get timeSlots => _timeSlots;
  List<Reservation> get todayReservations => _todayReservations;
  ConflictService get conflictService => _conflictService;
  AvailabilityService get availabilityService => _availabilityService;
  StatsService get statsService => _statsService;
  BackupService get backupService => _backupService;
  FloorDao get floorDao => _floorDao;
  AreaDao get areaDao => _areaDao;
  TableDao get tableDao => _tableDao;
  TimeSlotDao get timeSlotDao => _timeSlotDao;
  ReservationDao get reservationDao => _reservationDao;

  /// 初始化加载
  Future<void> init() async {
    await refreshAll();
  }

  /// 刷新所有缓存
  Future<void> refreshAll() async {
    _floors = await _floorDao.getAll();
    _areas = await _areaDao.getAll();
    _tables = await _tableDao.getAll();
    _timeSlots = await _timeSlotDao.getAll();
    _todayReservations = await _reservationDao.getByDate(TimeUtil.today());
    notifyListeners();
  }

  /// 刷新预订缓存
  Future<void> refreshReservations() async {
    _todayReservations = await _reservationDao.getByDate(TimeUtil.today());
    notifyListeners();
  }

  // ===== 预订操作 =====

  /// 获取指定日期的预订
  Future<List<Reservation>> getReservationsByDate(String date) {
    return _reservationDao.getByDate(date);
  }

  /// 获取日期范围预订
  Future<List<Reservation>> getReservationsByRange(String start, String end) {
    return _reservationDao.getByDateRange(start, end);
  }

  /// 检测冲突
  Future<bool> hasConflict(Reservation reservation, {int? excludeId}) {
    return _conflictService.hasConflict(reservation, excludeId: excludeId);
  }

  /// 创建预订（含冲突检测）
  /// 返回 (success, message)
  Future<(bool, String)> createReservation(Reservation reservation) async {
    if (await _conflictService.hasConflict(reservation)) {
      return (false, '该时段已被预订，请选择其他桌位/包厢或调整时间');
    }
    await _reservationDao.create(reservation);
    await refreshReservations();
    return (true, '预订成功');
  }

  /// 更新预订
  Future<(bool, String)> updateReservation(Reservation reservation) async {
    if (await _conflictService.hasConflict(reservation, excludeId: reservation.id)) {
      return (false, '该时段已被预订，请选择其他桌位/包厢或调整时间');
    }
    await _reservationDao.update(reservation);
    await refreshReservations();
    return (true, '已保存修改');
  }

  /// 变更状态
  Future<void> changeReservationStatus(int id, ReservationStatus status) async {
    await _reservationDao.changeStatus(id, status, TimeUtil.nowIso());
    await refreshReservations();
  }

  /// 删除预订
  Future<void> deleteReservation(int id) async {
    await _reservationDao.delete(id);
    await refreshReservations();
  }

  // ===== 楼层操作 =====
  Future<void> createFloor(Floor floor) async {
    await _floorDao.create(floor);
    _floors = await _floorDao.getAll();
    notifyListeners();
  }

  Future<void> updateFloor(Floor floor) async {
    await _floorDao.update(floor);
    _floors = await _floorDao.getAll();
    notifyListeners();
  }

  Future<(bool, String)> deleteFloor(int id) async {
    if (!await _floorDao.canDelete(id)) {
      return (false, '该楼层下有区域，请先删除区域');
    }
    await _floorDao.delete(id);
    _floors = await _floorDao.getAll();
    notifyListeners();
    return (true, '已删除');
  }

  // ===== 区域操作 =====
  Future<void> createArea(Area area) async {
    await _areaDao.create(area);
    _areas = await _areaDao.getAll();
    notifyListeners();
  }

  Future<void> updateArea(Area area) async {
    await _areaDao.update(area);
    _areas = await _areaDao.getAll();
    notifyListeners();
  }

  Future<(bool, String)> deleteArea(int id) async {
    if (!await _areaDao.canDelete(id)) {
      return (false, '该区域下有桌位，请先删除桌位');
    }
    await _areaDao.delete(id);
    _areas = await _areaDao.getAll();
    notifyListeners();
    return (true, '已删除');
  }

  // ===== 桌位操作 =====
  Future<void> createTable(DiningTable table) async {
    await _tableDao.create(table);
    _tables = await _tableDao.getAll();
    notifyListeners();
  }

  Future<void> updateTable(DiningTable table) async {
    await _tableDao.update(table);
    _tables = await _tableDao.getAll();
    notifyListeners();
  }

  Future<void> deleteTable(int id) async {
    await _tableDao.delete(id);
    _tables = await _tableDao.getAll();
    notifyListeners();
  }

  // ===== 快捷时段操作 =====
  Future<void> createTimeSlot(QuickTimeSlot slot) async {
    await _timeSlotDao.create(slot);
    _timeSlots = await _timeSlotDao.getAll();
    notifyListeners();
  }

  Future<void> updateTimeSlot(QuickTimeSlot slot) async {
    await _timeSlotDao.update(slot);
    _timeSlots = await _timeSlotDao.getAll();
    notifyListeners();
  }

  Future<void> deleteTimeSlot(int id) async {
    await _timeSlotDao.delete(id);
    _timeSlots = await _timeSlotDao.getAll();
    notifyListeners();
  }

  // ===== 备份 =====
  Future<String> exportData() => _backupService.exportToFile();
  Future<ImportResult> importData(String json) async {
    final result = await _backupService.importFromJson(json);
    await refreshAll();
    return result;
  }

  /// 测试用：重置数据库到初始预置数据
  Future<void> resetToSeedForTesting() async {
    await _dbHelper.resetToSeed();
    await refreshAll();
  }

  // ===== 辅助 =====

  /// 获取预订的显示标签
  String getReservationLabel(Reservation r) {
    if (r.tableId != null) {
      final t = _tables.where((x) => x.id == r.tableId).firstOrNull;
      final a = t != null ? _areas.where((x) => x.id == t.areaId).firstOrNull : null;
      return '${a?.name ?? '-'} · ${t?.name ?? '-'}';
    }
    if (r.areaId != null) {
      final a = _areas.where((x) => x.id == r.areaId).firstOrNull;
      return a?.name ?? '-';
    }
    return '-';
  }

  /// 获取即将到店的预订（今日 booked 且前后30分钟内）
  List<Reservation> get upcoming {
    return _todayReservations
        .where((r) => r.status == ReservationStatus.booked && TimeUtil.isUpcoming(r.startTime))
        .toList();
  }

  /// 按状态统计今日预订数
  int get bookedCountToday => _todayReservations.where((r) => r.status == ReservationStatus.booked).length;
  int get completedCountToday => _todayReservations.where((r) => r.status == ReservationStatus.completed).length;
  int get cancelledCountToday => _todayReservations.where((r) => r.status == ReservationStatus.cancelled).length;
}
