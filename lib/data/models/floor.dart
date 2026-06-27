/// 楼层模型
class Floor {
  final int? id;
  final String name;
  final int sortOrder;
  final bool isMain;

  Floor({
    this.id,
    required this.name,
    this.sortOrder = 0,
    this.isMain = false,
  });

  Floor copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? isMain,
  }) {
    return Floor(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isMain: isMain ?? this.isMain,
    );
  }

  factory Floor.fromMap(Map<String, dynamic> map) {
    return Floor(
      id: map['id'] as int?,
      name: map['name'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isMain: (map['is_main'] as num?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'sort_order': sortOrder,
      'is_main': isMain ? 1 : 0,
    };
  }

  @override
  String toString() => 'Floor(id: $id, name: $name, sortOrder: $sortOrder, isMain: $isMain)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Floor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
