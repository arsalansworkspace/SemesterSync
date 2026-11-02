class Project {
  final int? id;
  final int subjectId;
  final String title;
  final String description;
  final String dueDate;
  final int isCompleted; // 0 = Pending, 1 = Completed

  Project({
    this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      subjectId: map['subjectId'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'],
      isCompleted: map['isCompleted'],
    );
  }
}