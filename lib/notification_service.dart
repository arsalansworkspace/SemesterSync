import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint("Notifications disabled on Web/Chrome mode.");
      return;
    }
  }

  Future<void> scheduleDeadlineNotification({
    required int id,
    required String taskTitle,
    required String subjectName,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) {
      debugPrint("Scheduled task alert for $taskTitle ($subjectName)");
      return;
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
  }
}