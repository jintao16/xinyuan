/// 桌位模型
class DiningTable {
  final int? id;
  final int areaId;
  final String name;
  final int seats;
  final int sortOrder;

  DiningTable({
    this.id,
    required this.areaId,
    required this.name,
    required this.seats,
    this.sortOrder = 0,
  });

  DiningTable copyWith({
    int? id,
    int? areaId,
    String? name,
    int? seats,
    int? sortOrder,
  }) {
    return DiningTable(
      id: id ?? this.id,
      areaId: areaId ?? this.areaId,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory DiningTable.fromMap(Map<String, dynamic> map) {
    return DiningTable(
      id: map['id'] as int?,
      areaId: (map['area_id'] as num).toInt(),
      name: map['name'] as String,
      seats: (map['seats'] as num).toInt(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'area_id': areaId,
      'name': name,
      'seats': seats,
      'sort_order': sortOrder,
    };
  }

  @override
  String toString() => 'DiningTable(id: $id, areaId: $areaId, name: $name, seats: $seats)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DiningTable && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
