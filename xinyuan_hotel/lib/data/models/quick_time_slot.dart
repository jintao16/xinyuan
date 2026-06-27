/// 快捷时段模型
class QuickTimeSlot {
  final int? id;
  final String name;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final int sortOrder;

  QuickTimeSlot({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.sortOrder = 0,
  });

  QuickTimeSlot copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    int? sortOrder,
  }) {
    return QuickTimeSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory QuickTimeSlot.fromMap(Map<String, dynamic> map) {
    return QuickTimeSlot(
      id: map['id'] as int?,
      name: map['name'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'sort_order': sortOrder,
    };
  }

  @override
  String toString() => 'QuickTimeSlot(id: $id, name: $name, $startTime-$endTime)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuickTimeSlot && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
