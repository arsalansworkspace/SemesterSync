class TimetableSlot {
  final int? id;
  final int subjectId;
  final String dayOfWeek; // e.g., 'Monday', 'Tuesday'
  final String startTime; // e.g., '09:00 AM'
  final String endTime;   // e.g., '10:30 AM'
  final String roomNumber;
  final String instructor;

  TimetableSlot({
    this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
    required this.instructor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
      'instructor': instructor,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      id: map['id'],
      subjectId: map['subjectId'],
      dayOfWeek: map['dayOfWeek'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      roomNumber: map['roomNumber'],
      instructor: map['instructor'],
    );
  }
}