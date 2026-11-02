class Subject {
  final int? id;
  final String title;
  final String code;
  final String instructor;
  final String colorHex;

  Subject({
    this.id,
    required this.title,
    required this.code,
    required this.instructor,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'instructor': instructor,
      'colorHex': colorHex,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      title: map['title'],
      code: map['code'],
      instructor: map['instructor'],
      colorHex: map['colorHex'],
    );
  }
}