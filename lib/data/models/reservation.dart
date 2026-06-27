import 'package:flutter/material.dart';

/// 预订状态枚举
enum ReservationStatus {
  booked('booked', '已预订'),
  completed('completed', '已完成'),
  cancelled('cancelled', '已取消');

  final String dbValue;
  final String label;
  const ReservationStatus(this.dbValue, this.label);

  static ReservationStatus fromDb(String value) {
    return values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ReservationStatus.booked,
    );
  }

  /// 是否占用资源（影响空闲判定）
  bool get occupies => this == ReservationStatus.booked;

  /// 状态对应的标签颜色
  Color get color {
    switch (this) {
      case ReservationStatus.booked:
        return const Color(0xFF2F80ED);
      case ReservationStatus.completed:
        return const Color(0xFF30A75F);
      case ReservationStatus.cancelled:
        return const Color(0xFF8E8E98);
    }
  }

  /// 标签背景色（淡色）
  Color get backgroundColor {
    switch (this) {
      case ReservationStatus.booked:
        return const Color(0xFF2F80ED).withOpacity(0.12);
      case ReservationStatus.completed:
        return const Color(0xFF30A75F).withOpacity(0.12);
      case ReservationStatus.cancelled:
        return const Color(0xFF8E8E98).withOpacity(0.12);
    }
  }
}

/// 预订模型
class Reservation {
  final int? id;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final int? tableId; // 大厅桌预订时填写
  final int? areaId; // 包厢预订时填写
  final String customerTitle;
  final String customerPhone;
  final int? guestCount;
  final ReservationStatus status;
  final String remark;
  final String createdAt;
  final String updatedAt;

  Reservation({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.tableId,
    this.areaId,
    required this.customerTitle,
    this.customerPhone = '',
    this.guestCount,
    this.status = ReservationStatus.booked,
    this.remark = '',
    required this.createdAt,
    required this.updatedAt,
  }) {
    // 互斥校验：tableId 和 areaId 二选一
    assert(
      (tableId != null && areaId == null) || (tableId == null && areaId != null),
      'tableId 和 areaId 必须二选一非空',
    );
  }

  Reservation copyWith({
    int? id,
    String? date,
    String? startTime,
    String? endTime,
    int? tableId,
    int? areaId,
    String? customerTitle,
    String? customerPhone,
    int? guestCount,
    ReservationStatus? status,
    String? remark,
    String? createdAt,
    String? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      tableId: tableId ?? this.tableId,
      areaId: areaId ?? this.areaId,
      customerTitle: customerTitle ?? this.customerTitle,
      customerPhone: customerPhone ?? this.customerPhone,
      guestCount: guestCount ?? this.guestCount,
      status: status ?? this.status,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as int?,
      date: map['date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      tableId: map['table_id'] as int?,
      areaId: map['area_id'] as int?,
      customerTitle: map['customer_title'] as String? ?? '',
      customerPhone: map['customer_phone'] as String? ?? '',
      guestCount: map['guest_count'] as int?,
      status: ReservationStatus.fromDb(map['status'] as String),
      remark: map['remark'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'table_id': tableId,
      'area_id': areaId,
      'customer_title': customerTitle,
      'customer_phone': customerPhone,
      'guest_count': guestCount,
      'status': status.dbValue,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() =>
      'Reservation(id: $id, date: $date, $startTime-$endTime, customer: $customerTitle, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reservation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
