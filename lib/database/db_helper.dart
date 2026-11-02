import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/timetable_slot.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  DBHelper._init();

  // --- Storage Keys ---
  static const String _subjectsKey = 'semester_sync_subjects';
  static const String _timetableKey = 'semester_sync_timetable';
  static const String _timetableImageKey = 'semester_sync_timetable_image';
  static const String _tasksKey = 'semester_sync_tasks';
  static const String _notesKey = 'semester_sync_notes'; // Declared ONLY once here

  // ==========================================
  // --- Subject CRUD Operations ---
  // ==========================================
  Future<int> insertSubject(Subject subject) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Subject> subjects = await getSubjects();

    int newId = DateTime.now().millisecondsSinceEpoch;
    final newSubject = Subject(
      id: newId,
      title: subject.title,
      code: subject.code,
      instructor: subject.instructor,
      colorHex: subject.colorHex,
    );

    subjects.add(newSubject);
    final String encoded = jsonEncode(subjects.map((s) => s.toMap()).toList());
    await prefs.setString(_subjectsKey, encoded);
    return newId;
  }

  Future<List<Subject>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_subjectsKey);
    if (encoded == null) return [];

    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((json) => Subject.fromMap(json)).toList();
  }

  Future<int> updateSubject(Subject subject) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Subject> subjects = await getSubjects();

    final index = subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      subjects[index] = subject;
      final String encoded = jsonEncode(subjects.map((s) => s.toMap()).toList());
      await prefs.setString(_subjectsKey, encoded);
      return 1;
    }
    return 0;
  }

  Future<int> deleteSubject(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Subject> subjects = await getSubjects();

    subjects.removeWhere((s) => s.id == id);
    final String encoded = jsonEncode(subjects.map((s) => s.toMap()).toList());
    await prefs.setString(_subjectsKey, encoded);
    return 1;
  }

  // ==========================================
  // --- Timetable Image & Slots CRUD ---
  // ==========================================
  Future<void> saveTimetableImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timetableImageKey, path);
  }

  Future<String?> getTimetableImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_timetableImageKey);
  }

  Future<int> insertTimetableSlot(TimetableSlot slot) async {
    final prefs = await SharedPreferences.getInstance();
    final List<TimetableSlot> slots = await getTimetableSlots();

    int newId = DateTime.now().millisecondsSinceEpoch;
    final newSlot = TimetableSlot(
      id: newId,
      subjectId: slot.subjectId,
      dayOfWeek: slot.dayOfWeek,
      startTime: slot.startTime,
      endTime: slot.endTime,
      roomNumber: slot.roomNumber,
      instructor: slot.instructor,
    );

    slots.add(newSlot);
    final String encoded = jsonEncode(slots.map((s) => s.toMap()).toList());
    await prefs.setString(_timetableKey, encoded);
    return newId;
  }

  Future<List<TimetableSlot>> getTimetableSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_timetableKey);
    if (encoded == null) return [];

    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((json) => TimetableSlot.fromMap(json)).toList();
  }

  Future<int> deleteTimetableSlot(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<TimetableSlot> slots = await getTimetableSlots();

    slots.removeWhere((s) => s.id == id);
    final String encoded = jsonEncode(slots.map((s) => s.toMap()).toList());
    await prefs.setString(_timetableKey, encoded);
    return 1;
  }

  Future<void> clearAllTimetableSlots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timetableKey, '[]');
  }

  // ==========================================
  // --- Tasks CRUD ---
  // ==========================================
  Future<int> insertTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Task> tasks = await getTasks();

    int newId = DateTime.now().millisecondsSinceEpoch;
    final newTask = Task(
      id: newId,
      subjectId: task.subjectId,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
    );

    tasks.add(newTask);
    final String encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_tasksKey, encoded);
    return newId;
  }

  Future<List<Task>> getTasksBySubject(int subjectId) async {
    final allTasks = await getTasks();
    return allTasks.where((t) => t.subjectId == subjectId).toList();
  }

  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_tasksKey);
    if (encoded == null) return [];

    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> updateTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Task> tasks = await getTasks();

    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      final String encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
      await prefs.setString(_tasksKey, encoded);
      return 1;
    }
    return 0;
  }

  Future<int> deleteTask(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Task> tasks = await getTasks();

    tasks.removeWhere((t) => t.id == id);
    final String encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_tasksKey, encoded);
    return 1;
  }

  // ==========================================
  // --- Notes CRUD --- (Corrected version)
  // ==========================================
  Future<int> insertNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Note> notes = await getNotes();

    int newId = DateTime.now().millisecondsSinceEpoch;
    final newNote = Note(
      id: newId,
      title: note.title,
      content: note.content,
      date: note.date, // Properly matches the model
    );

    notes.add(newNote);
    await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toMap()).toList()));
    return newId;
  }

  Future<List<Note>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_notesKey);
    if (encoded == null) return [];

    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((json) => Note.fromMap(json)).toList();
  }

  Future<void> updateNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Note> notes = await getNotes();

    final index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = note;
      await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toMap()).toList()));
    }
  }

  Future<void> deleteNote(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Note> notes = await getNotes();

    notes.removeWhere((n) => n.id == id);
    await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toMap()).toList()));
  }
}