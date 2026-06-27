import '../data/dao/reservation_dao.dart';
import '../data/models/reservation.dart';

/// 冲突检测服务
class ConflictService {
  final ReservationDao _reservationDao;
  ConflictService(this._reservationDao);

  /// 检测给定预订信息是否与现有预订冲突
  /// [excludeId] 编辑时排除自身 ID
  Future<bool> hasConflict(Reservation reservation, {int? excludeId}) async {
    // 已完成/已取消不占用资源，不冲突
    if (!reservation.status.occupies) return false;

    // 大厅桌预订
    if (reservation.tableId != null) {
      final conflicts = await _reservationDao.getConflictsForTable(
        tableId: reservation.tableId!,
        date: reservation.date,
        startTime: reservation.startTime,
        endTime: reservation.endTime,
        excludeId: excludeId,
      );
      return conflicts.isNotEmpty;
    }

    // 包厢预订
    if (reservation.areaId != null) {
      final conflicts = await _reservationDao.getConflictsForArea(
        areaId: reservation.areaId!,
        date: reservation.date,
        startTime: reservation.startTime,
        endTime: reservation.endTime,
        excludeId: excludeId,
      );
      return conflicts.isNotEmpty;
    }

    return false;
  }
}
