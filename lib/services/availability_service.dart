import '../data/dao/area_dao.dart';
import '../data/dao/floor_dao.dart';
import '../data/dao/reservation_dao.dart';
import '../data/dao/table_dao.dart';
import '../data/models/area.dart';
import '../data/models/dining_table.dart';
import '../data/models/floor.dart';
import '../data/models/reservation.dart';

/// 桌位空闲状态
enum AvailabilityStatus { free, occupied }

/// 单个桌位的空闲信息
class TableAvailability {
  final DiningTable table;
  final Area area;
  final Floor floor;
  final AvailabilityStatus status;
  final Reservation? reservation; // 占用时的来源预订
  final String? occupiedBy; // 'table' 或 'area'

  const TableAvailability({
    required this.table,
    required this.area,
    required this.floor,
    required this.status,
    this.reservation,
    this.occupiedBy,
  });

  bool get isFree => status == AvailabilityStatus.free;
}

/// 按楼层分组的空闲查询结果
class FloorAvailability {
  final Floor floor;
  final List<AreaAvailability> areas;
  const FloorAvailability({required this.floor, required this.areas});
}

/// 按区域分组的空闲查询结果
class AreaAvailability {
  final Area area;
  final List<TableAvailability> tables;
  const AreaAvailability({required this.area, required this.tables});

  /// 包厢整体是否空闲（所有桌位空闲）
  bool get isRoomFree {
    if (area.type != AreaType.privateRoom) return false;
    if (tables.isEmpty) return true;
    return tables.every((t) => t.isFree);
  }
}

/// 空闲查询服务
class AvailabilityService {
  final FloorDao _floorDao;
  final AreaDao _areaDao;
  final TableDao _tableDao;
  final ReservationDao _reservationDao;

  AvailabilityService(this._floorDao, this._areaDao, this._tableDao, this._reservationDao);

  /// 查询指定日期、时段的桌位/包厢空闲情况
  Future<List<FloorAvailability>> query({
    required String date,
    required String startTime,
    required String endTime,
    int? guestCount,
  }) async {
    final floors = await _floorDao.getAll();
    final result = <FloorAvailability>[];

    for (final floor in floors) {
      final areas = await _areaDao.getByFloorId(floor.id!);
      final areaAvailabilities = <AreaAvailability>[];

      for (final area in areas) {
        final tables = await _tableDao.getByAreaId(area.id!);
        final tableAvails = <TableAvailability>[];

        for (final table in tables) {
          // 查该桌位该时段是否有 booked 预订
          final tableConflicts = await _reservationDao.getConflictsForTable(
            tableId: table.id!,
            date: date,
            startTime: startTime,
            endTime: endTime,
          );

          if (tableConflicts.isNotEmpty) {
            tableAvails.add(TableAvailability(
              table: table,
              area: area,
              floor: floor,
              status: AvailabilityStatus.occupied,
              reservation: tableConflicts.first,
              occupiedBy: 'table',
            ));
            continue;
          }

          // 如果是包厢，查该包厢整体是否被预订
          if (area.type == AreaType.privateRoom) {
            final areaConflicts = await _reservationDao.getConflictsForArea(
              areaId: area.id!,
              date: date,
              startTime: startTime,
              endTime: endTime,
            );
            if (areaConflicts.isNotEmpty) {
              tableAvails.add(TableAvailability(
                table: table,
                area: area,
                floor: floor,
                status: AvailabilityStatus.occupied,
                reservation: areaConflicts.first,
                occupiedBy: 'area',
              ));
              continue;
            }
          }

          tableAvails.add(TableAvailability(
            table: table,
            area: area,
            floor: floor,
            status: AvailabilityStatus.free,
          ));
        }

        // 按人数过滤排序：seats >= 人数 优先，其次按座位数接近度
        if (guestCount != null && guestCount > 0) {
          tableAvails.sort((a, b) {
            final aOk = a.table.seats >= guestCount;
            final bOk = b.table.seats >= guestCount;
            if (aOk && !bOk) return -1;
            if (!aOk && bOk) return 1;
            final aDiff = (a.table.seats - guestCount).abs();
            final bDiff = (b.table.seats - guestCount).abs();
            return aDiff.compareTo(bDiff);
          });
        }

        areaAvailabilities.add(AreaAvailability(area: area, tables: tableAvails));
      }

      result.add(FloorAvailability(floor: floor, areas: areaAvailabilities));
    }

    return result;
  }
}
