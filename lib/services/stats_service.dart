import '../data/dao/area_dao.dart';
import '../data/dao/reservation_dao.dart';
import '../data/dao/table_dao.dart';
import '../data/models/reservation.dart';

/// 预订量汇总
class ReservationSummary {
  final int total;
  final int booked;
  final int completed;
  final int cancelled;
  final int arrivalRate; // 到店率百分比

  const ReservationSummary({
    required this.total,
    required this.booked,
    required this.completed,
    required this.cancelled,
    required this.arrivalRate,
  });
}

/// 桌位使用率条目
class TableUsageItem {
  final String name;
  final int count;
  final int percent; // 相对最大值的百分比

  const TableUsageItem({required this.name, required this.count, required this.percent});
}

/// 时段分布条目
class HourlyItem {
  final int hour;
  final int count;
  const HourlyItem({required this.hour, required this.count});
}

/// 区域占比
class AreaRatio {
  final int halls; // 大厅预订数
  final int rooms; // 包厢预订数
  final int total;
  final int hallsPercent;
  final int roomsPercent;

  const AreaRatio({
    required this.halls,
    required this.rooms,
    required this.total,
    required this.hallsPercent,
    required this.roomsPercent,
  });
}

/// 统计服务
class StatsService {
  final ReservationDao _reservationDao;
  final TableDao _tableDao;
  final AreaDao _areaDao;

  StatsService(this._reservationDao, this._tableDao, this._areaDao);

  /// 预订量汇总
  Future<ReservationSummary> summary(String startDate, String endDate) async {
    final list = await _reservationDao.getByDateRange(startDate, endDate);
    final booked = list.where((r) => r.status == ReservationStatus.booked).length;
    final completed = list.where((r) => r.status == ReservationStatus.completed).length;
    final cancelled = list.where((r) => r.status == ReservationStatus.cancelled).length;
    final arrivalRate = list.isEmpty ? 0 : (completed * 100 / list.length).round();
    return ReservationSummary(
      total: list.length,
      booked: booked,
      completed: completed,
      cancelled: cancelled,
      arrivalRate: arrivalRate,
    );
  }

  /// 桌位使用率（按桌位/包厢统计被预订次数）
  Future<List<TableUsageItem>> tableUsage(String startDate, String endDate) async {
    final list = await _reservationDao.getByDateRange(startDate, endDate);
    final usage = <String, int>{};

    for (final r in list) {
      if (r.status == ReservationStatus.cancelled) continue;
      if (r.tableId != null) {
        final t = await _tableDao.getById(r.tableId!);
        final a = t != null ? await _areaDao.getById(t.areaId) : null;
        final key = '桌·${a?.name ?? '?'} ${t?.name ?? '?'}';
        usage[key] = (usage[key] ?? 0) + 1;
      } else if (r.areaId != null) {
        final a = await _areaDao.getById(r.areaId!);
        final key = '包厢·${a?.name ?? '?'}';
        usage[key] = (usage[key] ?? 0) + 1;
      }
    }

    final max = usage.values.fold(1, (a, b) => a > b ? a : b);
    final entries = usage.entries.map((e) {
      return TableUsageItem(name: e.key, count: e.value, percent: (e.value * 100 / max).round());
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return entries;
  }

  /// 时段分布（按小时，9-22 点）
  Future<List<HourlyItem>> hourlyDistribution(String startDate, String endDate) async {
    final list = await _reservationDao.getByDateRange(startDate, endDate);
    final hours = List.filled(24, 0);
    for (final r in list) {
      final h = int.tryParse(r.startTime.split(':')[0]) ?? 0;
      if (h >= 0 && h < 24) hours[h]++;
    }
    return [for (int h = 9; h <= 22; h++) HourlyItem(hour: h, count: hours[h])];
  }

  /// 区域占比（大厅 vs 包厢）
  Future<AreaRatio> areaRatio(String startDate, String endDate) async {
    final list = await _reservationDao.getByDateRange(startDate, endDate);
    int halls = 0;
    int rooms = 0;
    for (final r in list) {
      if (r.status == ReservationStatus.cancelled) continue;
      if (r.tableId != null) {
        final t = await _tableDao.getById(r.tableId!);
        final a = t != null ? await _areaDao.getById(t.areaId) : null;
        if (a != null && a.type.name == 'hall') {
          halls++;
        }
      } else if (r.areaId != null) {
        rooms++;
      }
    }
    final total = halls + rooms;
    return AreaRatio(
      halls: halls,
      rooms: rooms,
      total: total,
      hallsPercent: total == 0 ? 0 : (halls * 100 / total).round(),
      roomsPercent: total == 0 ? 0 : (rooms * 100 / total).round(),
    );
  }
}
