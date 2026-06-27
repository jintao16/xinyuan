/// 区域类型枚举
enum AreaType {
  hall('hall', '大厅'),
  privateRoom('private_room', '包厢');

  final String dbValue;
  final String label;
  const AreaType(this.dbValue, this.label);

  static AreaType fromDb(String value) {
    return values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AreaType.hall,
    );
  }
}

/// 区域模型
class Area {
  final int? id;
  final int floorId;
  final String name;
  final AreaType type;
  final int sortOrder;

  Area({
    this.id,
    required this.floorId,
    required this.name,
    required this.type,
    this.sortOrder = 0,
  });

  Area copyWith({
    int? id,
    int? floorId,
    String? name,
    AreaType? type,
    int? sortOrder,
  }) {
    return Area(
      id: id ?? this.id,
      floorId: floorId ?? this.floorId,
      name: name ?? this.name,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Area.fromMap(Map<String, dynamic> map) {
    return Area(
      id: map['id'] as int?,
      floorId: (map['floor_id'] as num).toInt(),
      name: map['name'] as String,
      type: AreaType.fromDb(map['type'] as String),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'floor_id': floorId,
      'name': name,
      'type': type.dbValue,
      'sort_order': sortOrder,
    };
  }

  @override
  String toString() => 'Area(id: $id, floorId: $floorId, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Area && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
